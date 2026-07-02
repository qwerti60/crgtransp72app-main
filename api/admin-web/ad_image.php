<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_ads.php');

$pdo = tp_admin_web_require_login();

$kind = trim((string) ($_GET['kind'] ?? ''));
$type = trim((string) ($_GET['type'] ?? ''));
$slot = trim((string) ($_GET['slot'] ?? ''));
$id = (int) ($_GET['id'] ?? 0);

if ($id <= 0 || $slot === '') {
    http_response_code(400);
    exit;
}

$allowedSlots = $kind === 'customer'
    ? crg_admin_ad_customer_image_slots()
    : crg_admin_ad_image_columns();
if (!in_array($slot, $allowedSlots, true)) {
    http_response_code(400);
    exit;
}

if ($kind === 'performer') {
    $cfg = crg_admin_performer_ad_config($type);
} elseif ($kind === 'customer') {
    $cfg = crg_admin_customer_ad_config($type);
} else {
    http_response_code(400);
    exit;
}

if ($cfg === null) {
    http_response_code(400);
    exit;
}

$row = crg_admin_ad_get($pdo, $cfg, $id);
if ($row === null) {
    http_response_code(404);
    exit;
}

$bytes = crg_admin_ad_load_image_blob($row[$slot] ?? null);
if ($bytes === null) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Нет изображения';
    exit;
}

header('Content-Type: ' . crg_admin_ad_image_mime($bytes));
header('Cache-Control: private, max-age=300');
header('Content-Disposition: inline; filename="' . $slot . '"');
header('X-Content-Type-Options: nosniff');
echo $bytes;
