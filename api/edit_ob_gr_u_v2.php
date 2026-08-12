<?php
require __DIR__ . '/load_databd.php'; // Подключаемся к файлу конфигурации базы данных

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0; // ID объявления
$idusers = isset($_GET['idusers']) ? (int)$_GET['idusers'] : 0; // ID пользователя

// Создаем подключение
$conn = new mysqli($host, $username, $password, $dbname);

// Проверяем подключение
if ($conn->connect_error) {
    die("Ошибка подключения: " . $conn->connect_error);
}

// Устанавливаем корректную кодировку
$conn->set_charset("utf8");

// Поиск по id объявления (приоритет), иначе по id пользователя
if ($id > 0) {
    $sql = "SELECT * FROM add_ob_gr WHERE id=? ORDER BY created_at DESC";
    $bindValue = $id;
} else {
    $sql = "SELECT * FROM add_ob_gr WHERE iduser=? ORDER BY created_at DESC";
    $bindValue = $idusers;
}

$stmt = $conn->prepare($sql); // Готовим запрос

if (!$stmt) {
    die("Ошибка подготовки запроса: " . $conn->error);
}

$stmt->bind_param("i", $bindValue); // Привязываем параметр
$stmt->execute();                 // Выполняем запрос
$result = $stmt->get_result();    // Получаем результат

$fetchData = [];                  // Массив для хранения данных

if ($result->num_rows > 0) {      // Если есть записи
    while ($row = $result->fetch_assoc()) {
        // Преобразуем binary-данные изображений в Base64
        $row['img1'] = $row['img1'] !== null ? base64_encode($row['img1']) : null;
        $row['img2'] = $row['img2'] !== null ? base64_encode($row['img2']) : null;
        $row['img3'] = $row['img3'] !== null ? base64_encode($row['img3']) : null;
        $row['img4'] = $row['img4'] !== null ? base64_encode($row['img4']) : null;
        $row['imgdoc1'] = $row['imgdoc1'] !== null ? base64_encode($row['imgdoc1']) : null;
        $row['imgdoc2'] = $row['imgdoc2'] !== null ? base64_encode($row['imgdoc2']) : null;
        $row['imgdoc3'] = $row['imgdoc3'] !== null ? base64_encode($row['imgdoc3']) : null;
        $row['imgdoc4'] = $row['imgdoc4'] !== null ? base64_encode($row['imgdoc4']) : null;
        
        $fetchData[] = $row;       // Добавляем строку в итоговый массив
    }
    
    header('Content-Type: application/json; charset=utf-8'); // Устанавливаем заголовок для вывода JSON
    echo json_encode($fetchData);              // Отправляем данные в формате JSON
} else {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([]);                      // Если нет данных, возвращаем пустой массив
}

// Закрываем соединение
$stmt->close();
$conn->close();
?>
