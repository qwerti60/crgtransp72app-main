<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

$pdo = tp_pdo();
$userId = chat_api_require_user($pdo);

if (!crg_chat_tables_ready($pdo)) {
    chat_api_json(['success' => false, 'error' => 'Chat not deployed'], 503);
}

$counterpartId = (int) ($_POST['counterpart_user_id'] ?? $_GET['counterpart_user_id'] ?? 0);
$bd = (int) ($_POST['bd'] ?? $_GET['bd'] ?? 0);
$adId = (int) ($_POST['ad_id'] ?? $_GET['ad_id'] ?? 0);

$result = crg_chat_open_deal_thread($pdo, $userId, $counterpartId, $bd, $adId);
if (!$result['success']) {
    chat_api_json($result, 400);
}

$threadId = (int) $result['thread_id'];
$title = crg_chat_user_display_name($pdo, $counterpartId);

chat_api_json([
    'success' => true,
    'thread_id' => $threadId,
    'title' => $title,
    'counterpart_name' => $title,
    'type' => 'deal',
]);
