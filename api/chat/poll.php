<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

$pdo = tp_pdo();
$userId = chat_api_require_user($pdo);

if (!crg_chat_tables_ready($pdo)) {
    chat_api_json(['success' => false, 'error' => 'Chat not deployed', 'items' => []], 503);
}

$threadId = (int) ($_GET['thread_id'] ?? 0);
$afterId = (int) ($_GET['after_id'] ?? 0);

if ($threadId <= 0) {
    chat_api_json(['success' => false, 'error' => 'thread_id required'], 400);
}

$items = crg_chat_poll_messages($pdo, $userId, $threadId, $afterId);

chat_api_json(['success' => true, 'items' => $items]);
