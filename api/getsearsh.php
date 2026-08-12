<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

header('Content-Type: application/json; charset=UTF-8');

require __DIR__ . '/load_databd.php';
$dsn = "mysql:host=$host;dbname=$dbname;charset=utf8mb4";
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

try {
    $pdo = new PDO($dsn, $username, $password, $options);
    
    $pdo->exec("SET NAMES 'utf8mb4'");
    $pdo->exec("SET CHARACTER SET 'utf8mb4'");

    // Получаем данные из таблицы vidg
    $stmt_vidg = $pdo->query("SELECT id, name FROM vidg");
    $data_vidg = $stmt_vidg->fetchAll();

    // Получаем данные из таблицы vidt
    $stmt_vidt = $pdo->query("SELECT id, name FROM vidt");
    $data_vidt = $stmt_vidt->fetchAll();

    // Получаем данные из таблицы gruzchik
    $stmt_gruzchik = $pdo->query("SELECT id, name FROM gruzchik");
    $data_gruzchik = $stmt_gruzchik->fetchAll();

    // Объединяем массивы данных
    $combined_data = array_merge($data_vidg, $data_vidt, $data_gruzchik);

    echo json_encode($combined_data, JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>