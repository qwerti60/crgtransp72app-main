<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/include/api_bootstrap.php';
require_once dirname(__DIR__) . '/token_auth.php';
require_once dirname(__DIR__) . '/include/chat_attachments.php';
require_once dirname(__DIR__) . '/include/chat_core.php';

$pdo = tp_pdo();

$token = trim((string) ($_GET['token'] ?? $_POST['token'] ?? ''));
if ($token === '') {
    http_response_code(401);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Unauthorized';
    exit;
}

$userId = resolveUserIdFromToken($pdo, $token);
if ($userId === null) {
    http_response_code(401);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Unauthorized';
    exit;
}

$messageId = (int) ($_GET['message_id'] ?? 0);
if ($messageId <= 0) {
    http_response_code(400);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'message_id required';
    exit;
}

$info = crg_chat_message_attachment($pdo, $messageId, $userId);
if ($info === null) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Not found';
    exit;
}

$mime = (string) ($info['mime'] ?? 'application/octet-stream');
$name = (string) ($info['name'] ?? 'file');
$abs = (string) ($info['abs_path'] ?? '');

header('Content-Type: ' . $mime);
header('Content-Length: ' . (string) filesize($abs));
header('Cache-Control: private, max-age=3600');
if (!crg_chat_is_image_mime($mime)) {
    header('Content-Disposition: attachment; filename="' . str_replace('"', '', $name) . '"');
}

readfile($abs);
