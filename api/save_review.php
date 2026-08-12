<?php
/**
 * Исполнитель оставляет отзыв о заказчике (таблица reviews).
 * user_id = исполнитель (автор), target_user_id = заказчик.
 * Один отзыв на пару (исполнитель, заказчик).
 */
header('Content-Type: application/json; charset=utf-8');
require __DIR__ . '/load_databd.php'; // Подключение конфигурационного файла с параметрами базы данных

try {
    // Соединение с базой данных
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);

    // Читаем POST-данные из тела запроса
    $rawData = file_get_contents('php://input');
    if (empty($rawData)) {
        echo json_encode(['status' => 'error', 'message' => 'Нет данных в запросе']);
        exit;
    }

    // Декодируем JSON-данные
    $data = json_decode($rawData, true);
    if (!is_array($data)) {
        echo json_encode(['status' => 'error', 'message' => 'Некорректный формат JSON']);
        exit;
    }

    // Проверка входящих данных
    if (
        empty($data['user_id']) || !ctype_digit((string)$data['user_id']) ||
        empty($data['target_user_id']) || !ctype_digit((string)$data['target_user_id']) ||
        empty($data['rating']) || !ctype_digit((string)$data['rating']) ||
        empty($data['comment']) || strlen(trim($data['comment'])) === 0
    ) {
        echo json_encode(['status' => 'error', 'message' => 'Недостаточно данных для отправки отзыва']);
        exit;
    }

    // Извлекаем нужные значения
    $userId = intval($data['user_id']); // Отправляющий отзыв
    $targetUserId = intval($data['target_user_id']); // Получатель отзыва
    $rating = intval($data['rating']); // Рейтинг
    $comment = trim($data['comment']); // Отзыв

    // Шаг 1: Проверяем существование отзыва для конкретной пары пользователей
    $checkStmt = $pdo->prepare('SELECT id FROM reviews WHERE user_id = ? AND target_user_id = ?');
    $checkStmt->execute([$userId, $targetUserId]);
    $existingReview = $checkStmt->fetch();

    if ($existingReview) {
        // Если отзыв существует, обновляем его
        $updateStmt = $pdo->prepare('UPDATE reviews SET rating = ?, comment = ?, datastamp = NOW() WHERE id = ?');
        $updateStmt->execute([$rating, $comment, $existingReview['id']]);

        echo json_encode(['status' => 'success', 'message' => 'Отзыв обновлён']);
    } else {
        // Если отзыва нет, добавляем новый
        $insertStmt = $pdo->prepare('INSERT INTO reviews (user_id, target_user_id, rating, comment) VALUES (?, ?, ?, ?)');
        $insertStmt->execute([$userId, $targetUserId, $rating, $comment]);

        echo json_encode(['status' => 'success', 'message' => 'Новый отзыв успешно добавлен']);
    }

} catch (PDOException $e) {
    error_log('Ошибка при обработке отзыва: ' . $e->getMessage()); // Логирование ошибок
    echo json_encode(['status' => 'error', 'message' => 'Внутренняя ошибка сервера']);
}
?>