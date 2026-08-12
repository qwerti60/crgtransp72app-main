<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
require __DIR__ . '/load_databd.php';

$email = isset($_POST['email']) ? trim((string)$_POST['email']) : '';
$code = isset($_POST['code']) ? trim((string)$_POST['code']) : '';
$newPassword = isset($_POST['new_password']) ? (string)$_POST['new_password'] : '';

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL) || $code === '' || strlen($newPassword) < 8) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Некорректные данные']);
    exit;
}

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Ошибка подключения к базе']);
    exit;
}
$conn->set_charset('utf8');

$lookup = $conn->prepare('
    SELECT id, expires_at, email
    FROM password_resets
    WHERE LOWER(TRIM(email)) = LOWER(TRIM(?)) AND code = ?
    ORDER BY id DESC
    LIMIT 1
');
$lookup->bind_param('ss', $email, $code);
$lookup->execute();
$row = $lookup->get_result()->fetch_assoc();
$lookup->close();

if (!$row) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Неверный код']);
    $conn->close();
    exit;
}

$email = trim((string) ($row['email'] ?? $email));

$now = new DateTime();
$expires = new DateTime($row['expires_at']);
if ($expires < $now) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Срок действия кода истек']);
    $conn->close();
    exit;
}

$hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
if ($hashedPassword === false) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Ошибка хеширования пароля']);
    $conn->close();
    exit;
}

$update = $conn->prepare('UPDATE users SET password = ? WHERE LOWER(TRIM(email)) = LOWER(TRIM(?))');
$update->bind_param('ss', $hashedPassword, $email);
$ok = $update->execute();
$update->close();

if (!$ok) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Не удалось обновить пароль']);
    $conn->close();
    exit;
}

$delete = $conn->prepare('DELETE FROM password_resets WHERE LOWER(TRIM(email)) = LOWER(TRIM(?))');
$delete->bind_param('s', $email);
$delete->execute();
$delete->close();

echo json_encode(['status' => 'success', 'message' => 'Пароль обновлен']);
$conn->close();
?>
