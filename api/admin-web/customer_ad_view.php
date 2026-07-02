<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_ads.php');
tp_admin_web_require_include('admin_users.php');
tp_admin_web_require_include('admin_reviews.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$type = crg_admin_customer_type_from_request();
if ($type === null) {
    http_response_code(400);
    exit;
}
$cfg = crg_admin_customer_ad_config($type);
assert($cfg !== null);

$id = (int) ($_GET['id'] ?? 0);
$row = crg_admin_ad_get($pdo, $cfg, $id);
if ($row === null) {
    http_response_code(404);
    echo 'Не найдено';
    exit;
}

$userId = (int) ($row['iduser'] ?? 0);
$userRow = crg_admin_user_get($pdo, $userId);
$userName = $userRow !== null ? crg_admin_user_display_name($userRow) : ('#' . $userId);

tp_admin_web_layout_start('Заявка #' . $id, 'customer_ads', $adminLogin !== '' ? $adminLogin : null);
?>
<p>
    <a class="btn secondary small" href="customer_ads.php?type=<?= tp_admin_web_h($type) ?>">← К списку</a>
    <a class="btn secondary small" href="user_edit.php?id=<?= $userId ?>"><?= tp_admin_web_h($userName) ?></a>
    <a class="btn small" href="customer_ad_edit.php?type=<?= tp_admin_web_h($type) ?>&id=<?= $id ?>">Изменить</a>
</p>

<div class="card">
    <?php crg_admin_ad_render_details_table($pdo, $row, 'customer', $type, 'Заказчик'); ?>
</div>

<div class="card">
    <p class="meta"><strong>Фото</strong> — нажмите на превью для просмотра в полном размере</p>
    <?php crg_admin_ad_render_media_gallery('customer', $type, $id, $row, crg_admin_ad_customer_image_slots()); ?>
</div>

<div class="card">
    <p class="meta"><strong>Отклики исполнителей</strong></p>
    <?php
    $offers = crg_admin_customer_ad_offers($pdo, $id, crg_admin_bd_for_customer_type($type));
    crg_admin_render_offer_rows_table($offers, 'Исполнитель', true);
    ?>
</div>

<?php crg_admin_render_customer_reviews($pdo, $userId); ?>

<form method="post" action="customer_ad_delete.php" onsubmit="return confirm('Удалить заявку?');">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
    <input type="hidden" name="type" value="<?= tp_admin_web_h($type) ?>">
    <input type="hidden" name="id" value="<?= $id ?>">
    <button type="submit" name="delete_ad" value="1" class="btn secondary">Удалить</button>
</form>
<?php
tp_admin_web_layout_end();
