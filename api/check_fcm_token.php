<?php
header("Content-Type: application/json");
include 'databd.php';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $fcm_token = $_POST['fcm_token'];

    $sql = "SELECT COUNT(*) AS count FROM users WHERE fcm_token = :fcm_token";
    $stmt = $pdo->prepare($sql);
    $stmt->bindParam(':fcm_token', $fcm_token);
    $stmt->execute();

    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $count = intval($row['count']);

    $response = array();
    if ($count > 0) {
        $response['exists'] = true;
    } else {
        $response['exists'] = false;
    }

    echo json_encode($response);
} catch (PDOException $e) {
    die("Ошибка базы данных: " . $e->getMessage());
}
?>