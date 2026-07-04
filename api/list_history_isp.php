<?php
/**
 * История заказов исполнителя: сценарий 1 (offer_data) + сценарий 2 (offer_dataf).
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
               CASE WHEN MAX(l.usersid IS NOT NULL) THEN 'true' ELSE 'false' END AS success,
               'customer_order' AS deal_source,
               COALESCE(og.end_time, og.cancel_time, og.start_time) AS sort_time
        FROM offer_data od
        INNER JOIN ordersglobal og
            ON od.id = og.idoffer
            AND od.iduserp = og.user_id
            AND CAST(od.iduser AS CHAR) = CAST(og.order_id AS CHAR)
        INNER JOIN users u ON u.idusers = og.user_idok
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

        UNION ALL

        SELECT odf.iduser AS id,
               odf.bd AS bd,
               u.idusers AS iduser,
               u.idusers AS review_user_id,
               odf.cena,
               odf.about,
               og.user_id AS iduserp,
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
               'false' AS success,
               'performer_ad' AS deal_source,
               COALESCE(og.end_time, og.cancel_time, og.start_time) AS sort_time
        FROM offer_dataf odf
        INNER JOIN ordersglobal og
            ON odf.id = og.idoffer
            AND CAST(odf.iduser AS CHAR) = CAST(og.order_id AS CHAR)
        INNER JOIN users u ON u.idusers = og.user_idok
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
        WHERE og.status IN ('выполнен', 'отменен')
          AND og.user_id = ?
    ) history
    ORDER BY sort_time DESC
";

$stmt = $conn->prepare($sql);
$stmt->bind_param('iii', $nameImg, $nameImg, $nameImg);
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
