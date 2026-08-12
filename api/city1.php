<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

header('Content-Type: application/json; charset=UTF-8');

require __DIR__ . '/load_databd.php';
$user = $username;
$pass = $password;
$db = $dbname;

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
