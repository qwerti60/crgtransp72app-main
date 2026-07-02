<?php
declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=UTF-8');

require_once __DIR__ . '/include/api_bootstrap.php';
require_once __DIR__ . '/include/admin_ref_lists.php';

$allowedTables = crg_admin_ref_image_tables();
$tableName = trim((string) ($_GET['bd'] ?? ''));

if (!in_array($tableName, $allowedTables, true)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid table name'], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $pdo = tp_pdo();
    $sql = "SELECT name, image FROM `{$tableName}` WHERE LENGTH(image) > 0 ORDER BY id";
    $stmt = $pdo->query($sql);
    $images = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $img = crg_admin_ref_blob_to_string($row['image'] ?? '');
        if ($img === '') {
            continue;
        }
        $images[] = [
            'name' => (string) ($row['name'] ?? ''),
            'image' => base64_encode($img),
        ];
    }
    echo json_encode($images, JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
