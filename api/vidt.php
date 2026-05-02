<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

header('Content-Type: application/json; charset=UTF-8');

include 'databd.php';
$dsn = "mysql:host=$host;dbname=$dbname;charset=utf8mb4";
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

try {
    $pdo = new PDO($dsn, $username, $password, $options);
    
    $pdo->exec("SET NAMES 'utf8mb4'");
    $pdo->exec("SET CHARACTER SET 'utf8mb4'");

    $stmt = $pdo->query("SELECT id, name FROM vidt");
    $cities = $stmt->fetchAll();

    echo json_encode($cities, JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>
