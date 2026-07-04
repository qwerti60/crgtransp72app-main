<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once dirname(__DIR__) . '/include/api_bootstrap.php';
require_once dirname(__DIR__) . '/token_auth.php';
require_once dirname(__DIR__) . '/include/chat_core.php';

$pdo = tp_pdo();

$token = trim((string) ($_POST['token'] ?? $_GET['token'] ?? ''));
if ($token === '') {
    http_response_code(401);
    echo json_encode(['success' => false, 'error' => 'Token is required'], JSON_UNESCAPED_UNICODE);
    exit;
}

$userId = resolveUserIdFromToken($pdo, $token);
if ($userId === null) {
    http_response_code(401);
    echo json_encode(['success' => false, 'error' => 'User not found'], JSON_UNESCAPED_UNICODE);
    exit;
}

if (!crg_chat_tables_ready($pdo)) {
    http_response_code(503);
    echo json_encode(['success' => false, 'error' => 'Chat not deployed'], JSON_UNESCAPED_UNICODE);
    exit;
}

$subject = (string) ($_POST['subject'] ?? '');
$category = (string) ($_POST['category'] ?? 'other');
$body = (string) ($_POST['body'] ?? '');
$contextJson = (string) ($_POST['context_json'] ?? '');
$contextJson = $contextJson !== '' ? $contextJson : null;

$result = crg_chat_create_support_ticket($pdo, $userId, $subject, $category, $body, $contextJson);

if (!$result['success']) {
    http_response_code(400);
}

echo json_encode($result, JSON_UNESCAPED_UNICODE);
