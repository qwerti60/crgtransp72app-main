<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_ads.php');

$pdo = tp_admin_web_require_login();

if ($_SERVER['REQUEST_METHOD'] !== 'POST' || !isset($_POST['delete_ad'])) {
    header('Location: performer_ads.php', true, 302);
    exit;
}
if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
    http_response_code(400);
    echo 'CSRF';
    exit;
}

$type = crg_admin_performer_type_from_request() ?? 'gp';
$cfg = crg_admin_performer_ad_config($type);
if ($cfg === null) {
    http_response_code(400);
    exit;
}

$id = (int) ($_POST['id'] ?? 0);
$res = crg_admin_ad_delete($pdo, $cfg, $id);
if ($res === true) {
    header('Location: performer_ads.php?type=' . rawurlencode($type) . '&deleted=1', true, 303);
    exit;
}

http_response_code(400);
echo is_string($res) ? $res : 'Ошибка';
