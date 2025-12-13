<?php
// Läs in inställningar från OpenShift Secrets (Env vars)
define( 'DB_NAME',     getenv('DB_NAME') ?: 'wordpress_db' );
define( 'DB_USER',     getenv('DB_USER') ?: 'wordpress' );
define( 'DB_PASSWORD', getenv('DB_PASSWORD') ?: 'password' );
define( 'DB_HOST',     'mariadb' ); // Namnet på din Service
define( 'DB_CHARSET',  'utf8' );
define( 'DB_COLLATE',  '' );

// Unika nycklar och salter (Viktigt för säkerhet!)
define('AUTH_KEY',         getenv('WP_AUTH_KEY'));
define('SECURE_AUTH_KEY',  getenv('WP_SECURE_AUTH_KEY'));
define('LOGGED_IN_KEY',    getenv('WP_LOGGED_IN_KEY'));
define('NONCE_KEY',        getenv('WP_NONCE_KEY'));
define('AUTH_SALT',        getenv('WP_AUTH_SALT'));
define('SECURE_AUTH_SALT', getenv('WP_SECURE_AUTH_SALT'));
define('LOGGED_IN_SALT',   getenv('WP_LOGGED_IN_SALT'));
define('NONCE_SALT',       getenv('WP_NONCE_SALT'));

$table_prefix = 'wp_';

define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', true );

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';