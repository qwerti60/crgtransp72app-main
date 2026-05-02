<?php
include 'databd.php';
$idusers = isset($_GET['idusers']) ? $_GET['idusers'] : '';

// Создаем подключение
$conn = new mysqli($host, $username, $password, $dbname);

// Проверяем подключение
if ($conn->connect_error) {
    die("Ошибка подключения: " . $conn->connect_error);
}

// Устанавливаем корректную кодировку
$conn->set_charset("utf8");

// Обобщенный SQL-запрос с добавлением имени таблицы
$sql = "
SELECT 
    'orders' as table_name,   -- Добавляем имя таблицы
    o.id, 
    o.maxgruz, 
    o.city, 
    o.startdate, 
    o.enddate, 
    o.city1, 
    o.vidk, 
    o.zagr, 
    o.typepr, 
    o.cena, 
    o.about, 
    o.enddatez, 
    o.img1, 
    o.img2, 
    o.img3, 
    o.img4, 
    o.created_at,
    (SELECT COUNT(*) FROM offer_data od WHERE od.iduser=o.id AND od.status=0) AS offer
FROM 
    orders o
WHERE 
    o.iduser = ?
UNION ALL
SELECT 
    'orderst' as table_name,  -- Добавляем имя таблицы
    ot.id, 
    '',  -- Поле maxgruz отсутствует в таблице orderst
    ot.city, 
    ot.startdate, 
    ot.enddate, 
    '',  -- Поле city1 отсутствует в таблице orderst
    '',  -- Поле vidk отсутствует в таблице orderst
    '',  -- Поле zagr отсутствует в таблице orderst
    '',  -- Поле typepr отсутствует в таблице orderst
    ot.cena, 
    ot.about, 
    ot.enddatez, 
    ot.img1, 
    ot.img2, 
    ot.img3, 
    ot.img4, 
    ot.created_at,
    (SELECT COUNT(*) FROM offer_data od WHERE od.iduser=ot.id AND od.status=0) AS offer
FROM 
    orderst ot
WHERE 
    ot.iduser = ?
UNION ALL
SELECT 
    'ordersg' as table_name,  -- Добавляем имя таблицы
    og.id, 
    '',  -- Поле maxgruz отсутствует в таблице ordersg
    og.city, 
    og.startdate, 
    og.enddate, 
    '',  -- Поле city1 отсутствует в таблице ordersg
    '',  -- Поле vidk отсутствует в таблице ordersg
    '',  -- Поле zagr отсутствует в таблице ordersg
    '',  -- Поле typepr отсутствует в таблице ordersg
    og.cena, 
    og.about, 
    og.enddatez, 
    og.img1, 
    og.img2, 
    og.img3, 
    og.img4, 
    og.created_at,
    (SELECT COUNT(*) FROM offer_data od WHERE od.iduser=og.id AND od.status=0) AS offer
FROM 
    ordersg og
WHERE 
    og.iduser = ?
ORDER BY 
    created_at DESC;";

$stmt = $conn->prepare($sql); // Подготовливаем запрос

if (!$stmt) {
    die("Ошибка подготовки запроса: " . $conn->error);
}

$stmt->bind_param("sss", $idusers, $idusers, $idusers); // Передаваем один раз переменную трижды
$stmt->execute();                     // Выполняем подготовленный запрос
$result = $stmt->get_result();        // Получаем результат выборки

$fetchData = [];

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        // Преобразуем binary-данные изображений в Base64
        $row['img1'] = $row['img1'] !== null ? base64_encode($row['img1']) : null;
        $row['img2'] = $row['img2'] !== null ? base64_encode($row['img2']) : null;
        $row['img3'] = $row['img3'] !== null ? base64_encode($row['img3']) : null;
        $row['img4'] = $row['img4'] !== null ? base64_encode($row['img4']) : null;
        
        $fetchData[] = $row;
    }
    
    header('Content-Type: application/json'); // Устанавливаем заголовок для вывода JSON
    echo json_encode($fetchData);
} else {
    echo json_encode([]); // Если нет данных, возвращаем пустой массив
}

// Закрываем соединение
$stmt->close();
$conn->close();
?>