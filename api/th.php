<?php
include 'databd.php';
$nameImg = isset($_GET['nameImg']) ? $_GET['nameImg'] : '';
$bd = isset($_GET['bd']) ? $_GET['bd'] : '';
$usersid = isset($_GET['usersid']) ? $_GET['usersid'] : '';

// Создаем подключение
$conn = new mysqli($host, $username, $password, $dbname);

// Проверяем подключение
if ($conn->connect_error) {
    die("Ошибка подключения: " . $conn->connect_error);
}

// Устанавливаем корректную кодировку
$conn->set_charset("utf8");

if($bd == 1) {
    // Изменяем SQL для включения данных из таблицы пользователей
$sql = "SELECT 
    a.*, 
    u.idusers AS idusers, 
    u.fotouser, 
    u.firstName, 
    u.lastName, 
    u.middleName, 
    u.city AS userCity, 
    u.phone, 
    u.email,
    u.namefirm, 
    u.innStr, 
    u.ogrnStr, 
    u.kppStr,
       CASE 
           WHEN EXISTS (
               SELECT 1 
               FROM likes1 
               WHERE idusers = u.idusers AND 
                     id = a.id AND 
                     bd = 1 AND 
                     usersid = $usersid
           ) THEN 'true' 
           ELSE 'false'
       END AS success

FROM add_ob_gp AS a 
LEFT JOIN users AS u 
    ON a.iduser = u.idusers 
WHERE a.flag = 1 
AND a.iduser != $usersid"; // Добавлено исключение для iduser
}
if($bd == 2) {
    // Изменяем SQL для включения данных из таблицы пользователей
    $sql = "SELECT a.*, u.idusers AS idusers, u.fotouser, u.firstName, u.lastName, 
            u.middleName, u.city AS userCity, u.phone, u.email,
    u.namefirm, 
    u.innStr, 
    u.ogrnStr, 
    u.kppStr,
                   CASE 
           WHEN EXISTS (
               SELECT 2 
               FROM likes1 
               WHERE idusers = u.idusers AND 
                     id = a.id AND 
                     bd = 2 AND 
                     usersid = $usersid
           ) THEN 'true' 
           ELSE 'false'
       END AS success
            FROM add_ob_vidt AS a 
            LEFT JOIN users AS u ON a.iduser = u.idusers WHERE a.flag = 1 AND a.iduser != $usersid";
}
if($bd == 3) {
    $sql = "SELECT a.*, u.idusers AS idusers, u.fotouser, u.firstName, u.lastName, 
            u.middleName, u.city AS userCity, u.phone, u.email,
    u.namefirm, 
    u.innStr, 
    u.ogrnStr, 
    u.kppStr,
                   CASE 
           WHEN EXISTS (
               SELECT 3 
               FROM likes1 
               WHERE idusers = u.idusers AND 
               id = a.id AND 
                     bd = 3 AND 
                     usersid = $usersid
           ) THEN 'true' 
           ELSE 'false'
       END AS success
            FROM add_ob_gr AS a 
            LEFT JOIN users AS u ON a.iduser = u.idusers WHERE a.flag = 1 AND a.iduser != $usersid";
}

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
