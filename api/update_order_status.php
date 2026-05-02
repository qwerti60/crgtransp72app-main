<?php
header("Content-Type: application/json");

// Подключение к базе данных
require_once 'databd.php';

try {
    // Создание соединения с базой данных
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Получение данных из PUT-запроса
    $rawInput = file_get_contents('php://input');
    $requestData = json_decode($rawInput, true);

    // Проверка обязательных параметров
    $requiredParams = ['user_id', 'order_id', 'status'];
    foreach ($requiredParams as $param) {
        if (!isset($requestData[$param]) || empty($requestData[$param])) {
            throw new Exception("Параметр '$param' отсутствует или пуст.");
        }
    }

    // Извлекаем параметры
    $user_id = $requestData['user_id'];
    $order_id = $requestData['order_id'];
    $new_status = $requestData['status'];

    // Определяем дополнительные условия, если указаны временные метки
    $additionalCondition = '';
    if (isset($requestData['current_date_time']) && !empty($requestData['current_date_time'])) {
        switch ($new_status) {
            case 'выполнен':
                $additionalCondition .= ', end_time=:current_date_time';
                break;
            case 'отменен':
                $additionalCondition .= ', cancel_time=:current_date_time'; // Обязательно добавляем cancel_time
                break;
        }
    }

    // Если current_date_time не передан, используем текущее время сервера
    if (empty($additionalCondition) && $new_status === 'отменен') {
        $currentDateTime = date('Y-m-d H:i:s'); // Текущие дата и время
        $additionalCondition .= ", cancel_time='{$currentDateTime}'";
    }

    // Готовим SQL-запрос для обновления статуса заказа
    $sqlUpdate = "UPDATE ordersglobal SET status = :status {$additionalCondition} WHERE user_id = :user_id AND order_id = :order_id";

    $stmt = $pdo->prepare($sqlUpdate);
    $stmt->bindParam(':status', $new_status, PDO::PARAM_STR);
    $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $stmt->bindParam(':order_id', $order_id, PDO::PARAM_STR);

    if ($additionalCondition !== '' && strpos($additionalCondition, ':current_date_time') !== false) { // Проверяем, используется ли плейсхолдер
        $stmt->bindValue(':current_date_time', $requestData['current_date_time'], PDO::PARAM_STR);
    }

    // Выполняем обновление
    $updatedRows = $stmt->execute();

    if ($updatedRows > 0) {
        // Выборка обновленной записи
        $selectStmt = $pdo->prepare("SELECT * FROM ordersglobal WHERE user_id = :user_id AND order_id = :order_id");
        $selectStmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $selectStmt->bindParam(':order_id', $order_id, PDO::PARAM_STR);
        $selectStmt->execute();
        $row = $selectStmt->fetch(PDO::FETCH_ASSOC);

        if ($new_status === 'отменен') {
            // Теперь обязательно проверяем наличие cancel_time
            if (isset($row['cancel_time']) && !empty($row['cancel_time'])) {
                echo json_encode([
                    'message' => 'Заказ отменён.',
                    'cancel_time' => $row['cancel_time']
                ]);
            } else {
                echo json_encode(['message' => 'Заказ отменён.']); // Без конкретного времени
            }
        } elseif ($new_status === 'выполнен') {
            // Вычисляем длительность выполнения заказа
            $startTime = strtotime($row['start_time']);
            $endTime = strtotime($row['end_time']);
            $durationSeconds = $endTime - $startTime;

            echo json_encode([
                'message' => 'Заказ выполнен.',
                'start_time' => $row['start_time'],
                'end_time' => $row['end_time'],
                'duration_seconds' => $durationSeconds
            ]);
        } else {
            echo json_encode(['message' => 'Обновлён статус заказа']);
        }
    } else {
        throw new Exception('Не удалось обновить статус заказа.');
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка базы данных.', 'details' => $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode(['error' => $e->getMessage()]);
}
?>