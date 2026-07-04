<?php
/**
 * История заказов заказчика: сценарий 1 (offer_data) + сценарий 2 (offer_dataf).
 */
require_once 'databd.php';

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
    SELECT * FROM (
        SELECT od.cena,
               od.about,
               od.iduserp,
               u.fotouser,
               u.firstName,
               u.lastName,
               u.middleName,
               u.city,
               u.phone,
               og.start_time,
               og.end_time,
               og.cancel_time,
               og.status AS order_status,
               IFNULL(avg_ratings.avg_rating, 0) AS avg_rating,
               COALESCE(rev_count.reviewsCount, 0) AS reviewsCount,
               'customer_order' AS deal_source,
               COALESCE(og.end_time, og.cancel_time, og.start_time) AS sort_time
        FROM offer_data od
        INNER JOIN ordersglobal og
            ON od.id = og.idoffer
            AND od.iduserp = og.user_id
            AND CAST(od.iduser AS CHAR) = CAST(og.order_id AS CHAR)
        INNER JOIN users u ON od.iduserp = u.idusers
        LEFT JOIN (
            SELECT user_id, AVG(rating) AS avg_rating
            FROM reviewsisp
            GROUP BY user_id
        ) avg_ratings ON og.user_id = avg_ratings.user_id
        LEFT JOIN (
            SELECT user_id, COUNT(*) AS reviewsCount
            FROM reviewsisp
            GROUP BY user_id
        ) rev_count ON og.user_id = rev_count.user_id
        WHERE od.status = 1
          AND og.status IN ('выполнен', 'отменен')
          AND og.user_idok = ?

        UNION ALL

        SELECT odf.cena,
               odf.about,
               og.user_id AS iduserp,
               u.fotouser,
               u.firstName,
               u.lastName,
               u.middleName,
               u.city,
               u.phone,
               og.start_time,
               og.end_time,
               og.cancel_time,
               og.status AS order_status,
               IFNULL(avg_ratings.avg_rating, 0) AS avg_rating,
               COALESCE(rev_count.reviewsCount, 0) AS reviewsCount,
               'performer_ad' AS deal_source,
               COALESCE(og.end_time, og.cancel_time, og.start_time) AS sort_time
        FROM offer_dataf odf
        INNER JOIN ordersglobal og
            ON odf.id = og.idoffer
            AND CAST(odf.iduser AS CHAR) = CAST(og.order_id AS CHAR)
        INNER JOIN users u ON og.user_id = u.idusers
        LEFT JOIN (
            SELECT user_id, AVG(rating) AS avg_rating
            FROM reviewsisp
            GROUP BY user_id
        ) avg_ratings ON og.user_id = avg_ratings.user_id
        LEFT JOIN (
            SELECT user_id, COUNT(*) AS reviewsCount
            FROM reviewsisp
            GROUP BY user_id
        ) rev_count ON og.user_id = rev_count.user_id
        WHERE og.status IN ('выполнен', 'отменен')
          AND odf.iduserp = ?
    ) history
    ORDER BY sort_time DESC
";

$stmt = $conn->prepare($sql);
$stmt->bind_param('ii', $nameImg, $nameImg);
$stmt->execute();
$result = $stmt->get_result();

$data = [];
while ($row = $result->fetch_assoc()) {
    unset($row['sort_time']);
    if (!empty($row['fotouser'])) {
        $row['fotouser'] = base64_encode($row['fotouser']);
    }
    $data[] = $row;
}

header('Content-Type: application/json; charset=utf-8');
echo json_encode($data, JSON_UNESCAPED_UNICODE);

$stmt->close();
$conn->close();
