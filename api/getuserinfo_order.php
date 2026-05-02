<?php
header('Content-Type: application/json; charset=UTF-8');
ini_set('default_charset', 'UTF-8');
mb_internal_encoding('UTF-8');

/* --- подключение к БД --- */
$host     = 'localhost';
$dbname   = 'u2395188_apps';
$username = 'u2395188_apps72';
$password = 'kR3iV2aA6gjU8nC9';

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8",
        $username,
        $password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    /* --- в запросе обязательно передаём FCM-токен --- */
    if (empty($_GET['token'])) {
        echo json_encode(['error' => 'FCM Token is required']);
        exit;
    }
    $token = $_GET['token'];

    /* --- один запрос: пользователь + его заказ --- */
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
            og.user_id
        FROM users u
        LEFT JOIN ordersglobal og ON og.user_idok = u.idusers
        WHERE u.fcm_token = ?
        ORDER BY og.order_id DESC       -- если заказов несколько, берём последний
        LIMIT 1
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode(['error' => 'User with this FCM token not found']);
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