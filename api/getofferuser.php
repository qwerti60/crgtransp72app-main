<?php
require __DIR__ . '/load_databd.php';
$useId = isset($_GET['useId']) ? $_GET['useId'] : '';

// Создаем подключение
$conn = new mysqli($host, $username, $password, $dbname);

// Проверяем подключение
if ($conn->connect_error) {
    die("Ошибка подключения: " . $conn->connect_error);
}

// Устанавливаем корректную кодировку
$conn->set_charset("utf8");

// Определяем текущую дату
$currentDate = date('Y-m-d');

// Формируем общий SQL-запрос для объединения трех таблиц
$sql = "
 -- Объединяем заказы из всех трёх таблиц с учётом особенностей каждой таблицы
SELECT
    a.id AS id,
    a.iduser AS iduser,
    '' AS vidt, -- Нет соответствующего поля в таблице orders
    '' AS maxgruz, -- Только в таблице orders присутствует
    a.city AS city,
    a.startdate AS startdate,
    a.enddate AS enddate,
    a.cena AS cena,
    a.about AS about,
    a.enddatez AS enddatez,
    a.img1 AS img1,
    a.img2 AS img2,
    a.img3 AS img3,
    a.img4 AS img4,
    a.created_at AS created_at
FROM
    orders a
WHERE
    a.iduser IS NOT NULL
AND
    a.enddatez >= NOW()

UNION ALL

SELECT
    b.id AS id,
    b.iduser AS iduser,
    b.vidt AS vidt,
    '' AS maxgruz, -- Поле отсутствует в таблице orderst
    b.city AS city,
    b.startdate AS startdate,
    b.enddate AS enddate,
    b.cena AS cena,
    b.about AS about,
    b.enddatez AS enddatez,
    b.img1 AS img1,
    b.img2 AS img2,
    b.img3 AS img3,
    b.img4 AS img4,
    b.created_at AS created_at
FROM
    orderst b
WHERE
    b.iduser IS NOT NULL
AND
    b.enddatez >= NOW()

UNION ALL

SELECT
    c.id AS id,
    c.iduser AS iduser,
    '' AS vidt, -- Нет соответствующего поля в таблице ordersg
    '' AS maxgruz, -- Нет такого поля в таблице ordersg
    c.city AS city,
    c.startdate AS startdate,
    c.enddate AS enddate,
    c.cena AS cena,
    c.about AS about,
    c.enddatez AS enddatez,
    c.img1 AS img1,
    c.img2 AS img2,
    c.img3 AS img3,
    c.img4 AS img4,
    c.created_at AS created_at
FROM
    ordersg c
WHERE
    c.iduser IS NOT NULL
AND
    c.enddatez >= NOW()

ORDER BY
    id DESC;
";

$result = $conn->query($sql);

$fetchData = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // Конвертируем img и fotouser BLOBs в Base64 для включения в JSON
        $imgsToEncode = ['img1', 'img2', 'img3', 'img4', 'fotouser'];
        foreach ($imgsToEncode as $imgField) {
            if (isset($row[$imgField])) {
                $row[$imgField] = base64_encode($row[$imgField]);
            }
        }

        $fetchData[] = $row;
    }

    // Устанавливаем заголовок Content-Type для отправки JSON
    header('Content-Type: application/json');
    echo json_encode($fetchData);
} else {
    echo json_encode([]);
}

// Закрываем подключение
$conn->close();