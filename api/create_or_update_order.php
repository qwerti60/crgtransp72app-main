<?php
header("Content-Type: application/json");

// Параметры подключения к базе данных
include 'databd<?php
header("Content-Type: application/json");

// Параметры подключения к базе данных
require __DIR__ . '/load_databd.php';

try {
    // Подключение к базе данных
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Получение данных из POST-запроса
    $user_id = $_POST['user_id'];
    $order_id = $_POST['order_id'];
    $start_time = $_POST['start_time']; // Дата и время передаются из Flutter

    // Проверка обязательных параметров
    if (empty($user_id) || empty($order_id) || empty($start_time)) {
        throw new Exception('Параметры user_id, order_id или start_time отсутствуют!');
    }

    // Проверяем существование записи в базе данных
    $stmtCheck = $pdo->prepare("SELECT * FROM ordersglobal WHERE user_id = :user_id AND order_id = :order_id");
    $stmtCheck->bindValue(':user_id', $user_id, PDO::PARAM_INT);
    $stmtCheck->bindValue(':order_id', $order_id, PDO::PARAM_STR);
    $stmtCheck->execute();
    $row = $stmtCheck->fetch(PDO::FETCH_ASSOC);
    $recordExists = !empty($row);

    if ($recordExists) {
        // Проверяем статус записи
        if ($row['status'] === 'выполняется') {
            // Возвращаем start_time, если статус "выполняется"
            $start_time_db = $row['start_time'];
            echo json_encode([
                'message' => 'Продолжается выполнение',
                'start_time' => $start_time_db
            ]);
        } else {
            // Если статус отличается от "выполняется", выводим сообщение
            echo json_encode([
                'message' => 'Заказ уже завершён или отменён'
            ]);
        }
    } else {
        // Если записи нет, создаём новую запись с указанной датой и временем
        $stmtInsert = $pdo->prepare("INSERT INTO ordersglobal (user_id, order_id, start_time, status) VALUES (:user_id, :order_id, :start_time, 'выполняется')");
        $stmtInsert->bindValue(':user_id', $user_id, PDO::PARAM_INT);
        $stmtInsert->bindValue(':order_id', $order_id, PDO::PARAM_STR);
        $stmtInsert->bindValue(':start_time', $start_time, PDO::PARAM_STR);
        $stmtInsert->execute();

        echo json_encode([
            'message' => 'Запись успешно создана'
        ]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка при выполнении запроса к базе данных.', 'details' => $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Возникла непредвиденная ошибка.', 'details' => $e->getMessage()]);
}
?>.php';

try {
    // Подключаемся к базе данных
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Получение данных из POST-запроса
    $user_id = $_POST['user_id'];
    $order_id = $_POST['order_id'];

    // Проверка обязательных параметров
    if (empty($user_id) || empty($order_id)) {
        throw new Exception('Параметры user_id и/или order_id отсутствуют!');
    }

    // Проверяем существование записи в базе данных
    $stmtCheck = $pdo->prepare("SELECT * FROM ordersglobal WHERE user_id = :user_id AND order_id = :order_id");
    $stmtCheck->bindValue(':user_id', $user_id, PDO::PARAM_INT);
    $stmtCheck->bindValue(':order_id', $order_id, PDO::PARAM_STR);
    $stmtCheck->execute();
    $row = $stmtCheck->fetch(PDO::FETCH_ASSOC);
    $recordExists = !empty($row);

    if ($recordExists) {
        // Проверяем статус записи
        if ($row['status'] === 'выполняется') {
            // Возвращаем start_time, если статус "выполняется"
            $start_time = $row['start_time'];
            echo json_encode([
                'message' => 'Продолжается выполнение',
                'start_time' => $start_time
            ]);
        } else {
            // Если статус отличается от "выполняется", выводим соответствующее сообщение
            echo json_encode([
                'message' => 'Заказ уже завершён или отменён'
            ]);
        }
    } else {
        // Если записи нет, создаём новую запись и устанавливаем статус "выполняется"
        $stmtInsert = $pdo->prepare("INSERT INTO ordersglobal (user_id, order_id, status, created_at) VALUES (:user_id, :order_id, 'выполняется', NOW())");
        $stmtInsert->bindValue(':user_id', $user_id, PDO::PARAM_INT);
        $stmtInsert->bindValue(':order_id', $order_id, PDO::PARAM_STR);
        $stmtInsert->execute();

        echo json_encode([
            'message' => 'Запись успешно создана'
        ]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка при выполнении запроса к базе данных.', 'details' => $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Возникла непредвиденная ошибка.', 'details' => $e->getMessage()]);
}
?>