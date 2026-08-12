<?php
require_once __DIR__ . '/include/ad_image_update.php';

require __DIR__ . '/load_databd.php';
$user = $username;
$pass = $password;
$db = $dbname;

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die('Connection failed: ' . $conn->connect_error);
}
$conn->set_charset('utf8');

$id = (int) ($_POST['id'] ?? 0);
$iduser = (string) ($_POST['iduser'] ?? '');
$city = (string) ($_POST['city'] ?? '');
$cenahaurs = (string) ($_POST['cenahaurs'] ?? '');
$cenasmena = (string) ($_POST['cenasmena'] ?? '');
$cenakm = (string) ($_POST['cenakm'] ?? '');

if ($id <= 0) {
    die('Не указан id объявления');
}

$sets = [
    'iduser = ?',
    'city = ?',
    'cenahaurs = ?',
    'cenasmena = ?',
    'cenakm = ?',
];
$params = [$iduser, $city, $cenahaurs, $cenasmena, $cenakm];
$types = 'sssss';

crg_append_performer_photo_updates($sets, $params, $types);

$params[] = $id;
$types .= 'i';

$sql = 'UPDATE add_ob_gr SET ' . implode(', ', $sets) . ' WHERE id = ?';
$stmt = $conn->prepare($sql);
if (!$stmt) {
    die('Prepare failed: ' . $conn->error);
}

$stmt->bind_param($types, ...$params);

if ($stmt->execute()) {
    echo 'Record updated successfully';
} else {
    echo 'Error: ' . $stmt->error;
}

$stmt->close();
$conn->close();
