<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
require __DIR__ . '/load_databd.php';
require_once __DIR__ . '/include/admin_mail.php';

$email = isset($_POST['email']) ? trim((string) $_POST['email']) : '';
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
$conn->set_charset('utf8mb4');

$createSql = "CREATE TABLE IF NOT EXISTS password_resets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email)
)";
$conn->query($createSql);

$checkStmt = $conn->prepare(
    'SELECT idusers, email FROM users WHERE LOWER(TRIM(email)) = LOWER(TRIM(?)) LIMIT 1'
);
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

$emailTo = trim((string) ($exists['email'] ?? $email));

$code = (string) random_int(100000, 999999);
$expiresAt = (new DateTime('+15 minutes'))->format('Y-m-d H:i:s');

$deleteStmt = $conn->prepare('DELETE FROM password_resets WHERE LOWER(TRIM(email)) = LOWER(TRIM(?))');
$deleteStmt->bind_param('s', $emailTo);
$deleteStmt->execute();
$deleteStmt->close();

$saveStmt = $conn->prepare('INSERT INTO password_resets (email, code, expires_at) VALUES (?, ?, ?)');
$saveStmt->bind_param('sss', $emailTo, $code, $expiresAt);
$ok = $saveStmt->execute();
$saveStmt->close();

if (!$ok) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Не удалось сохранить код']);
    $conn->close();
    exit;
}

$mailReady = function_exists('crg_mail_is_configured')
    ? crg_mail_is_configured()
    : is_readable(__DIR__ . '/mail.local.php');
if (!$mailReady) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Почта не настроена на сервере',
    ], JSON_UNESCAPED_UNICODE);
    $conn->close();
    exit;
}

$mailRes = function_exists('crg_admin_send_code_mail')
    ? crg_admin_send_code_mail($emailTo, 'код восстановления пароля', $code)
    : crg_admin_send_plain_mail(
        $emailTo,
        'CRG Transp72: код восстановления пароля',
        "Здравствуйте!\n\nВаш код: {$code}\nКод действует 15 минут.\n\n—\nГрузоперевозки72\n"
    );
if ($mailRes !== true) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => is_string($mailRes) ? $mailRes : 'Не удалось отправить e-mail',
    ], JSON_UNESCAPED_UNICODE);
    $conn->close();
    exit;
}

echo json_encode([
    'status' => 'success',
    'message' => 'Код отправлен',
    'email' => $emailTo,
], JSON_UNESCAPED_UNICODE);
$conn->close();
