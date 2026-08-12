<?php
header('Content-Type: application/json');

require __DIR__ . '/load_databd.php'; // Убедитесь, что здесь правильный путь к файлу

// Получаем POST-данные от клиента
$idUsers     = isset($_POST['idusers']) ? intval($_POST['idusers']) : null;
$newPayment  = isset($_POST['payment']) ? trim($_POST['payment']) : null;
$typePayment = isset($_POST['typepayment']) ? trim($_POST['typepayment']) : null;

// Проверка наличия необходимых полей
if (!$idUsers || !$newPayment || !$typePayment) {
    http_response_code(400);
    echo json_encode([
        'status' => false,
        'message' => 'Неверные или отсутствующие данные'
    ]);
    exit(); // Завершаем выполнение скрипта
}

// Подключаемся к базе данных
try {
    $pdo = new PDO("mysql:host={$host};dbname={$dbname};charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Подготовленный SQL-запрос для обновления двух столбцов одновременно
    $updateQuery = "UPDATE users SET payment = :newPayment, typepayment = :typePayment WHERE idusers = :idUsers";
    $statement = $pdo->prepare($updateQuery);
    $statement->bindParam(':newPayment', $newPayment);
    $statement->bindParam(':typePayment', $typePayment); // Добавляем новую переменную
    $statement->bindParam(':idUsers', $idUsers);

    // Выполняем запрос
    if ($statement->execute()) {
        http_response_code(200);
        echo json_encode([
            'status' => true,
            'message' => 'Данные успешно обновлены'
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'status' => false,
            'message' => 'Ошибка при обновлении данных'
        ]);
    }
} catch (PDOException $exception) {
    http_response_code(500);
    echo json_encode([
        'status' => false,
        'message' => 'Ошибка соединения с базой данных: ' . $exception->getMessage()
    ]);
}

exit();
?>