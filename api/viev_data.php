<?php

// Подключение к базе данных
require __DIR__ . '/load_databd.php';
$user = $username;
$pass = $password;
$db = $dbname;
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    throw new \PDOException($e->getMessage(), (int)$e->getCode());
}

// Получение данных из таблицы users
$stmt = $pdo->query('SELECT username, email, password FROM users');
$users = $stmt->fetchAll();

// Возвращаем данные в формате JSON
header('Content-Type: application/json');
echo json_encode($users);
?>
