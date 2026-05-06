<?php
header("Content-Type: application/json");

include 'databd.php';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    if (empty($_POST['fcm_token'])) {
        echo json_encode(['success' => false, 'message' => 'FCM token is missing']);
        exit;
    }

    $fcmToken = $_POST['fcm_token'];

    $stmt = $pdo->prepare("SELECT idusers FROM users WHERE fcm_token = :fcm_token LIMIT 1");
    $stmt->execute([':fcm_token' => $fcmToken]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode(['success' => false, 'message' => 'Account not found']);
        exit;
    }

    $userId = (int)$user['idusers'];

    $pdo->beginTransaction();

    $deleteByUserColumns = [
        'likes' => ['idusers', 'usersid'],
        'likes1' => ['idusers', 'usersid'],
        'reviews' => ['user_id', 'target_user_id'],
        'reviewsisp' => ['user_id', 'target_user_id'],
        'offer_data' => ['iduserp'],
        'ordersglobal' => ['user_id', 'user_idok'],
        'subscriptions' => ['iduser'],
        'add_ob_gp' => ['iduser'],
        'add_ob_vidt' => ['iduser'],
        'add_ob_gr' => ['iduser'],
        'orders' => ['iduser'],
        'orderst' => ['iduser'],
        'ordersg' => ['iduser'],
    ];

    foreach ($deleteByUserColumns as $table => $columns) {
        foreach ($columns as $column) {
            $deleteStmt = $pdo->prepare("DELETE FROM `$table` WHERE `$column` = :user_id");
            $deleteStmt->execute([':user_id' => $userId]);
        }
    }

    $deleteUser = $pdo->prepare("DELETE FROM users WHERE idusers = :user_id");
    $deleteUser->execute([':user_id' => $userId]);

    $pdo->commit();

    echo json_encode(['success' => true, 'message' => 'Account deleted']);
} catch (Throwable $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }

    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>
