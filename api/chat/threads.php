<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

$pdo = tp_pdo();
$userId = chat_api_require_user($pdo);

if (!crg_chat_tables_ready($pdo)) {
    chat_api_json(['success' => false, 'error' => 'Chat not deployed', 'items' => []], 503);
}

$type = trim((string) ($_GET['type'] ?? ''));
if ($type !== '' && $type !== 'deal' && $type !== 'support') {
    $type = '';
}
$limit = max(1, min(100, (int) ($_GET['limit'] ?? 50)));
$page = max(1, (int) ($_GET['page'] ?? 1));
$offset = ($page - 1) * $limit;

$items = crg_chat_list_threads($pdo, $userId, $type !== '' ? $type : null, $limit, $offset);

chat_api_json(['success' => true, 'items' => $items]);
