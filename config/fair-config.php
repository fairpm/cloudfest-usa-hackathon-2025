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

// Configure FAIR to use local AspireCloud via Docker network
// WordPress can access AspireCloud directly by container name
// This constant is checked by FAIR\Default_Repo\get_default_repo_domain()
// Format: just the domain/hostname without protocol or port
// FAIR will add the protocol and path
// NOTE: Port 80 is implicit, don't include it to avoid wp_http_validate_url() rejection
if (!defined('FAIR_DEFAULT_REPO_DOMAIN')) {
    define('FAIR_DEFAULT_REPO_DOMAIN', 'aspirecloud');
}

// Enable FAIR for all package types
add_filter('fair_enable_plugin_updates', '__return_true', 1);
add_filter('fair_enable_theme_updates', '__return_true', 1);
add_filter('fair_enable_core_updates', '__return_true', 1);

// Debug logging for hackathon
add_filter('fair_debug_mode', function() {
    return defined('WP_DEBUG') && WP_DEBUG;
}, 1);

// Configure HTTP requests for local AspireCloud
add_filter('http_request_args', function($args, $url) {
    // Configure requests to local AspireCloud
    if (strpos($url, 'aspirecloud') !== false) {
        $args['sslverify'] = false;
        $args['timeout'] = 30;
        $args['redirection'] = 10;  // Ensure redirects are followed (AspireCloud redirects to downloads.wordpress.org)
        $args['reject_unsafe_urls'] = false;  // CRITICAL: Bypass wp_http_validate_url() which can't resolve Docker hostnames
    }

    return $args;
}, 10, 2);

// Rewrite HTTPS AspireCloud URLs to HTTP before the request is made
add_filter('pre_http_request', function($preempt, $args, $url) {
    static $in_filter = false;

    // Prevent infinite recursion
    if ($in_filter) {
        return $preempt;
    }

    // Only modify requests to our local AspireCloud instance that use HTTPS
    if (strpos($url, 'https://aspirecloud') === 0) {
        // Fix the URL to use HTTP
        $fixed_url = str_replace('https://aspirecloud', 'http://aspirecloud', $url);

        // Set flag to prevent recursion
        $in_filter = true;

        // Make the request with the fixed URL
        $response = wp_remote_request($fixed_url, $args);

        // Reset flag
        $in_filter = false;

        return $response;
    }

    return $preempt;
}, 999, 3);  // High priority to run after most other filters

// Rewrite AspireCloud URLs based on context
// AspireCloud returns URLs like http://localhost:8099/download/...
// - download_link: rewrite to http://aspirecloud (server-side access)
// - icons/banners: rewrite to http://localhost:8099 (browser access)
add_filter('plugins_api_result', function($result, $action, $args) {
    if (is_wp_error($result)) {
        return $result;
    }

    if (!is_object($result)) {
        return $result;
    }

    // Fix download_link in plugin information responses (server-side access)
    // NOTE: Use http://aspirecloud/ (port 80 is default) instead of http://aspirecloud:80/
    // because WordPress's wp_http_validate_url() rejects URLs with port in hostname
    if (isset($result->download_link)) {
        $result->download_link = str_replace(
            ['https://api.aspiredev.local', 'http://api.aspiredev.local', 'http://localhost:8099'],
            'http://aspirecloud',
            $result->download_link
        );
    }

    // Fix download links in plugin list results (server-side access)
    if (isset($result->plugins) && is_array($result->plugins)) {
        foreach ($result->plugins as &$plugin) {
            if (isset($plugin->download_link)) {
                $plugin->download_link = str_replace(
                    ['https://api.aspiredev.local', 'http://api.aspiredev.local', 'http://localhost:8099'],
                    'http://aspirecloud',
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
            '<div class="notice notice-info"><p><strong>CloudFest Hackathon:</strong> FAIR plugin is configured to use local AspireCloud at <code>http://aspirecloud</code> (accessible from your browser at <a href="http://localhost:8099" target="_blank">http://localhost:8099</a>)</p></div>'
        );
    }
});
