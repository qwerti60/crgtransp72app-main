<?php
require_once __DIR__ . '/databd.php';
require_once __DIR__ . '/include/customer_order_deal.php';

$nameImg = isset($_GET['nameImg']) && is_numeric($_GET['nameImg']) ? (int) $_GET['nameImg'] : null;
$bd = isset($_GET['bd']) && is_numeric($_GET['bd']) ? (int) $_GET['bd'] : null;
$usersid = isset($_GET['usersid']) ? (int) $_GET['usersid'] : 0;
$debug = isset($_GET['debug']) && $_GET['debug'] === '1';

if ($nameImg === null) {
    http_response_code(400);
    exit(json_encode(['error' => 'Параметр nameImg обязателен']));
}

$conn = new mysqli($host, $username, $password, $dbname);
$conn->set_charset('utf8mb4');

if ($conn->connect_error) {
    die('Ошибка подключения к базе данных: ' . $conn->connect_error);
}

function tableExists(mysqli $conn, string $name): bool
{
    if ($name === '' || !preg_match('/^[A-Za-z0-9_]+$/', $name)) {
        return false;
    }
    $esc = $conn->real_escape_string($name);
    $r = $conn->query("SHOW TABLES LIKE '{$esc}'");

    return $r && $r->num_rows > 0;
}

/** Таблица объявлений исполнителя — как в get_ads2_new.php (не orders/orderst/ordersg). */
function performerAdTableForBd(int $bd): ?string
{
    switch ($bd) {
        case 1:
            return 'add_ob_gp';
        case 2:
            return 'add_ob_vidt';
        case 3:
            return 'add_ob_gr';
        default:
            return null;
    }
}

function customerOrderCity(mysqli $conn, int $orderId, int $bd): ?string
{
    $customerTables = [
        1 => 'orders',
        2 => 'orderst',
        3 => 'ordersg',
    ];
    $table = $customerTables[$bd] ?? 'orders';
    if (!tableExists($conn, $table)) {
        return null;
    }

    $stmt = $conn->prepare("SELECT city FROM {$table} WHERE id = ? LIMIT 1");
    if (!$stmt) {
        return null;
    }
    $stmt->bind_param('i', $orderId);
    if (!$stmt->execute()) {
        return null;
    }
    $res = $stmt->get_result();
    if (!$res || !($row = $res->fetch_assoc())) {
        return null;
    }
    $city = trim((string) ($row['city'] ?? ''));

    return $city !== '' ? $city : null;
}

function queryLatestPerformerAd(
    mysqli $conn,
    string $table,
    int $performerId,
    ?string $city
): int {
    if (!tableExists($conn, $table)) {
        return 0;
    }

    if ($city !== null && $city !== '') {
        $sql = "SELECT id FROM {$table} WHERE iduser = ? AND city = ? ORDER BY id DESC LIMIT 1";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            return 0;
        }
        $stmt->bind_param('is', $performerId, $city);
    } else {
        $sql = "SELECT id FROM {$table} WHERE iduser = ? ORDER BY id DESC LIMIT 1";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            return 0;
        }
        $stmt->bind_param('i', $performerId);
    }

    if (!$stmt->execute()) {
        return 0;
    }
    $res = $stmt->get_result();
    if ($res && ($row = $res->fetch_assoc())) {
        return (int) ($row['id'] ?? 0);
    }

    return 0;
}

/**
 * id объявления исполнителя для likes1 — тот же, что на экране «Исполнители» (get_ads2_new.php).
 */
function findPerformerListingId(
    mysqli $conn,
    int $performerId,
    int $bd,
    int $customerOrderId
): int {
    $city = customerOrderCity($conn, $customerOrderId, $bd);
    $table = performerAdTableForBd($bd);

    if ($table !== null) {
        $id = queryLatestPerformerAd($conn, $table, $performerId, $city);
        if ($id > 0) {
            return $id;
        }
        $id = queryLatestPerformerAd($conn, $table, $performerId, null);
        if ($id > 0) {
            return $id;
        }
    }

    foreach (['add_ob_gp', 'add_ob_vidt', 'add_ob_gr'] as $fallbackTable) {
        $id = queryLatestPerformerAd($conn, $fallbackTable, $performerId, $city);
        if ($id > 0) {
            return $id;
        }
        $id = queryLatestPerformerAd($conn, $fallbackTable, $performerId, null);
        if ($id > 0) {
            return $id;
        }
    }

    return 0;
}

function checkLikeStatus(mysqli $conn, int $performerId, int $listingId, int $usersid): string
{
    if ($performerId <= 0 || $listingId <= 0 || $usersid <= 0 || !tableExists($conn, 'likes1')) {
        return 'false';
    }

    $stmt = $conn->prepare(
        'SELECT 1 FROM likes1 WHERE idusers = ? AND id = ? AND usersid = ? LIMIT 1'
    );
    if (!$stmt) {
        return 'false';
    }
    $stmt->bind_param('iii', $performerId, $listingId, $usersid);
    $stmt->execute();
    $res = $stmt->get_result();

    return ($res && $res->fetch_row()) ? 'true' : 'false';
}

$bdFilter = $bd !== null && $bd > 0;
$latestSubquery = $bdFilter
    ? 'SELECT iduserp, MAX(id) AS max_id
       FROM offer_data
       WHERE iduser = ?
         AND (status IN (0, 1) OR status IS NULL)
         AND bd = ?
       GROUP BY iduserp'
    : 'SELECT iduserp, MAX(id) AS max_id
       FROM offer_data
       WHERE iduser = ?
         AND (status IN (0, 1) OR status IS NULL)
       GROUP BY iduserp';

$outerBdFilter = $bdFilter ? ' AND od.bd = ?' : '';

$bdVal = ($bd !== null && $bd > 0) ? (int) $bd : 1;
$customerIdExpr = match ($bdVal) {
    2 => '(SELECT ot.iduser FROM orderst ot WHERE ot.id = od.iduser LIMIT 1)',
    3 => '(SELECT ogc.iduser FROM ordersg ogc WHERE ogc.id = od.iduser LIMIT 1)',
    default => '(SELECT o.iduser FROM orders o WHERE o.id = od.iduser LIMIT 1)',
};

$sql = "
    SELECT od.id, od.iduser AS order_id, od.bd, od.cena, od.about, od.iduserp, od.isp,
           " . crg_sql_customer_ad_order_status('od.iduser', $bdVal, $customerIdExpr) . ",
           " . crg_sql_customer_ad_chosen_performer('od.iduser', $bdVal, $customerIdExpr) . ",
           u.fotouser, u.firstName, u.lastName, u.middleName, u.city, u.phone,
           u.namefirm, u.innStr, u.ogrnStr, u.kppStr,
           COALESCE(AVG(r.rating), 0) AS rating,
           COALESCE(COUNT(r.user_id), 0) AS reviewsCount
    FROM offer_data od
    INNER JOIN (
        {$latestSubquery}
    ) latest ON od.id = latest.max_id
    INNER JOIN users u ON od.iduserp = u.idusers
    LEFT JOIN reviewsisp r ON u.idusers = r.user_id
    WHERE od.iduser = ?
      AND (od.status IN (0, 1) OR od.status IS NULL)
      {$outerBdFilter}
    GROUP BY od.id, u.idusers
    ORDER BY od.id DESC
";

$stmt = $conn->prepare($sql);
if ($bdFilter) {
    $stmt->bind_param('iiii', $nameImg, $bd, $nameImg, $bd);
} else {
    $stmt->bind_param('ii', $nameImg, $nameImg);
}
$stmt->execute();
$result = $stmt->get_result();

$data = [];
while ($row = $result->fetch_assoc()) {
    if (!empty($row['fotouser'])) {
        $row['fotouser'] = base64_encode($row['fotouser']);
    }

    $performerId = (int) ($row['iduserp'] ?? 0);
    $bdVal = (int) ($row['bd'] ?? 0);
    $listingId = findPerformerListingId($conn, $performerId, $bdVal, $nameImg);

    $row['listing_id'] = $listingId;
    $row['idusers'] = $performerId;
    $row['iduser'] = $performerId;
    $row['success'] = checkLikeStatus($conn, $performerId, $listingId, $usersid);

    $data[] = $row;
}

header('Content-Type: application/json; charset=utf-8');

if ($debug) {
    echo json_encode([
        'ok' => true,
        'request' => [
            'nameImg' => $nameImg,
            'bd' => $bd,
            'usersid' => $usersid,
        ],
        'data' => $data,
    ], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
}

$conn->close();
