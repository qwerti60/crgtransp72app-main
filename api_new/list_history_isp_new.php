<?php
require_once __DIR__ . '/../api/databd.php';

$nameImg = filter_input(INPUT_GET, 'nameImg', FILTER_VALIDATE_INT);

if (!$nameImg) {
    http_response_code(400);
    echo json_encode(['error' => 'Параметр nameImg обязателен'], JSON_UNESCAPED_UNICODE);
    exit;
}

$conn = new mysqli($host, $username, $password, $dbname);
$conn->set_charset('utf8mb4');

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка подключения к базе данных'], JSON_UNESCAPED_UNICODE);
    exit;
}

$sql = "
    SELECT od.iduser AS id,
           od.bd AS bd,
           u.idusers AS iduser,
           u.idusers AS review_user_id,
           od.cena,
           od.about,
           od.iduserp,
           u.fotouser,
           u.firstName,
           u.lastName,
           u.middleName,
           u.city,
           u.phone,
           u.namefirm,
           u.innStr,
           u.ogrnStr,
           u.kppStr,
           og.start_time,
           og.end_time,
           og.cancel_time,
           og.status AS order_status,
           IFNULL(avg_ratings.avg_rating, 0) AS avg_rating,
           COALESCE(rev_count.reviewsCount, 0) AS reviewsCount,
           CASE WHEN MAX(l.usersid IS NOT NULL) THEN 'true' ELSE 'false' END AS success
    FROM offer_data od
    INNER JOIN ordersglobal og
        ON od.iduserp = og.user_id
        AND CAST(od.iduser AS CHAR) = CAST(og.order_id AS CHAR)
    LEFT JOIN orders o ON od.bd = 1 AND o.id = od.iduser
    LEFT JOIN orderst ot ON od.bd = 2 AND ot.id = od.iduser
    LEFT JOIN ordersg osg ON od.bd = 3 AND osg.id = od.iduser
    INNER JOIN users u ON u.idusers = COALESCE(o.iduser, ot.iduser, osg.iduser)
    LEFT JOIN (
        SELECT target_user_id, AVG(rating) AS avg_rating
        FROM reviews
        GROUP BY target_user_id
    ) avg_ratings ON u.idusers = avg_ratings.target_user_id
    LEFT JOIN (
        SELECT target_user_id, COUNT(*) AS reviewsCount
        FROM reviews
        GROUP BY target_user_id
    ) rev_count ON u.idusers = rev_count.target_user_id
    LEFT JOIN likes1 l
        ON l.idusers = u.idusers AND l.id = od.iduser AND l.usersid = ?
    WHERE od.status = 1
      AND og.status IN ('выполнен', 'отменен')
      AND og.user_id = ?
    GROUP BY od.id, od.iduser, od.iduserp, od.bd, od.cena, od.about,
             u.idusers, u.fotouser, u.firstName, u.lastName, u.middleName,
             u.city, u.phone, u.namefirm, u.innStr, u.ogrnStr, u.kppStr,
             og.start_time, og.end_time, og.cancel_time, og.status
    ORDER BY COALESCE(og.end_time, og.cancel_time, og.start_time) DESC
";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    http_response_code(500);
    echo json_encode(['error' => $conn->error], JSON_UNESCAPED_UNICODE);
    $conn->close();
    exit;
}

$stmt->bind_param('ii', $nameImg, $nameImg);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    if (!empty($row['fotouser'])) {
        $row['fotouser'] = base64_encode($row['fotouser']);
    }
    $data[] = $row;
}

header('Content-Type: application/json; charset=utf-8');
echo json_encode($data, JSON_UNESCAPED_UNICODE);

$stmt->close();
$conn->close();
?>
