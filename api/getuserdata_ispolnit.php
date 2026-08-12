<?php
header('Content-Type: application/json');
require __DIR__ . '/load_databd.php'; // Предполагается, что в файле 'databd.php' находятся данные для подключения к БД

// Создаем соединение с базой данных
$conn = new mysqli($host, $username, $password, $dbname);

// Проверяем соединение
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
$conn->set_charset("utf8mb4");

$name = isset($_GET['name']) ? $_GET['name'] : '';
$city = isset($_GET['city']) ? $_GET['city'] : '';

if ($name == 'Грузчики') {
    $rollNum = 4;
if (!empty($city)) {
    $sql = "SELECT firstName, lastName, middleName, city, phone, namefirm FROM users WHERE rollNum = ? AND city = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("is", $rollNum, $city);
} else {
    $vidt = $name; // Предполагая, что $name определен ранее
    $sql = "SELECT firstName, lastName, middleName, city, phone, namefirm FROM users WHERE city = ? AND (vidt = ? OR maxgruz = ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $city, $vidt);
}

    $stmt->execute();
    $result = $stmt->get_result();
    $users = $result->fetch_all(MYSQLI_ASSOC);

    echo json_encode($users);
}
elseif ($name != 'Грузчики') {
if (!empty($city)) {
    $vidt = $name; // Предполагая, что $name определен ранее
    $sql = "SELECT firstName, lastName, middleName, city, phone, namefirm FROM users WHERE city = ? AND (vidt = ? OR maxgruz = ?) AND  flag='1'";
    $stmt = $conn->prepare($sql);
$stmt->bind_param("sss", $city, $vidt, $vidt);}

    $stmt->execute();
    $result = $stmt->get_result();
    $users = $result->fetch_all(MYSQLI_ASSOC);

    echo json_encode($users);
} else {
    echo json_encode([]);
}

$conn->close();
?>
