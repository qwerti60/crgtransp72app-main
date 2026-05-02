<?php
include 'databd.php';
$nameImg = isset($_GET['nameImg']) ? $_GET['nameImg'] : '';
$bd = isset($_GET['bd']) ? $_GET['bd'] : '';
$useId = isset($_GET['useId']) ? $_GET['useId'] : '';

// Создаем подключение
$conn = new mysqli($host, $username, $password, $dbname);

// Проверяем подключение
if ($conn->connect_error) {
    die("Ошибка подключения: " . $conn->connect_error);
}

// Устанавливаем корректную кодировку
$conn->set_charset("utf8");

$sql = "";

// Определяем текущую дату
$currentDate = date('Y-m-d');

// Проверяем, какая таблица используется
switch ($bd) {
    case 1:
        $table = 'orders';
        break;
    case 2:
        $table = 'orderst';
        break;
    case 3:
        $table = 'ordersg';
        break;
    default:
        die("Неверная база данных");
}

// Формируем основной SQL-запрос
$sql = "
    SELECT a.*,
           u.idusers AS idusers,
           u.fotouser,
           u.firstName,
           u.lastName,
           u.middleName,
           u.city AS userCity,
           u.phone,
           u.email,
           CASE
               WHEN EXISTS(
                   SELECT *
                   FROM likes
                   WHERE idusers = u.idusers AND
                         id = a.id AND
                         bd = {$bd}
               ) THEN 'true'
               ELSE 'false'
           END AS success
    FROM {$table} AS a
    INNER JOIN users AS u ON a.iduser = u.idusers
    INNER JOIN offer_dataf AS od ON a.id = od.iduser
    WHERE od.bd = {$bd} AND od.iduserp = '{$useId}'
          AND a.enddatez >= '$currentDate' /* Исключаем записи с датой раньше текущей */
    ORDER BY a.id DESC
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
?>