<?php
// Настройки подключения к базе данных

$host = "localhost";
$user = "u2395188_apps72";
$pass = "kR3iV2aA6gjU8nC9";
$db = "u2395188_apps";
$charset = 'utf8mb4';
// Создание соединения
$conn = new mysqli($host, $user, $pass, $db);

// Проверка соединения
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
// Установить кодировку utf8 для обмена данными в этом формате
if (!$conn->set_charset("utf8")) {
    printf("Error loading character set utf8: %s\n", $conn->error);
} 
// Предположим у вас есть соединение с базой данных $conn

$idUser = $_GET['iduser'] ?? ''; // Получение iduser из GET, если отсутствует, используется пустая строка

if (!$idUser) {
    echo "ID пользователя не указан";
    exit;
}

// Обработка нажатия на ссылку изменения состояния объявления
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $table = $_POST['table'];
    $id = $_POST['id'];
    $flag = isset($_POST['publish']) ? 1 : 0;

    $updateSql = "UPDATE `$table` SET `flag`=$flag WHERE `id`=? AND `iduser`=?";
    $stmt = $conn->prepare($updateSql);
    $stmt->bind_param("ss", $id, $idUser);
    $stmt->execute();

    header('Location: '.$_SERVER['PHP_SELF'].'?iduser='.$idUser);
    exit;
}

// Функция для получения данных из таблицы
function getData($conn, $table, $idUser) {
    $sql = "SELECT * FROM `$table` WHERE `iduser`=?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $idUser);
    $stmt->execute();
    return $stmt->get_result(); // Получение результатов запроса
}

// Получение данных
$dataObGp = getData($conn, "add_ob_gp", $idUser);
$dataObGr = getData($conn, "add_ob_gr", $idUser);
$dataObVidt = getData($conn, "add_ob_vidt", $idUser);

// Функция для отображения изображений
function displayImage($imgData) {
    if (!empty($imgData)) {
        return '<a href="data:image/jpeg;base64,'.base64_encode($imgData).'" target="_blank"><img src="data:image/jpeg;base64,'.base64_encode($imgData).'" width="50" height="50"></a>';
    }
    return '';
}

// Функция для отображения ссылок
function displayLink($link) {
    if (!empty($link)) {
        return "<a href='${Config.baseUrl}/api/$link' target='_blank'>Ссылка</a>";
    }
    return '';
}

// Функция для вывода данных в виде HTML-таблицы
function renderTable($data, $table) {
    global $conn;
    $columnNamesMap = [
        'fotouser' => 'Фото',
        'firstName' => 'Имя',
        'lastName' => 'Фамилия',
        'middleName' => 'Отчество',
        'city' => 'Город',
        'phone' => 'Телефон',
        'email' => 'E-mail',
        'password' => 'Пароль',
        'namefirm' => 'Организация',
        'innStr' => 'ИНН',
        'ogrnStr' => 'ОГРН',
        'kppStr' => 'КПП',
        'vidt' => 'Вид техники',
        'marka' => 'Марка авто',
        'godv' => 'Год выпуска',
        'maxgruz' => 'макс грузоподъемность',
        'dkuzov' => 'Длинна кузова',
        'shkuzov' => 'Ширина кузова',
        'vidk' => 'Вид кузова',
        'cenahaurs' => 'Цена за час',
        'cenasmena' => 'Цена за смену',
        'cenakm' => 'Цена за км',
        'img1' => 'Фото 1',
        'img2' => 'Фото 2',
        'img3' => 'Фото 3',
        'img4' => 'Фото 4',
        'imgdoc1' => 'Документ 1',
        'imgdoc2' => 'Документ 2',
        'imgdoc3' => 'Документ 3',
        'imgdoc4' => 'Документ 4',
        'created_at' => 'Создаано',
        'flag' => 'Состояние' // Название новой колонки
    ];

    if ($data->num_rows > 0) {
        // Добавляем заголовки столбцов
        echo "<tr style='background-color:#D3D3D3;'>"; // Используем светло-серый фон для заголовков
        $fields = $data->fetch_fields(); // Получаем поля
        foreach ($fields as $field) {
            // Проверяем сопоставление названия поля в $columnNamesMap, если существует, используем его, иначе оставляем оригинальное
            $displayName = array_key_exists($field->name, $columnNamesMap) ? $columnNamesMap[$field->name] : $field->name;
            
            // Выводим название каждого поля как заголовок столбца
            echo "<th>".htmlspecialchars($displayName)."</th>";
        }
        echo "</tr>";
        
        // Переменная для чередования цвета фона строк
        $rowColor = true;
        // Выводим данные
        while ($row = $data->fetch_assoc()) {
            echo '<form method="post" action="">'; // Формируем форму для каждой строки
            echo '<input type="hidden" name="table" value="'.$table.'">';
            echo '<input type="hidden" name="id" value="'.$row['id'].'">';
            echo '<tr'.($rowColor ? ' style="background-color:#f0f5f7;"' : '').'>';
            foreach ($row as $key => $value) {
                if ($key === 'flag') {
                    // Определяем состояние объявления и формируем соответствующую ссылку
                    if ($value == 0) {
                        echo '<td><button type="submit" name="publish">Опубликовать</button></td>';
                    } else {
                        echo '<td><button type="submit" name="unpublish">Снять с публикации</button></td>';
                    }
                } elseif (in_array($key, ['img1', 'img2', 'img3', 'img4'])) {
                    echo '<td>'.displayImage($value).'</td>';
                } elseif (in_array($key, ['imgdoc1', 'imgdoc2', 'imgdoc3', 'imgdoc4'])) { // Для ссылок
                    echo '<td>'.displayLink($value).'</td>';
                } else { // Для остальных данных
                    echo '<td>'.htmlspecialchars($value).'</td>';
                }
            }
            echo '</tr>';
            echo '</form>';
            $rowColor = !$rowColor; // Смена фона строки
        }
    } else {
        // Если данных нет, печатаем сообщение
        echo "<tr><td colspan='100%'>Нет данных для отображения</td></tr>";
    }
}

// Начало встраивания HTML
echo '<table border="0" style="background-color: #FCC485;">';
echo '<tr><th colspan="100%">Объявления грузоперевозки</th></tr>';
renderTable($dataObGp, 'add_ob_gp'); // Отрисовка данных таблицы add_ob_gp
echo '</table><br>';
echo '<table border="0" style="background-color: #FCC485;">';
echo '<tr><th colspan="100%">Объявления спецтехники</th></tr>';
renderTable($dataObVidt, 'add_ob_vidt'); // Отрисовка данных таблицы add_ob_vidt
echo '</table><br>';
echo '<table border="0" style="background-color: #FCC485;">';
echo '<tr><th colspan="100%">Объявления грузчиков</th></tr>';
renderTable($dataObGr, 'add_ob_gr'); // Отрисовка данных таблицы add_ob_vidt
echo '</table>';
?>
