<?php
/**
 * Compare, pour chaque extension / thème / cœur : version épinglée (lock), version installée,
 * version disponible selon WordPress.org (ou l'updater du fournisseur pour les premium).
 *
 * Usage : wp eval-file scripts/php/check-updates.php <config/plugins.json> <config/stack.json> [json]
 * (`json` sans tirets : `wp eval-file` refuse les options qu'il ne connaît pas.)
 * Sortie : tableau lisible (défaut) ou JSON (json). Code de retour 0 toujours ; le JSON contient `updates_available`.
 */

if ( ! defined( 'WP_CLI' ) || ! WP_CLI ) {
	fwrite( STDERR, "Ce script doit être lancé via `wp eval-file`.\n" );
	exit( 1 );
}

$plugins_file = $args[0] ?? '';
$stack_file   = $args[1] ?? '';
$as_json      = in_array( 'json', $args, true );

foreach ( array( $plugins_file, $stack_file ) as $f ) {
	if ( ! is_readable( $f ) ) {
		WP_CLI::error( "Fichier introuvable : {$f}" );
	}
}
$lock  = json_decode( file_get_contents( $plugins_file ), true );
$stack = json_decode( file_get_contents( $stack_file ), true );

require_once ABSPATH . 'wp-admin/includes/plugin.php';
require_once ABSPATH . 'wp-admin/includes/update.php';
require_once ABSPATH . 'wp-admin/includes/theme.php';

// Forcer une vérification fraîche auprès de WordPress.org (et des updaters tiers via les hooks standards).
delete_site_transient( 'update_plugins' );
delete_site_transient( 'update_themes' );
delete_site_transient( 'update_core' );
wp_update_plugins();
wp_update_themes();
wp_version_check( array(), true );

$plugin_updates = get_site_transient( 'update_plugins' );
$theme_updates  = get_site_transient( 'update_themes' );
$core_updates   = get_core_updates();

$installed = get_plugins(); // [ 'elementor/elementor.php' => [ 'Name' => ..., 'Version' => ... ] ]
$by_slug   = array();
foreach ( $installed as $file => $data ) {
	$by_slug[ dirname( $file ) === '.' ? basename( $file, '.php' ) : dirname( $file ) ] = array( 'file' => $file, 'data' => $data );
}

$rows = array();
$updates_available = 0;

// --- Cœur ----------------------------------------------------------------------
$core_latest = null;
foreach ( (array) $core_updates as $u ) {
	if ( isset( $u->response ) && 'upgrade' === $u->response ) {
		$core_latest = $u->current;
		break;
	}
}
$core_installed = get_bloginfo( 'version' );
$core_row = array(
	'type'      => 'core',
	'slug'      => 'wordpress',
	'name'      => 'WordPress',
	'locked'    => $stack['wordpress']['version'] ?? '',
	'installed' => $core_installed,
	'available' => $core_latest ?: $core_installed,
	'source'    => 'wporg',
	'status'    => $core_latest && version_compare( $core_latest, $core_installed, '>' ) ? 'update' : 'ok',
);
if ( 'update' === $core_row['status'] ) {
	$updates_available++;
}
$rows[] = $core_row;

// --- Thème ---------------------------------------------------------------------
$theme_slug      = $stack['theme']['slug'] ?? get_stylesheet();
$theme_obj       = wp_get_theme( $theme_slug );
$theme_installed = $theme_obj->exists() ? $theme_obj->get( 'Version' ) : null;
$theme_available = $theme_updates->response[ $theme_slug ]['new_version'] ?? $theme_installed;
$theme_row = array(
	'type'      => 'theme',
	'slug'      => $theme_slug,
	'name'      => $stack['theme']['name'] ?? $theme_slug,
	'locked'    => $stack['theme']['version'] ?? '',
	'installed' => $theme_installed ?: 'absent',
	'available' => $theme_available ?: '?',
	'source'    => $stack['theme']['source'] ?? 'wporg',
	'status'    => ! $theme_installed ? 'missing' : ( version_compare( $theme_available, $theme_installed, '>' ) ? 'update' : 'ok' ),
);
if ( 'update' === $theme_row['status'] ) {
	$updates_available++;
}
$rows[] = $theme_row;

// --- Extensions ----------------------------------------------------------------
foreach ( $lock['plugins'] as $p ) {
	$slug = $p['slug'];
	$inst = $by_slug[ $slug ] ?? null;
	$row  = array(
		'type'         => 'plugin',
		'slug'         => $slug,
		'name'         => $p['name'],
		'locked'       => $p['version'],
		'installed'    => $inst ? $inst['data']['Version'] : 'absent',
		'available'    => '?',
		'source'       => $p['source'],
		'update_check' => $p['update_check'] ?? 'wporg',
		'active'       => $inst ? is_plugin_active( $inst['file'] ) : false,
		'status'       => 'ok',
	);

	if ( ! $inst ) {
		$row['status'] = 'missing';
	} else {
		$file = $inst['file'];
		if ( isset( $plugin_updates->response[ $file ] ) ) {
			$row['available'] = $plugin_updates->response[ $file ]->new_version;
			$row['status']    = 'update';
			$updates_available++;
		} elseif ( isset( $plugin_updates->no_update[ $file ] ) ) {
			$row['available'] = $plugin_updates->no_update[ $file ]->new_version;
			$row['status']    = 'ok';
		} else {
			// Aucune info : premium sans licence active, ou plugin hors dépôt sans updater.
			$row['available'] = 'inconnu';
			$row['status']    = ( 'manual' === $row['update_check'] || 'license' === $row['update_check'] ) ? 'check-vendor' : 'unknown';
		}
		if ( 'ok' === $row['status'] && version_compare( $row['installed'], $row['locked'], '!=' ) ) {
			$row['status'] = 'lock-drift'; // installé ≠ lock : snapshot.sh à relancer
		}
		if ( ! $row['active'] && ! empty( $p['activate'] ) ) {
			$row['status'] = 'inactive';
		}
	}
	$rows[] = $row;
}

// --- Extensions installées mais absentes du lock ---------------------------------
$lock_slugs = array_column( $lock['plugins'], 'slug' );
foreach ( $by_slug as $slug => $inst ) {
	if ( ! in_array( $slug, $lock_slugs, true ) ) {
		$rows[] = array(
			'type'      => 'plugin',
			'slug'      => $slug,
			'name'      => $inst['data']['Name'],
			'locked'    => '—',
			'installed' => $inst['data']['Version'],
			'available' => '',
			'source'    => '?',
			'active'    => is_plugin_active( $inst['file'] ),
			'status'    => 'not-in-lock',
		);
	}
}

$report = array(
	'checked_at'        => gmdate( 'c' ),
	'updates_available' => $updates_available,
	'rows'              => $rows,
);

if ( $as_json ) {
	echo wp_json_encode( $report, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE ), "\n";
	return;
}

$labels = array(
	'ok'           => 'à jour',
	'update'       => 'MISE À JOUR',
	'missing'      => 'MANQUANT',
	'inactive'     => 'INACTIF',
	'lock-drift'   => 'lock ≠ installé',
	'check-vendor' => 'vérifier chez le fournisseur',
	'unknown'      => 'inconnu',
	'not-in-lock'  => 'HORS LOCK',
);
$table = array();
foreach ( $rows as $r ) {
	$table[] = array(
		'Type'       => $r['type'],
		'Extension'  => $r['name'],
		'Slug'       => $r['slug'],
		'Lock'       => $r['locked'],
		'Installée'  => $r['installed'],
		'Disponible' => $r['available'],
		'Source'     => $r['source'],
		'État'       => $labels[ $r['status'] ] ?? $r['status'],
	);
}
WP_CLI\Utils\format_items( 'table', $table, array( 'Type', 'Extension', 'Slug', 'Lock', 'Installée', 'Disponible', 'Source', 'État' ) );
WP_CLI::log( '' );
$missing = count( wp_list_filter( $rows, array( 'status' => 'missing' ) ) );
if ( $updates_available ) {
	WP_CLI::log( "{$updates_available} mise(s) à jour disponible(s)." );
} elseif ( ! $missing ) {
	WP_CLI::log( 'Tout est à jour.' );
}
if ( $missing ) {
	WP_CLI::log( "{$missing} élément(s) manquant(s) : lancer scripts/install.sh." );
}
