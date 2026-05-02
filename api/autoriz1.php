<?php
header("Content-Type: application/json");
include 'databd.php';
require_once '/var/www/u2395188/data/vendor/autoload.php';

use \Firebase\JWT\JWT;

// Создаем новое соединение с базой данных
$conn = new mysqli($host, $username, $password, $dbname);

// Получаем входящие данные
$email = $_POST['email'];
$password = $_POST['password'];
$fcm_token = isset($_POST['fcm_token']) ? $_POST['fcm_token'] : ''; // Новый параметр

$response = array();
$response['success'] = false; // По умолчанию ставим ложь

if ($stmt = $conn->prepare('SELECT idusers, rollNum, statNum, password, flag, fcm_token FROM users WHERE email = ?')) {
    $stmt->bind_param('s', $email);
    $stmt->execute();
    $stmt->store_result();

    if ($stmt->num_rows > 0) {
        $stmt->bind_result($idusers, $rollNum, $statNum, $hashed_password, $flag, $current_fcm_token);
        $stmt->fetch();

        // Проверяем пароль
        if (password_verify($password, $hashed_password)) {
            // Проверяем флаги блокировки и одобрения аккаунта
            if (($rollNum == 2 || $rollNum == 3) && $flag == 0) {
                $response['message'] = "Данные пользователя еще на проверке";
            } else {
                // Проверяем токен FCM
                if (!empty($fcm_token) && ($fcm_token !== $current_fcm_token)) {
                    // Токен не совпадает или пуст, обновляем
                    $update_stmt = $conn->prepare('UPDATE users SET fcm_token = ? WHERE idusers = ?');
                    $update_stmt->bind_param('si', $fcm_token, $idusers);
                    $update_stmt->execute();
                }
                
                // Генерируем JWT-токен
                $timeIssuedAt = time();
                $token = array(
                    "iss" => "http://example.org",
                    "aud" => "http://example.com",
                    "iat" => $timeIssuedAt,
                    "exp" => $timeIssuedAt + 3600 * 24 * 30, // Срок действия токена (месяц)
                    "data" => array(
                        "idusers" => $idusers,
                        "email" => $email
                    )
                );
                $secret_key = "789456123"; // ВАШ секретный ключ
                $jwt = JWT::encode($token, $secret_key, 'HS256');

                // Ответ успешен
                $response['success'] = true;
                $response['rollNum'] = $rollNum;
                $response['statNum'] = $statNum;
                $response['token'] = $jwt;
            }
        } else {
            $response['message'] = "Неверный пароль";
        }
    } else {
        $response['message'] = "Пользователь не найден";
    }

    $stmt->close();
} else {
    $response['message'] = "Ошибка сервера";
}

echo json_encode($response);
$conn->close();
?>