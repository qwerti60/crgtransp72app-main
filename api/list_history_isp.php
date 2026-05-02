<?php
// Подключаем файл настроек подключения к базе данных
require_once 'databd.php';

// Получаем GET-параметры и проверяем их валидность
$nameImg= filter_input(INPUT_GET, 'nameImg', FILTER_VALIDATE_INT);
$bd = filter_input(INPUT_GET, 'bd', FILTER_VALIDATE_INT);

// Проверка наличия обязательного параметра
if (!$nameImg) {
    http_response_code(400); // Код состояния HTTP 400 — некорректный запрос
    echo json_encode(['error' => 'Параметр nameImg обязателен']);
    exit;
}

// Устанавливаем соединение с базой данных
$conn = new mysqli($host, $username, $password, $dbname);
$conn->set_charset("utf8");

// Проверка успешного подключения
if ($conn->connect_error) {
    die("Ошибка подключения к базе данных: " . $conn->connect_error);
}
// Новый SQL-запрос с дополнительным условием для поля success
$sql = "
    SELECT od.iduser AS id, u.idusers AS iduser, u.idusers AS review_user_id, od.cena, od.about, od.iduserp,
           u.fotouser, u.firstName, u.lastName, u.middleName, u.city, u.phone,
           u.namefirm, u.innStr, u.ogrnStr, u.kppStr,
           og.start_time, og.end_time, og.cancel_time, og.status AS order_status,
           IFNULL(avg_ratings.avg_rating, 0) AS avg_rating,
           COALESCE(rev_count.reviewsCount, 0) AS reviewsCount,
           CASE WHEN MAX(l.usersid IS NOT NULL) THEN 'true' ELSE 'false' END AS success
    FROM offer_data od
    INNER JOIN ordersglobal og ON od.iduserp = og.user_id AND od.iduser = og.order_id
    LEFT JOIN add_ob_gp gp ON od.bd = 1 AND od.iduser = gp.id
    LEFT JOIN add_ob_vidt vidt ON od.bd = 2 AND od.iduser = vidt.id
    LEFT JOIN add_ob_gr gr ON od.bd = 3 AND od.iduser = gr.id
    INNER JOIN users u ON u.idusers = COALESCE(gp.iduser, vidt.iduser, gr.iduser)
    LEFT JOIN (
        SELECT user_id, AVG(rating) AS avg_rating
        FROM reviewsisp
        GROUP BY user_id
    ) avg_ratings ON u.idusers = avg_ratings.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS reviewsCount
        FROM reviewsisp
        GROUP BY user_id
    ) rev_count ON u.idusers = rev_count.user_id
    LEFT JOIN likes1 l ON l.idusers = u.idusers AND l.id = od.iduser AND l.usersid = ?
    WHERE od.status = 1
      AND (og.status IS NULL OR og.status NOT IN ('выполняется'))
      AND og.user_id = ?
      AND u.idusers != ?
    GROUP BY od.iduser, u.idusers, od.iduserp
    ORDER BY COALESCE(og.end_time, og.cancel_time, og.start_time) DESC
";


// Подготовленный SQL-запрос с двумя привязанными параметрами
$stmt = $conn->prepare($sql);
$stmt->bind_param("iii", $nameImg, $nameImg, $nameImg); // Передаем id текущего исполнителя
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