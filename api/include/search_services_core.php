<?php
/**
 * Ядро поиска услуг (docs/search_logic_ru.md).
 * role=customer → объявления исполнителей (supply)
 * role=performer → объявления заказчиков (demand)
 */

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

/** @return list<array{bd:int,demand:string,supply:string,category_field:?string}> */
function search_all_bd_configs(): array
{
    return [
        ['bd' => 1, 'demand' => 'orders', 'supply' => 'add_ob_gp', 'category_field' => 'maxgruz'],
        ['bd' => 2, 'demand' => 'orderst', 'supply' => 'add_ob_vidt', 'category_field' => 'vidt'],
        ['bd' => 3, 'demand' => 'ordersg', 'supply' => 'add_ob_gr', 'category_field' => null],
    ];
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
    $cityLine = $applyCityFilter ? 'AND a.city = ?' : '';

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
            INNER JOIN offer_data od2 ON od2.id = og.idoffer AND od2.bd = {$bd}
            WHERE CAST(og.order_id AS CHAR) = CAST(a.id AS CHAR)
              AND og.status IN ('выполняется', 'выполнен')
        )"
        : "AND NOT EXISTS (
            SELECT 1 FROM ordersglobal og
            INNER JOIN offer_dataf odf ON odf.id = og.idoffer AND odf.bd = {$bd}
            WHERE CAST(og.order_id AS CHAR) = CAST(a.id AS CHAR)
              AND og.user_idok = ?
              AND og.status = 'выполняется'
        )";

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
        INNER JOIN users AS u ON a.iduser = u.idusers
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
                $resolved = search_resolve_category($conn, $matchedName);
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

        $resolved = search_resolve_category($conn, $nameImg);
        if ($resolved === null) {
            return [];
        }

        if ($city === '' && !$allCities) {
            return [];
        }

        $rows = search_fetch_rows_for_config(
            $conn,
            $resolved,
            $params,
            $role,
            $nameImg,
            $city,
            $allCities,
            $query,
            $priceMax,
            $cityTo
        );
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
