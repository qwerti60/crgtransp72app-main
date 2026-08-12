<?php
declare(strict_types=1);

require_once __DIR__ . '/load_databd.php';
$user = $username;
$pass = $password;
$db = $dbname;

header('Content-Type: text/plain; charset=utf-8');

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    http_response_code(500);
    echo 'Connection failed: ' . $conn->connect_error;
    exit;
}
$conn->set_charset('utf8mb4');

function crg_upload_blob_vidt(string $field): ?string
{
    if (!isset($_FILES[$field]) || !is_array($_FILES[$field])) {
        return null;
    }
    $err = (int) ($_FILES[$field]['error'] ?? UPLOAD_ERR_NO_FILE);
    if ($err !== UPLOAD_ERR_OK) {
        return null;
    }
    $tmp = (string) ($_FILES[$field]['tmp_name'] ?? '');
    if ($tmp === '' || !is_uploaded_file($tmp)) {
        return null;
    }
    $data = file_get_contents($tmp);

    return $data === false ? null : $data;
}

$iduser = (int) ($_POST['iduser'] ?? 0);
if ($iduser <= 0) {
    http_response_code(400);
    echo 'Error: iduser is required';
    exit;
}

$city = (string) ($_POST['city'] ?? '');
$vidt = (string) ($_POST['vidt'] ?? '');
$cenahaurs = (string) ($_POST['cenahaurs'] ?? '');
$cenasmena = (string) ($_POST['cenasmena'] ?? '');
$cenakm = (string) ($_POST['cenakm'] ?? '');

$img1 = crg_upload_blob_vidt('img1');
$img2 = crg_upload_blob_vidt('img2');
$img3 = crg_upload_blob_vidt('img3');
$img4 = crg_upload_blob_vidt('img4');
$imgDoc1 = crg_upload_blob_vidt('imgDoc1');
$imgDoc2 = crg_upload_blob_vidt('imgDoc2');
$imgDoc3 = crg_upload_blob_vidt('imgDoc3');
$imgDoc4 = crg_upload_blob_vidt('imgDoc4');

$stmt = $conn->prepare(
    'INSERT INTO add_ob_vidt (iduser, city, vidt, cenahaurs, cenasmena, cenakm, img1, img2, img3, img4, imgdoc1, imgdoc2, imgdoc3, imgdoc4, flag) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)'
);
if (!$stmt) {
    http_response_code(500);
    echo 'Error: ' . $conn->error;
    $conn->close();
    exit;
}

$stmt->bind_param(
    'isssssssssssss',
    $iduser,
    $city,
    $vidt,
    $cenahaurs,
    $cenasmena,
    $cenakm,
    $img1,
    $img2,
    $img3,
    $img4,
    $imgDoc1,
    $imgDoc2,
    $imgDoc3,
    $imgDoc4
);

if ($stmt->execute()) {
    $adId = (int) $conn->insert_id;
    require_once __DIR__ . '/include/ad_auto_moderation.php';
    crg_ad_auto_moderate_hook('vidt', $adId, $iduser, [
        'city' => $city,
        'vidt' => $vidt,
    ], [$img1, $img2, $img3, $img4]);
    echo 'New record created successfully';
} else {
    http_response_code(500);
    echo 'Error: ' . $stmt->error;
}

$stmt->close();
$conn->close();
