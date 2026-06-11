<?php
header("Content-Type: application/json");

include 'databd.php';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $token = $_POST['fcm_token'] ?? $_POST['token'] ?? '';
    if ($token === '') {
        echo json_encode(['success' => false, 'message' => 'Token is missing']);
        exit;
    }

    require_once __DIR__ . '/token_auth.php';

    $userId = resolveUserIdFromToken($pdo, $token);
    if ($userId === null) {
        echo json_encode(['success' => false, 'message' => 'Account not found']);
        exit;
    }

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
