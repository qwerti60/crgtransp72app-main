<?php
header('Content-Type: application/json; charset=utf-8');

// Подключаемся к базе данных
require __DIR__ . '/load_databd.php'; // Предположительно файл databd.php содержит конфигурационные данные для подключения к БД

// Параметры, которые приходят извне (поддержка обоих ключей)
$useId = isset($_GET['idusers']) ? (int)$_GET['idusers'] : 0;
if ($useId <= 0 && isset($_GET['usersid'])) {
    $useId = (int)$_GET['usersid'];
}

// Проверка наличия обязательного параметра useId
if ($useId <= 0) {
    http_response_code(400);
    exit(json_encode(['message' => 'Параметр idusers/usersid отсутствует']));
}

// Подключение к базе данных
try {
    $conn = new mysqli($host, $username, $password, $dbname);

    if ($conn->connect_errno) {
        throw new Exception("Ошибка подключения к базе данных: " . $conn->connect_error);
    }

    // Настройка кодировки
    $conn->set_charset("utf8mb4");

    // Подготовленный SQL-запрос с подсчетом рейтинга и количеством отзывов
    $sql = "
SELECT
    u.idusers AS idusers,
    u.fotouser,
    u.firstName,
    u.lastName,
    u.middleName,
    u.city AS userCity,
    u.phone,
    u.email,
    'true' AS success,                                -- Строковая версия успеха
    AVG(rev.rating) AS avg_rating,                    -- Средний рейтинг
    COUNT(rev.id) AS reviewsCount                     -- Количество отзывов
FROM users AS u
LEFT JOIN reviews AS rev ON u.idusers = rev.target_user_id
WHERE u.idusers IN (
    SELECT DISTINCT idusers                            -- Уникальные пользователи из лайков
    FROM likes
    WHERE usersid = ?
)
GROUP BY u.idusers                                    -- Группируем по пользователю
ORDER BY u.idusers ASC";

    // Готовим запрос с параметрами
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception("Ошибка подготовки SQL: " . $conn->error);
    }
    $stmt->bind_param("i", $useId); // i означает integer-параметр

    // Выполняем запрос
    $stmt->execute();

    // Получаем результаты
    $result = $stmt->get_result();

    // Если есть результаты, формируем массив данных
    if ($result->num_rows > 0) {
        $data = array();
        while ($row = $result->fetch_assoc()) {
            // Преобразуем binary BLOB поля (изображения) в base64
            $fields_to_convert = ['fotouser'];

            foreach ($fields_to_convert as $field_name) {
                if (isset($row[$field_name]) && !is_null($row[$field_name])) {
                    $row[$field_name] = base64_encode($row[$field_name]);
                }
            }

            // Среднее значение рейтинга и количество отзывов уже включены в результат
            $data[] = $row;
        }

        // Отправляем данные в формате JSON
        echo json_encode($data);
    } else {
        echo json_encode(array()); // Если нет результатов, отправляем пустой массив
    }

    // Освобождаем память и закрываем соединение
    $stmt->free_result();
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['message' => 'Ошибка сервера: ' . $e->getMessage()]);
}
?>
