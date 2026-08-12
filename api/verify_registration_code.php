<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
require __DIR__ . '/load_databd.php';

$email = isset($_POST['email']) ? trim((string)$_POST['email']) : '';
$code = isset($_POST['code']) ? trim((string)$_POST['code']) : '';

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Некорректный e-mail']);
    exit;
}
if ($code === '' || !preg_match('/^\d{6}$/', $code)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Некорректный код']);
    exit;
}

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Ошибка подключения к базе']);
    exit;
}
$conn->set_charset('utf8');

$purpose = 'registration';
$stmt = $conn->prepare(
    "SELECT id FROM email_verification_codes
     WHERE email = ? AND purpose = ? AND code = ? AND verified = 0 AND expires_at >= NOW()
     ORDER BY id DESC LIMIT 1"
);
$stmt->bind_param('sss', $email, $purpose, $code);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$row) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Неверный или просроченный код']);
    $conn->close();
    exit;
}

$verifyStmt = $conn->prepare("UPDATE email_verification_codes SET verified = 1 WHERE id = ?");
$verifyStmt->bind_param('i', $row['id']);
$verifyStmt->execute();
$verifyStmt->close();

echo json_encode(['status' => 'success', 'message' => 'E-mail подтвержден']);
$conn->close();
?>
