`1<?php
// Включите обработку ошибок для упрощения отладки
ini_set('display_errors', 1);
error_reporting(E_ALL);

include 'databd.php';

$dsn = "mysql:host=$host;dbname=$dbname";
try {
    $pdo = new PDO($dsn, $username, $password);
} catch (PDOException $e) {
    die("Ошибка подключения к базе данных: " . $e->getMessage());
}

// Получение заголовков авторизации
$headers = apache_request_headers();
$token = $headers['Authorization'] ?? ''; // Предполагаем, что токен передается через заголовок Authorization

// Проверка токена и получение данных пользователя (Для примера предполагаем, что токен является id пользователя)
$query = $pdo->prepare("SELECT firstName, lastName, middleName, city, phone, email FROM users WHERE email = ?");
$query->execute([$token]);
$user = $query->fetch(PDO::FETCH_ASSOC);

if ($user) {
    echo json_encode($user);
} else {
    // Если пользователь не найден или токен неверен
    http_response_code(401);
    echo json_encode(['error' => 'Не авторизован']);
}
?>