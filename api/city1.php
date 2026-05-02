<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

header('Content-Type: application/json; charset=UTF-8');

$host = 'localhost';
$db = 'u2395188_apps';
$user = 'u2395188_apps72';
$pass = 'kR3iV2aA6gjU8nC9';

$dsn = "mysql:host=$host;dbname=$db";
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);

    $stmt = $pdo->query("SELECT id, name FROM cities");
    $cities = $stmt->fetchAll();

    echo json_encode($cities);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>
