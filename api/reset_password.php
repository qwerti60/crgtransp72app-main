<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

include 'databd.php';
require_once __DIR__ . '/include/site_config.php';

$email = isset($_POST['email']) ? trim((string)$_POST['email']) : '';

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'message' => 'Некорректный e-mail',
    ]);
    exit;
}

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Ошибка подключения к базе',
    ]);
    exit;
}

$conn->set_charset('utf8');

$checkSql = "SELECT idusers FROM users WHERE email = ? LIMIT 1";
$checkStmt = $conn->prepare($checkSql);
if (!$checkStmt) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Ошибка подготовки запроса',
    ]);
    $conn->close();
    exit;
}

$checkStmt->bind_param('s', $email);
$checkStmt->execute();
$result = $checkStmt->get_result();
$user = $result ? $result->fetch_assoc() : null;
$checkStmt->close();

if (!$user) {
    http_response_code(404);
    echo json_encode([
        'status' => 'error',
        'message' => 'Пользователь с таким e-mail не найден',
    ]);
    $conn->close();
    exit;
}

function generatePassword(int $length = 10): string {
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    $max = strlen($alphabet) - 1;
    $password = '';
    for ($i = 0; $i < $length; $i++) {
        $password .= $alphabet[random_int(0, $max)];
    }
    return $password;
}

$newPassword = generatePassword(10);
$hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
if ($hashedPassword === false) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Ошибка хеширования пароля',
    ]);
    $conn->close();
    exit;
}

$updateSql = "UPDATE users SET password = ? WHERE idusers = ?";
$updateStmt = $conn->prepare($updateSql);
if (!$updateStmt) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Ошибка обновления пароля',
    ]);
    $conn->close();
    exit;
}

$userId = (int)$user['idusers'];
$updateStmt->bind_param('si', $hashedPassword, $userId);
$updateStmt->execute();
$okUpdate = $updateStmt->affected_rows >= 0;
$updateStmt->close();

if (!$okUpdate) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Не удалось сохранить новый пароль',
    ]);
    $conn->close();
    exit;
}

$subject = 'Восстановление пароля';
$message = "Здравствуйте!\n\nВаш новый пароль: {$newPassword}\n\nРекомендуем сменить пароль после входа.";

require_once __DIR__ . '/include/admin_mail.php';
$mailSent = crg_admin_send_plain_mail($email, $subject, $message);

if ($mailSent !== true) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => is_string($mailSent) ? $mailSent : 'Пароль обновлен, но не удалось отправить e-mail',
    ]);
    $conn->close();
    exit;
}

echo json_encode([
    'status' => 'success',
    'message' => 'Новый пароль отправлен на e-mail',
]);

$conn->close();
?>
