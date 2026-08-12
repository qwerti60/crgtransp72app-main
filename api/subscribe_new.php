<?php
header("Content-Type: application/json");

require __DIR__ . '/load_databd.php'; // Убедитесь, что здесь правильный путь к файлу

$connect = new mysqli($host, $username, $password, $dbname);

// Проверка подключения
if ($connect->connect_error) {
    die("Connection failed: " . $connect->connect_error);
}

$iduser = isset($_POST['iduser']) ? intval($_POST['iduser']) : 0;

$currentDate = date("Y-m-d");

// Проверяем, существует ли запись
$sql = "SELECT date FROM subscriptions WHERE iduser = $iduser";
$result = $connect->query($sql);

if ($result->num_rows > 0) {
    // Если запись найдена, извлекаем текущую дату окончания подписки
    $row = $result->fetch_assoc();
    $currentEndDate = $row['date'];
    
    if ($currentEndDate < $currentDate) { // Дата подписки истекла
        // Начинаем отсчёт заново от текущей даты плюс 30 дней
        $newEndDate = date("Y-m-d", strtotime($currentDate. ' + 30 days'));
    } else {
        // Добавляем ещё 30 дней к существующей дате подписки
        $newEndDate = date("Y-m-d", strtotime($currentEndDate. ' + 30 days'));
    }
    
    // Обновляем дату окончания подписки в базе данных
    $sql = "UPDATE subscriptions SET date='$newEndDate' WHERE iduser = $iduser";
} else {
    // Если записи нет, добавляем новую запись с датой окончания через 30 дней
    $newDate = date("Y-m-d", strtotime($currentDate. ' + 30 days'));
    $sql = "INSERT INTO subscriptions (iduser, date) VALUES ($iduser, '$newDate')";
}

if ($connect->query($sql) === TRUE) {
    echo json_encode(array("success" => true, "message" => "Subscription updated successfully."));
} else {
    echo json_encode(array("success" => false, "message" => "Error updating subscription: " . $connect->error));
}

$connect->close();
?>