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

$createSql = "CREATE TABLE IF NOT EXISTS email_verification_codes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    code VARCHAR(6) NOT NULL,
    purpose VARCHAR(32) NOT NULL,
    expires_at DATETIME NOT NULL,
    verified TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email_purpose (email, purpose)
)";
$conn->query($createSql);

$purpose = 'registration';
$code = (string)random_int(100000, 999999);
$expiresAt = (new DateTime('+15 minutes'))->format('Y-m-d H:i:s');

$deleteStmt = $conn->prepare("DELETE FROM email_verification_codes WHERE email = ? AND purpose = ?");
$deleteStmt->bind_param('ss', $email, $purpose);
$deleteStmt->execute();
$deleteStmt->close();

$saveStmt = $conn->prepare("INSERT INTO email_verification_codes (email, code, purpose, expires_at) VALUES (?, ?, ?, ?)");
$saveStmt->bind_param('ssss', $email, $code, $purpose, $expiresAt);
$ok = $saveStmt->execute();
$saveStmt->close();

if (!$ok) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Не удалось сохранить код']);
    $conn->close();
    exit;
}

$subject = 'Код подтверждения регистрации';
$message = "Ваш код подтверждения регистрации: {$code}\nКод действует 15 минут.";
$headers = "From: no-reply@ivnovav.ru\r\n";
$headers .= "Content-Type: text/plain; charset=UTF-8\r\n";

if (!@mail($email, $subject, $message, $headers)) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Не удалось отправить e-mail']);
    $conn->close();
    exit;
}

echo json_encode(['status' => 'success', 'message' => 'Код отправлен на e-mail']);
$conn->close();
?>
