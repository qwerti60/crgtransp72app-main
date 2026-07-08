<?php
declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=UTF-8');

require_once __DIR__ . '/include/api_bootstrap.php';
require_once __DIR__ . '/include/admin_ref_lists.php';
require_once __DIR__ . '/include/site_config.php';

$allowedTables = crg_admin_ref_image_tables();
$tableName = trim((string) ($_GET['bd'] ?? ''));
$legacyBase64 = isset($_GET['legacy']) && (string) $_GET['legacy'] === '1';
$thumbWidth = (int) ($_GET['w'] ?? 480);
if ($thumbWidth < 1) {
    $thumbWidth = 480;
}
if ($thumbWidth > 1600) {
    $thumbWidth = 1600;
}

if ($tableName === '') {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid table name'], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $pdo = tp_pdo();

    if ($tableName === 'all') {
        $bundle = [];
        foreach ($allowedTables as $table) {
            $bundle[$table] = crg_admin_ref_image_items($pdo, $table, $thumbWidth, $legacyBase64);
        }
        echo json_encode($bundle, JSON_UNESCAPED_UNICODE);
        exit;
    }

    if (!in_array($tableName, $allowedTables, true)) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid table name'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    echo json_encode(
        crg_admin_ref_image_items($pdo, $tableName, $thumbWidth, $legacyBase64),
        JSON_UNESCAPED_UNICODE
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
