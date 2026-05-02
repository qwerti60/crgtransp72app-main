<?php
header('Content-Type: application/json');

include 'databd.php'; // Убедитесь, что здесь правильный путь к файлу


try {
    $conn = new PDO("mysql:host={$host};dbname={$dbname};charset=utf8", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
  
  
    // Получаем данные из запроса
    $idusers = $_POST['idusers'];     // Пользовательский ID
    $bd = $_POST['bd'];               // Раздел заказа
    $iduserp = $_POST['iduserp'];     // Дополнительный идентификатор

    // Проверяем наличие обязательных параметров
    if (!isset($idusers) || !isset($bd) || !isset($iduserp)) {
        throw new Exception("Отсутствуют обязательные параметры");
    }

    // SQL-запрос для автоматического переключения значения поля isp
    $sql = "
        UPDATE offer_data
        SET isp = CASE
                    WHEN isp = 0 THEN 1
                    ELSE 0
                  END
        WHERE iduser = :idusers AND iduserp = :iduserp
          AND bd = :bd
    "; // Удалила условие по полю bd

    // Подготовленный оператор
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(':idusers', $idusers);
    $stmt->bindParam(':bd', $bd);
    $stmt->bindParam(':iduserp', $iduserp);

    // Выполняем обновление
    $result = $stmt->execute();

    if ($result) {
        echo json_encode(['message' => 'Данные успешно обновлены']);
    } else {
        echo json_encode(['error' => 'Ошибка обновления данных']);
    }
} catch (PDOException | Exception $e) {
    die(json_encode(['error' => 'Ошибка обработки запроса: ' . $e->getMessage()]));
}
?>