<?php
header("Content-Type: application/json");


// Параметры подключения к базе данных
require __DIR__ . '/load_databd.php';

try {
    // Подключаемся к базе данных
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

   // Получаем данные из POST
$iduserp = $_POST['iduserp'];

// Проверяем, получил ли мы iduserp
if (!$iduserp) {
    echo json_encode(['error' => 'Parameter iduserp is missing']);
    exit;
}


    // Выполняем запрос на выборку fcm_token
    $stmt = $pdo->prepare("SELECT fcm_token FROM users WHERE idusers = :iduserp LIMIT 1");
    $stmt->bindParam(':iduserp', $iduserp);
    $stmt->execute();

    // Получаем результат
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result && !empty($result['fcm_token'])) {
        // Если нашли токен, возвращаем его
        echo json_encode(['fcm_token' => $result['fcm_token'], 'success' => true]);
    } else {
        // Если токен не найден
        echo json_encode(['error' => 'User not found or no FCM token associated']);
    }
} catch (PDOException $e) {
    // Обрабатываем ошибки базы данных
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>