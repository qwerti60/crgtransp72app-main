<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/databd.php';

$corePath = __DIR__ . '/include/search_services_core.php';
if (!is_file($corePath)) {
    http_response_code(503);
    echo json_encode(
        ['success' => false, 'error' => 'search_services_core not deployed'],
        JSON_UNESCAPED_UNICODE
    );
    exit;
}
require_once $corePath;

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Ошибка подключения'], JSON_UNESCAPED_UNICODE);
    exit;
}
$conn->set_charset('utf8mb4');

$params = array_merge($_GET, $_POST);
$useId = '0';
if (isset($params['useId']) && (string) $params['useId'] !== '') {
    $useId = (string) $params['useId'];
} elseif (isset($params['usersid']) && (string) $params['usersid'] !== '') {
    $useId = (string) $params['usersid'];
}
if ((int) $useId < 0) {
    $useId = '0';
}

$city = isset($params['city']) ? trim((string) $params['city']) : '';
$role = isset($params['role']) ? trim((string) $params['role']) : 'performer';
if ($role !== 'customer') {
    $role = 'performer';
}

$withBreakdown = isset($params['breakdown']) && (string) $params['breakdown'] === '1';

try {
    $payload = [
        'success' => true,
        'core_version' => search_core_version(),
        'role' => $role,
        'cities' => [],
        'services' => [],
    ];

    if ($role === 'customer') {
        $payload['role'] = 'customer';
        $payload['cities'] = search_supply_counts_by_city($conn, $useId);
        if ($city !== '') {
            $payload['services'] = search_supply_counts_by_service_in_city($conn, $useId, $city);
            if ($withBreakdown) {
                $payload['city_breakdown'] = [
                    $city => search_supply_breakdown_by_city($conn, $useId, $city),
                ];
            }
        }
    } else {
        $payload['role'] = 'performer';
        $payload['cities'] = search_demand_counts_by_city($conn, $useId);
        if ($city !== '') {
            $payload['services'] = search_demand_counts_by_service_in_city($conn, $useId, $city);
            if ($withBreakdown) {
                $payload['city_breakdown'] = [
                    $city => search_demand_breakdown_by_city($conn, $useId, $city),
                ];
            }
        }
    }

    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Ошибка подсчёта'], JSON_UNESCAPED_UNICODE);
}

$conn->close();
