<?php
declare(strict_types=1);

ob_start();

require_once __DIR__ . '/bootstrap_web.php';

/**
 * @param array<string, mixed> $payload
 */
function support_poll_json_exit(int $code, array $payload): void
{
    while (ob_get_level() > 0) {
        ob_end_clean();
    }
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store, no-cache, must-revalidate');
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}

try {
    foreach (['chat_core.php', 'admin_support.php'] as $includeFile) {
        $path = TP_PUBLIC_ROOT . '/include/' . $includeFile;
        if (!is_readable($path)) {
            support_poll_json_exit(503, [
                'success' => false,
                'error' => 'missing_include',
                'message' => $includeFile,
            ]);
        }
        require_once $path;
    }

    if (ob_get_length()) {
        ob_clean();
    }

    $pdo = tp_admin_web_require_login_json();

    $ticketId = (int) ($_GET['id'] ?? 0);
    $afterId = (int) ($_GET['after_id'] ?? 0);

    if ($ticketId <= 0) {
        support_poll_json_exit(400, ['success' => false, 'error' => 'id required']);
    }

    if (!function_exists('crg_admin_support_ticket')) {
        support_poll_json_exit(503, ['success' => false, 'error' => 'admin_support not deployed']);
    }

    $ticket = crg_admin_support_ticket($pdo, $ticketId);
    if ($ticket === null) {
        support_poll_json_exit(404, ['success' => false, 'error' => 'not found']);
    }

    $threadId = (int) ($ticket['thread_id'] ?? 0);
    if ($threadId <= 0) {
        support_poll_json_exit(200, [
            'success' => true,
            'items' => [],
            'ticket_status' => (string) ($ticket['status'] ?? ''),
            'thread_id' => 0,
        ]);
    }

    $rows = [];
    if (function_exists('crg_admin_support_messages_since')) {
        $rows = crg_admin_support_messages_since($pdo, $threadId, $afterId);
    } else {
        $st = $pdo->prepare(
            'SELECT id, sender_type, body, created_at, sender_admin_id
             FROM chat_messages
             WHERE thread_id = ? AND id > ? AND is_deleted = 0
             ORDER BY id ASC'
        );
        $st->execute([$threadId, max(0, $afterId)]);
        $rows = $st->fetchAll(PDO::FETCH_ASSOC);
    }

    $items = [];
    foreach ($rows as $row) {
        if (function_exists('crg_admin_support_message_to_json')) {
            $items[] = crg_admin_support_message_to_json($row);
        } else {
            $items[] = [
                'id' => (int) ($row['id'] ?? 0),
                'sender_type' => (string) ($row['sender_type'] ?? 'user'),
                'body' => (string) ($row['body'] ?? ''),
                'created_at' => (string) ($row['created_at'] ?? ''),
                'admin_login' => '',
            ];
        }
    }

    support_poll_json_exit(200, [
        'success' => true,
        'items' => $items,
        'ticket_status' => (string) ($ticket['status'] ?? ''),
        'thread_id' => $threadId,
    ]);
} catch (Throwable $e) {
    support_poll_json_exit(500, [
        'success' => false,
        'error' => 'poll_failed',
        'message' => $e->getMessage(),
    ]);
}
