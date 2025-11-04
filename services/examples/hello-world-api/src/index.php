<?php
/**
 * Hello World API - Example Service
 *
 * Demonstrates:
 * - RESTful API endpoints
 * - Health checks
 * - Environment variables
 * - Redis integration
 * - AspireCloud API calls
 * - Structured logging
 */

// Error handling
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// Set JSON response header
header('Content-Type: application/json');

// Get environment variables
$serviceName = getenv('SERVICE_NAME') ?: 'hello-world-api';
$servicePort = getenv('SERVICE_PORT') ?: '8100';
$aspireCloudUrl = getenv('ASPIRECLOUD_API_URL') ?: 'http://aspirecloud:80';
$redisUrl = getenv('REDIS_URL') ?: 'redis://redis:6379';
$logLevel = getenv('LOG_LEVEL') ?: 'info';

// Parse request
$requestMethod = $_SERVER['REQUEST_METHOD'];
$requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$requestQuery = $_GET;

/**
 * Simple logging function
 */
function logMessage($level, $message, $context = []) {
    global $logLevel, $serviceName;

    $levels = ['debug' => 0, 'info' => 1, 'warning' => 2, 'error' => 3];
    $currentLevel = $levels[$logLevel] ?? 1;
    $messageLevel = $levels[$level] ?? 1;

    if ($messageLevel < $currentLevel) {
        return;
    }

    $log = [
        'timestamp' => date('c'),
        'service' => $serviceName,
        'level' => strtoupper($level),
        'message' => $message,
        'context' => $context
    ];

    error_log(json_encode($log));
}

/**
 * Send JSON response
 */
function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_PRETTY_PRINT);
    exit;
}

/**
 * Send error response
 */
function sendError($message, $statusCode = 500, $details = null) {
    global $serviceName;

    logMessage('error', $message, ['details' => $details]);

    $response = [
        'error' => true,
        'message' => $message,
        'service' => $serviceName,
        'timestamp' => date('c')
    ];

    if ($details) {
        $response['details'] = $details;
    }

    sendResponse($response, $statusCode);
}

/**
 * Router - match URI to handler
 */
try {
    logMessage('info', "Received {$requestMethod} request", ['uri' => $requestUri]);

    switch ($requestUri) {
        case '/':
        case '/health':
            // Health check endpoint (required by all services)
            sendResponse([
                'status' => 'healthy',
                'service' => $serviceName,
                'version' => '1.0.0',
                'timestamp' => date('c'),
                'environment' => [
                    'php_version' => PHP_VERSION,
                    'aspirecloud_url' => $aspireCloudUrl,
                    'redis_configured' => !empty($redisUrl)
                ]
            ]);
            break;

        case '/version':
            // Version information endpoint
            sendResponse([
                'service' => $serviceName,
                'version' => '1.0.0',
                'build' => 'dev',
                'environment' => getenv('APP_ENV') ?: 'development',
                'php_version' => PHP_VERSION
            ]);
            break;

        case '/api/hello':
            // Simple hello world endpoint
            $name = $requestQuery['name'] ?? 'World';
            sendResponse([
                'message' => "Hello, {$name}!",
                'service' => $serviceName,
                'timestamp' => date('c'),
                'request_id' => uniqid('req_', true)
            ]);
            break;

        case '/api/redis/test':
            // Test Redis connection
            try {
                $redis = new Redis();
                $parsed = parse_url($redisUrl);
                $host = $parsed['host'] ?? 'redis';
                $port = $parsed['port'] ?? 6379;

                if (!$redis->connect($host, $port, 2.0)) {
                    throw new Exception("Failed to connect to Redis at {$host}:{$port}");
                }

                // Test SET and GET
                $key = 'test:' . time();
                $value = 'Hello from ' . $serviceName;
                $redis->setex($key, 60, $value);
                $retrieved = $redis->get($key);

                sendResponse([
                    'redis_connected' => true,
                    'host' => $host,
                    'port' => $port,
                    'test_key' => $key,
                    'test_value' => $value,
                    'retrieved_value' => $retrieved,
                    'success' => $retrieved === $value
                ]);
            } catch (Exception $e) {
                sendError('Redis connection failed', 500, $e->getMessage());
            }
            break;

        case '/api/aspirecloud/test':
            // Test AspireCloud API call
            try {
                $url = $aspireCloudUrl . '/plugins/info/1.1/?action=query_plugins&request[per_page]=1';

                logMessage('debug', 'Calling AspireCloud API', ['url' => $url]);

                $ch = curl_init($url);
                curl_setopt_array($ch, [
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_TIMEOUT => 10,
                    CURLOPT_FOLLOWLOCATION => true,
                    CURLOPT_HTTPHEADER => [
                        'Accept: application/json',
                        'User-Agent: HelloWorldAPI/1.0'
                    ]
                ]);

                $response = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                $error = curl_error($ch);
                curl_close($ch);

                if ($error) {
                    throw new Exception("cURL error: {$error}");
                }

                if ($httpCode !== 200) {
                    throw new Exception("AspireCloud API returned HTTP {$httpCode}");
                }

                $data = json_decode($response, true);

                sendResponse([
                    'aspirecloud_connected' => true,
                    'url' => $url,
                    'http_code' => $httpCode,
                    'plugins_found' => $data['info']['results'] ?? 0,
                    'sample_plugin' => isset($data['plugins'][0]) ? [
                        'name' => $data['plugins'][0]['name'] ?? 'N/A',
                        'slug' => $data['plugins'][0]['slug'] ?? 'N/A',
                        'version' => $data['plugins'][0]['version'] ?? 'N/A'
                    ] : null
                ]);
            } catch (Exception $e) {
                sendError('AspireCloud API call failed', 500, $e->getMessage());
            }
            break;

        case '/api/echo':
            // Echo endpoint - returns request details
            if ($requestMethod === 'POST') {
                $body = json_decode(file_get_contents('php://input'), true);
            } else {
                $body = null;
            }

            sendResponse([
                'method' => $requestMethod,
                'uri' => $requestUri,
                'query' => $requestQuery,
                'body' => $body,
                'headers' => getallheaders(),
                'timestamp' => date('c')
            ]);
            break;

        case '/api/env':
            // Show environment configuration (for debugging)
            sendResponse([
                'service_name' => $serviceName,
                'service_port' => $servicePort,
                'aspirecloud_url' => $aspireCloudUrl,
                'redis_url' => $redisUrl,
                'log_level' => $logLevel,
                'app_env' => getenv('APP_ENV') ?: 'development',
                'app_debug' => getenv('APP_DEBUG') ?: 'false'
            ]);
            break;

        default:
            // 404 Not Found
            logMessage('warning', 'Route not found', ['uri' => $requestUri]);
            sendError('Route not found', 404, [
                'requested_uri' => $requestUri,
                'available_routes' => [
                    'GET /' => 'Health check',
                    'GET /health' => 'Health check',
                    'GET /version' => 'Version information',
                    'GET /api/hello' => 'Hello world endpoint',
                    'GET /api/redis/test' => 'Test Redis connection',
                    'GET /api/aspirecloud/test' => 'Test AspireCloud API',
                    'GET|POST /api/echo' => 'Echo request details',
                    'GET /api/env' => 'Show environment configuration'
                ]
            ]);
            break;
    }
} catch (Throwable $e) {
    // Catch any unhandled exceptions
    sendError('Internal server error', 500, [
        'exception' => get_class($e),
        'message' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}
