<?php
/**
 * Исполнитель: активный/завершённый заказ в ordersglobal.
 * GET userIdok — id исполнителя (users.idusers), не заказчика.
 */
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $performerId = isset($_GET['userIdok']) ? trim($_GET['userIdok']) : '';

    if ($performerId === '' || $performerId === '0') {
        throw new Exception('Отсутствует обязательный параметр userIdok (id исполнителя).');
    }

    $stmtCheckOrderExecuting = $pdo->prepare(
        "SELECT * FROM ordersglobal
         WHERE user_id = :performerId AND status = 'выполняется'
         ORDER BY id DESC
         LIMIT 1"
    );
    $stmtCheckOrderExecuting->bindParam(':performerId', $performerId, PDO::PARAM_STR);
    $stmtCheckOrderExecuting->execute();
    $activeOrder = $stmtCheckOrderExecuting->fetch(PDO::FETCH_ASSOC);

    if ($activeOrder !== false) {
        echo json_encode([
            'result' => true,
            'user_id' => $activeOrder['user_id'],
            'order_id' => $activeOrder['order_id'],
            'user_idok' => $activeOrder['user_idok'],
            'status' => $activeOrder['status'],
            'start_time' => $activeOrder['start_time'],
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmtCheckOrderCompleted = $pdo->prepare(
        "SELECT * FROM ordersglobal
         WHERE user_id = :performerId AND status = 'выполнен'
         ORDER BY id DESC"
    );
    $stmtCheckOrderCompleted->bindParam(':performerId', $performerId, PDO::PARAM_STR);
    $stmtCheckOrderCompleted->execute();

    $foundValidOrder = false;
    $validOrder = null;

    while ($completedOrder = $stmtCheckOrderCompleted->fetch(PDO::FETCH_ASSOC)) {
        $performerIdInt = (int) $completedOrder['user_id'];
        $customerIdInt = (int) $completedOrder['user_idok'];

        // Исполнитель пишет отзыв о заказчике в таблицу reviews (save_review.php).
        $stmtCheckReview = $pdo->prepare(
            'SELECT COUNT(*) FROM reviews
             WHERE user_id = :performerId AND target_user_id = :customerId'
        );
        $stmtCheckReview->bindValue(':performerId', $performerIdInt, PDO::PARAM_INT);
        $stmtCheckReview->bindValue(':customerId', $customerIdInt, PDO::PARAM_INT);
        $stmtCheckReview->execute();
        $reviewCount = (int) $stmtCheckReview->fetchColumn();

        if ($reviewCount === 0) {
            $validOrder = [
                'user_id' => $completedOrder['user_id'],
                'order_id' => $completedOrder['order_id'],
                'user_idok' => $completedOrder['user_idok'],
                'status' => 'выполнен',
            ];
            $foundValidOrder = true;
            break;
        }
    }

    if ($foundValidOrder && $validOrder !== null) {
        echo json_encode(array_merge(['result' => true], $validOrder), JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode(['result' => false], JSON_UNESCAPED_UNICODE);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Ошибка при выполнении запроса к базе данных.',
        'details' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Возникла непредвиденная ошибка.',
        'details' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
