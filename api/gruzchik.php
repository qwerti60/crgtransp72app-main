<?php
declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=UTF-8');

require_once __DIR__ . '/include/api_bootstrap.php';

try {
    $pdo = tp_pdo();
    $stmt = $pdo->query('SELECT id, name FROM gruzchik ORDER BY id');
    echo json_encode($stmt->fetchAll(), JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
