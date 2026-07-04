<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('chat_core.php');
tp_admin_web_require_include('admin_support.php');

$pdo = tp_admin_web_require_login();

$messageId = (int) ($_GET['message_id'] ?? 0);
if ($messageId <= 0) {
    http_response_code(400);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'message_id required';
    exit;
}

if (!function_exists('crg_admin_support_message_attachment')) {
    http_response_code(503);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'admin_support.php не обновлён на сервере';
    exit;
}

$info = crg_admin_support_message_attachment($pdo, $messageId);
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
