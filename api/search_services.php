<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/databd.php';

$corePath = __DIR__ . '/include/search_services_core.php';
if (!is_file($corePath)) {
    http_response_code(503);
    echo json_encode(
        ['error' => 'search_services_core not deployed', 'items' => []],
        JSON_UNESCAPED_UNICODE
    );
    exit;
}
require_once $corePath;

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка подключения'], JSON_UNESCAPED_UNICODE);
    exit;
}
$conn->set_charset('utf8mb4');

$params = array_merge($_GET, $_POST);
$data = search_services_query($conn, $params);

echo json_encode($data, JSON_UNESCAPED_UNICODE);
$conn->close();
