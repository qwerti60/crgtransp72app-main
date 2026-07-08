<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require __DIR__ . '/load_databd.php';

/**
 * JWT для входа: только api/include/jwt_bootstrap.php (без дубликата api/jwt_bootstrap.php).
 */
function crg_autoriz1_bootstrap_jwt(): bool
{
    if (!function_exists('crg_jwt_autoload')) {
        $bootstrap = __DIR__ . '/include/jwt_bootstrap.php';
        if (!is_readable($bootstrap)) {
            return false;
        }
        require_once $bootstrap;
    }

    return function_exists('crg_jwt_autoload') && crg_jwt_autoload();
}

$response = ['success' => false];

try {
    $conn = new mysqli($host, $username, $password, $dbname);
    if ($conn->connect_error) {
        throw new RuntimeException('DB connect');
    }
    $conn->set_charset('utf8mb4');

    $email = trim((string) ($_POST['email'] ?? ''));
    $password = (string) ($_POST['password'] ?? '');
    $fcmToken = trim((string) ($_POST['fcm_token'] ?? ''));

    if ($email === '' || $password === '') {
        $response['message'] = 'Укажите e-mail и пароль';
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    if (!crg_autoriz1_bootstrap_jwt()) {
        $response['message'] = 'Ошибка сервера (JWT)';
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    $hasFcm = false;
    $colRes = $conn->query("SHOW COLUMNS FROM users LIKE 'fcm_token'");
    if ($colRes !== false && $colRes->num_rows > 0) {
        $hasFcm = true;
    }

    $sql = $hasFcm
        ? 'SELECT idusers, rollNum, statNum, password, flag, fcm_token FROM users WHERE email = ? LIMIT 1'
        : 'SELECT idusers, rollNum, statNum, password, flag FROM users WHERE email = ? LIMIT 1';

    $stmt = $conn->prepare($sql);
    if ($stmt === false) {
        throw new RuntimeException('prepare failed');
    }

    $stmt->bind_param('s', $email);
    $stmt->execute();
    $stmt->store_result();

    if ($stmt->num_rows === 0) {
        $response['message'] = 'Пользователь не найден';
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    $idusers = 0;
    $rollNum = 0;
    $statNum = 0;
    $hashedPassword = '';
    $flag = 0;
    $currentFcm = '';

    if ($hasFcm) {
        $stmt->bind_result($idusers, $rollNum, $statNum, $hashedPassword, $flag, $currentFcm);
    } else {
        $stmt->bind_result($idusers, $rollNum, $statNum, $hashedPassword, $flag);
    }
    $stmt->fetch();
    $stmt->close();

    if (!password_verify($password, $hashedPassword)) {
        $response['message'] = 'Неверный пароль';
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($hasFcm && $fcmToken !== '') {
        require_once __DIR__ . '/include/fcm_push.php';
        $tokenCheck = crg_fcm_validate_device_token($fcmToken);
        if ($tokenCheck === true) {
            $upd = $conn->prepare('UPDATE users SET fcm_token = ? WHERE idusers = ?');
            if ($upd !== false) {
                $upd->bind_param('si', $fcmToken, $idusers);
                $upd->execute();
                $upd->close();
            }
        }
    }

    $timeIssuedAt = time();
    $jwt = crg_jwt_encode([
        'iss' => 'http://example.org',
        'aud' => 'http://example.com',
        'iat' => $timeIssuedAt,
        'exp' => $timeIssuedAt + 3600 * 24 * 30,
        'data' => [
            'idusers' => $idusers,
            'email' => $email,
        ],
    ]);

    if ($jwt === null) {
        $response['message'] = 'Ошибка сервера (JWT)';
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    $response['success'] = true;
    $response['rollNum'] = (int) $rollNum;
    $response['statNum'] = (int) $statNum;
    $response['token'] = $jwt;
} catch (Throwable $e) {
    $response['message'] = 'Ошибка сервера';
}

echo json_encode($response, JSON_UNESCAPED_UNICODE);
