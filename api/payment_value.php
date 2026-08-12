<?php
header("Content-Type: application/json");

require __DIR__ . '/load_databd.php'; // Убедитесь, что здесь правильный путь к файлу

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION); // Включаем режим отображения ошибок
} catch (PDOException $e) {
    die('Ошибка подключения к базе данных: ' . $e->getMessage());
}

// Получение POST-запросов от клиента
$idusers      = $_POST['idusers'];
$paymentValue = $_POST['payment']; // новое значение платежа

if (!$idusers || !$paymentValue) {
    http_response_code(400);
    echo json_encode(['message' => 'Отсутствуют обязательные параметры']);
    exit();
}

// Обновляем запись в базе данных
$sql = "UPDATE users SET payment=:new_payment WHERE idusers=:id";
$stmt = $pdo->prepare($sql);
$stmt->bindParam(':new_payment', $paymentValue);
$stmt->bindParam(':id', $idusers);

try {
    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(['message' => 'Обновление успешно выполнено']);
    } else {
        http_response_code(500);
        echo json_encode(['message' => 'Ошибка при обновлении записи']);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['message' => 'Ошибка SQL: ' . $e->getMessage()]);
}
?>