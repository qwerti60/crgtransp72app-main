<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_cities.php');

$pdo = tp_admin_web_require_login();

if ($_SERVER['REQUEST_METHOD'] !== 'POST' || !isset($_POST['delete_city'])) {
    header('Location: cities.php', true, 303);
    exit;
}

if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
    http_response_code(403);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'CSRF';
    exit;
}

$id = (int) ($_POST['id'] ?? 0);
$res = crg_admin_city_delete($pdo, $id);
if ($res !== true) {
    http_response_code(400);
    header('Content-Type: text/html; charset=utf-8');
    echo '<!DOCTYPE html><html lang="ru"><head><meta charset="utf-8"><title>Ошибка</title></head><body>';
    echo '<p>' . tp_admin_web_h(is_string($res) ? $res : 'Ошибка удаления') . '</p>';
    echo '<p><a href="city_edit.php?id=' . $id . '">← Назад</a></p></body></html>';
    exit;
}

header('Location: cities.php?deleted=1', true, 303);
exit;
