<?php
/**
 * Applique config/settings.json au site courant.
 * Usage : wp eval-file scripts/php/apply-settings.php <chemin/settings.json> [--dry-run]
 * Idempotent. S'exécute dans le contexte WordPress chargé par WP-CLI.
 */

if ( ! defined( 'WP_CLI' ) || ! WP_CLI ) {
	fwrite( STDERR, "Ce script doit être lancé via `wp eval-file`.\n" );
	exit( 1 );
}

$settings_file = $args[0] ?? '';
$dry_run       = in_array( '--dry-run', $args, true );

if ( ! $settings_file || ! is_readable( $settings_file ) ) {
	WP_CLI::error( "Fichier settings.json introuvable : {$settings_file}" );
}

$settings = json_decode( file_get_contents( $settings_file ), true );
if ( json_last_error() !== JSON_ERROR_NONE ) {
	WP_CLI::error( 'settings.json invalide : ' . json_last_error_msg() );
}

$changed = 0;
$same    = 0;

// --- 1. Options brutes ------------------------------------------------------
foreach ( $settings['options'] ?? array() as $key => $value ) {
	$current = get_option( $key, '__absent__' );
	// Comparaison souple : WP stocke souvent les entiers en chaînes.
	$equal = ( $current !== '__absent__' ) && ( (string) $current === (string) $value || $current === $value );
	if ( $equal ) {
		$same++;
		continue;
	}
	$changed++;
	WP_CLI::log( sprintf( '  %-42s %s → %s', $key, var_export( $current === '__absent__' ? null : $current, true ), var_export( $value, true ) ) );
	if ( ! $dry_run ) {
		update_option( $key, $value );
	}
}
WP_CLI::log( sprintf( 'Options : %d modifiée(s), %d déjà conforme(s).', $changed, $same ) );

// --- 2. Nom du site starter (uniquement s'il est vide ou par défaut) ---------
$default_name = $settings['site_defaults']['blogname'] ?? '';
$blogname     = get_option( 'blogname' );
if ( $default_name && ( '' === $blogname || preg_match( '/^(My WordPress|Mon site|Local Site)/i', $blogname ) ) ) {
	WP_CLI::log( "  blogname : « {$blogname} » → « {$default_name} »" );
	if ( ! $dry_run ) {
		update_option( 'blogname', $default_name );
	}
}

// --- 3. Nettoyage -----------------------------------------------------------
$cleanup = $settings['cleanup'] ?? array();

if ( ! empty( $cleanup['delete_sample_content'] ) ) {
	$samples = array();
	// Article « Hello world! » / « Bonjour tout le monde ! »
	foreach ( get_posts( array( 'post_type' => 'post', 'numberposts' => 5, 'post_status' => 'any', 'orderby' => 'ID', 'order' => 'ASC' ) ) as $p ) {
		if ( in_array( $p->post_name, array( 'hello-world', 'bonjour-tout-le-monde' ), true ) ) {
			$samples[] = $p;
		}
	}
	// Page d'exemple + politique de confidentialité (brouillon par défaut)
	foreach ( get_posts( array( 'post_type' => 'page', 'numberposts' => 10, 'post_status' => 'any', 'orderby' => 'ID', 'order' => 'ASC' ) ) as $p ) {
		if ( in_array( $p->post_name, array( 'sample-page', 'page-d-exemple', 'privacy-policy', 'politique-de-confidentialite' ), true ) ) {
			$samples[] = $p;
		}
	}
	foreach ( $samples as $p ) {
		WP_CLI::log( "  Suppression {$p->post_type} #{$p->ID} « {$p->post_title} »" );
		if ( ! $dry_run ) {
			wp_delete_post( $p->ID, true );
		}
	}
	if ( ! $dry_run ) {
		update_option( 'wp_page_for_privacy_policy', 0 );
	}
	// Commentaire d'exemple
	foreach ( get_comments( array( 'number' => 5, 'orderby' => 'comment_ID', 'order' => 'ASC' ) ) as $c ) {
		if ( false !== stripos( $c->comment_author, 'WordPress' ) || false !== stripos( $c->comment_content, 'wapuu' ) ) {
			WP_CLI::log( "  Suppression commentaire #{$c->comment_ID}" );
			if ( ! $dry_run ) {
				wp_delete_comment( $c->comment_ID, true );
			}
		}
	}
}

if ( ! empty( $cleanup['delete_default_themes_except'] ) ) {
	$keep   = (array) $cleanup['delete_default_themes_except'];
	$active = get_stylesheet();
	foreach ( wp_get_themes() as $slug => $theme ) {
		$is_default = 0 === strpos( $slug, 'twentytwenty' ) || 0 === strpos( $slug, 'twenty' );
		if ( $is_default && ! in_array( $slug, $keep, true ) && $slug !== $active ) {
			WP_CLI::log( "  Suppression thème {$slug}" );
			if ( ! $dry_run ) {
				delete_theme( $slug );
			}
		}
	}
}

if ( ! empty( $cleanup['empty_trash'] ) && ! $dry_run ) {
	foreach ( get_posts( array( 'post_type' => 'any', 'post_status' => 'trash', 'numberposts' => -1 ) ) as $p ) {
		wp_delete_post( $p->ID, true );
	}
}

if ( ! empty( $cleanup['flush_rewrite_rules'] ) && ! $dry_run ) {
	flush_rewrite_rules( true );
	WP_CLI::log( '  Règles de réécriture régénérées.' );
}

if ( $dry_run ) {
	WP_CLI::success( 'Simulation terminée (aucune modification).' );
} else {
	WP_CLI::success( 'Réglages appliqués.' );
}
