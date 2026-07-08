<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require __DIR__ . '/load_databd.php';
require_once __DIR__ . '/include/site_config.php';
require_once __DIR__ . '/include/jwt_bootstrap.php';

if (!isset($_POST['email'], $_POST['password'])) {
    echo json_encode(['message' => 'Не получен логин или пароль'], JSON_UNESCAPED_UNICODE);
    exit;
}

$email = trim((string) $_POST['email']);
$loginPassword = (string) $_POST['password'];

if ($email === '' || $loginPassword === '') {
    echo json_encode(['message' => 'Не получен логин или пароль'], JSON_UNESCAPED_UNICODE);
    exit;
}

$db = crg_db_config();
$conn = new mysqli($db['host'], $db['username'], $db['password'], $db['dbname']);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['message' => 'Ошибка сервера'], JSON_UNESCAPED_UNICODE);
    exit;
}
$conn->set_charset('utf8mb4');

$stmt = $conn->prepare('SELECT idusers, email, rollNum, statNum, password FROM users WHERE email = ? LIMIT 1');
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(['message' => 'Ошибка сервера'], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmt->bind_param('s', $email);
$stmt->execute();
$result = $stmt->get_result();
$row = $result->fetch_assoc();
$stmt->close();
$conn->close();

if (!is_array($row)) {
    echo json_encode(['message' => 'Неверный логин или пароль'], JSON_UNESCAPED_UNICODE);
    exit;
}

$hash = (string) ($row['password'] ?? '');
$passwordOk = $hash !== '' && (
    password_verify($loginPassword, $hash)
    || (!str_starts_with($hash, '$') && hash_equals($hash, $loginPassword))
);

if (!$passwordOk) {
    echo json_encode(['message' => 'Неверный логин или пароль'], JSON_UNESCAPED_UNICODE);
    exit;
}

if (!crg_jwt_autoload()) {
    http_response_code(500);
    echo json_encode(['message' => 'Ошибка сервера'], JSON_UNESCAPED_UNICODE);
    exit;
}

$payload = [
    'iss' => crg_site_host(),
    'aud' => crg_site_host(),
    'iat' => time(),
    'nbf' => time(),
    'exp' => time() + 3600,
    'data' => [
        'idusers' => (int) $row['idusers'],
        'email' => (string) $row['email'],
        'rollNum' => (int) $row['rollNum'],
        'statNum' => (int) $row['statNum'],
    ],
];

$jwt = crg_jwt_encode($payload);
if ($jwt === null) {
    http_response_code(500);
    echo json_encode(['message' => 'Ошибка сервера'], JSON_UNESCAPED_UNICODE);
    exit;
}

echo json_encode(['token' => $jwt], JSON_UNESCAPED_UNICODE);
?>