<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_ref_lists.php');

$pdo = tp_admin_web_require_login();

$type = crg_admin_ref_type_from_request();
if ($type === null) {
    http_response_code(400);
    exit;
}
$cfg = crg_admin_ref_config($type);
assert($cfg !== null);

$id = (int) ($_GET['id'] ?? 0);
$bytes = crg_admin_ref_load_image($pdo, $cfg, $id);
if ($bytes === null) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Нет изображения';
    exit;
}

header('Content-Type: ' . crg_admin_ref_image_mime($bytes));
header('Cache-Control: private, max-age=300');
echo $bytes;
