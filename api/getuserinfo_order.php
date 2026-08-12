<?php
header('Content-Type: application/json; charset=UTF-8');
ini_set('default_charset', 'UTF-8');
mb_internal_encoding('UTF-8');

/* --- подключение к БД --- */
require __DIR__ . '/load_databd.php';

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    if (empty($_GET['token'])) {
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

    $sql = "
        SELECT 
            u.idusers,
            u.fotouser,
            u.firstName,
            u.lastName,
            u.middleName,
            u.city,
            u.phone,
            u.email,
            og.order_id,
            og.user_id,
            COALESCE((
                SELECT ROUND(AVG(r.rating), 1)
                FROM reviewsisp r
                WHERE r.user_id = u.idusers
            ), 0) AS avg_rating,
            (
                SELECT COUNT(*)
                FROM reviewsisp r
                WHERE r.user_id = u.idusers
            ) AS reviewsCount,
            (
                SELECT COUNT(*)
                FROM reviewsisp r
                WHERE r.user_id = u.idusers
            ) AS review_count
        FROM users u
        LEFT JOIN ordersglobal og ON og.user_idok = u.idusers
        WHERE u.idusers = ?
        ORDER BY og.order_id DESC
        LIMIT 1
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode(['error' => 'User not found']);
        exit;
    }

    /* --- конвертируем фото --- */
    if (!empty($user['fotouser'])) {
        $user['fotouser'] = base64_encode($user['fotouser']);
    }

    echo json_encode($user);

} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>