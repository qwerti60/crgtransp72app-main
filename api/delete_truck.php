
<?php
require __DIR__ . '/load_databd.php';

// Получаем данные из POST-запроса
$truckId = intval($_POST['id']);

// Проверка наличия необходимого параметра
if (empty($truckId)) {
    echo 'Отсутствует идентификатор записи';
    exit;
}

// Создание соединения с базой данных
$conn = new mysqli($servername, $username, $password, $dbname);

// Проверка успешного соединения
if ($conn->connect_error) {
    die('Ошибка подключения: ' . $conn->connect_error);
}

// Начинаем транзакцию для защиты целостности данных
$conn->begin_transaction();

try {
    // Шаг 1: Удаляем запись из таблицы orders
    $sql_orders_delete = "DELETE FROM add_ob_gp WHERE id = ?";
    $stmt_orders = $conn->prepare($sql_orders_delete);
    $stmt_orders->bind_param("i", $truckId);
    $stmt_orders->execute();

    // Шаг 2: Удаляем запись из таблицы orderst
    $sql_orderst_delete = "DELETE FROM add_ob_gr WHERE id = ?";
    $stmt_orderst = $conn->prepare($sql_orderst_delete);
    $stmt_orderst->bind_param("i", $truckId);
    $stmt_orderst->execute();

    // Шаг 3: Удаляем запись из таблицы ordersg
    $sql_ordersg_delete = "DELETE FROM add_ob_vidt WHERE id = ?";
    $stmt_ordersg = $conn->prepare($sql_ordersg_delete);
    $stmt_ordersg->bind_param("i", $truckId);
    $stmt_ordersg->execute();

    // Шаг 4: Удаляем соответствующую запись из таблицы offer_data
    $sql_offer_delete = "DELETE FROM offer_data WHERE iduser = ?";
    $stmt_offer = $conn->prepare($sql_offer_delete);
    $stmt_offer->bind_param("i", $truckId);
    $stmt_offer->execute();

    // Сообщаем об успехе
    $conn->commit();
    echo "Записи успешно удалены";
} catch (Exception $e) {
    // Откатываем изменения в случае ошибки
    $conn->rollback();
    echo "Ошибка при удалении записей: " . $e->getMessage();
}

// Закрываем ресурсы
$stmt_orders->close();
$stmt_orderst->close();
$stmt_ordersg->close();
$stmt_offer->close();
$conn->close();
?>