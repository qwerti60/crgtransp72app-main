<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/include/fcm_push.php';

$rawInput = file_get_contents('php://input');
$input = json_decode($rawInput, true);
if (!is_array($input)) {
    $input = $_POST;
}

$deviceToken = (string) ($input['device_token'] ?? '');
$title = (string) ($input['title'] ?? '');
$body = (string) ($input['body'] ?? '');

if ($deviceToken === '' || $title === '' || $body === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing notification fields'], JSON_UNESCAPED_UNICODE);
    exit;
}

$result = crg_fcm_send($deviceToken, $title, $body);
if ($result !== true) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $result], JSON_UNESCAPED_UNICODE);
    exit;
}

echo json_encode(['success' => true], JSON_UNESCAPED_UNICODE);
