<?php
header('Content-Type: application/json; charset=utf-8');

require __DIR__ . '/load_databd.php';

/**
 * Отзыв заказчика об исполнителе (reviewsisp):
 * user_id = исполнитель, target_user_id = заказчик.
 */
function crg_customer_review_exists(PDO $pdo, int $performerId, int $customerId): bool
{
    if ($performerId <= 0 || $customerId <= 0) {
        return false;
    }

    $stmt = $pdo->prepare(
        'SELECT 1 FROM reviewsisp
         WHERE user_id = :performerId AND target_user_id = :customerId
         LIMIT 1'
    );
    $stmt->bindValue(':performerId', $performerId, PDO::PARAM_INT);
    $stmt->bindValue(':customerId', $customerId, PDO::PARAM_INT);
    $stmt->execute();

    return (bool) $stmt->fetchColumn();
}

function crg_isp_customer_order_payload(array $row, bool $hasReview): array
{
    return [
        'result' => true,
        'user_id' => $row['user_id'],
        'order_id' => $row['order_id'],
        'status' => $row['status'],
        'deal_source' => $row['deal_source'] ?? 'customer_order',
        'bd' => $row['bd'] ?? null,
        'needs_review' => !$hasReview && ($row['status'] ?? '') === 'выполнен',
        'has_review' => $hasReview,
    ];
}

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $customerId = isset($_GET['userIdok']) ? trim($_GET['userIdok']) : '';

    if ($customerId === '') {
        throw new Exception('Отсутствует обязательный параметр userIdok.');
    }

    $customerIdInt = (int) $customerId;

    $stmtCheckOrderExecuting = $pdo->prepare(
        "SELECT * FROM ordersglobal
         WHERE user_idok = :customerId AND status = 'выполняется'
         ORDER BY id DESC
         LIMIT 1"
    );
    $stmtCheckOrderExecuting->bindParam(':customerId', $customerId, PDO::PARAM_STR);
    $stmtCheckOrderExecuting->execute();
    $activeOrder = $stmtCheckOrderExecuting->fetch(PDO::FETCH_ASSOC);

    if ($activeOrder !== false) {
        $performerId = (int) ($activeOrder['user_id'] ?? 0);
        $hasReview = crg_customer_review_exists($pdo, $performerId, $customerIdInt);
        echo json_encode(
            crg_isp_customer_order_payload($activeOrder, $hasReview),
            JSON_UNESCAPED_UNICODE
        );
        exit;
    }

    $stmtCheckOrderCompleted = $pdo->prepare(
        "SELECT * FROM ordersglobal
         WHERE user_idok = :customerId AND status = 'выполнен'
         ORDER BY id DESC"
    );
    $stmtCheckOrderCompleted->bindParam(':customerId', $customerId, PDO::PARAM_STR);
    $stmtCheckOrderCompleted->execute();

    while ($completedOrder = $stmtCheckOrderCompleted->fetch(PDO::FETCH_ASSOC)) {
        $performerId = (int) ($completedOrder['user_id'] ?? 0);
        if ($performerId <= 0) {
            continue;
        }

        if (!crg_customer_review_exists($pdo, $performerId, $customerIdInt)) {
            echo json_encode(
                crg_isp_customer_order_payload($completedOrder, false),
                JSON_UNESCAPED_UNICODE
            );
            exit;
        }
    }

    echo json_encode(['result' => false], JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка при выполнении запроса к базе данных.', 'details' => $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Возникла непредвиденная ошибка.', 'details' => $e->getMessage()]);
}
