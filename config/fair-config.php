<?php
/**
 * FAIR Plugin Configuration for CloudFest Hackathon
 *
 * This file is automatically loaded as a mu-plugin to configure
 * the FAIR plugin to use the local AspireCloud instance.
 */

// Ensure we're in WordPress context
if (!defined('ABSPATH')) {
    exit;
}

// Log that mu-plugin is loading (FIRST LINE after ABSPATH check)
error_log('[FAIR Config] mu-plugin loaded at ' . date('Y-m-d H:i:s'));

// Configure FAIR to use local AspireCloud via Docker network
// WordPress can access AspireCloud directly by container name
// This constant is checked by FAIR\Default_Repo\get_default_repo_domain()
// Format: just the domain/hostname without protocol or port
// FAIR will add the protocol and path
if (!defined('FAIR_DEFAULT_REPO_DOMAIN')) {
    define('FAIR_DEFAULT_REPO_DOMAIN', 'aspirecloud:80');
}

// Enable FAIR for all package types
add_filter('fair_enable_plugin_updates', '__return_true', 1);
add_filter('fair_enable_theme_updates', '__return_true', 1);
add_filter('fair_enable_core_updates', '__return_true', 1);

// Debug logging for hackathon
add_filter('fair_debug_mode', function() {
    return defined('WP_DEBUG') && WP_DEBUG;
}, 1);

// Force HTTP for local AspireCloud requests (AspireCloud doesn't support HTTPS)
// This filter runs at high priority to catch requests AFTER FAIR has modified them
add_filter('pre_http_request', function($preempt, $args, $url) {
    // Log all API requests for debugging
    if (strpos($url, 'api.wordpress.org') !== false || strpos($url, 'aspirecloud') !== false) {
        error_log('[FAIR Config] pre_http_request (priority 999): ' . $url);
    }

    // Only modify requests to our local AspireCloud instance that use HTTPS
    if (strpos($url, 'https://aspirecloud:80') === 0) {
        // Fix the URL to use HTTP
        $fixed_url = str_replace('https://aspirecloud:80', 'http://aspirecloud:80', $url);
        error_log('[FAIR Config] FIXED HTTPS->HTTP: ' . $fixed_url);

        // Make the request with the fixed URL
        return wp_remote_request($fixed_url, $args);
    }

    return $preempt;
}, 999, 3);  // High priority to run after most other filters

// Log FAIR API calls for debugging (runs after plugins are loaded)
add_action('plugins_loaded', function() {
    if (defined('WP_DEBUG_LOG') && WP_DEBUG_LOG) {
        add_action('fair_api_request', function($url, $args) {
            error_log(sprintf(
                '[FAIR] API Request: %s',
                $url
            ));
        }, 10, 2);

        add_action('fair_api_response', function($response, $url) {
            if (is_wp_error($response)) {
                error_log(sprintf(
                    '[FAIR] API Error: %s - %s',
                    $url,
                    $response->get_error_message()
                ));
            }
        }, 10, 2);
    }
}, 1);

// Rewrite AspireCloud URLs based on context
// AspireCloud returns URLs like https://api.aspiredev.local/download/...
// - download_link: rewrite to http://aspirecloud:80 (server-side access)
// - icons/banners: rewrite to http://localhost:8099 (browser access)
add_filter('plugins_api_result', function($result, $action, $args) {
    if (!is_object($result)) {
        return $result;
    }

    // Fix download_link in plugin information responses (server-side access)
    if (isset($result->download_link)) {
        $result->download_link = str_replace(
            ['https://api.aspiredev.local', 'http://api.aspiredev.local'],
            'http://aspirecloud:80',
            $result->download_link
        );
    }

    // Fix download links in plugin list results (server-side access)
    if (isset($result->plugins) && is_array($result->plugins)) {
        foreach ($result->plugins as &$plugin) {
            if (isset($plugin->download_link)) {
                $plugin->download_link = str_replace(
                    ['https://api.aspiredev.local', 'http://api.aspiredev.local'],
                    'http://aspirecloud:80',
                    $plugin->download_link
                );
            }
            // Fix icon URLs (browser access)
            if (isset($plugin->icons) && is_array($plugin->icons)) {
                foreach ($plugin->icons as $size => &$url) {
                    $url = str_replace(
                        ['https://api.aspiredev.local', 'http://api.aspiredev.local'],
                        'http://localhost:8099',
                        $url
                    );
                }
            }
        }
    }

    // Fix icon URLs in single plugin responses (browser access)
    if (isset($result->icons) && is_array($result->icons)) {
        foreach ($result->icons as $size => &$url) {
            $url = str_replace(
                ['https://api.aspiredev.local', 'http://api.aspiredev.local'],
                'http://localhost:8099',
                $url
            );
        }
    }

    // Fix banner URLs (browser access)
    if (isset($result->banners) && is_array($result->banners)) {
        foreach ($result->banners as $size => &$url) {
            $url = str_replace(
                ['https://api.aspiredev.local', 'http://api.aspiredev.local'],
                'http://localhost:8099',
                $url
            );
        }
    }

    return $result;
}, 10, 3);

// Add FAIR status to admin dashboard
add_action('admin_notices', function() {
    if (!current_user_can('manage_options')) {
        return;
    }

    $screen = get_current_screen();
    if ($screen && $screen->id === 'dashboard') {
        printf(
            '<div class="notice notice-info"><p><strong>CloudFest Hackathon:</strong> FAIR plugin is configured to use local AspireCloud at <code>http://aspirecloud:80</code> (accessible from your browser at <a href="http://localhost:8099" target="_blank">http://localhost:8099</a>)</p></div>'
        );
    }
});
