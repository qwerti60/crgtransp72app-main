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

$ticketId = (int) ($_POST['ticket_id'] ?? $_GET['ticket_id'] ?? 0);
$rating = (int) ($_POST['rating'] ?? $_GET['rating'] ?? 0);
$comment = (string) ($_POST['comment'] ?? $_GET['comment'] ?? '');

$result = crg_chat_rate_support_ticket($pdo, $userId, $ticketId, $rating, $comment);
if (!$result['success']) {
    http_response_code(400);
}
echo json_encode($result, JSON_UNESCAPED_UNICODE);
