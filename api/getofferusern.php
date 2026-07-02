<?php
/**
 * Список объявлений, на которые текущий исполнитель подал предложение (offer_data).
 * GET: useId — id исполнителя (idusers).
 * Возвращает все заявки пользователя по orders/orderst/ordersg.
 */
header('Content-Type: application/json; charset=utf-8');

include __DIR__ . '/databd.php';

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

$debugMode = isset($_GET['debug']) && (string)$_GET['debug'] === '1';
if ($debugMode) {
    $debug = [
        'useId' => $useId,
        'offer_rows' => [],
        'match_counts' => [
            'orders_by_id' => 0,
            'orders_by_owner' => 0,
            'orderst_by_id' => 0,
            'orderst_by_owner' => 0,
            'ordersg_by_id' => 0,
            'ordersg_by_owner' => 0,
        ],
    ];

    $offerSql = "SELECT id, iduserp, iduser, bd, status, isp FROM offer_data WHERE iduserp = ? ORDER BY id DESC LIMIT 50";
    if ($offerStmt = $conn->prepare($offerSql)) {
        $offerStmt->bind_param('i', $useId);
        $offerStmt->execute();
        $offerRes = $offerStmt->get_result();
        while ($r = $offerRes->fetch_assoc()) {
            $debug['offer_rows'][] = $r;
        }
        $offerStmt->close();
    }

    foreach ($debug['offer_rows'] as $r) {
        $offerIdUser = (int)$r['iduser'];
        foreach ([
            ['orders', 'id', 'orders_by_id'],
            ['orders', 'iduser', 'orders_by_owner'],
            ['orderst', 'id', 'orderst_by_id'],
            ['orderst', 'iduser', 'orderst_by_owner'],
            ['ordersg', 'id', 'ordersg_by_id'],
            ['ordersg', 'iduser', 'ordersg_by_owner'],
        ] as $pair) {
            [$table, $col, $key] = $pair;
            $q = "SELECT COUNT(*) AS c FROM {$table} WHERE {$col} = ?";
            if ($s = $conn->prepare($q)) {
                $s->bind_param('i', $offerIdUser);
                $s->execute();
                $res = $s->get_result()->fetch_assoc();
                $debug['match_counts'][$key] += (int)($res['c'] ?? 0);
                $s->close();
            }
        }
    }

    echo json_encode($debug, JSON_UNESCAPED_UNICODE);
    $conn->close();
    exit;
}

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
        1 AS bd
    FROM offer_data od
    INNER JOIN orders b ON b.id = od.iduser
    JOIN users u ON b.iduser = u.idusers
    LEFT JOIN (
        SELECT user_id, AVG(rating) AS avg_rating, COUNT(*) AS reviewsCount
        FROM reviews
        GROUP BY user_id
    ) rev ON b.iduser = rev.user_id
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
        2 AS bd
    FROM offer_data od
    INNER JOIN orderst b ON b.id = od.iduser
    JOIN users u ON b.iduser = u.idusers
    LEFT JOIN (
        SELECT user_id, AVG(rating) AS avg_rating, COUNT(*) AS reviewsCount
        FROM reviews
        GROUP BY user_id
    ) rev ON b.iduser = rev.user_id
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
        3 AS bd
    FROM offer_data od
    INNER JOIN ordersg b ON b.id = od.iduser
    JOIN users u ON b.iduser = u.idusers
    LEFT JOIN (
        SELECT user_id, AVG(rating) AS avg_rating, COUNT(*) AS reviewsCount
        FROM reviews
        GROUP BY user_id
    ) rev ON b.iduser = rev.user_id
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
