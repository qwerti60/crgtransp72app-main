<?php
// Подключение к базе данных
$host = "localhost";
$user = "u2395188_apps72";
$password = "kR3iV2aA6gjU8nC9";
$database = "u2395188_apps";

$conn = new mysqli($host, $user, $password, $database);
if ($conn->connect_error) {
    die("Ошибка подключения к базе данных: " . $conn->connect_error);
}

// Получаем данные
$email = $_POST['email'];
$image = $_POST['image'];

// Декодирование изображения
$image = base64_decode($image);

// Подготовка запроса
$stmt = $conn->prepare("UPDATE users SET fotouser=? WHERE email=?");
$stmt->bind_param("bs", $null, $email);
$stmt->send_long_data(0, $image);

// Выполнение запроса
if($stmt->execute()){
    echo "Изображение сохранено.";
} else {
    echo "Ошибка при сохранении изображения.";
}

$stmt->close();
$conn->close();
?>
