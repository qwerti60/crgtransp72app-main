<?php
header('Content-Type: application/json; charset=utf-8');

include 'databd.php';

$bd = isset($_GET['bd']) ? (int) $_GET['bd'] : 0;
$usersid = isset($_GET['usersid']) ? (int) $_GET['usersid'] : 0;

if ($usersid <= 0) {
    echo json_encode([], JSON_UNESCAPED_UNICODE);
    exit;
}

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([], JSON_UNESCAPED_UNICODE);
    exit;
}
$conn->set_charset("utf8");

$sql = "
    SELECT MAX(l.id) AS id,
           l.idusers AS iduser,
           MAX(l.bd) AS bd,
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
           'true' AS success
    FROM likes1 AS l
    INNER JOIN users AS u ON l.idusers = u.idusers
    WHERE l.usersid = ?
    GROUP BY u.idusers
    ORDER BY MAX(l.id) DESC
";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode([], JSON_UNESCAPED_UNICODE);
    $conn->close();
    exit;
}

$stmt->bind_param("i", $usersid);
$stmt->execute();
$result = $stmt->get_result();

$fetchData = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        foreach (['img1', 'img2', 'img3', 'img4', 'fotouser'] as $imgField) {
            if (!empty($row[$imgField])) {
                $row[$imgField] = base64_encode($row[$imgField]);
            }
        }

        foreach (['imgdoc1', 'imgdoc2', 'imgdoc3', 'imgdoc4'] as $doc) {
            unset($row[$doc]);
        }

        $fetchData[] = $row;
    }
}

echo json_encode($fetchData, JSON_UNESCAPED_UNICODE);

$stmt->close();
$conn->close();
?>
