<?php
include 'databd.php';

$truckId = isset($_POST['id']) ? (int) $_POST['id'] : 0;
$bd = isset($_POST['bd']) ? (int) $_POST['bd'] : 0;

$tableMap = [
    1 => 'orders',
    2 => 'orderst',
    3 => 'ordersg',
];

if ($truckId <= 0 || !isset($tableMap[$bd])) {
    echo 'Отсутствуют обязательные параметры';
    exit;
}

$conn = new mysqli($host, $username, $password, $dbname);

if ($conn->connect_error) {
    die('Ошибка подключения: ' . $conn->connect_error);
}

$conn->begin_transaction();

try {
    $table = $tableMap[$bd];
    $sqlOrderDelete = "DELETE FROM {$table} WHERE id = ?";
    $stmtOrder = $conn->prepare($sqlOrderDelete);
    $stmtOrder->bind_param('i', $truckId);
    $stmtOrder->execute();
    $stmtOrder->close();

    // Принятые предложения (status = 1) оставляем — они нужны для истории заказов.
    $sqlOfferDelete = 'DELETE FROM offer_data WHERE iduser = ? AND bd = ? AND status = 0';
    $stmtOffer = $conn->prepare($sqlOfferDelete);
    $stmtOffer->bind_param('ii', $truckId, $bd);
    $stmtOffer->execute();
    $stmtOffer->close();

    $conn->commit();
    echo 'Записи успешно удалены';
} catch (Exception $e) {
    $conn->rollback();
    echo 'Ошибка при удалении записей: ' . $e->getMessage();
}

$conn->close();
