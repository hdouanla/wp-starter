<?php
/**
 * Synchronise les versions épinglées (config/plugins.json, config/stack.json) avec ce qui est
 * réellement installé sur le site. À lancer après une mise à jour réussie.
 *
 * Usage : wp eval-file scripts/php/snapshot.php <config/plugins.json> <config/stack.json>
 * Affiche les changements de version (ancien → nouveau), un par ligne, sur STDOUT.
 */

if ( ! defined( 'WP_CLI' ) || ! WP_CLI ) {
	fwrite( STDERR, "Ce script doit être lancé via `wp eval-file`.\n" );
	exit( 1 );
}

$plugins_file = $args[0] ?? '';
$stack_file   = $args[1] ?? '';
foreach ( array( $plugins_file, $stack_file ) as $f ) {
	if ( ! is_writable( $f ) ) {
		WP_CLI::error( "Fichier introuvable ou non inscriptible : {$f}" );
	}
}

require_once ABSPATH . 'wp-admin/includes/plugin.php';

$lock  = json_decode( file_get_contents( $plugins_file ), true );
$stack = json_decode( file_get_contents( $stack_file ), true );

$installed = array();
foreach ( get_plugins() as $file => $data ) {
	$installed[ dirname( $file ) === '.' ? basename( $file, '.php' ) : dirname( $file ) ] = $data['Version'];
}

$changes = array();

foreach ( $lock['plugins'] as &$p ) {
	$slug = $p['slug'];
	if ( isset( $installed[ $slug ] ) && $installed[ $slug ] !== $p['version'] ) {
		$changes[] = "{$p['name']} {$p['version']} → {$installed[ $slug ]}";
		$p['version'] = $installed[ $slug ];
	}
}
unset( $p );

$core = get_bloginfo( 'version' );
if ( ( $stack['wordpress']['version'] ?? '' ) !== $core ) {
	$changes[] = "WordPress {$stack['wordpress']['version']} → {$core}";
	$stack['wordpress']['version'] = $core;
}

$theme = wp_get_theme( $stack['theme']['slug'] ?? get_stylesheet() );
if ( $theme->exists() && $theme->get( 'Version' ) !== ( $stack['theme']['version'] ?? '' ) ) {
	$changes[] = "{$stack['theme']['name']} {$stack['theme']['version']} → {$theme->get( 'Version' )}";
	$stack['theme']['version'] = $theme->get( 'Version' );
}

$stack['localwp']['php']      = PHP_VERSION;
$stack['wordpress']['locale'] = get_locale();
$stack['snapshot_at']         = gmdate( 'Y-m-d' );

$flags = JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE;
file_put_contents( $plugins_file, wp_json_encode( $lock, $flags ) . "\n" );
file_put_contents( $stack_file, wp_json_encode( $stack, $flags ) . "\n" );

if ( $changes ) {
	foreach ( $changes as $c ) {
		WP_CLI::log( $c );
	}
} else {
	WP_CLI::log( 'Aucun changement de version.' );
}
