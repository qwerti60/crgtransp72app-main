<?php
header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../api/databd.php';

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
        b.startdate AS created_at,
        CASE WHEN EXISTS(
                SELECT 1 FROM likes1 l
                WHERE l.idusers = b.iduser AND l.id = b.id AND l.usersid = ?
            ) THEN 'true' ELSE 'false' END AS success,
        COALESCE(rev.avg_rating, 0) AS avg_rating,
        COALESCE(rev.reviewsCount, 0) AS reviewsCount,
        od.iduserp AS iduserp,
        1 AS bd
    FROM offer_data od
    INNER JOIN orders b ON b.id = od.iduser
    JOIN users u ON b.iduser = u.idusers
    LEFT JOIN (
        SELECT target_user_id, AVG(rating) AS avg_rating, COUNT(*) AS reviewsCount
        FROM reviews
        GROUP BY target_user_id
    ) rev ON b.iduser = rev.target_user_id
    WHERE od.iduserp = ?

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
        b.startdate AS created_at,
        CASE WHEN EXISTS(
                SELECT 1 FROM likes1 l
                WHERE l.idusers = b.iduser AND l.id = b.id AND l.usersid = ?
            ) THEN 'true' ELSE 'false' END AS success,
        COALESCE(rev.avg_rating, 0) AS avg_rating,
        COALESCE(rev.reviewsCount, 0) AS reviewsCount,
        od.iduserp AS iduserp,
        2 AS bd
    FROM offer_data od
    INNER JOIN orderst b ON b.id = od.iduser
    JOIN users u ON b.iduser = u.idusers
    LEFT JOIN (
        SELECT target_user_id, AVG(rating) AS avg_rating, COUNT(*) AS reviewsCount
        FROM reviews
        GROUP BY target_user_id
    ) rev ON b.iduser = rev.target_user_id
    WHERE od.iduserp = ?

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
        b.startdate AS created_at,
        CASE WHEN EXISTS(
                SELECT 1 FROM likes1 l
                WHERE l.idusers = b.iduser AND l.id = b.id AND l.usersid = ?
            ) THEN 'true' ELSE 'false' END AS success,
        COALESCE(rev.avg_rating, 0) AS avg_rating,
        COALESCE(rev.reviewsCount, 0) AS reviewsCount,
        od.iduserp AS iduserp,
        3 AS bd
    FROM offer_data od
    INNER JOIN ordersg b ON b.id = od.iduser
    JOIN users u ON b.iduser = u.idusers
    LEFT JOIN (
        SELECT target_user_id, AVG(rating) AS avg_rating, COUNT(*) AS reviewsCount
        FROM reviews
        GROUP BY target_user_id
    ) rev ON b.iduser = rev.target_user_id
    WHERE od.iduserp = ?
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
