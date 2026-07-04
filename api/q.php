<?php
/** @deprecated Используйте get_ads2_new.php */
include 'databd.php';
$nameImg = isset($_GET['nameImg']) ? $_GET['nameImg'] : '';
$city = isset($_GET['city']) ? $_GET['city'] : '';
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

// Определяем таблицу на основе значения поля name в соответствующих таблицах
$table = null;

// Сначала проверяем наличие записи в таблице vidt
$sqlCheckVidt = "SELECT * FROM vidt WHERE name = '$nameImg'";
$resultVidt = $conn->query($sqlCheckVidt);
if ($resultVidt && $resultVidt->num_rows > 0) {
    $table = 'add_ob_gp'; // Если запись найдена в vidt, используем add_ob_gp
} else {
    // Затем проверяем таблицу vidg
    $sqlCheckVidg = "SELECT * FROM vidg WHERE name = '$nameImg'";
    $resultVidg = $conn->query($sqlCheckVidg);
    if ($resultVidg && $resultVidg->num_rows > 0) {
        $table = 'add_ob_vidt'; // Если запись найдена в vidg, используем add_ob_vidt
    } else {
        // Наконец, проверяем таблицу gruzchik
        $sqlCheckGruzchik = "SELECT * FROM gruzchik WHERE name = '$nameImg'";
        $resultGruzchik = $conn->query($sqlCheckGruzchik);
        if ($resultGruzchik && $resultGruzchik->num_rows > 0) {
            $table = 'add_ob_gr'; // Если запись найдена в gruzchik, используем add_ob_vidtg
        }
    }
}

if (!$table) {
    die("Запись не найдена ни в одной из таблиц.");
}

// Теперь определяем переменную $bd на основе выбранной таблицы
switch ($table) {
    case 'add_ob_gp':
        $bd = 1;
        break;
    case 'add_ob_vidt':
        $bd = 2;
        break;
    case 'add_ob_gr':
        $bd = 3;
        break;
    default:
        die("Неправильная база данных");
}

// Формируем основной SQL-запрос
$sql = "
    SELECT a.*,
           {$bd} AS bd,
           u.idusers AS idusers,
           u.fotouser,
           u.firstName,
           u.lastName,
           u.middleName,
           u.city AS userCity,
           u.phone,
           u.email,
           COUNT(r.id) AS reviewsCount, -- Подсчет количества отзывов
           COALESCE(AVG(r.rating), 0) AS avg_rating, -- Среднее значение рейтинга
           CASE
               WHEN EXISTS(
                   SELECT *
                   FROM likes
                   WHERE idusers = u.idusers  
               ) THEN 'true'
               ELSE 'false'
           END AS success
    FROM {$table} AS a
    INNER JOIN users AS u ON a.iduser = u.idusers
    LEFT JOIN reviews AS r ON u.idusers = r.target_user_id -- Отзывы, соответствующие пользователю
    WHERE a.iduser IS NOT NULL 
      AND a.iduser != '$useId' /* Исключаем записи текущего пользователя */
      AND (a.flag IS NULL OR a.flag = 1)
      AND NOT EXISTS (
          SELECT 1
          FROM ordersglobal og
          INNER JOIN offer_dataf odf ON odf.id = og.idoffer AND odf.bd = {$bd}
          WHERE CAST(og.order_id AS CHAR) = CAST(a.id AS CHAR)
            AND og.user_idok = '$useId'
            AND og.status = 'выполняется'
      )
      AND a.city = '$city' /* Фильтруем по городу */
    GROUP BY a.id, u.idusers              -- Группируем по объявлениям и пользователям
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