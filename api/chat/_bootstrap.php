<?php
declare(strict_types=1);

ob_start();

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once dirname(__DIR__) . '/include/api_bootstrap.php';
require_once dirname(__DIR__) . '/token_auth.php';
require_once dirname(__DIR__) . '/include/chat_attachments.php';
require_once dirname(__DIR__) . '/include/chat_core.php';

function chat_api_json(array $data, int $code = 200): void
{
    while (ob_get_level() > 0) {
        ob_end_clean();
    }
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}

function chat_api_require_user(PDO $pdo): int
{
    $token = trim((string) ($_GET['token'] ?? $_POST['token'] ?? ''));
    if ($token === '') {
        chat_api_json(['success' => false, 'error' => 'Token is required'], 401);
    }
    $userId = resolveUserIdFromToken($pdo, $token);
    if ($userId === null) {
        chat_api_json(['success' => false, 'error' => 'User not found'], 401);
    }

    return $userId;
}
