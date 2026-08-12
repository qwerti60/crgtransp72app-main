<?php
header("Content-Type: application/json");

require __DIR__ . '/load_databd.php'; // Убедитесь, что здесь правильный путь к файлу

$conn = new mysqli($host, $username, $password, $dbname);


// Проверка соединения
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Получение iduser из запроса с проверкой на наличие параметра
$iduser = isset($_GET['iduser']) ? (int)$_GET['iduser'] : 0; // Приводим значение к целому типу для безопасности
//$iduser = $_POST['iduser'];
$currentDate = date("Y-m-d");

$sql = "SELECT date FROM subscriptions WHERE iduser = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $iduser);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows > 0) {
    $stmt->bind_result($date);
    $stmt->fetch();

    if ($date >= $currentDate) {
        echo json_encode(['status' => 'active']);
    } else {
        echo json_encode(['status' => 'expired']);
    }
} else {
    echo json_encode(['status' => 'not_found']);
}


$stmt->close();
$conn->close();
?>
