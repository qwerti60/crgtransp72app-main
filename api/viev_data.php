<?php

// Подключение к базе данных
$host = 'localhost';
$db   = 'u2395188_apps';
$user = 'u2395188_apps72';
$pass = 'kR3iV2aA6gjU8nC9';
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
