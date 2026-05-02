<?php

header("Content-Type: application/json");
// Подключение к базе данных
$host = "localhost";
$user = "u2395188_apps72";
$pass = "kR3iV2aA6gjU8nC9";
$db = "u2395188_apps";

// Подключение к базе данных
$host = 'localhost'; // Либо 127.0.0.1
$dbname = 'u2395188_apps';
$username = 'u2395188_apps72'; // Имя пользователя БД
$password = 'kR3iV2aA6gjU8nC9'; // Пароль пользователя
$data = json_decode(file_get_contents("php://input"), true);

$cena = $data['cena'];
$about = $data['about'];
$iduserp = $data['iduserp'];
$iduser = $data['iduser'];
$bd = $data['bd'];
$pdo = new PDO("mysql:host={$host};dbname={$dbname};charset=utf8", $username, $password);

// Получаем переменные от Flutter
$cena = $_POST['cena'] ?? '';
$about = $_POST['about'] ?? '';
$iduserp = $_POST['iduserp'] ?? '';
$iduser = $_POST['iduser'] ?? '';
$bd = $_POST['bd'] ?? '';
// Проверяем, есть ли уже такая запись в базе данных
$stmt = $pdo->prepare("SELECT COUNT(*) FROM offer_dataf WHERE iduserp = ? AND iduser = ? AND bd = ?");
$stmt->execute([$iduserp, $iduser, $bd]);
$exists = $stmt->fetchColumn() > 0;

if ($exists) {
    // Обновляем существующую запись
    $sql = "UPDATE offer_dataf SET cena=?, about=? WHERE iduserp=? AND iduser=? AND bd=?";
    $pdo->prepare($sql)->execute([$cena, $about, $iduserp, $iduser, $bd]);
    echo json_encode(["status" => "updated", "message" => "Data updated successfully"]);
} else {
    // Если записи нет — добавляем новую
    $sql = "INSERT INTO offer_dataf (cena, about, iduserp, iduser, bd) VALUES (?, ?, ?, ?, ?)";
    $pdo->prepare($sql)->execute([$cena, $about, $iduserp, $iduser, $bd]);
    echo json_encode(["status" => "success", "message" => "Data added successfully"]);
}

?>