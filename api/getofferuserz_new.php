<?php
/**
 * Объявления исполнителей, на которые заказчик оставил заявку (offer_dataf).
 * id в offer_dataf.iduser — id объявления в orders / orderst / ordersg ИЛИ add_ob_*.
 * Таблицы reviewsisp и likes1 подключаются только если существуют (иначе prepare падал и ответ был []).
 * Сопоставление исполнителя с users: iduser в orders может быть varchar.
 */
declare(strict_types=1);

require_once __DIR__ . '/databd.php';

header('Content-Type: application/json; charset=utf-8');

$useIdRaw = isset($_GET['useId']) ? trim((string) $_GET['useId']) : '';
if ($useIdRaw === '' && isset($_GET['usersid'])) {
    $useIdRaw = trim((string) $_GET['usersid']);
}

$fetchAll = isset($_GET['all']) && $_GET['all'] === '1';
$bd       = isset($_GET['bd']) ? (int) $_GET['bd'] : 0;

if ($useIdRaw === '') {
    echo json_encode([], JSON_UNESCAPED_UNICODE);
    exit;
}
if (!$fetchAll && ($bd < 1 || $bd > 3)) {
    echo json_encode([], JSON_UNESCAPED_UNICODE);
    exit;
}

$conn = @new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    echo json_encode([], JSON_UNESCAPED_UNICODE);
    exit;
}
$conn->set_charset('utf8mb4');

/** @var array<string, bool> */
$tableCache = [];

$exists = static function (mysqli $c, string $name) use (&$tableCache): bool {
    $key = strtolower($name);
    if (array_key_exists($key, $tableCache)) {
        return $tableCache[$key];
    }
    if ($name === '' || !preg_match('/^[A-Za-z0-9_]+$/', $name)) {
        return $tableCache[$key] = false;
    }
    $esc = $c->real_escape_string($name);
    $r   = $c->query("SHOW TABLES LIKE '{$esc}'");
    return $tableCache[$key] = ($r && $r->num_rows > 0);
};

$hasReviewsIsp = $exists($conn, 'reviewsisp');
$hasLikes1     = $exists($conn, 'likes1');

$ratingExpr = $hasReviewsIsp
    ? '(SELECT COALESCE(AVG(r2.rating), 0) FROM reviewsisp r2 WHERE r2.user_id = u.idusers)'
    : '0';
$reviewsCountExpr = $hasReviewsIsp
    ? '(SELECT COALESCE(COUNT(*), 0) FROM reviewsisp r3 WHERE r3.user_id = u.idusers)'
    : '0';

$successExpr = $hasLikes1
    ? "CASE WHEN EXISTS(SELECT 1 FROM likes1 l WHERE l.idusers = u.idusers AND l.id = a.id AND l.usersid = ?) THEN 'true' ELSE 'false' END"
    : "'false'";

// LEFT JOIN: как в get_ads2_new.php — объявление из add_ob_* должно попадать в список,
// даже если iduser не сматчился с users (иначе offer_dataf есть, а ответ пустой).
$userJoin = 'LEFT JOIN users AS u ON u.idusers = CAST(NULLIF(NULLIF(TRIM(CAST(a.iduser AS CHAR)), \'\'), \'NULL\') AS UNSIGNED) AND CAST(NULLIF(NULLIF(TRIM(CAST(a.iduser AS CHAR)), \'\'), \'NULL\') AS UNSIGNED) > 0';

$baseMap = [
    1 => ['orders', 'add_ob_gp'],
    2 => ['orderst', 'add_ob_vidt'],
    3 => ['ordersg', 'add_ob_gr'],
];

$tableCandidates = [];
foreach ($baseMap as $bdKey => $tables) {
    $tableCandidates[$bdKey] = array_values(array_filter(
        $tables,
        static function (string $t) use ($conn, $exists): bool {
            return $exists($conn, $t);
        }
    ));
}

$fetchData = [];

try {
    if ($fetchAll) {
        $stmtOffers = $conn->prepare(
            'SELECT iduser AS listing_id, bd FROM offer_dataf WHERE iduserp = ?'
        );
        if (!$stmtOffers) {
            throw new RuntimeException($conn->error);
        }
        // Строковый bind: iduserp в БД может быть CHAR/VARCHAR.
        $stmtOffers->bind_param('s', $useIdRaw);
    } else {
        $stmtOffers = $conn->prepare(
            'SELECT DISTINCT iduser AS listing_id FROM offer_dataf WHERE iduserp = ? AND bd = ?'
        );
        if (!$stmtOffers) {
            throw new RuntimeException($conn->error);
        }
        $stmtOffers->bind_param('si', $useIdRaw, $bd);
    }

    $stmtOffers->execute();
    $rOffers = $stmtOffers->get_result();

    while ($o = $rOffers->fetch_assoc()) {
        $listingId = (int) $o['listing_id'];
        if ($listingId <= 0) {
            continue;
        }
        $rowBd = $fetchAll ? (int) $o['bd'] : $bd;
        // Сначала категория из offer_dataf, затем 1/2/3 — если bd в строке неверный, объявление всё равно ищем.
        $bdsToTry = [];
        if ($rowBd >= 1 && $rowBd <= 3) {
            $bdsToTry[] = $rowBd;
        }
        foreach ([1, 2, 3] as $b) {
            if (!in_array($b, $bdsToTry, true)) {
                $bdsToTry[] = $b;
            }
        }

        $row     = null;
        $foundBd = $rowBd >= 1 && $rowBd <= 3 ? $rowBd : 1;
        foreach ($bdsToTry as $tryBd) {
            $candidates = $tableCandidates[$tryBd] ?? [];
            if ($candidates === []) {
                continue;
            }
            foreach ($candidates as $tbl) {
                $sql = "
                SELECT a.*,
                       u.idusers AS idusers,
                       u.fotouser,
                       u.firstName,
                       u.lastName,
                       u.middleName,
                       u.city AS userCity,
                       u.phone,
                       u.email,
                       {$ratingExpr} AS rating,
                       {$reviewsCountExpr} AS reviewsCount,
                       {$successExpr} AS success
                FROM {$tbl} AS a
                {$userJoin}
                WHERE a.id = ?
                LIMIT 1
            ";

                $stmt = $conn->prepare($sql);
                if (!$stmt) {
                    continue;
                }
                if ($hasLikes1) {
                    $stmt->bind_param('si', $useIdRaw, $listingId);
                } else {
                    $stmt->bind_param('i', $listingId);
                }
                if (!$stmt->execute()) {
                    continue;
                }
                $res = $stmt->get_result();
                if ($res && ($row = $res->fetch_assoc())) {
                    $foundBd = $tryBd;
                    break 2;
                }
            }
        }

        if (!$row) {
            continue;
        }

        if ($fetchAll) {
            $row['offer_bd'] = $foundBd;
        }
        $row['offer_dataf_bd'] = $rowBd;

        $imgsToEncode = ['img1', 'img2', 'img3', 'img4', 'fotouser'];
        foreach ($imgsToEncode as $imgField) {
            if (isset($row[$imgField]) && $row[$imgField] !== null && $row[$imgField] !== '') {
                $row[$imgField] = base64_encode((string) $row[$imgField]);
            }
        }

        $fetchData[] = $row;
    }

    usort($fetchData, static function ($a, $b) {
        return ((int) ($b['id'] ?? 0)) <=> ((int) ($a['id'] ?? 0));
    });
} catch (Throwable $e) {
    $fetchData = [];
}

$flags = JSON_UNESCAPED_UNICODE;
if (defined('JSON_INVALID_UTF8_SUBSTITUTE')) {
    $flags |= JSON_INVALID_UTF8_SUBSTITUTE;
}
$out = json_encode($fetchData, $flags);
if ($out === false) {
    $out = '[]';
}
echo $out;
$conn->close();
