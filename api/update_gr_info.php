<?php
declare(strict_types=1);

header('Content-Type: text/plain; charset=utf-8');

require __DIR__ . '/load_databd.php';
require __DIR__ . '/include/ad_image_update.php';

$id = (int) ($_POST['id'] ?? 0);
if ($id <= 0) {
    http_response_code(400);
    echo 'Не указан id объявления';
    exit;
}

$conn = new mysqli($host, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo 'Connection failed';
    exit;
}
$conn->set_charset('utf8mb4');

$iduser = (string) ($_POST['iduser'] ?? '');
$city = (string) ($_POST['city'] ?? '');
$startdate = (string) ($_POST['startdate'] ?? '');
$enddate = (string) ($_POST['enddate'] ?? '');
$cena = (string) ($_POST['cena'] ?? '');
$about = (string) ($_POST['about'] ?? '');
$enddatez = (string) ($_POST['enddatez'] ?? '');

$sets = [
    'iduser = ?',
    'city = ?',
    'startdate = ?',
    'enddate = ?',
    'cena = ?',
    'about = ?',
    'enddatez = ?',
];
$params = [$iduser, $city, $startdate, $enddate, $cena, $about, $enddatez];
$types = 'sssssss';

crg_append_listing_photo_updates($sets, $params, $types);

$params[] = $id;
$types .= 'i';

$sql = 'UPDATE ordersg SET ' . implode(', ', $sets) . ' WHERE id = ?';
$stmt = $conn->prepare($sql);
if ($stmt === false) {
    http_response_code(500);
    echo 'Prepare failed: ' . $conn->error;
    exit;
}

$stmt->bind_param($types, ...$params);

if ($stmt->execute()) {
    echo 'Record updated successfully';
} else {
    http_response_code(500);
    echo 'Error updating record: ' . $stmt->error;
}

$stmt->close();
$conn->close();
