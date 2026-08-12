<?php
// Заголовки для обеспечения корректного взаимодействия с Flutter (или другими клиентами).
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Подключаемся к базе данных
require __DIR__ . '/load_databd.php';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    // Устанавливаем режим ошибки PDO на исключение
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo "Ошибка подключения к базе данных: " . $e->getMessage();
    exit;
}

// Получаем idusers из запроса
$idusers = isset($_GET['idusers']) ? $_GET['idusers'] : '';

// SQL запрос к базе данных
$sql = "SELECT idusers, fotouser, firstName, lastName, middleName, city, phone, email, namefirm, innStr, ogrnStr, kppStr FROM users WHERE idusers = :idusers";

// Подготовка запроса
$stmt = $pdo->prepare($sql);
$stmt->bindParam(':idusers', $idusers, PDO::PARAM_INT);

// Выполняем запрос и проверяем наличие записи
if($stmt->execute() && $stmt->rowCount() > 0) {
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    // Получаем данные пользователя
    $user = [
        'idusers' => $row['idusers'],
        'firstName' => $row['firstName'],
        'lastName' => $row['lastName'],
        'middleName' => $row['middleName'],
        'city' => $row['city'],
        'phone' => $row['phone'],
        'email' => $row['email'],
        // Превращаем BLOB в base64 для передачи через JSON
        'fotouser' => base64_encode($row['fotouser'])
    ];

    // Отправляем данные пользователя в формате JSON
    echo json_encode($user);
} else {
    // Возвращаем ошибку, если пользователь не найден
    echo json_encode(['message' => 'Пользователь не найден.']);
}
?>
