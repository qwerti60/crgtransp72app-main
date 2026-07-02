<?php
header('Content-Type: application/json; charset=utf-8');

include 'databd.php';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $customerId = isset($_GET['userIdok']) ? trim($_GET['userIdok']) : '';

    if ($customerId === '') {
        throw new Exception('Отсутствует обязательный параметр userIdok.');
    }

    $stmtCheckOrderExecuting = $pdo->prepare(
        "SELECT * FROM ordersglobal WHERE user_idok = :customerId AND status = 'выполняется' ORDER BY id DESC LIMIT 1"
    );
    $stmtCheckOrderExecuting->bindParam(':customerId', $customerId, PDO::PARAM_STR);
    $stmtCheckOrderExecuting->execute();
    $activeOrder = $stmtCheckOrderExecuting->fetch(PDO::FETCH_ASSOC);

    if ($activeOrder !== false) {
        echo json_encode([
            'result' => true,
            'user_id' => $activeOrder['user_id'],
            'order_id' => $activeOrder['order_id'],
        ]);
        exit;
    }

    $stmtCheckOrderCompleted = $pdo->prepare(
        "SELECT * FROM ordersglobal WHERE user_idok = :customerId AND status = 'выполнен' ORDER BY id DESC"
    );
    $stmtCheckOrderCompleted->bindParam(':customerId', $customerId, PDO::PARAM_STR);
    $stmtCheckOrderCompleted->execute();

    $foundValidOrder = false;
    $validOrder = null;

    while ($completedOrder = $stmtCheckOrderCompleted->fetch(PDO::FETCH_ASSOC)) {
        $performerId = (int) $completedOrder['user_id'];
        $orderCustomerId = (int) $completedOrder['user_idok'];

        $stmtCheckReview = $pdo->prepare(
            'SELECT COUNT(*) FROM reviewsisp
             WHERE user_id = :performerId AND target_user_id = :customerId'
        );
        $stmtCheckReview->bindValue(':performerId', $performerId, PDO::PARAM_INT);
        $stmtCheckReview->bindValue(':customerId', $orderCustomerId, PDO::PARAM_INT);
        $stmtCheckReview->execute();
        $reviewCount = (int) $stmtCheckReview->fetchColumn();

        if ($reviewCount === 0) {
            $validOrder = [
                'user_id' => $completedOrder['user_id'],
                'order_id' => $completedOrder['order_id'],
            ];
            $foundValidOrder = true;
            break;
        }
    }

    if ($foundValidOrder && $validOrder !== null) {
        echo json_encode(array_merge(['result' => true], $validOrder));
    } else {
        echo json_encode(['result' => false]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка при выполнении запроса к базе данных.', 'details' => $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Возникла непредвиденная ошибка.', 'details' => $e->getMessage()]);
}
