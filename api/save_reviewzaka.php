<?php
/**
 * Заказчик оставляет отзыв об исполнителе (таблица reviewsisp).
 * user_id = исполнитель, target_user_id = заказчик (автор отзыва).
 * Один отзыв на пару (исполнитель, заказчик).
 */
header('Content-Type: application/json; charset=utf-8');
include __DIR__ . '/databd.php';

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );

    $rawData = file_get_contents('php://input');
    if (empty($rawData)) {
        echo json_encode(['status' => 'error', 'message' => 'Нет данных в запросе']);
        exit;
    }

    $data = json_decode($rawData, true);
    if (!is_array($data)) {
        echo json_encode(['status' => 'error', 'message' => 'Некорректный формат JSON']);
        exit;
    }

    if (
        empty($data['user_id']) || !ctype_digit((string) $data['user_id']) ||
        empty($data['target_user_id']) || !ctype_digit((string) $data['target_user_id']) ||
        empty($data['rating']) || !ctype_digit((string) $data['rating']) ||
        empty($data['comment']) || strlen(trim($data['comment'])) === 0
    ) {
        echo json_encode(['status' => 'error', 'message' => 'Недостаточно данных для отправки отзыва']);
        exit;
    }

    $customerId = (int) $data['user_id'];
    $orderId = (int) $data['target_user_id'];
    $rating = (int) $data['rating'];
    $comment = trim($data['comment']);

    $orderStmt = $pdo->prepare(
        'SELECT user_id, user_idok
         FROM ordersglobal
         WHERE order_id = ? AND user_idok = ?
         ORDER BY id DESC
         LIMIT 1'
    );
    $orderStmt->execute([$orderId, $customerId]);
    $orderRow = $orderStmt->fetch();

    if (!$orderRow) {
        $orderStmt = $pdo->prepare(
            'SELECT user_id, user_idok
             FROM ordersglobal
             WHERE order_id = ?
             ORDER BY id DESC
             LIMIT 1'
        );
        $orderStmt->execute([$orderId]);
        $orderRow = $orderStmt->fetch();
    }

    if (!$orderRow) {
        echo json_encode(['status' => 'error', 'message' => 'Заказ с указанным ID не найден']);
        exit;
    }

    $performerId = (int) $orderRow['user_id'];
    $orderCustomerId = (int) $orderRow['user_idok'];

    if ($orderCustomerId > 0 && $orderCustomerId !== $customerId) {
        echo json_encode(['status' => 'error', 'message' => 'Заказ не принадлежит этому заказчику']);
        exit;
    }

    $checkStmt = $pdo->prepare(
        'SELECT id FROM reviewsisp WHERE user_id = ? AND target_user_id = ? LIMIT 1'
    );
    $checkStmt->execute([$performerId, $customerId]);
    $existingReview = $checkStmt->fetch();

    if ($existingReview) {
        $updateStmt = $pdo->prepare(
            'UPDATE reviewsisp
             SET rating = ?, comment = ?, datastamp = NOW()
             WHERE id = ?'
        );
        $updateStmt->execute([$rating, $comment, $existingReview['id']]);
        echo json_encode(['status' => 'success', 'message' => 'Отзыв обновлён']);
    } else {
        $insertStmt = $pdo->prepare(
            'INSERT INTO reviewsisp (user_id, target_user_id, rating, comment)
             VALUES (?, ?, ?, ?)'
        );
        $insertStmt->execute([$performerId, $customerId, $rating, $comment]);
        echo json_encode(['status' => 'success', 'message' => 'Новый отзыв успешно добавлен']);
    }
} catch (PDOException $e) {
    error_log('Ошибка при обработке отзыва: ' . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'Внутренняя ошибка сервера']);
}
