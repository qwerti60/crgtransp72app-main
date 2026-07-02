<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_users.php');

$pdo = tp_admin_web_require_login();

if ($_SERVER['REQUEST_METHOD'] !== 'POST' || !isset($_POST['delete_user'])) {
    header('Location: users.php', true, 302);
    exit;
}

if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
    http_response_code(400);
    echo 'CSRF';
    exit;
}

$id = (int) ($_POST['id'] ?? 0);
$res = crg_admin_user_delete($pdo, $id);
if ($res === true) {
    header('Location: users.php?deleted=1', true, 303);
    exit;
}

http_response_code(400);
echo is_string($res) ? $res : 'Ошибка удаления';
