<?php
header("Content-Type: application/json");

// Параметры подключения к базе данных
require __DIR__ . '/load_databd.php';


try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    if (!isset($_POST['fcm_token'])) {
        echo json_encode(['success' => false, 'message' => 'FCM token is missing']);
        exit;
    }

    $fcm_token = $_POST['fcm_token'];

    // Подготовленная инструкция для обновления поля fcm_token
    $stmt = $pdo->prepare("UPDATE users SET fcm_token = NULL WHERE fcm_token = :fcm_token");
    $stmt->bindValue(':fcm_token', $fcm_token);
    $rowsAffected = $stmt->execute();

    if ($rowsAffected >= 1) {
        echo json_encode(['success' => true, 'message' => 'FCM token cleared successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'No matching record found']);
    }
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}

?>