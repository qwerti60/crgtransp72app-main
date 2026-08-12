<?php
declare(strict_types=1);

/**
 * Прокси оплаты: Flutter → банк (register / status / reverse).
 *
 * На api_test по умолчанию пробрасывает POST в боевой /api/payment-proxy.php
 * (там уже рабочие логин/пароль банка).
 *
 * Свои секреты: payment.local.php с 'force_local' => true
 */
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'error' => 'Method not allowed. Use POST.',
        'proxy' => 'crg-v2',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * Собираем параметры из form / query / JSON (на части хостингов $_POST пустой).
 *
 * @return array<string, string>
 */
function crg_payment_request_params(): array
{
    $params = [];

    foreach ($_POST as $k => $v) {
        if (is_scalar($v)) {
            $params[(string) $k] = trim((string) $v);
        }
    }
    foreach ($_GET as $k => $v) {
        if (!isset($params[(string) $k]) && is_scalar($v)) {
            $params[(string) $k] = trim((string) $v);
        }
    }

    $raw = file_get_contents('php://input');
    if (is_string($raw) && $raw !== '') {
        $json = json_decode($raw, true);
        if (is_array($json)) {
            foreach ($json as $k => $v) {
                if (!isset($params[(string) $k]) && is_scalar($v)) {
                    $params[(string) $k] = trim((string) $v);
                }
            }
        } elseif (empty($params)) {
            parse_str($raw, $parsed);
            if (is_array($parsed)) {
                foreach ($parsed as $k => $v) {
                    if (is_scalar($v)) {
                        $params[(string) $k] = trim((string) $v);
                    }
                }
            }
        }
    }

    return $params;
}

function crg_payment_is_api_test(): bool
{
    $script = str_replace('\\', '/', (string) ($_SERVER['SCRIPT_NAME'] ?? ''));
    if (strpos($script, '/api_test/') !== false) {
        return true;
    }
    $dir = str_replace('\\', '/', __DIR__);

    return substr($dir, -9) === '/api_test' || substr($dir, -8) === 'api_test';
}

/**
 * @return array{bank_url:string,username:string,password:string}|null
 */
function crg_payment_load_config(): ?array
{
    foreach ([__DIR__ . '/payment.local.php', dirname(__DIR__) . '/api/payment.local.php'] as $path) {
        if (!is_readable($path)) {
            continue;
        }
        /** @var mixed $cfg */
        $cfg = require $path;
        if (!is_array($cfg)) {
            continue;
        }
        $bankUrl = rtrim((string) ($cfg['bank_url'] ?? ''), '/') . '/';
        $username = (string) ($cfg['username'] ?? '');
        $password = (string) ($cfg['password'] ?? '');
        if ($bankUrl !== '/' && $username !== '' && $password !== '') {
            return [
                'bank_url' => $bankUrl,
                'username' => $username,
                'password' => $password,
            ];
        }
    }

    return null;
}

/**
 * @param array<string, string> $params
 */
function crg_payment_forward_to_prod_proxy(array $params): void
{
    $host = (string) ($_SERVER['HTTP_HOST'] ?? 'gruzoperevozki72.ru');
    $https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        || ((string) ($_SERVER['SERVER_PORT'] ?? '') === '443');
    $scheme = $https ? 'https' : 'http';
    $url = $scheme . '://' . $host . '/api/payment-proxy.php';

    $ch = curl_init($url);
    if ($ch === false) {
        http_response_code(500);
        echo json_encode([
            'errorCode' => '999',
            'errorMessage' => 'Не удалось пробросить оплату на /api/payment-proxy.php',
            'proxy' => 'crg-v2',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query($params),
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2,
        CURLOPT_TIMEOUT => 45,
        CURLOPT_HTTPHEADER => ['Content-Type: application/x-www-form-urlencoded'],
    ]);

    $response = curl_exec($ch);
    $curlErr = curl_error($ch);
    curl_close($ch);

    if ($response === false) {
        http_response_code(502);
        echo json_encode([
            'errorCode' => '999',
            'errorMessage' => 'Ошибка проброса на /api/: ' . $curlErr,
            'proxy' => 'crg-v2',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    echo $response;
    exit;
}

$params = crg_payment_request_params();
$method = $params['method'] ?? '';

$forceLocal = false;
$localProbe = __DIR__ . '/payment.local.php';
if (is_readable($localProbe)) {
    /** @var mixed $probe */
    $probe = require $localProbe;
    $forceLocal = is_array($probe) && !empty($probe['force_local']);
}

if (crg_payment_is_api_test() && !$forceLocal) {
    if ($method === '') {
        http_response_code(400);
        echo json_encode([
            'errorCode' => '4',
            'errorMessage' => 'Parameter "method" is required.',
            'proxy' => 'crg-v2',
            'debug_keys' => array_keys($params),
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    crg_payment_forward_to_prod_proxy($params);
}

$cfg = crg_payment_load_config();
if ($cfg === null) {
    http_response_code(500);
    echo json_encode([
        'errorCode' => '1',
        'errorMessage' => 'payment.local.php не найден. Скопируйте из payment.local.example.php',
        'proxy' => 'crg-v2',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($method === '' || !preg_match('/^[a-zA-Z0-9._-]+$/', $method)) {
    http_response_code(400);
    echo json_encode([
        'errorCode' => '4',
        'errorMessage' => 'Parameter "method" is required.',
        'proxy' => 'crg-v2',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$allowed = [
    'orderNumber',
    'amount',
    'returnUrl',
    'failUrl',
    'description',
    'orderId',
    'language',
    'pageView',
    'clientId',
    'jsonParams',
];

$data = [
    'userName' => $cfg['username'],
    'password' => $cfg['password'],
];
foreach ($allowed as $key) {
    if (!empty($params[$key])) {
        $data[$key] = $params[$key];
    }
}

$ch = curl_init($cfg['bank_url'] . $method);
if ($ch === false) {
    http_response_code(500);
    echo json_encode([
        'errorCode' => '999',
        'errorMessage' => 'Не удалось инициализировать cURL',
        'proxy' => 'crg-v2',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => $data,
    CURLOPT_SSL_VERIFYPEER => true,
    CURLOPT_SSL_VERIFYHOST => 2,
    CURLOPT_TIMEOUT => 45,
]);

$response = curl_exec($ch);
$curlErr = curl_error($ch);
curl_close($ch);

if ($response === false) {
    http_response_code(502);
    echo json_encode([
        'errorCode' => '999',
        'errorMessage' => 'Ошибка cURL: ' . $curlErr,
        'proxy' => 'crg-v2',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

echo $response;
