<?php

require __DIR__ . '/load_databd.php';
$servername = $host;

$iduser = $_GET['iduser'] ?? '';
$truck = $_GET['truck'] ?? '';
$bd = $_GET['bd'] ?? '';

if (!$iduser || !$truck || !$bd) {
    echo json_encode(['exists' => false], JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname;charset=utf8mb4", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $conn->prepare("SELECT COUNT(*) FROM offer_dataz WHERE iduserp=:iduserp AND iduser=:iduser AND bd=:bd");
    $stmt->bindParam(':iduserp', $iduser);
    $stmt->bindParam(':iduser', $truck); // Предполагается, что $truck является ID пользователя-перевозчика
    $stmt->bindParam(':bd', $bd);
    $stmt->execute();

    $count = $stmt->fetchColumn();
    
    echo json_encode(['exists' => ($count > 0)], JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    echo json_encode(['exists' => false], JSON_UNESCAPED_UNICODE);
}

?>