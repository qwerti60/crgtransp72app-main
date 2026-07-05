<?php
header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/databd.php';
require_once __DIR__ . '/include/customer_order_deal.php';

$useId = isset($_GET['useId']) ? (int) $_GET['useId'] : 0;

if ($useId <= 0) {
    echo json_encode([], JSON_UNESCAPED_UNICODE);
    exit;
}

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([], JSON_UNESCAPED_UNICODE);
    exit;
}
$conn->set_charset('utf8mb4');

$sql = "
SELECT DISTINCT sq.*
FROM (
    SELECT
        b.id AS id,
        b.iduser AS iduser,
        u.fotouser AS fotouser,
        u.firstName AS firstName,
        u.lastName AS lastName,
        u.phone AS phone,
        '' AS vidt,
        '' AS maxgruz,
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
        CASE
            WHEN b.created_at IS NOT NULL
                 AND CAST(b.created_at AS CHAR) NOT IN ('0000-00-00', '0000-00-00 00:00:00')
                THEN DATE(b.created_at)
            WHEN b.startdate IS NOT NULL AND b.startdate NOT IN ('0000-00-00', '')
                THEN b.startdate
            ELSE DATE(od.timestamp)
        END AS created_at,
        CASE WHEN EXISTS(
                SELECT 1 FROM likes1 l
                WHERE l.idusers = b.iduser AND l.id = b.id AND l.usersid = ?
            ) THEN 'true' ELSE 'false' END AS success,
        COALESCE(rev.avg_rating, 0) AS avg_rating,
        COALESCE(rev.reviewsCount, 0) AS reviewsCount,
        od.iduserp AS iduserp,
        od.bd AS bd,
        od.isp AS isp,
        od.status AS offer_status,
        " . crg_sql_customer_ad_order_status('b.id', 1, 'b.iduser') . ",
        " . crg_sql_customer_ad_chosen_performer('b.id', 1, 'b.iduser') . "
    FROM offer_data od
    INNER JOIN orders b ON b.id = od.iduser
    JOIN users u ON b.iduser = u.idusers
    LEFT JOIN (
        SELECT target_user_id, AVG(rating) AS avg_rating, COUNT(*) AS reviewsCount
        FROM reviews
        GROUP BY target_user_id
    ) rev ON b.iduser = rev.target_user_id
    WHERE od.iduserp = ?
      AND od.status IN (0, 1, 2)

    UNION ALL

    SELECT
        b.id AS id,
        b.iduser AS iduser,
        u.fotouser AS fotouser,
        u.firstName AS firstName,
        u.lastName AS lastName,
        u.phone AS phone,
        b.vidt AS vidt,
        '' AS maxgruz,
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
        CASE
            WHEN b.created_at IS NOT NULL
                 AND CAST(b.created_at AS CHAR) NOT IN ('0000-00-00', '0000-00-00 00:00:00')
                THEN DATE(b.created_at)
            WHEN b.startdate IS NOT NULL AND b.startdate NOT IN ('0000-00-00', '')
                THEN b.startdate
            ELSE DATE(od.timestamp)
        END AS created_at,
        CASE WHEN EXISTS(
                SELECT 1 FROM likes1 l
                WHERE l.idusers = b.iduser AND l.id = b.id AND l.usersid = ?
            ) THEN 'true' ELSE 'false' END AS success,
        COALESCE(rev.avg_rating, 0) AS avg_rating,
        COALESCE(rev.reviewsCount, 0) AS reviewsCount,
        od.iduserp AS iduserp,
        od.bd AS bd,
        od.isp AS isp,
        od.status AS offer_status,
        " . crg_sql_customer_ad_order_status('b.id', 2, 'b.iduser') . ",
        " . crg_sql_customer_ad_chosen_performer('b.id', 2, 'b.iduser') . "
    FROM offer_data od
    INNER JOIN orderst b ON b.id = od.iduser
    JOIN users u ON b.iduser = u.idusers
    LEFT JOIN (
        SELECT target_user_id, AVG(rating) AS avg_rating, COUNT(*) AS reviewsCount
        FROM reviews
        GROUP BY target_user_id
    ) rev ON b.iduser = rev.target_user_id
    WHERE od.iduserp = ?
      AND od.status IN (0, 1, 2)

    UNION ALL

    SELECT
        b.id AS id,
        b.iduser AS iduser,
        u.fotouser AS fotouser,
        u.firstName AS firstName,
        u.lastName AS lastName,
        u.phone AS phone,
        '' AS vidt,
        '' AS maxgruz,
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
        CASE
            WHEN b.created_at IS NOT NULL
                 AND CAST(b.created_at AS CHAR) NOT IN ('0000-00-00', '0000-00-00 00:00:00')
                THEN DATE(b.created_at)
            WHEN b.startdate IS NOT NULL AND b.startdate NOT IN ('0000-00-00', '')
                THEN b.startdate
            ELSE DATE(od.timestamp)
        END AS created_at,
        CASE WHEN EXISTS(
                SELECT 1 FROM likes1 l
                WHERE l.idusers = b.iduser AND l.id = b.id AND l.usersid = ?
            ) THEN 'true' ELSE 'false' END AS success,
        COALESCE(rev.avg_rating, 0) AS avg_rating,
        COALESCE(rev.reviewsCount, 0) AS reviewsCount,
        od.iduserp AS iduserp,
        od.bd AS bd,
        od.isp AS isp,
        od.status AS offer_status,
        " . crg_sql_customer_ad_order_status('b.id', 3, 'b.iduser') . ",
        " . crg_sql_customer_ad_chosen_performer('b.id', 3, 'b.iduser') . "
    FROM offer_data od
    INNER JOIN ordersg b ON b.id = od.iduser
    JOIN users u ON b.iduser = u.idusers
    LEFT JOIN (
        SELECT target_user_id, AVG(rating) AS avg_rating, COUNT(*) AS reviewsCount
        FROM reviews
        GROUP BY target_user_id
    ) rev ON b.iduser = rev.target_user_id
    WHERE od.iduserp = ?
      AND od.status IN (0, 1, 2)
) sq
ORDER BY sq.created_at DESC, sq.id DESC
";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    http_response_code(500);
    echo json_encode([], JSON_UNESCAPED_UNICODE);
    $conn->close();
    exit;
}

$stmt->bind_param(
    'iiiiii',
    $useId,
    $useId,
    $useId,
    $useId,
    $useId,
    $useId
);
$stmt->execute();
$result = $stmt->get_result();

$fetchData = [];
while ($row = $result->fetch_assoc()) {
    $imgsToEncode = ['img1', 'img2', 'img3', 'img4', 'fotouser'];
    foreach ($imgsToEncode as $imgField) {
        if (isset($row[$imgField]) && $row[$imgField] !== null && $row[$imgField] !== '') {
            $row[$imgField] = base64_encode($row[$imgField]);
        }
    }
    $fetchData[] = $row;
}

$stmt->close();
$conn->close();

echo json_encode($fetchData, JSON_UNESCAPED_UNICODE);
?>
