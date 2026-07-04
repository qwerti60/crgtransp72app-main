<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

$pdo = tp_pdo();
$userId = chat_api_require_user($pdo);

if (!crg_chat_tables_ready($pdo)) {
    chat_api_json(['success' => false, 'error' => 'Chat not deployed'], 503);
}

$threadId = (int) ($_POST['thread_id'] ?? $_GET['thread_id'] ?? 0);
$lastRead = (int) ($_POST['last_read_message_id'] ?? $_GET['last_read_message_id'] ?? 0);

if ($threadId <= 0 || $lastRead <= 0) {
    chat_api_json(['success' => false, 'error' => 'Invalid parameters'], 400);
}

crg_chat_mark_read($pdo, $userId, $threadId, $lastRead);

chat_api_json(['success' => true]);
