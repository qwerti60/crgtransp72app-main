<?php
header("Content-Type: application/json");

ini_set('default_charset', 'UTF-8');
mb_internal_encoding("UTF-8");

require __DIR__ . '/load_databd.php';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    if (!isset($_GET['token']) || $_GET['token'] === '') {
        echo json_encode(['error' => 'Token is required']);
        exit;
    }

    require_once __DIR__ . '/token_auth.php';

    $token = $_GET['token'];
    $userId = resolveUserIdFromToken($pdo, $token);

    if ($userId === null) {
        echo json_encode(['error' => 'User not found']);
        exit;
    }

    $stmt = $pdo->prepare("
        SELECT u.idusers, u.fotouser, u.firstName, u.lastName, u.middleName, u.city, u.phone, u.email,
               u.statNum, u.namefirm, u.innStr, u.kppStr, u.ogrnStr,
               COALESCE(u.is_verified, 0) AS is_verified,
               COALESCE((
                   SELECT ROUND(AVG(r.rating), 1)
                   FROM reviews r
                   WHERE r.target_user_id = u.idusers
               ), 0) AS avg_rating,
               (
                   SELECT COUNT(*)
                   FROM reviews r
                   WHERE r.target_user_id = u.idusers
               ) AS reviewsCount,
               (
                   SELECT COUNT(*)
                   FROM reviews r
                   WHERE r.target_user_id = u.idusers
               ) AS review_count
        FROM users u
        WHERE u.idusers = ?
    ");
    $stmt->execute([$userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        if ($user['fotouser']) {
            // Преобразуем фотографию пользователя в Base64
            $user['fotouser'] = base64_encode($user['fotouser']);
        }
        echo json_encode($user); // Возвращаем данные пользователя
    } else {
        echo json_encode(['error' => 'User not found']);
    }
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}

?>