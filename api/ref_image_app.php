<?php
declare(strict_types=1);

require_once __DIR__ . '/include/api_bootstrap.php';
require_once __DIR__ . '/include/admin_ref_lists.php';

$tableName = trim((string) ($_GET['bd'] ?? ''));
$id = (int) ($_GET['id'] ?? 0);
$maxWidth = (int) ($_GET['w'] ?? 0);
if ($maxWidth < 1) {
    $maxWidth = 480;
}
if ($maxWidth > 1600) {
    $maxWidth = 1600;
}

$allowedTables = crg_admin_ref_image_tables();
if (!in_array($tableName, $allowedTables, true) || $id <= 0) {
    http_response_code(400);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Invalid request';
    exit;
}

$cfg = crg_admin_ref_image_table_config($tableName);
if ($cfg === null) {
    http_response_code(400);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Invalid table';
    exit;
}

try {
    $pdo = tp_pdo();
    $bytes = crg_admin_ref_load_image($pdo, $cfg, $id);
} catch (Throwable $e) {
    http_response_code(500);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Database error';
    exit;
}

if ($bytes === null) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Not found';
    exit;
}

$bytes = crg_admin_ref_resize_image($bytes, $maxWidth);
$mime = crg_admin_ref_image_mime($bytes);

header('Access-Control-Allow-Origin: *');
header('Content-Type: ' . $mime);
header('Cache-Control: public, max-age=604800');
header('Content-Length: ' . (string) strlen($bytes));
echo $bytes;
