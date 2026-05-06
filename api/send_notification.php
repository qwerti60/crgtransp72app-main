<?php
header("Content-Type: application/json");

function base64url_encode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function json_response($statusCode, $payload) {
    http_response_code($statusCode);
    echo json_encode($payload);
    exit;
}

$rawInput = file_get_contents('php://input');
$input = json_decode($rawInput, true);

if (!is_array($input)) {
    $input = $_POST;
}

$deviceToken = $input['device_token'] ?? '';
$title = $input['title'] ?? '';
$body = $input['body'] ?? '';

if ($deviceToken === '' || $title === '' || $body === '') {
    json_response(400, ['success' => false, 'message' => 'Missing notification fields']);
}

$serviceAccountPath = __DIR__ . '/service_account.json';
if (!file_exists($serviceAccountPath)) {
    json_response(500, ['success' => false, 'message' => 'Server service account is not configured']);
}

$serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);
if (!is_array($serviceAccount) || empty($serviceAccount['client_email']) || empty($serviceAccount['private_key']) || empty($serviceAccount['project_id'])) {
    json_response(500, ['success' => false, 'message' => 'Invalid service account']);
}

$now = time();
$jwtHeader = ['alg' => 'RS256', 'typ' => 'JWT'];
$jwtClaim = [
    'iss' => $serviceAccount['client_email'],
    'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
    'aud' => 'https://oauth2.googleapis.com/token',
    'iat' => $now,
    'exp' => $now + 3600,
];

$jwtUnsigned = base64url_encode(json_encode($jwtHeader)) . '.' . base64url_encode(json_encode($jwtClaim));
$signature = '';
if (!openssl_sign($jwtUnsigned, $signature, $serviceAccount['private_key'], 'sha256WithRSAEncryption')) {
    json_response(500, ['success' => false, 'message' => 'Failed to sign service account JWT']);
}

$jwt = $jwtUnsigned . '.' . base64url_encode($signature);

$tokenCurl = curl_init('https://oauth2.googleapis.com/token');
curl_setopt_array($tokenCurl, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ['Content-Type: application/x-www-form-urlencoded'],
    CURLOPT_POSTFIELDS => http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt,
    ]),
]);

$tokenResponse = curl_exec($tokenCurl);
$tokenStatus = curl_getinfo($tokenCurl, CURLINFO_HTTP_CODE);
$tokenError = curl_error($tokenCurl);
curl_close($tokenCurl);

if ($tokenResponse === false || $tokenStatus !== 200) {
    json_response(500, [
        'success' => false,
        'message' => 'Failed to get Firebase access token',
        'error' => $tokenError,
    ]);
}

$tokenData = json_decode($tokenResponse, true);
$accessToken = $tokenData['access_token'] ?? '';
if ($accessToken === '') {
    json_response(500, ['success' => false, 'message' => 'Firebase access token is empty']);
}

$message = [
    'message' => [
        'token' => $deviceToken,
        'notification' => [
            'title' => $title,
            'body' => $body,
        ],
        'apns' => [
            'headers' => [
                'apns-priority' => '10',
            ],
            'payload' => [
                'aps' => [
                    'alert' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'sound' => 'default',
                    'badge' => 1,
                ],
            ],
        ],
        'android' => [
            'priority' => 'high',
            'notification' => [
                'sound' => 'default',
                'icon' => '@drawable/icon',
                'color' => '#FF0000',
            ],
        ],
    ],
];

$sendUrl = 'https://fcm.googleapis.com/v1/projects/' . rawurlencode($serviceAccount['project_id']) . '/messages:send';
$sendCurl = curl_init($sendUrl);
curl_setopt_array($sendCurl, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json; charset=UTF-8',
    ],
    CURLOPT_POSTFIELDS => json_encode($message),
]);

$sendResponse = curl_exec($sendCurl);
$sendStatus = curl_getinfo($sendCurl, CURLINFO_HTTP_CODE);
$sendError = curl_error($sendCurl);
curl_close($sendCurl);

if ($sendResponse === false || $sendStatus < 200 || $sendStatus >= 300) {
    json_response(500, [
        'success' => false,
        'message' => 'Failed to send notification',
        'status' => $sendStatus,
        'error' => $sendError,
        'response' => $sendResponse,
    ]);
}

json_response(200, ['success' => true, 'response' => json_decode($sendResponse, true)]);
?>
