<?php
header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../api/databd.php';

$useId = isset($_GET['idusers']) ? (int)$_GET['idusers'] : 0;
if ($useId <= 0 && isset($_GET['usersid'])) {
    $useId = (int)$_GET['usersid'];
}

if ($useId <= 0) {
    http_response_code(400);
    exit(json_encode(['message' => 'Параметр idusers/usersid отсутствует']));
}

try {
    $conn = new mysqli($host, $username, $password, $dbname);

    if ($conn->connect_errno) {
        throw new Exception("Ошибка подключения к базе данных: " . $conn->connect_error);
    }

    $conn->set_charset("utf8mb4");

    $sql = "
SELECT
    MAX(l.id) AS id,
    l.idusers AS iduser,
    l.idusers AS iduserp,
    MAX(l.bd) AS bd,
    u.idusers AS idusers,
    u.fotouser,
    u.firstName,
    u.lastName,
    u.middleName,
    u.city AS userCity,
    u.phone,
    u.email,
    'true' AS success,
    COALESCE(avg_ratings.avg_rating, 0) AS avg_rating,
    COALESCE(rev_count.reviewsCount, 0) AS reviewsCount
FROM users AS u
INNER JOIN likes AS l ON l.idusers = u.idusers
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
WHERE l.usersid = ?
  AND l.idusers != ?
GROUP BY u.idusers
ORDER BY MAX(l.id) DESC";

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception("Ошибка подготовки SQL: " . $conn->error);
    }
    $stmt->bind_param("ii", $useId, $useId);
    $stmt->execute();

    $result = $stmt->get_result();
    $data = [];

    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            if (isset($row['fotouser']) && !is_null($row['fotouser'])) {
                $row['fotouser'] = base64_encode($row['fotouser']);
            }
            $data[] = $row;
        }
    }

    echo json_encode($data, JSON_UNESCAPED_UNICODE);

    $stmt->free_result();
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['message' => 'Ошибка сервера: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>
