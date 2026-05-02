<?php
// Получаем входные данные POST-запроса
// Получаем входные данные POST-запроса
$idUser = $_POST['idusers'] ?? null;
$bd = $_POST['bd'] ?? null;
$idUserP = $_POST['iduserp'] ?? null;

if (!$idUser || !$bd || !$idUserP) {
    echo json_encode(['isp' => 'Error: Missing parameters']);
    exit();
}

// Подключаемся к БД MySQL (необходимо заменить значения на реальные)
$servername = "localhost";
$username = "u2395188_apps72";
$password = "kR3iV2aA6gjU8nC9";
$dbname = "u2395188_apps";

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Выполняем SQL-запрос
    $stmt = $conn->prepare("SELECT isp FROM offer_data WHERE iduserp=:idUserP AND iduser=:idUser AND bd=:bd AND status = 0 LIMIT 1");
    $stmt->bindParam(':idUser', $idUser);
    $stmt->bindParam(':bd', $bd);
    $stmt->bindParam(':idUserP', $idUserP);
    $stmt->execute();

    // Проверяем наличие результата
    $result = $stmt->fetchColumn(); // получаем первое значение первой строки

    if ($result === false) {
        echo json_encode(['isp' => 'Not found']); // запись не найдена
    } else {
        echo json_encode(['isp' => $result]); // возвращаем найденное значение
    }
} catch (PDOException $e) {
    echo json_encode(['isp' => 'Database error: '.$e->getMessage()]);
}

$conn = null; // закрываем соединение
?>