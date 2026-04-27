<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
include 'databd.php';

$email = isset($_POST['email']) ? trim((string)$_POST['email']) : '';
if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Некорректный e-mail']);
    exit;
}

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Ошибка подключения к базе']);
    exit;
}
$conn->set_charset('utf8');

$createSql = "CREATE TABLE IF NOT EXISTS password_resets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email)
)";
$conn->query($createSql);

$checkStmt = $conn->prepare("SELECT idusers FROM users WHERE email = ? LIMIT 1");
$checkStmt->bind_param('s', $email);
$checkStmt->execute();
$exists = $checkStmt->get_result()->fetch_assoc();
$checkStmt->close();

if (!$exists) {
    http_response_code(404);
    echo json_encode(['status' => 'error', 'message' => 'Пользователь не найден']);
    $conn->close();
    exit;
}

$code = (string)random_int(100000, 999999);
$expiresAt = (new DateTime('+15 minutes'))->format('Y-m-d H:i:s');

$conn->query("DELETE FROM password_resets WHERE email = '" . $conn->real_escape_string($email) . "'");

$saveStmt = $conn->prepare("INSERT INTO password_resets (email, code, expires_at) VALUES (?, ?, ?)");
$saveStmt->bind_param('sss', $email, $code, $expiresAt);
$ok = $saveStmt->execute();
$saveStmt->close();

if (!$ok) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Не удалось сохранить код']);
    $conn->close();
    exit;
}

$subject = 'Код восстановления пароля';
$message = "Ваш код восстановления: {$code}\nКод действует 15 минут.";
$headers = "From: no-reply@ivnovav.ru\r\n";
$headers .= "Content-Type: text/plain; charset=UTF-8\r\n";

if (!@mail($email, $subject, $message, $headers)) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Не удалось отправить e-mail']);
    $conn->close();
    exit;
}

echo json_encode(['status' => 'success', 'message' => 'Код отправлен']);
$conn->close();
?>
