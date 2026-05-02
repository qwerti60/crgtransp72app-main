<?
// Определите заголовки для ответа
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Max-Age: 3600');
header('Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With');

// Подключение к базе данных
$connection = null;
$host = "localhost";
$username = "u2395188_apps72";
$password = "kR3iV2aA6gjU8nC9";
$db_name = "u2395188_apps";

try {
$connection = new PDO("mysql:host=" . $host . ";dbname=" . $db_name, $username, $password);
$connection->exec("set names utf8");
} catch(PDOException $exception) {
http_response_code(500);
echo json_encode(array("message" => "Ошибка подключения к базе данных."));
exit();
}

// Получаем отправленные данные
$data = json_decode(file_get_contents("php://input"));

if(
!empty($data->rollNum) &&
// Проверьте здесь все обязательные поля
!empty($data->password) // Пример проверки на наличие обязательного поля
) {
$query = "INSERT INTO users SET
rollNum = :rollNum,
statNum = :statNum,
firstName = :firstName,
lastName = :lastName,
middleName = :middleName,
city = :city,
phone = :phone,
email = :email,
password = :password,
namefirm = :namefirm,
innStr = :innStr,
ogrnStr = :ogrnStr,
kppStr = :kppStr,
vidt = :vidt,
marka = :marka,
godv = :godv,
maxgruz = :maxgruz,
dkuzov = :dkuzov,
shkuzov = :shkuzov,
vidk = :vidk,
cenahaurs = :cenahaurs,
cenasmena = :cenasmena,
cenakm = :cenakm";

$stmt = $connection->prepare($query);

// Clean additional fields...
$cleanMiddleName = htmlspecialchars(strip_tags($data->middleName));
$cleanCity = htmlspecialchars(strip_tags($data->city));
$cleanPhone = htmlspecialchars(strip_tags($data->phone));
$cleanEmail = htmlspecialchars(strip_tags($data->email));
$cleanPassword = htmlspecialchars(strip_tags($data->password)); // Make sure this gets hashed before it's actually saved if it's a user password
$cleanNameFirm = htmlspecialchars(strip_tags($data->namefirm));
$cleanInnStr = htmlspecialchars(strip_tags($data->innStr));
$cleanOgrnStr = htmlspecialchars(strip_tags($data->ogrnStr));
$cleanKppStr = htmlspecialchars(strip_tags($data->kppStr));
$cleanVidt = htmlspecialchars(strip_tags($data->vidt));
$cleanMarka = htmlspecialchars(strip_tags($data->marka));
$cleanGodv = htmlspecialchars(strip_tags($data->godv));
$cleanMaxgruz = htmlspecialchars(strip_tags($data->maxgruz));
$cleanDkuzov = htmlspecialchars(strip_tags($data->dkuzov));
$cleanShkuzov = htmlspecialchars(strip_tags($data->shkuzov));
$cleanVidk = htmlspecialchars(strip_tags($data->vidk));
$cleanCenahaurs = htmlspecialchars(strip_tags($data->cenahaurs));
$cleanCenasmena = htmlspecialchars(strip_tags($data->cenasmena));
$cleanCenakm = htmlspecialchars(strip_tags($data->cenakm));
// Continue binding the rest of your variables
$stmt->bindParam(':middleName', $cleanMiddleName);
$stmt->bindParam(':city', $cleanCity);
$stmt->bindParam(':phone', $cleanPhone);
$stmt->bindParam(':email', $cleanEmail);
$stmt->bindParam(':password', $cleanPassword); // Ensure password is securely hashed before it reaches this point if storing user passwords
$stmt->bindParam(':namefirm', $cleanNameFirm);
$stmt->bindParam(':innStr', $cleanInnStr);
$stmt->bindParam(':ogrnStr', $cleanOgrnStr);
$stmt->bindParam(':kppStr', $cleanKppStr);
$stmt->bindParam(':vidt', $cleanVidt);
$stmt->bindParam(':marka', $cleanMarka);
$stmt->bindParam(':godv', $cleanGodv);
$stmt->bindParam(':maxgruz', $cleanMaxgruz);
$stmt->bindParam(':dkuzov', $cleanDkuzov);
$stmt->bindParam(':shkuzov', $cleanShkuzov);
$stmt->bindParam(':vidk', $cleanVidk);
$stmt->bindParam(':cenahaurs', $cleanCenahaurs);
$stmt->bindParam(':cenasmena', $cleanCenasmena);
$stmt->bindParam(':cenakm', $cleanCenakm);

if($stmt->execute()) {
http_response_code(201); // Создано
echo json_encode(array("message" => "Пользователь был успешно зарегистрирован."));
} else {
http_response_code(503); // Сервис недоступен
echo json_encode(array("message" => "Невозможно зарегистрировать пользователя."));
}
} else {
// Ошибка в данных
http_response_code(400); // Неверный запрос
echo json_encode(array("message" => "Невозможно создать пользователя. Данные неполные."));
}
?>