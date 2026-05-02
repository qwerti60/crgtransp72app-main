<?php
// Подключение к базе данных
$servername = "localhost";
$username = "u2395188_apps72";
$password = "kR3iV2aA6gjU8nC9";
$dbname = "u2395188_apps"; // замените на имя вашей базы данных

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname;charset=utf8", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Получение POST-параметров от клиента
    $iduserp = $_POST['iduserp'];
    $userId = $_POST['userId'];
    $bd = $_POST['bd'];

    // Проверка наличия записи
    $stmt = $conn->prepare("SELECT * FROM offer_dataz WHERE iduserp=:iduserp AND iduser=:userId");
    $stmt->bindParam(':iduserp', $iduserp);
    $stmt->bindParam(':userId', $userId);
    //$stmt->bindParam(':bd', $bd);
    $stmt->execute();

    if ($row = $stmt->fetch()) {
        echo json_encode([
            'cena' => $row['cena'],
            'about' => $row['about']
        ]);
    } else {
        http_response_code(404); // Запись не найдена
        echo json_encode(['message' => 'Запись не найдена']);
    }
} catch(PDOException $e) {
    http_response_code(500); // Ошибка сервера
    echo json_encode(['message' => 'Ошибка подключения к базе данных']);
}
?>