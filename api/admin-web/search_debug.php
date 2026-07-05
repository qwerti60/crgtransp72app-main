<?php
declare(strict_types=1);

/**
 * Диагностика счётчиков поиска (только админка).
 * См. docs/search_future_ru.md §2.4
 */
require_once __DIR__ . '/bootstrap_web.php';

header('Content-Type: application/json; charset=utf-8');

$pdo = tp_admin_web_require_login_json();

$corePath = TP_PUBLIC_ROOT . '/include/search_services_core.php';
if (!is_readable($corePath)) {
    http_response_code(503);
    echo json_encode(['success' => false, 'error' => 'search_services_core not deployed'], JSON_UNESCAPED_UNICODE);
    exit;
}
require_once $corePath;

require_once TP_PUBLIC_ROOT . '/databd.php';

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'DB connect'], JSON_UNESCAPED_UNICODE);
    exit;
}
$conn->set_charset('utf8mb4');

$params = array_merge($_GET, $_POST);
$role = isset($params['role']) && (string) $params['role'] === 'customer' ? 'customer' : 'performer';
$useId = isset($params['useId']) ? trim((string) $params['useId']) : '';
$city = isset($params['city']) ? trim((string) $params['city']) : '';
$nameImg = isset($params['nameImg']) ? trim((string) $params['nameImg']) : '';

$out = [
    'success' => true,
    'core_version' => search_core_version(),
    'role' => $role,
    'useId' => $useId,
    'city' => $city,
    'nameImg' => $nameImg,
    'resolved_category' => null,
    'counts' => [],
    'filters' => [],
];

$resolved = null;

if ($useId === '') {
    $out['error'] = 'useId required';
    echo json_encode($out, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    $conn->close();
    exit;
}

if ($nameImg !== '') {
    $resolved = $role === 'customer'
        ? search_resolve_supply_category($conn, $nameImg)
        : search_resolve_demand_category($conn, $nameImg);
    $out['resolved_category'] = $resolved;
}

if ($city !== '') {
    if ($role === 'customer') {
        $out['counts']['city_total'] = ($out['counts']['city_total'] ?? 0)
            + array_sum(search_supply_counts_by_city($conn, $useId) ?: []);
        $services = search_supply_counts_by_service_in_city($conn, $useId, $city);
        $out['counts']['services_in_city'] = $services;
        $out['counts']['breakdown'] = search_supply_breakdown_by_city($conn, $useId, $city);
        if ($nameImg !== '') {
            $out['counts']['selected_service'] = $services[$nameImg] ?? search_supply_count_for_service($conn, $useId, $city, $nameImg);
        }
    } else {
        $cities = search_demand_counts_by_city($conn, $useId);
        $out['counts']['city_total'] = (int) ($cities[$city] ?? 0);
        $services = search_demand_counts_by_service_in_city($conn, $useId, $city);
        $out['counts']['services_in_city'] = $services;
        $out['counts']['breakdown'] = search_demand_breakdown_by_city($conn, $useId, $city);
        if ($nameImg !== '') {
            $out['counts']['selected_service'] = $services[$nameImg] ?? search_demand_count_for_service($conn, $useId, $city, $nameImg);
        }
    }
}

if ($resolved !== null && $city !== '' && $role === 'performer') {
    $bd = (int) ($resolved['bd'] ?? 0);
    $table = (string) ($resolved['demand'] ?? '');
    $currentDate = date('Y-m-d');
    $escapedCity = $conn->real_escape_string($city);

    $steps = [
        'all_in_table_city' => "SELECT COUNT(*) AS c FROM {$table} WHERE TRIM(city) = '{$escapedCity}'",
        'not_own' => "SELECT COUNT(*) AS c FROM {$table} WHERE TRIM(city) = '{$escapedCity}' AND iduser IS NOT NULL AND iduser != '{$conn->real_escape_string($useId)}'",
        'enddate_ok' => "SELECT COUNT(*) AS c FROM {$table} WHERE TRIM(city) = '{$escapedCity}' AND iduser IS NOT NULL AND iduser != '{$conn->real_escape_string($useId)}' AND enddatez >= '{$currentDate}'",
    ];

    foreach ($steps as $label => $sql) {
        $r = $conn->query($sql);
        $out['filters'][$label] = $r ? (int) ($r->fetch_assoc()['c'] ?? 0) : null;
    }

    $out['filters']['after_core_filters'] = search_count_demand_for_config(
        $conn,
        $resolved,
        $useId,
        $city,
        ($resolved['category_field'] ?? null) !== null ? $nameImg : ''
    );
}

echo json_encode($out, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
$conn->close();
