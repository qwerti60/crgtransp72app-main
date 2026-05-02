<?php
header("Content-Type: application/json");

// Параметры подключения к базе данных
include 'databd.php';

try {
    // Подключаемся к базе данных
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Получаем значение userIdok из GET-запроса
    $userIdok = isset($_GET['userIdok']) ? trim($_GET['userIdok']) : '';

    // Проверка обязательных параметров
    if (empty($userIdok)) {
        throw new Exception('Отсутствует обязательный параметр userIdok.');
    }

    // Шаг 1: Проверяем активные заказы ("выполняется")
    $stmtCheckOrderExecuting = $pdo->prepare("SELECT * FROM ordersglobal WHERE user_idok = :userIdok AND status='выполняется'");
    $stmtCheckOrderExecuting->bindParam(':userIdok', $userIdok, PDO::PARAM_STR);
    $stmtCheckOrderExecuting->execute();
    $activeOrder = $stmtCheckOrderExecuting->fetch(PDO::FETCH_ASSOC);

    if ($activeOrder !== false) {
        // Если есть активный заказ, возвращаем success (result=true) и детали заказа
        echo json_encode([
            'result' => true,
            'user_id' => $activeOrder['user_id'],
            'order_id' => $activeOrder['order_id']
        ]);
        exit;
    }

    // Шаг 2: Проверяем завершённые заказы ("выполнен") и отсутствие отзыва
    $stmtCheckOrderCompleted = $pdo->prepare("SELECT * FROM ordersglobal WHERE user_idok = :userIdok AND status='выполнен'");
    $stmtCheckOrderCompleted->bindParam(':userIdok', $userIdok, PDO::PARAM_STR);
    $stmtCheckOrderCompleted->execute();

    $foundValidOrder = false; // Флаг для хранения факта нахождения подходящего заказа

    while ($completedOrder = $stmtCheckOrderCompleted->fetch(PDO::FETCH_ASSOC)) {
        // Проверяем наличие отзыва для текущего заказа
        $stmtCheckReview = $pdo->prepare(
            "SELECT COUNT(*) AS count_reviews
             FROM reviews
             WHERE user_id = :userId
               AND target_user_id = :targetUserId"
        );
        $stmtCheckReview->bindValue(':userId', (int) $completedOrder['user_idok'], PDO::PARAM_INT); // кто должен оставить отзыв
        $stmtCheckReview->bindValue(':targetUserId', (int) $completedOrder['user_id'], PDO::PARAM_INT); // кому оставляют отзыв
        $stmtCheckReview->execute();
        $reviewCount = $stmtCheckReview->fetchColumn();

        if ($reviewCount === 0) { // Отзыв отсутствует
            // Сохраняем данные заказа и устанавливаем флаг
            $validOrder = [
                'user_id' => $completedOrder['user_id'],
                'order_id' => $completedOrder['order_id']
            ];
            $foundValidOrder = true;
            break; // Выходим из цикла при первой подходящей записи
        }
    }

    if ($foundValidOrder) {
        // Нашли подходящий заказ без отзыва
        echo json_encode(array_merge(['result' => true], $validOrder));
    } else {
        // Ни одного подходящего заказа не найдено
        echo json_encode(['result' => false]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка при выполнении запроса к базе данных.', 'details' => $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Возникла непредвиденная ошибка.', 'details' => $e->getMessage()]);
}

?>
