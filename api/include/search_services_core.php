<?php
/**
 * Ядро поиска услуг (docs/search_logic_ru.md).
 * role=customer → объявления исполнителей (supply)
 * role=performer → объявления заказчиков (demand)
 */

require_once __DIR__ . '/viewer_user.php';
require_once __DIR__ . '/search_visibility_sql.php';

function search_normalize_text(string $text): string
{
    $text = mb_strtolower(trim($text), 'UTF-8');
    $text = str_replace('ё', 'е', $text);
    return $text;
}

function search_parse_price(?string $raw): ?float
{
    if ($raw === null || $raw === '') {
        return null;
    }
    $digits = preg_replace('/[^\d.,]/', '', $raw);
    $digits = str_replace(',', '.', $digits);
    if ($digits === '' || !is_numeric($digits)) {
        return null;
    }
    return (float) $digits;
}

/** @return list<string> */
function search_query_words(string $query): array
{
    $words = preg_split('/\s+/u', search_normalize_text($query), -1, PREG_SPLIT_NO_EMPTY);
    $filtered = [];
    foreach ($words as $word) {
        if (mb_strlen($word, 'UTF-8') >= 3) {
            $filtered[] = $word;
        }
    }
    return $filtered;
}

function search_has_meaningful_query(string $query): bool
{
    return search_query_words($query) !== [];
}

/**
 * @return array{bd:int,demand:string,supply:string,category_field:?string}|null
 */
function search_resolve_category(mysqli $conn, string $nameImg): ?array
{
    $stmt = $conn->prepare('SELECT 1 FROM vidg WHERE name = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return ['bd' => 1, 'demand' => 'orders', 'supply' => 'add_ob_gp', 'category_field' => 'maxgruz'];
    }

    $stmt = $conn->prepare('SELECT 1 FROM vidt WHERE name = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return ['bd' => 2, 'demand' => 'orderst', 'supply' => 'add_ob_vidt', 'category_field' => 'vidt'];
    }

    $stmt = $conn->prepare('SELECT 1 FROM gruzchik WHERE name = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return ['bd' => 3, 'demand' => 'ordersg', 'supply' => 'add_ob_gr', 'category_field' => null];
    }

    return null;
}

/**
 * Определение категории объявления исполнителя — как get_ads2_new.php
 * (по фактическим объявлениям, не только справочникам vidg/vidt/gruzchik).
 *
 * @return array{bd:int,demand:string,supply:string,category_field:?string}|null
 */
function search_resolve_supply_category(mysqli $conn, string $nameImg): ?array
{
    if ($nameImg === '') {
        return null;
    }

    $stmt = $conn->prepare('SELECT 1 FROM add_ob_gp WHERE maxgruz = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return ['bd' => 1, 'demand' => 'orders', 'supply' => 'add_ob_gp', 'category_field' => 'maxgruz'];
    }

    $stmt = $conn->prepare('SELECT 1 FROM add_ob_vidt WHERE vidt = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return ['bd' => 2, 'demand' => 'orderst', 'supply' => 'add_ob_vidt', 'category_field' => 'vidt'];
    }

    $resolved = search_resolve_category($conn, $nameImg);
    if ($resolved !== null && ($resolved['bd'] ?? 0) === 3) {
        return $resolved;
    }

    $result = $conn->query('SELECT 1 FROM add_ob_gr LIMIT 1');
    if ($result && $result->num_rows > 0) {
        return ['bd' => 3, 'demand' => 'ordersg', 'supply' => 'add_ob_gr', 'category_field' => null];
    }

    return $resolved;
}

/**
 * Категория заявки заказчика — как getads3.php (по фактическим orders* и справочникам).
 *
 * @return array{bd:int,demand:string,supply:string,category_field:?string}|null
 */
function search_resolve_demand_category(mysqli $conn, string $nameImg): ?array
{
    if ($nameImg === '') {
        return null;
    }

    // 1. Как getads3.php — справочники vidt → vidg → gruzchik (gruzchik не через vidg).
    $tableResolved = search_resolve_getads3_table($conn, $nameImg);
    if ($tableResolved !== null) {
        return search_bd_config_from_bd((int) $tableResolved['bd']);
    }

    // 2. По фактическим заявкам (свободный текст / устаревшие данные).
    $stmt = $conn->prepare('SELECT 1 FROM orders WHERE maxgruz = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return search_bd_config_from_bd(1);
    }

    $stmt = $conn->prepare('SELECT 1 FROM orderst WHERE vidt = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return search_bd_config_from_bd(2);
    }

    // 3. Как get_ads2_new.php / search_resolve_supply_category — есть ordersg → bd=3.
    $result = $conn->query('SELECT 1 FROM ordersg LIMIT 1');
    if ($result && $result->num_rows > 0) {
        return search_bd_config_from_bd(3);
    }

    // 4. Справочник vidg/vidt (gruzchik уже обработан в п.1).
    $resolved = search_resolve_category($conn, $nameImg);
    if ($resolved !== null && (int) ($resolved['bd'] ?? 0) !== 3) {
        return $resolved;
    }

    return null;
}

function search_sql_demand_user_exists(): string
{
    return crg_sql_demand_user_exists();
}

/**
 * Таблица заявки заказчика — та же логика, что getads3.php.
 *
 * @return array{table:string,bd:int}|null
 */
function search_resolve_getads3_table(mysqli $conn, string $nameImg): ?array
{
    $stmt = $conn->prepare('SELECT 1 FROM vidt WHERE name = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return ['table' => 'orderst', 'bd' => 2];
    }

    $stmt = $conn->prepare('SELECT 1 FROM vidg WHERE name = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return ['table' => 'orders', 'bd' => 1];
    }

    $stmt = $conn->prepare('SELECT 1 FROM gruzchik WHERE name = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return ['table' => 'ordersg', 'bd' => 3];
    }

    return null;
}

function search_sql_demand_deal_exclude(int $bd): string
{
    return crg_sql_hide_active_deal_customer_order($bd);
}

/**
 * Выборка заявок заказчика — копия getads3.php (legacy fallback).
 *
 * @param array<string,mixed> $params
 * @return array<int,array<string,mixed>>
 */
function search_fetch_demand_getads3(
    mysqli $conn,
    array $params,
    string $nameImg,
    string $city,
    bool $allCities
): array {
    $resolved = search_resolve_getads3_table($conn, $nameImg);
    if ($resolved === null) {
        return [];
    }

    $useId = '';
    if (isset($params['usersid']) && $params['usersid'] !== '') {
        $useId = (string) $params['usersid'];
    } elseif (isset($params['useId']) && $params['useId'] !== '') {
        $useId = (string) $params['useId'];
    }

    $table = $resolved['table'];
    $bd = (int) $resolved['bd'];
    $currentDate = date('Y-m-d');
    $cityLine = $allCities ? '' : 'AND TRIM(a.city) = ?';

    $sql = "
        SELECT a.*,
               {$bd} AS bd,
               u.idusers AS idusers,
               u.idusers AS review_user_id,
               u.fotouser,
               u.firstName,
               u.lastName,
               u.middleName,
               u.city AS userCity,
               u.phone,
               u.email,
               COUNT(r.id) AS reviewsCount,
               COUNT(r.id) AS review_count,
               COALESCE(AVG(r.rating), 0) AS avg_rating,
               CASE
                   WHEN EXISTS(
                       SELECT 1 FROM likes l
                       WHERE l.idusers = u.idusers
                         AND l.id = a.id
                         AND l.usersid = ?
                   ) THEN 'true'
                   ELSE 'false'
               END AS success
        FROM {$table} AS a
        INNER JOIN users AS u ON a.iduser = u.idusers
        LEFT JOIN reviews AS r ON u.idusers = r.target_user_id
        WHERE a.iduser IS NOT NULL
          AND a.enddatez >= ?
          AND a.iduser != ?
          {$cityLine}
          " . search_sql_demand_deal_exclude($bd) . "
        GROUP BY a.id, u.idusers
        ORDER BY a.id DESC
    ";

    $bindTypes = 'sss';
    $bindValues = [$useId, $currentDate, $useId];
    if ($cityLine !== '') {
        $bindTypes .= 's';
        $bindValues[] = $city;
    }

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        return [];
    }
    $stmt->bind_param($bindTypes, ...$bindValues);
    $stmt->execute();
    $result = $stmt->get_result();

    $rows = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            search_encode_row_images($row);
            $rows[] = $row;
        }
    }

    return $rows;
}

/**
 * Распределить счётчик ordersg по услугам из справочника gruzchik.
 *
 * @param array<string, int> $counts
 */
function search_apply_gruzchik_demand_counts(mysqli $conn, array &$counts, int $total): void
{
    if ($total <= 0) {
        return;
    }

    $result = $conn->query('SELECT name FROM gruzchik');
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $serviceName = trim((string) ($row['name'] ?? ''));
            if ($serviceName !== '' && array_key_exists($serviceName, $counts)) {
                $counts[$serviceName] = $total;
            }
        }
    }
}

function search_sql_supply_deal_exclude(int $bd): string
{
    return crg_sql_hide_active_deal_performer_ad($bd);
}

/** @return list<array{bd:int,demand:string,supply:string,category_field:?string}> */
function search_all_bd_configs(): array
{
    return [
        ['bd' => 1, 'demand' => 'orders', 'supply' => 'add_ob_gp', 'category_field' => 'maxgruz'],
        ['bd' => 2, 'demand' => 'orderst', 'supply' => 'add_ob_vidt', 'category_field' => 'vidt'],
        ['bd' => 3, 'demand' => 'ordersg', 'supply' => 'add_ob_gr', 'category_field' => null],
    ];
}

/**
 * @return array{bd:int,demand:string,supply:string,category_field:?string}|null
 */
function search_bd_config_from_bd(int $bd): ?array
{
    foreach (search_all_bd_configs() as $cfg) {
        if ((int) $cfg['bd'] === $bd) {
            return $cfg;
        }
    }

    return null;
}

/**
 * Имя услуги из справочника gruzchik (bd=3).
 */
function search_is_gruzchik_service_name(mysqli $conn, string $nameImg): bool
{
    if ($nameImg === '') {
        return false;
    }

    $stmt = $conn->prepare('SELECT 1 FROM gruzchik WHERE name = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();

    return $stmt->get_result()->num_rows > 0;
}

/** @return list<string> */
function search_load_city_names(mysqli $conn): array
{
    static $cache = null;
    if ($cache !== null) {
        return $cache;
    }

    $names = [];
    $result = $conn->query('SELECT name FROM cities ORDER BY CHAR_LENGTH(name) DESC');
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $name = trim((string) ($row['name'] ?? ''));
            if ($name !== '') {
                $names[] = $name;
            }
        }
    }
    $cache = $names;
    return $names;
}

function search_match_city_from_query(mysqli $conn, string $query): ?string
{
    $normalizedQuery = search_normalize_text($query);
    foreach (search_load_city_names($conn) as $cityName) {
        $normalizedCity = search_normalize_text($cityName);
        if ($normalizedCity === '') {
            continue;
        }
        if (mb_strpos($normalizedQuery, $normalizedCity, 0, 'UTF-8') !== false) {
            return $cityName;
        }
    }
    return null;
}

/** @return list<string> */
function search_load_all_category_names(mysqli $conn): array
{
    static $cache = null;
    if ($cache !== null) {
        return $cache;
    }

    $names = [];
    foreach (['vidg', 'vidt', 'gruzchik'] as $table) {
        $result = $conn->query("SELECT name FROM {$table} ORDER BY CHAR_LENGTH(name) DESC");
        if (!$result) {
            continue;
        }
        while ($row = $result->fetch_assoc()) {
            $name = trim((string) ($row['name'] ?? ''));
            if ($name !== '') {
                $names[] = $name;
            }
        }
    }

    usort($names, static function (string $a, string $b): int {
        return mb_strlen($b, 'UTF-8') <=> mb_strlen($a, 'UTF-8');
    });

    $cache = $names;
    return $cache;
}

/** @return list<string> */
function search_match_categories_from_query(mysqli $conn, string $query): array
{
    $normalizedQuery = search_normalize_text($query);
    $matched = [];
    foreach (search_load_all_category_names($conn) as $categoryName) {
        $normalizedCategory = search_normalize_text($categoryName);
        if ($normalizedCategory === '') {
            continue;
        }
        if (mb_strpos($normalizedQuery, $normalizedCategory, 0, 'UTF-8') !== false) {
            $matched[] = $categoryName;
        }
    }
    return $matched;
}

function search_text_score(array $row, string $query, string $side, ?string $categoryField): int
{
    if ($query === '') {
        return 0;
    }

    $filtered = search_query_words($query);
    if ($filtered === []) {
        return 0;
    }

    $fields = ['city', 'about'];
    if ($side === 'demand') {
        $fields[] = 'city1';
        $fields = array_merge($fields, ['maxgruz', 'vidt', 'vidk', 'zagr', 'typepr']);
    } else {
        $fields = array_merge($fields, ['marka', 'maxgruz', 'vidt', 'vidk', 'namefirm']);
    }

    $haystack = search_normalize_text(implode(' ', array_map(static function ($f) use ($row) {
        return isset($row[$f]) ? (string) $row[$f] : '';
    }, $fields)));

    $score = 0;
    foreach ($filtered as $word) {
        if ($categoryField && isset($row[$categoryField])) {
            $cat = search_normalize_text((string) $row[$categoryField]);
            if ($cat !== '' && mb_strpos($cat, $word, 0, 'UTF-8') !== false) {
                $score += 10;
                continue;
            }
        }
        foreach (['city', 'city1'] as $cityField) {
            if (!isset($row[$cityField])) {
                continue;
            }
            $cityVal = search_normalize_text((string) $row[$cityField]);
            if ($cityVal !== '' && mb_strpos($cityVal, $word, 0, 'UTF-8') !== false) {
                $score += 8;
                continue 2;
            }
        }
        foreach (['marka', 'vidk', 'vidt', 'maxgruz'] as $midField) {
            if (!isset($row[$midField])) {
                continue;
            }
            $mid = search_normalize_text((string) $row[$midField]);
            if ($mid !== '' && mb_strpos($mid, $word, 0, 'UTF-8') !== false) {
                $score += 5;
                continue 2;
            }
        }
        if ($haystack !== '' && mb_strpos($haystack, $word, 0, 'UTF-8') !== false) {
            $score += 3;
        }
    }

    return $score;
}

function search_compute_relevance(array $row, string $query, string $side, ?string $categoryField, ?float $priceMax): float
{
    $text = search_text_score($row, $query, $side, $categoryField);
    $rating = isset($row['avg_rating']) ? (float) $row['avg_rating'] : 0.0;
    $hasPhoto = !empty($row['img1']) ? 5 : 0;
    $recency = 0;
    if (!empty($row['created_at'])) {
        $ts = strtotime((string) $row['created_at']);
        if ($ts !== false) {
            $days = max(0, (time() - $ts) / 86400);
            $recency = max(0, 10 - min(10, $days));
        }
    }

    $pricePenalty = 0;
    if ($priceMax !== null) {
        $priceRaw = $row['cena'] ?? $row['cenahaurs'] ?? $row['cenasmena'] ?? null;
        $price = search_parse_price($priceRaw !== null ? (string) $priceRaw : null);
        if ($price !== null) {
            if ($price <= $priceMax) {
                $hasPhoto += 10;
            } else {
                $pricePenalty = 10;
            }
        }
    }

    return 0.30 * $text + 0.25 * ($text > 0 ? 25 : 0) + 0.20 * 20 + 0.15 * ($rating / 5.0 * 15) + 0.10 * $recency + $hasPhoto - $pricePenalty;
}

function search_encode_row_images(array &$row): void
{
    foreach (['img1', 'img2', 'img3', 'img4'] as $imgField) {
        if (!empty($row[$imgField])) {
            $row[$imgField] = base64_encode($row[$imgField]);
        }
    }
    foreach (['imgdoc1', 'imgdoc2', 'imgdoc3', 'imgdoc4'] as $doc) {
        unset($row[$doc]);
    }
    if (!empty($row['fotouser'])) {
        $row['fotouser'] = base64_encode($row['fotouser']);
    }
}

/**
 * Таблица объявления исполнителя — та же логика, что get_ads2_new.php.
 *
 * @return array{table:string,bd:int,condition:string,bind_name:bool}|null
 */
function search_resolve_get_ads2_table(mysqli $conn, string $nameImg): ?array
{
    $stmt = $conn->prepare('SELECT 1 FROM add_ob_gp WHERE maxgruz = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return ['table' => 'add_ob_gp', 'bd' => 1, 'condition' => 'AND a.maxgruz = ?', 'bind_name' => true];
    }

    $stmt = $conn->prepare('SELECT 1 FROM add_ob_vidt WHERE vidt = ? LIMIT 1');
    $stmt->bind_param('s', $nameImg);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return ['table' => 'add_ob_vidt', 'bd' => 2, 'condition' => 'AND a.vidt = ?', 'bind_name' => true];
    }

    $result = $conn->query('SELECT 1 FROM add_ob_gr LIMIT 1');
    if ($result && $result->num_rows > 0) {
        return ['table' => 'add_ob_gr', 'bd' => 3, 'condition' => '', 'bind_name' => false];
    }

    return null;
}

/**
 * Выборка объявлений исполнителей — копия get_ads2_new.php (legacy fallback).
 *
 * @param array<string,mixed> $params
 * @return array<int,array<string,mixed>>
 */
function search_fetch_supply_get_ads2(
    mysqli $conn,
    array $params,
    string $nameImg,
    string $city,
    bool $allCities
): array {
    $resolved = search_resolve_get_ads2_table($conn, $nameImg);
    if ($resolved === null) {
        return [];
    }

    $useId = '';
    if (isset($params['usersid']) && $params['usersid'] !== '') {
        $useId = (string) $params['usersid'];
    } elseif (isset($params['useId']) && $params['useId'] !== '') {
        $useId = (string) $params['useId'];
    }

    $table = $resolved['table'];
    $bd = (int) $resolved['bd'];
    $condition = $resolved['condition'];
    $bindName = (bool) $resolved['bind_name'];
    $cityLine = $allCities ? '' : 'AND TRIM(a.city) = ?';

    $sql = "
        SELECT a.*,
               {$bd} AS bd,
               u.idusers AS idusers,
               u.idusers AS review_user_id,
               u.fotouser,
               u.firstName,
               u.lastName,
               u.middleName,
               u.city AS userCity,
               u.phone,
               u.email,
               COUNT(r.user_id) AS reviewsCount,
               COUNT(r.user_id) AS review_count,
               COALESCE(AVG(r.rating), 0) AS avg_rating,
               CASE
                   WHEN EXISTS(
                       SELECT 1 FROM likes1 l
                       WHERE l.idusers = u.idusers
                         AND l.id = a.id
                         AND l.usersid = ?
                   ) THEN 'true'
                   ELSE 'false'
               END AS success
        FROM {$table} AS a
        LEFT JOIN users AS u ON a.iduser = u.idusers
        LEFT JOIN reviewsisp AS r ON u.idusers = r.user_id
        WHERE a.iduser IS NOT NULL
          AND a.iduser != ?
          AND (a.flag IS NULL OR a.flag = 1)
          {$cityLine}
          {$condition}
          " . search_sql_supply_deal_exclude($bd) . '
        GROUP BY a.id, u.idusers
        ORDER BY a.id DESC
    ';

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        return [];
    }

    // Порядок: likes.usersid, iduser!=, [city], [category], deal.user_idok
    if ($bindName) {
        if ($allCities) {
            $stmt->bind_param('ssss', $useId, $useId, $nameImg, $useId);
        } else {
            $stmt->bind_param('sssss', $useId, $useId, $city, $nameImg, $useId);
        }
    } elseif ($allCities) {
        $stmt->bind_param('sss', $useId, $useId, $useId);
    } else {
        $stmt->bind_param('ssss', $useId, $useId, $city, $useId);
    }

    $stmt->execute();
    $result = $stmt->get_result();
    if (!$result) {
        return [];
    }

    $rows = [];
    while ($row = $result->fetch_assoc()) {
        $rows[] = $row;
    }

    return $rows;
}

/**
 * @param array{bd:int,demand:string,supply:string,category_field:?string} $resolved
 * @param array<string,mixed> $params
 * @return array<int,array<string,mixed>>
 */
function search_fetch_rows_for_config(
    mysqli $conn,
    array $resolved,
    array $params,
    string $role,
    string $nameImg,
    string $city,
    bool $allCities,
    string $query,
    ?float $priceMax,
    string $cityTo
): array {
    $bd = $resolved['bd'];
    $side = $role === 'customer' ? 'supply' : 'demand';
    $table = $resolved[$side];
    $categoryField = $resolved['category_field'];
    $currentDate = date('Y-m-d');

    $useId = '';
    if (isset($params['usersid']) && $params['usersid'] !== '') {
        $useId = (string) $params['usersid'];
    } elseif (isset($params['useId']) && $params['useId'] !== '') {
        $useId = (string) $params['useId'];
    }

    $applyCityFilter = !$allCities && $city !== '';
    $cityLine = $applyCityFilter ? 'AND TRIM(a.city) = ?' : '';

    $categoryLine = '';
    if ($categoryField !== null && $nameImg !== '') {
        $categoryLine = "AND a.{$categoryField} = ?";
    }

    $cityToLine = '';
    if ($cityTo !== '' && $side === 'demand' && $bd === 1) {
        $cityToLine = 'AND a.city1 = ?';
    }

    $priceLine = '';
    if ($priceMax !== null && $side === 'demand') {
        $priceLine = 'AND (a.cena IS NULL OR a.cena = \'\' OR CAST(REPLACE(REPLACE(a.cena, \' \', \'\'), \',\', \'.\') AS DECIMAL(12,2)) <= ?)';
    } elseif ($priceMax !== null && $side === 'supply') {
        $priceLine = 'AND (a.cenahaurs IS NULL OR a.cenahaurs = \'\' OR CAST(REPLACE(REPLACE(a.cenahaurs, \' \', \'\'), \',\', \'.\') AS DECIMAL(12,2)) <= ?)';
    }

    $reviewsJoin = $side === 'supply'
        ? 'LEFT JOIN reviewsisp AS r ON u.idusers = r.user_id'
        : 'LEFT JOIN reviews AS r ON u.idusers = r.target_user_id';
    $reviewCountExpr = $side === 'supply' ? 'COUNT(r.user_id)' : 'COUNT(r.id)';
    $likesTable = $side === 'supply' ? 'likes1' : 'likes';

    $demandExtra = '';
    if ($side === 'demand') {
        $demandExtra = 'AND a.enddatez >= ?';
    }

    $supplyExtra = '';
    if ($side === 'supply') {
        $supplyExtra = 'AND (a.flag IS NULL OR a.flag = 1)';
    }

    $dealExclude = $side === 'demand'
        ? "AND NOT EXISTS (
            SELECT 1 FROM offer_data od_busy
            WHERE od_busy.iduser = a.id AND od_busy.bd = {$bd} AND od_busy.isp = 1
              AND (od_busy.status = 0 OR od_busy.status IS NULL)
        )
        AND NOT EXISTS (
            SELECT 1 FROM ordersglobal og
            WHERE CAST(og.order_id AS CHAR) = CAST(a.id AS CHAR)
              AND (og.bd IS NULL OR og.bd = {$bd} OR og.bd = 0)
              AND og.status = 'выполняется'
        )"
        : search_sql_supply_deal_exclude($bd);

    $sql = "
        SELECT a.*,
               {$bd} AS bd,
               u.idusers AS idusers,
               u.idusers AS review_user_id,
               u.fotouser,
               u.firstName,
               u.lastName,
               u.middleName,
               u.city AS userCity,
               u.phone,
               u.email,
               {$reviewCountExpr} AS reviewsCount,
               {$reviewCountExpr} AS review_count,
               COALESCE(AVG(r.rating), 0) AS avg_rating,
               CASE
                   WHEN EXISTS(
                       SELECT 1 FROM {$likesTable} l
                       WHERE l.idusers = u.idusers
                         AND l.id = a.id
                         AND l.usersid = ?
                   ) THEN 'true'
                   ELSE 'false'
               END AS success
        FROM {$table} AS a
        " . ($side === 'supply'
            ? 'LEFT JOIN users AS u ON a.iduser = u.idusers'
            : 'INNER JOIN users AS u ON a.iduser = u.idusers') . "
        {$reviewsJoin}
        WHERE a.iduser IS NOT NULL
          AND a.iduser != ?
          {$demandExtra}
          {$supplyExtra}
          {$cityLine}
          {$categoryLine}
          {$cityToLine}
          {$priceLine}
          {$dealExclude}
        GROUP BY a.id, u.idusers
    ";

    $bindTypes = '';
    $bindValues = [];

    $bindTypes .= 'ss';
    $bindValues[] = $useId;
    $bindValues[] = $useId;

    if ($side === 'supply') {
        $bindTypes .= 's';
        $bindValues[] = $useId;
    }

    if ($side === 'demand') {
        $bindTypes .= 's';
        $bindValues[] = $currentDate;
    }

    if ($applyCityFilter) {
        $bindTypes .= 's';
        $bindValues[] = $city;
    }
    if ($categoryLine !== '') {
        $bindTypes .= 's';
        $bindValues[] = $nameImg;
    }
    if ($cityToLine !== '') {
        $bindTypes .= 's';
        $bindValues[] = $cityTo;
    }
    if ($priceLine !== '') {
        $bindTypes .= 'd';
        $bindValues[] = $priceMax;
    }

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        return [];
    }
    $stmt->bind_param($bindTypes, ...$bindValues);
    $stmt->execute();
    $result = $stmt->get_result();

    $rows = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            if ($query !== '') {
                $textScore = search_text_score($row, $query, $side, $categoryField);
                if ($textScore < 3) {
                    continue;
                }
                $row['_text_score'] = $textScore;
            }
            $row['_relevance'] = search_compute_relevance($row, $query, $side, $categoryField, $priceMax);
            $rows[] = $row;
        }
    }

    return $rows;
}

/**
 * @param array<string,mixed> $params
 * @return array<int,array<string,mixed>>
 */
function search_services_query(mysqli $conn, array $params): array
{
    $role = isset($params['role']) ? (string) $params['role'] : '';
    $nameImg = isset($params['nameImg']) ? trim((string) $params['nameImg']) : '';
    $category = isset($params['category']) ? trim((string) $params['category']) : '';
    if ($nameImg === '' && $category !== '') {
        $nameImg = $category;
    }

    $city = isset($params['city']) ? trim((string) $params['city']) : '';
    $cityTo = isset($params['city_to']) ? trim((string) $params['city_to']) : '';
    $rawQuery = isset($params['q']) ? trim((string) $params['q']) : '';
    $query = search_normalize_text($rawQuery);
    $sort = isset($params['sort']) ? (string) $params['sort'] : 'relevance';
    $priceMax = isset($params['price_max']) && $params['price_max'] !== ''
        ? search_parse_price((string) $params['price_max'])
        : null;
    $page = max(1, (int) ($params['page'] ?? 1));
    $limit = min(50, max(1, (int) ($params['limit'] ?? 20)));
    $offset = ($page - 1) * $limit;

    $allCities = isset($params['all_cities']) && $params['all_cities'] === '1';
    $freeText = isset($params['free_text']) && $params['free_text'] === '1';

    if ($role !== 'customer' && $role !== 'performer') {
        return [];
    }

    $viewerId = crg_viewer_user_id_from_request($params);
    // Гость (0): просмотр выдачи разрешён; исключение «своих» и активных сделок не срабатывает
    $params['useId'] = (string) max(0, $viewerId);
    $params['usersid'] = (string) max(0, $viewerId);

    if ($nameImg === '' && search_has_meaningful_query($rawQuery)) {
        $freeText = true;
    }

    if ($freeText) {
        if (!search_has_meaningful_query($rawQuery)) {
            return [];
        }

        if ($city === '') {
            $detectedCity = search_match_city_from_query($conn, $rawQuery);
            if ($detectedCity !== null) {
                $city = $detectedCity;
            } else {
                $allCities = true;
            }
        }

        $matchedCategories = search_match_categories_from_query($conn, $rawQuery);
        $configs = [];
        if ($matchedCategories !== []) {
            foreach ($matchedCategories as $matchedName) {
                $resolved = $role === 'customer'
                    ? search_resolve_supply_category($conn, $matchedName)
                    : search_resolve_demand_category($conn, $matchedName);
                if ($resolved !== null) {
                    $configs[] = ['resolved' => $resolved, 'nameImg' => $matchedName];
                }
            }
        } else {
            foreach (search_all_bd_configs() as $resolved) {
                $configs[] = ['resolved' => $resolved, 'nameImg' => ''];
            }
        }

        $rows = [];
        foreach ($configs as $cfg) {
            $chunk = search_fetch_rows_for_config(
                $conn,
                $cfg['resolved'],
                $params,
                $role,
                $cfg['nameImg'],
                $city,
                $allCities,
                $query,
                $priceMax,
                $cityTo
            );
            foreach ($chunk as $row) {
                $rows[] = $row;
            }
        }
    } else {
        if ($nameImg === '') {
            return [];
        }

        $resolved = $role === 'customer'
            ? search_resolve_supply_category($conn, $nameImg)
            : search_resolve_demand_category($conn, $nameImg);
        if ($resolved === null) {
            return [];
        }

        if ($city === '' && !$allCities) {
            return [];
        }

        $categoryFilter = $nameImg;
        if (($resolved['category_field'] ?? null) === null) {
            $categoryFilter = '';
        }

        $rows = search_fetch_rows_for_config(
            $conn,
            $resolved,
            $params,
            $role,
            $categoryFilter,
            $city,
            $allCities,
            $query,
            $priceMax,
            $cityTo
        );

        if (
            $rows === []
            && $role === 'customer'
            && $nameImg !== ''
            && ($city !== '' || $allCities)
        ) {
            $rows = search_fetch_supply_get_ads2($conn, $params, $nameImg, $city, $allCities);
            if ($priceMax !== null) {
                $rows = array_values(array_filter(
                    $rows,
                    static function (array $row) use ($priceMax): bool {
                        $price = search_parse_price((string) ($row['cenahaurs'] ?? ''));
                        return $price === null || $price <= $priceMax;
                    }
                ));
            }
        }

        if (
            $rows === []
            && $role === 'performer'
            && $nameImg !== ''
            && ($city !== '' || $allCities)
        ) {
            $rows = search_fetch_demand_getads3($conn, $params, $nameImg, $city, $allCities);
            if ($priceMax !== null) {
                $rows = array_values(array_filter(
                    $rows,
                    static function (array $row) use ($priceMax): bool {
                        $price = search_parse_price((string) ($row['cena'] ?? ''));
                        return $price === null || $price <= $priceMax;
                    }
                ));
            }
        }
    }

    usort($rows, static function (array $a, array $b) use ($sort): int {
        switch ($sort) {
            case 'rating':
                $ra = (float) ($a['avg_rating'] ?? 0);
                $rb = (float) ($b['avg_rating'] ?? 0);
                if ($ra !== $rb) {
                    return $rb <=> $ra;
                }
                return ((int) ($b['reviewsCount'] ?? 0)) <=> ((int) ($a['reviewsCount'] ?? 0));
            case 'price':
                $pa = search_parse_price((string) ($a['cena'] ?? $a['cenahaurs'] ?? '')) ?? PHP_FLOAT_MAX;
                $pb = search_parse_price((string) ($b['cena'] ?? $b['cenahaurs'] ?? '')) ?? PHP_FLOAT_MAX;
                if ($pa !== $pb) {
                    return $pa <=> $pb;
                }
                return ((int) ($b['id'] ?? 0)) <=> ((int) ($a['id'] ?? 0));
            case 'date':
                $da = strtotime((string) ($a['created_at'] ?? '')) ?: (int) ($a['id'] ?? 0);
                $db = strtotime((string) ($b['created_at'] ?? '')) ?: (int) ($b['id'] ?? 0);
                return $db <=> $da;
            case 'relevance':
            default:
                $sa = (float) ($a['_relevance'] ?? 0);
                $sb = (float) ($b['_relevance'] ?? 0);
                if ($sa !== $sb) {
                    return $sb <=> $sa;
                }
                return ((int) ($b['id'] ?? 0)) <=> ((int) ($a['id'] ?? 0));
        }
    });

    $rows = array_slice($rows, $offset, $limit);

    foreach ($rows as &$row) {
        unset($row['_text_score'], $row['_relevance']);
        search_encode_row_images($row);
    }
    unset($row);

    return $rows;
}

/**
 * Счётчик доступных заявок заказчиков (demand) — те же фильтры, что в поиске исполнителя.
 */
function search_count_demand_for_config(
    mysqli $conn,
    array $resolved,
    string $useId,
    string $city,
    string $nameImg
): int {
    $bd = (int) $resolved['bd'];
    $table = $resolved['demand'];
    $categoryField = $resolved['category_field'];
    $currentDate = date('Y-m-d');
    $city = trim($city);

    $categoryLine = '';
    if ($categoryField !== null && $nameImg !== '') {
        $categoryLine = "AND a.{$categoryField} = ?";
    }

    $sql = "
        SELECT COUNT(DISTINCT a.id) AS cnt
        FROM {$table} AS a
        WHERE a.iduser IS NOT NULL
          AND a.iduser != ?
          AND a.enddatez >= ?
          AND TRIM(a.city) = ?
          {$categoryLine}
          " . search_sql_demand_user_exists() . "
          AND NOT EXISTS (
              SELECT 1 FROM offer_data od_busy
              WHERE od_busy.iduser = a.id AND od_busy.bd = {$bd} AND od_busy.isp = 1
                AND (od_busy.status = 0 OR od_busy.status IS NULL)
          )
          AND NOT EXISTS (
              SELECT 1 FROM ordersglobal og
              WHERE CAST(og.order_id AS CHAR) = CAST(a.id AS CHAR)
                AND (og.bd IS NULL OR og.bd = {$bd} OR og.bd = 0)
                AND og.status = 'выполняется'
          )
    ";

    $bindTypes = 'sss';
    $bindValues = [$useId, $currentDate, $city];
    if ($categoryLine !== '') {
        $bindTypes .= 's';
        $bindValues[] = $nameImg;
    }

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        return 0;
    }
    $stmt->bind_param($bindTypes, ...$bindValues);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();

    return (int) ($row['cnt'] ?? 0);
}

/**
 * @return array<string, int> city name => count
 */
function search_demand_counts_by_city(mysqli $conn, string $useId): array
{
    $counts = [];
    foreach (search_load_city_names($conn) as $cityName) {
        $counts[$cityName] = 0;
    }

    $currentDate = date('Y-m-d');

    foreach (search_all_bd_configs() as $resolved) {
        $bd = (int) $resolved['bd'];
        $table = $resolved['demand'];

        $sql = "
            SELECT TRIM(a.city) AS city_name, COUNT(DISTINCT a.id) AS cnt
            FROM {$table} AS a
            WHERE a.iduser IS NOT NULL
              AND a.iduser != ?
              AND a.enddatez >= ?
              " . search_sql_demand_user_exists() . "
              AND NOT EXISTS (
                  SELECT 1 FROM offer_data od_busy
                  WHERE od_busy.iduser = a.id AND od_busy.bd = {$bd} AND od_busy.isp = 1
                    AND (od_busy.status = 0 OR od_busy.status IS NULL)
              )
              AND NOT EXISTS (
                  SELECT 1 FROM ordersglobal og
                  WHERE CAST(og.order_id AS CHAR) = CAST(a.id AS CHAR)
                    AND (og.bd IS NULL OR og.bd = {$bd} OR og.bd = 0)
                    AND og.status = 'выполняется'
              )
            GROUP BY TRIM(a.city)
        ";

        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            continue;
        }
        $stmt->bind_param('ss', $useId, $currentDate);
        $stmt->execute();
        $result = $stmt->get_result();
        if (!$result) {
            continue;
        }
        while ($row = $result->fetch_assoc()) {
            $cityName = trim((string) ($row['city_name'] ?? ''));
            if ($cityName === '') {
                continue;
            }
            $counts[$cityName] = ($counts[$cityName] ?? 0) + (int) ($row['cnt'] ?? 0);
        }
    }

    return $counts;
}

/**
 * @return array<string, int> service name => count in city
 */
function search_demand_count_for_service(
    mysqli $conn,
    string $useId,
    string $city,
    string $serviceName
): int {
    if ($city === '' || $serviceName === '') {
        return 0;
    }

    if (search_is_gruzchik_service_name($conn, $serviceName)) {
        $resolved = search_bd_config_from_bd(3);
        if ($resolved === null) {
            return 0;
        }

        return search_count_demand_for_config($conn, $resolved, $useId, $city, '');
    }

    $resolved = search_resolve_demand_category($conn, $serviceName);
    if ($resolved === null || (int) ($resolved['bd'] ?? 0) === 3) {
        return 0;
    }

    return search_count_demand_for_config($conn, $resolved, $useId, $city, $serviceName);
}

/**
 * @return array<string, int> service name => count in city
 */
function search_demand_counts_by_service_in_city(mysqli $conn, string $useId, string $city): array
{
    $counts = [];
    foreach (search_load_all_category_names($conn) as $serviceName) {
        $counts[$serviceName] = 0;
    }

    if ($city === '') {
        return $counts;
    }

    $city = trim($city);
    $currentDate = date('Y-m-d');

    foreach (search_all_bd_configs() as $resolved) {
        $bd = (int) $resolved['bd'];
        $table = $resolved['demand'];
        $categoryField = $resolved['category_field'];

        if ($categoryField !== null) {
            $sql = "
                SELECT TRIM(a.{$categoryField}) AS service_name, COUNT(DISTINCT a.id) AS cnt
                FROM {$table} AS a
                WHERE a.iduser IS NOT NULL
                  AND a.iduser != ?
                  AND a.enddatez >= ?
                  AND TRIM(a.city) = ?
                  " . search_sql_demand_user_exists() . "
                  AND NOT EXISTS (
                      SELECT 1 FROM offer_data od_busy
                      WHERE od_busy.iduser = a.id AND od_busy.bd = {$bd} AND od_busy.isp = 1
                        AND (od_busy.status = 0 OR od_busy.status IS NULL)
                  )
                  AND NOT EXISTS (
                      SELECT 1 FROM ordersglobal og
                      WHERE CAST(og.order_id AS CHAR) = CAST(a.id AS CHAR)
                        AND (og.bd IS NULL OR og.bd = {$bd} OR og.bd = 0)
                        AND og.status = 'выполняется'
                  )
                GROUP BY TRIM(a.{$categoryField})
            ";
            $stmt = $conn->prepare($sql);
            if (!$stmt) {
                continue;
            }
            $stmt->bind_param('sss', $useId, $currentDate, $city);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result) {
                while ($row = $result->fetch_assoc()) {
                    $serviceName = trim((string) ($row['service_name'] ?? ''));
                    if ($serviceName === '') {
                        continue;
                    }
                    if (array_key_exists($serviceName, $counts)) {
                        $counts[$serviceName] = (int) ($row['cnt'] ?? 0);
                    }
                }
            }
            continue;
        }

        $total = search_count_demand_for_config($conn, $resolved, $useId, $city, '');
        search_apply_gruzchik_demand_counts($conn, $counts, $total);
    }

    return search_build_counts_map($counts, array_keys($counts));
}

/**
 * Счётчик объявлений исполнителей (supply) — те же фильтры, что в поиске заказчика.
 */
function search_count_supply_for_config(
    mysqli $conn,
    array $resolved,
    string $useId,
    string $city,
    string $nameImg
): int {
    $bd = (int) $resolved['bd'];
    $table = $resolved['supply'];
    $categoryField = $resolved['category_field'];

    $categoryLine = '';
    if ($categoryField !== null && $nameImg !== '') {
        $categoryLine = "AND a.{$categoryField} = ?";
    }

    $sql = "
        SELECT COUNT(DISTINCT a.id) AS cnt
        FROM {$table} AS a
        LEFT JOIN users AS u ON a.iduser = u.idusers
        WHERE a.iduser IS NOT NULL
          AND a.iduser != ?
          AND (a.flag IS NULL OR a.flag = 1)
          AND a.city = ?
          {$categoryLine}
          " . search_sql_supply_deal_exclude($bd) . '
    ';

    $bindTypes = 'sss';
    $bindValues = [$useId, $city, $useId];
    if ($categoryLine !== '') {
        $bindTypes = 'ssss';
        $bindValues = [$useId, $city, $nameImg, $useId];
    }

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        return 0;
    }
    $stmt->bind_param($bindTypes, ...$bindValues);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();

    return (int) ($row['cnt'] ?? 0);
}

/**
 * @return array<string, int> city name => count of performer ads
 */
function search_supply_counts_by_city(mysqli $conn, string $useId): array
{
    $counts = [];
    foreach (search_load_city_names($conn) as $cityName) {
        $counts[$cityName] = 0;
    }

    foreach (search_all_bd_configs() as $resolved) {
        $bd = (int) $resolved['bd'];
        $table = $resolved['supply'];

        $sql = "
            SELECT a.city AS city_name, COUNT(DISTINCT a.id) AS cnt
            FROM {$table} AS a
            LEFT JOIN users AS u ON u.idusers = a.iduser
            WHERE a.iduser IS NOT NULL
              AND a.iduser != ?
              AND (a.flag IS NULL OR a.flag = 1)
              " . search_sql_supply_deal_exclude($bd) . '
            GROUP BY a.city
        ';

        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            continue;
        }
        $stmt->bind_param('ss', $useId, $useId);
        $stmt->execute();
        $result = $stmt->get_result();
        if (!$result) {
            continue;
        }
        while ($row = $result->fetch_assoc()) {
            $cityName = trim((string) ($row['city_name'] ?? ''));
            if ($cityName === '') {
                continue;
            }
            $counts[$cityName] = ($counts[$cityName] ?? 0) + (int) ($row['cnt'] ?? 0);
        }
    }

    return $counts;
}

function search_supply_count_for_service(
    mysqli $conn,
    string $useId,
    string $city,
    string $serviceName
): int {
    if ($city === '' || $serviceName === '') {
        return 0;
    }

    $resolved = search_resolve_supply_category($conn, $serviceName);
    if ($resolved === null) {
        return 0;
    }

    $categoryFilter = '';
    if (($resolved['category_field'] ?? null) !== null) {
        $categoryFilter = $serviceName;
    }

    return search_count_supply_for_config($conn, $resolved, $useId, $city, $categoryFilter);
}

/**
 * @return array<string, int> service name => performer ads count in city
 */
function search_supply_counts_by_service_in_city(mysqli $conn, string $useId, string $city): array
{
    $catalog = search_load_all_category_names($conn);
    $raw = [];
    foreach ($catalog as $serviceName) {
        $raw[$serviceName] = search_supply_count_for_service($conn, $useId, $city, $serviceName);
    }

    return search_build_counts_map($raw, $catalog);
}

function search_core_version(): string
{
    $path = __FILE__;
    if (is_file($path)) {
        return 'search_services_core:' . date('Y-m-d', (int) filemtime($path));
    }

    return 'search_services_core:unknown';
}

function search_normalize_service_key(string $name): string
{
    return trim($name);
}

/**
 * @param array<string, int|string> $rawCounts
 * @param list<string> $catalogNames
 * @return array<string, int>
 */
function search_build_counts_map(array $rawCounts, array $catalogNames): array
{
    $byKey = [];
    foreach ($rawCounts as $key => $value) {
        $normalized = search_normalize_service_key((string) $key);
        if ($normalized === '') {
            continue;
        }
        $byKey[$normalized] = (int) $value;
    }

    $out = [];
    foreach ($catalogNames as $name) {
        $key = search_normalize_service_key($name);
        $out[$name] = $byKey[$key] ?? 0;
    }

    return $out;
}

/**
 * @return array<string, int> только услуги с count > 0
 */
function search_demand_breakdown_by_city(mysqli $conn, string $useId, string $city): array
{
    $all = search_demand_counts_by_service_in_city($conn, $useId, $city);

    return array_filter($all, static function (int $count): bool {
        return $count > 0;
    });
}

/**
 * @return array<string, int> только услуги с count > 0
 */
function search_supply_breakdown_by_city(mysqli $conn, string $useId, string $city): array
{
    $all = search_supply_counts_by_service_in_city($conn, $useId, $city);

    return array_filter($all, static function (int $count): bool {
        return $count > 0;
    });
}
