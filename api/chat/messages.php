<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

$pdo = tp_pdo();
$userId = chat_api_require_user($pdo);

if (!crg_chat_tables_ready($pdo)) {
    chat_api_json(['success' => false, 'error' => 'Chat not deployed', 'items' => []], 503);
}

$threadId = (int) ($_GET['thread_id'] ?? 0);
if ($threadId <= 0) {
    chat_api_json(['success' => false, 'error' => 'thread_id required'], 400);
}

$beforeId = isset($_GET['before_id']) && $_GET['before_id'] !== ''
    ? (int) $_GET['before_id']
    : null;
$limit = max(1, min(100, (int) ($_GET['limit'] ?? 50)));

if (!crg_chat_user_can_access_thread($pdo, $userId, $threadId)) {
    chat_api_json(['success' => false, 'error' => 'Нет доступа к диалогу'], 403);
}

$items = crg_chat_get_messages($pdo, $threadId, $userId, $beforeId, $limit);

chat_api_json(['success' => true, 'items' => $items]);
