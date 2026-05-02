<?php
header("Content-Type: application/json");

// Параметры подключения к базе данных
include 'databd.php';

try {
    // Подключение к базе данных
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Получение данных из POST-запроса
    $user_id = $_POST['user_id'];
    $order_id = $_POST['order_id'];
    $start_time = $_POST['start_time']; // Дата и время передаются из Flutter
    $user_idok = $_POST['user_idok'];   // Дополнительный параметр передается из Flutter

    // Проверка обязательных параметров
    if (empty($user_id) || empty($order_id) || empty($start_time) || empty($user_idok)) {
        throw new Exception('Параметры user_id, order_id, user_idok или start_time отсутствуют!');
    }

    // Проверяем наличие последней записи в таблице ordersglobal
    $stmtCheckOrdersGlobal = $pdo->prepare(
        "SELECT * FROM ordersglobal 
         WHERE user_id = :user_id AND order_id = :order_id 
         ORDER BY id DESC 
         LIMIT 1"
    );
    $stmtCheckOrdersGlobal->bindValue(':user_id', $user_id, PDO::PARAM_INT);
    $stmtCheckOrdersGlobal->bindValue(':order_id', $order_id, PDO::PARAM_STR);
    $stmtCheckOrdersGlobal->execute();
    $row = $stmtCheckOrdersGlobal->fetch(PDO::FETCH_ASSOC);
    $recordExistsInOrdersGlobal = !empty($row);

    if (!$recordExistsInOrdersGlobal) {
        // Проверяем таблицу offer_data на наличие принятого заказчиком предложения
        $stmtCheckOfferData = $pdo->prepare(
            "SELECT * FROM offer_data 
             WHERE iduserp = :iduserp AND iduser = :iduser AND status = 0 AND isp = 1
             LIMIT 1"
        );
        $stmtCheckOfferData->bindValue(':iduserp', $user_id, PDO::PARAM_INT);
        $stmtCheckOfferData->bindValue(':iduser', $order_id, PDO::PARAM_STR);
        $stmtCheckOfferData->execute();
        $offerRow = $stmtCheckOfferData->fetch(PDO::FETCH_ASSOC);
        
        if (!empty($offerRow)) {
            // Меняем статус заказа в offer_data на 1
            $stmtUpdateOfferData = $pdo->prepare("UPDATE offer_data SET status = 1 WHERE id = :id");
            $stmtUpdateOfferData->bindValue(':id', $offerRow['id'], PDO::PARAM_INT);
            $stmtUpdateOfferData->execute();
            
            // Создаем новую запись в ordersglobal с полем idoffer
            $stmtInsertOrdersGlobal = $pdo->prepare(
                "INSERT INTO ordersglobal 
                 (user_id, order_id, user_idok, start_time, status, idoffer) 
                 VALUES (:user_id, :order_id, :user_idok, :start_time, 'выполняется', :idoffer)"
            );
            $stmtInsertOrdersGlobal->bindParam(':user_id', $user_id, PDO::PARAM_INT);
            $stmtInsertOrdersGlobal->bindParam(':order_id', $order_id, PDO::PARAM_STR);
            $stmtInsertOrdersGlobal->bindParam(':user_idok', $user_idok, PDO::PARAM_STR);
            $stmtInsertOrdersGlobal->bindParam(':start_time', $start_time, PDO::PARAM_STR);
            $stmtInsertOrdersGlobal->bindValue(':idoffer', $offerRow['id'], PDO::PARAM_INT); // Значение поля idoffer
            $stmtInsertOrdersGlobal->execute();

            echo json_encode([
                'message' => 'Запись успешно создана'
            ]);
        } else {
            // Принятое заказчиком предложение не найдено
            echo json_encode([
                'message' => 'Предложение не принято заказчиком'
            ]);
        }
    } else {
        // Если запись существует, проверяем её статус
        switch ($row['status']) {
            case 'выполняется':
                // Возвращаем start_time, если статус "выполняется"
                $start_time_db = $row['start_time'];
                echo json_encode([
                    'message' => 'Продолжается выполнение',
                    'start_time' => $start_time_db
                ]);
                break;
            case 'отменен':
                // Возвращаем cancel_time, если заказ отменён
                $cancel_time_db = $row['cancel_time'];
                echo json_encode([
                    'message' => 'Заказ отменен',
                    'cancel_time' => $cancel_time_db
                ]);
                break;
            case 'выполнен':
                // Получаем start_time и end_time
                $start_time_db = $row['start_time'];
                $end_time_db = $row['end_time'];
                
                // Вычисляем разницу в секундах
                $duration_seconds = strtotime($end_time_db) - strtotime($start_time_db);
                
                // Формируем объект результата
                $result = [
                    'message' => 'Заказ выполнен',
                    'start_time' => $start_time_db,
                    'end_time' => $end_time_db,
                    'duration' => $duration_seconds . ' секунд'
                ];

                echo json_encode($result);
                break;
            default:
                // Обрабатываем неизвестный статус
                echo json_encode([
                    'message' => 'Неизвестный статус заказа'
                ]);
        }
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка при выполнении запроса к базе данных.', 'details' => $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Возникла непредвиденная ошибка.', 'details' => $e->getMessage()]);
}
?>
