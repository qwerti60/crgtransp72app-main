<?php

header('Content-Type: application/json; charset=utf-8');
include 'databd.php'; // параметры $host, $dbname, $username, $password

try {
/* 1. Подключаемся к БД */
$pdo = new PDO(
"mysql:host=$host;dbname=$dbname;charset=utf8mb4",
$username,
$password,
[
PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]
);

/* 2. Читаем и валидируем JSON */
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
empty($data['user_id']) || !ctype_digit((string)$data['user_id']) ||
empty($data['target_user_id']) || !ctype_digit((string)$data['target_user_id']) ||
empty($data['rating']) || !ctype_digit((string)$data['rating']) ||
empty($data['comment']) || strlen(trim($data['comment'])) === 0
) {
echo json_encode(['status' => 'error', 'message' => 'Недостаточно данных для отправки отзыва']);
exit;
}

/* 3. Исходные данные */
$senderId = (int)$data['user_id']; // отправитель (кто пишет)
$orderId = (int)$data['target_user_id']; // id заказа
$rating = (int)$data['rating'];
$comment = trim($data['comment']);

/* 4. Получаем user_idok по номеру заказа */
$orderStmt = $pdo->prepare('SELECT user_idok FROM ordersglobal WHERE order_id = ? LIMIT 1');
$orderStmt->execute([$orderId]);
$userIdOk = $orderStmt->fetchColumn();

if (!$userIdOk) {
echo json_encode(['status' => 'error', 'message' => 'Заказ с указанным ID не найден']);
exit;
}
$userIdOk = (int)$userIdOk; // тот самый user_id, который пишем в reviewsisp

/* 5. Проверяем, есть ли уже отзыв для этой пары (user_idok, senderId) */
$checkStmt = $pdo->prepare(
'SELECT id FROM reviewsisp WHERE user_id = ? AND target_user_id = ? LIMIT 1'
);
$checkStmt->execute([$userIdOk, $senderId]);
$existingReview = $checkStmt->fetch();

if ($existingReview) {
/* 5а. Обновляем старый отзыв */
$updateStmt = $pdo->prepare(
'UPDATE reviewsisp
SET rating = ?, comment = ?, datastamp = NOW()
WHERE id = ?'
);
$updateStmt->execute([$rating, $comment, $existingReview['id']]);

echo json_encode(['status' => 'success', 'message' => 'Отзыв обновлён']);
} else {
/* 5б. Добавляем новый отзыв */
$insertStmt = $pdo->prepare(
'INSERT INTO reviewsisp (user_id, target_user_id, rating, comment)
VALUES (?, ?, ?, ?)'
);
$insertStmt->execute([$userIdOk, $senderId, $rating, $comment]);

echo json_encode(['status' => 'success', 'message' => 'Новый отзыв успешно добавлен']);
}

} catch (PDOException $e) {
error_log('Ошибка при обработке отзыва: ' . $e->getMessage());
echo json_encode(['status' => 'error', 'message' => 'Внутренняя ошибка сервера']);
}
?>