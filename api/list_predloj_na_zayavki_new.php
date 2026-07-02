<?php
declare(strict_types=1);

/**
 * Заявки заказчиков на объявление исполнителя (offer_dataf).
 * nameImg — id объявления в add_ob_gp / add_ob_vidt / add_ob_gr.
 */
require_once __DIR__ . '/databd.php';

$nameImg = isset($_GET['nameImg']) && is_numeric($_GET['nameImg']) ? (int) $_GET['nameImg'] : null;
$bd = isset($_GET['bd']) && is_numeric($_GET['bd']) ? (int) $_GET['bd'] : null;
$debug = isset($_GET['debug']) && $_GET['debug'] === '1';

if ($nameImg === null) {
    http_response_code(400);
    exit(json_encode(['error' => 'Параметр nameImg обязателен'], JSON_UNESCAPED_UNICODE));
}

$conn = new mysqli($host, $username, $password, $dbname);
$conn->set_charset('utf8mb4');

if ($conn->connect_error) {
    http_response_code(500);
    exit(json_encode(['error' => 'Ошибка подключения к базе данных'], JSON_UNESCAPED_UNICODE));
}

$sql = "
    SELECT od.id, od.iduser, od.bd, od.cena, od.about, od.iduserp, od.isp,
           u.fotouser, u.firstName, u.lastName, u.middleName, u.city, u.phone,
           u.namefirm, u.innStr, u.ogrnStr, u.kppStr,
           COALESCE(AVG(r.rating), 0) AS rating,
           COALESCE(COUNT(r.id), 0) AS reviewsCount
    FROM offer_dataf od
    INNER JOIN users u ON od.iduserp = u.idusers
    LEFT JOIN reviews r ON u.idusers = r.target_user_id
    WHERE od.iduser = ?
";
$params = [$nameImg];
$types = 'i';

if ($bd !== null && $bd > 0) {
    $sql .= ' AND od.bd = ?';
    $types .= 'i';
    $params[] = $bd;
}

$sql .= ' GROUP BY od.id, u.idusers ORDER BY od.id DESC';

$stmt = $conn->prepare($sql);
if (!$stmt) {
    http_response_code(500);
    exit(json_encode(['error' => 'Ошибка подготовки запроса'], JSON_UNESCAPED_UNICODE));
}

$stmt->bind_param($types, ...$params);
$stmt->execute();
$result = $stmt->get_result();

$data = [];
while ($row = $result->fetch_assoc()) {
    if (!empty($row['fotouser'])) {
        $row['fotouser'] = base64_encode($row['fotouser']);
    }
    $data[] = $row;
}

$stmt->close();
$conn->close();

header('Content-Type: application/json; charset=utf-8');

if ($debug) {
    echo json_encode([
        'ok' => true,
        'request' => [
            'nameImg' => $nameImg,
            'bd' => $bd,
        ],
        'data' => $data,
    ], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
}
