<?php
// Подключаем файл настроек подключения к базе данных
require_once 'databd.php';

// Получаем GET-параметры и проверяем их валидность
/* 1. Получаем и проверяем userId */
$userId = filter_input(INPUT_GET, 'userId', FILTER_VALIDATE_INT);

// Проверка наличия обязательных параметров
if (!$userId) {
    http_response_code(400); // Код состояния HTTP 400 — некорректный запрос
    echo json_encode(['error' => 'Параметры nameImg и bd обязательны']);
    exit;
}

// Устанавливаем соединение с базой данных
$conn = new mysqli($host, $username, $password, $dbname);
$conn->set_charset("utf8");

// Проверка успешного подключения
if ($conn->connect_error) {
    die("Ошибка подключения к базе данных: " . $conn->connect_error);
}

// Формирование SQL-запроса с подготовленными выражениями

// Запрашиваем отзывы и информацию о пользователе
$sql = "
    SELECT 
        r.target_user_id,      -- кому оставили отзыв
        r.user_id,             -- кто оставил отзыв
        r.rating,
        r.comment,
        r.datastamp,
        u.idusers,
        u.fotouser,
        u.rollNum,
        u.statNum,
        u.firstName,
        u.lastName,
        u.middleName,
        u.city,
        u.phone,
        u.email,
        u.namefirm,
        u.innStr,
        u.ogrnStr,
        u.kppStr
    FROM reviewsisp r
    INNER JOIN users u ON u.idusers = r.target_user_id
    WHERE r.user_id = ?
";


// Подготовленный SQL-запрос с привязанными параметрами
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $userId);
$stmt->execute();

// Выполнение запроса и получение результата
$result = $stmt->get_result();

// Массив для хранения итоговых данных
$data = [];

// Обрабатываем полученные строки
while ($row = $result->fetch_assoc()) {
    // Преобразование фотографии пользователя в Base64, если она присутствует
    if (!empty($row['fotouser'])) {
        $row['fotouser'] = base64_encode($row['fotouser']);
    }
    $data[] = $row;
}

// Отправляем заголовок типа содержимого (JSON)
header('Content-Type: application/json');

// Возвращаем данные в формате JSON
echo json_encode($data);

// Закрываем соединение с базой данных
$conn->close();
?>