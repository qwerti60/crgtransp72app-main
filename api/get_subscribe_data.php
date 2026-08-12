<?php
header("Content-Type: application/json");

require __DIR__ . '/load_databd.php'; // Убедитесь, что здесь правильный путь к файлу

$db = new mysqli($host, $username, $password, $dbname);

//$iduser = isset($_GET['iduser']) ? $_GET['iduser'] : '';
$iduser = isset($_GET['iduser']) ? intval($_GET['iduser']) : 0;

if (empty($iduser)) {
    echo json_encode(['error' => 'UserID is required']);
    exit;
}

// Подключение к базе данных
//$db = new mysqli("localhost", "username", "password", "database_name");

$query = $db->prepare('SELECT date FROM subscriptions WHERE iduser = ?');
$query->bind_param('i', $iduser);
$query->execute();

$result = $query->get_result();
if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $date = $row['date'];
    echo json_encode(['message' => "Ваша подписка оформлена до $date"]);
} else {
    echo json_encode(['message' => 'Вы еще не оформляли подписку']);
}

?>
