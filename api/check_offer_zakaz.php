<?php
/**
 * GET: iduser (заказчик), truck (id объявления), bd, performer_id (id исполнителя).
 * Проверка offer_dataf и статуса сделки в ordersglobal (сценарий 2).
 */
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

$iduser      = (int) ($_GET['iduser'] ?? 0);
$truck       = (int) ($_GET['truck'] ?? 0);
$bd          = (int) ($_GET['bd'] ?? 0);
$performerId = (int) ($_GET['performer_id'] ?? 0);

if ($iduser <= 0 || $truck <= 0) {
    echo json_encode(['exists' => false, 'order_status' => '']);
    exit;
}

try {
    $conn = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $stmt = $conn->prepare(
        'SELECT COUNT(*) FROM offer_dataf
         WHERE iduserp = :iduserp AND iduser = :iduser AND bd = :bd
         LIMIT 1'
    );
    $stmt->bindParam(':iduserp', $iduser, PDO::PARAM_INT);
    $stmt->bindParam(':iduser', $truck, PDO::PARAM_INT);
    $stmt->bindParam(':bd', $bd, PDO::PARAM_INT);
    $stmt->execute();

    $exists = ((int) $stmt->fetchColumn()) > 0;
    $orderStatus = '';

    if ($performerId > 0) {
        $dealSql = 'SELECT status FROM ordersglobal
                    WHERE user_id = :performer_id
                      AND order_id = :order_id
                      AND user_idok = :customer_id
                    ORDER BY id DESC
                    LIMIT 1';
        $dealStmt = $conn->prepare($dealSql);
        $customerStr = (string) $iduser;
        $adStr = (string) $truck;
        $dealStmt->bindValue(':performer_id', $performerId, PDO::PARAM_INT);
        $dealStmt->bindValue(':order_id', $adStr, PDO::PARAM_STR);
        $dealStmt->bindParam(':customer_id', $customerStr, PDO::PARAM_STR);
        $dealStmt->execute();
        $statusRow = $dealStmt->fetch(PDO::FETCH_ASSOC);
        if ($statusRow) {
            $orderStatus = (string) ($statusRow['status'] ?? '');
        }
    }

    // Завершённые/отменённые сделки — можно оформить новую заявку, старая строка не считается активной.
    if (in_array($orderStatus, ['выполнен', 'отменен'], true)) {
        $exists = false;
    }

    echo json_encode([
        'exists' => $exists,
        'order_status' => $orderStatus,
    ], JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    echo json_encode(['exists' => false, 'order_status' => '']);
}
