<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require __DIR__ . '/load_databd.php';
$dbUser = $username;
$dbPassword = $password;
$dbName = $dbname;

$userId = isset($_POST['userId']) ? (int)$_POST['userId'] : 0;
$orderId = isset($_POST['orderId']) ? trim((string)$_POST['orderId']) : '';
$days = isset($_POST['days']) ? (int)$_POST['days'] : 30;
$days = $days > 0 ? $days : 30;
$amountRub = isset($_POST['amountRub']) ? (int)$_POST['amountRub'] : 0;
$packageId = isset($_POST['packageId']) ? (int)$_POST['packageId'] : 0;
$promoCode = isset($_POST['promoCode']) ? strtoupper(trim((string)$_POST['promoCode'])) : '';
$discountRub = 0;
$promoId = 0;

if ($userId <= 0 || $orderId === '') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Некорректные параметры userId/orderId',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

require_once __DIR__ . '/include/subscription_packages.php';
require_once __DIR__ . '/include/performer_finances.php';

try {
    $pdo = new PDO(
        "mysql:host={$host};dbname={$dbName};charset=utf8mb4",
        $dbUser,
        $dbPassword,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Ошибка подключения к базе данных',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($packageId > 0) {
    $pkg = crg_subscription_package_by_id($pdo, $packageId);
    if ($pkg !== null && (int) ($pkg['is_active'] ?? 0) === 1) {
        $days = max(1, (int) ($pkg['days'] ?? $days));
        $basePrice = (int) ($pkg['price_rub'] ?? 0);
        if ($promoCode !== '') {
            $promoRes = crg_promo_validate($pdo, $promoCode, $basePrice, $userId);
            if (($promoRes['ok'] ?? false) === true) {
                $discountRub = (int) ($promoRes['discount_rub'] ?? 0);
                $amountRub = (int) ($promoRes['amount_rub'] ?? $basePrice);
                $promoId = (int) (($promoRes['promo']['id'] ?? 0));
            } else {
                $amountRub = $basePrice > 0 ? $basePrice : $amountRub;
            }
        } elseif ($amountRub <= 0 && $basePrice > 0) {
            $amountRub = $basePrice;
        }
    }
}

$mysqli = new mysqli($host, $dbUser, $dbPassword, $dbName);
if ($mysqli->connect_error) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Ошибка подключения к базе данных',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$mysqli->set_charset('utf8mb4');

$checkSql = "SELECT `id`, `date` FROM `subscriptions` WHERE `iduser` = ? ORDER BY `id` DESC LIMIT 1";
$checkStmt = $mysqli->prepare($checkSql);
if (!$checkStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Ошибка подготовки запроса проверки',
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

$checkStmt->bind_param('i', $userId);
$checkStmt->execute();
$checkResult = $checkStmt->get_result();
$existingRow = $checkResult ? $checkResult->fetch_assoc() : null;
$checkStmt->close();

$baseDate = new DateTime('now');
if ($existingRow && !empty($existingRow['date'])) {
    $existingDate = DateTime::createFromFormat('Y-m-d', (string)$existingRow['date']);
    if ($existingDate instanceof DateTime) {
        $today = new DateTime('today');
        // Продлеваем от текущей даты окончания, если она в будущем.
        $baseDate = $existingDate > $today ? clone $existingDate : new DateTime('now');
    }
}

$newDate = (clone $baseDate)->modify('+' . $days . ' days')->format('Y-m-d');

if ($existingRow && isset($existingRow['id'])) {
    $subId = (int)$existingRow['id'];
    $updateSql = "UPDATE `subscriptions` SET `date` = ?, `payment` = ?, `count` = COALESCE(`count`, 0) + 1 WHERE `id` = ?";
    $updateStmt = $mysqli->prepare($updateSql);
    if (!$updateStmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Ошибка подготовки запроса обновления',
        ], JSON_UNESCAPED_UNICODE);
        $mysqli->close();
        exit;
    }

    $updateStmt->bind_param('ssi', $newDate, $orderId, $subId);
    $ok = $updateStmt->execute();
    $updateStmt->close();
} else {
    $insertSql = "INSERT INTO `subscriptions` (`iduser`, `date`, `payment`, `count`) VALUES (?, ?, ?, 1)";
    $insertStmt = $mysqli->prepare($insertSql);
    if (!$insertStmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Ошибка подготовки запроса создания',
        ], JSON_UNESCAPED_UNICODE);
        $mysqli->close();
        exit;
    }

    $insertStmt->bind_param('iss', $userId, $newDate, $orderId);
    $ok = $insertStmt->execute();
    $insertStmt->close();
}

if (!$ok) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Не удалось сохранить подписку',
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

try {
    crg_finances_log_subscription_payment(
        $pdo,
        $userId,
        $orderId,
        $amountRub,
        $days,
        $newDate,
        $packageId > 0 ? $packageId : null,
        $promoCode !== '' ? $promoCode : null,
        $discountRub
    );
    if ($promoId > 0) {
        crg_promo_redeem($pdo, $promoId, $userId, $packageId > 0 ? $packageId : null, $orderId);
    }
} catch (Throwable $e) {
    // Журнал оплат не блокирует успешное продление подписки.
}

echo json_encode([
    'success' => true,
    'date' => $newDate,
    'payment' => $orderId,
    'days' => $days,
    'amount_rub' => $amountRub,
    'discount_rub' => $discountRub,
], JSON_UNESCAPED_UNICODE);

$mysqli->close();
