<?php
$host = "localhost";
$username = "u2395188_apps72";
$password = "kR3iV2aA6gjU8nC9";
$dbname = "u2395188_apps";
// Подключаемся к базе данных
$pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
$allowedTables = ['vidt', 'vidg', 'gruzchik']; // Define allowed tables
$tableName = $_GET['bd']; // Get the table name from the URL

if (!in_array($tableName, $allowedTables)) {
    die('Error: Invalid table name.');
}

// Proceed with your database query 

// Запрос на получение всех картинок
$sql = "SELECT image, name FROM $tableName";

// Подготовка и выполнение запроса
$stmt = $pdo->prepare($sql);
$stmt->execute();

// Формирование ответа
$images = [];
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
$row['image'] = base64_encode($row['image']); // Кодируем картинку в base64 для передачи
$images[] = $row;
}

// Заголовок для возвращаемого JSON
header('Content-Type: application/json');
echo json_encode($images);
?>