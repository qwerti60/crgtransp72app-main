<?php
require __DIR__ . '/load_databd.php'; // Подключаемся к файлу конфигурации базы данных

$idusers = isset($_GET['idusers']) ? $_GET['idusers'] : ''; // Получаем ID пользователя

// Создаем подключение
$conn = new mysqli($host, $username, $password, $dbname);

// Проверяем подключение
if ($conn->connect_error) {
    die("Ошибка подключения: " . $conn->connect_error);
}

// Устанавливаем корректную кодировку
$conn->set_charset("utf8");

// Простой SQL-запрос для извлечения всех записей из таблицы ordersg
$sql = "SELECT * FROM orders WHERE id=? ORDER BY created_at DESC";

$stmt = $conn->prepare($sql); // Готовим запрос

if (!$stmt) {
    die("Ошибка подготовки запроса: " . $conn->error);
}

$stmt->bind_param("s", $idusers); // Привязываем параметр
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
        
        $fetchData[] = $row;       // Добавляем строку в итоговый массив
    }
    
    header('Content-Type: application/json'); // Устанавливаем заголовок для вывода JSON
    echo json_encode($fetchData);              // Отправляем данные в формате JSON
} else {
    echo json_encode([]);                      // Если нет данных, возвращаем пустой массив
}

// Закрываем соединение
$stmt->close();
$conn->close();
?>