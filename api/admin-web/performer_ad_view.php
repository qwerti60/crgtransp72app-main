<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_ads.php');
tp_admin_web_require_include('admin_users.php');
tp_admin_web_require_include('admin_reviews.php');
tp_admin_web_require_include('admin_mail.php');
tp_admin_web_require_include('fcm_push.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$type = crg_admin_performer_type_from_request();
if ($type === null) {
    http_response_code(400);
    echo 'Неизвестный тип';
    exit;
}
$cfg = crg_admin_performer_ad_config($type);
assert($cfg !== null);

$id = (int) ($_GET['id'] ?? 0);
$row = crg_admin_ad_get($pdo, $cfg, $id);
if ($row === null) {
    http_response_code(404);
    echo 'Объявление не найдено';
    exit;
}

$flashErr = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['reject_ad'])) {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу.';
    } else {
        $rejectMessage = trim((string) ($_POST['reject_message'] ?? ''));
        if (mb_strlen($rejectMessage) < 5) {
            $flashErr = 'Укажите пояснение для исполнителя (не менее 5 символов).';
        } else {
            $userIdPost = (int) ($row['iduser'] ?? 0);
            $notifyResult = crg_admin_reject_performer_ad_notify($pdo, $cfg, $id, $userIdPost, $rejectMessage);
            if ($notifyResult['ok'] ?? false) {
                $_SESSION['admin_web_flash_ok'] = crg_admin_reject_notify_flash_message($notifyResult);
                header(
                    'Location: performer_ad_view.php?type=' . rawurlencode($type) . '&id=' . $id . '&rejected=1',
                    true,
                    303
                );
                exit;
            }
            $flashErr = (string) ($notifyResult['error'] ?? 'Не удалось отправить уведомления');
        }
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['set_flag'])) {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF';
    } else {
        $newFlag = (int) ($_POST['flag'] ?? 1) === 1 ? 1 : 0;
        $userIdPost = (int) ($row['iduser'] ?? 0);

        if ($newFlag === 1) {
            $notifyResult = crg_admin_approve_performer_ad_notify($pdo, $cfg, $id, $userIdPost);
            if ($notifyResult['ok'] ?? false) {
                $_SESSION['admin_web_flash_ok'] = crg_admin_approve_notify_flash_message($notifyResult);
                header(
                    'Location: performer_ad_view.php?type=' . rawurlencode($type) . '&id=' . $id . '&approved=1',
                    true,
                    303
                );
                exit;
            }
            $flashErr = (string) ($notifyResult['error'] ?? 'Не удалось отправить уведомления');
        } else {
            $res = crg_admin_performer_ad_set_flag($pdo, $cfg, $id, 0);
            if ($res === true) {
                header('Location: performer_ad_view.php?type=' . rawurlencode($type) . '&id=' . $id . '&saved=1', true, 303);
                exit;
            }
            $flashErr = is_string($res) ? $res : 'Ошибка';
        }
    }
}

if ($flashErr === '' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $row = crg_admin_ad_get($pdo, $cfg, $id) ?? $row;
}

$flag = (int) ($row['flag'] ?? 0);
$userId = (int) ($row['iduser'] ?? 0);
$userRow = crg_admin_user_get($pdo, $userId);
$userName = $userRow !== null ? crg_admin_user_display_name($userRow) : ('#' . $userId);
$userEmail = $userRow !== null ? trim((string) ($userRow['email'] ?? '')) : '';
$userHasPush = crg_fcm_user_device_token($pdo, $userId) !== null;
$userCanNotify = ($userEmail !== '' && filter_var($userEmail, FILTER_VALIDATE_EMAIL)) || $userHasPush;

$flashOk = '';
if (isset($_SESSION['admin_web_flash_ok']) && is_string($_SESSION['admin_web_flash_ok'])) {
    $flashOk = $_SESSION['admin_web_flash_ok'];
    unset($_SESSION['admin_web_flash_ok']);
}

tp_admin_web_layout_start('Объявление #' . $id, 'performer_ads', $adminLogin !== '' ? $adminLogin : null);
?>
<p>
    <a class="btn secondary small" href="performer_ads.php?type=<?= tp_admin_web_h($type) ?>">← К списку</a>
    <a class="btn secondary small" href="user_edit.php?id=<?= $userId ?>"><?= tp_admin_web_h($userName) ?></a>
    <a class="btn small" href="performer_ad_edit.php?type=<?= tp_admin_web_h($type) ?>&id=<?= $id ?>">Изменить</a>
</p>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } elseif (isset($_GET['approved'])) { ?><p class="ok">Объявление опубликовано.</p><?php } ?>

<div class="card">
    <p>
        <?php if ($flag === 1) { ?>
            <span class="badge badge-ok">Опубликовано</span>
        <?php } else { ?>
            <span class="badge badge-pending">На проверке</span>
        <?php } ?>
    </p>
    <?php if ($flag === 0) { ?>
        <div class="card" style="margin:0;padding:0;border:none;box-shadow:none">
            <?php if (!$userCanNotify) { ?>
                <p class="warn">Нет e-mail и push-токена приложения — уведомить исполнителя нельзя. Пользователь должен хотя бы раз войти в приложение или указать e-mail.</p>
            <?php } else { ?>
                <p class="meta">При одобрении или отклонении будет отправлено:<?php if ($userEmail !== '') { ?> письмо на <?= tp_admin_web_h($userEmail) ?><?php } ?><?php if ($userEmail !== '' && $userHasPush) { ?> и<?php } ?><?php if ($userHasPush) { ?> push в приложение<?php } ?>.</p>
                <form method="post" action="" style="margin-bottom:1rem" onsubmit="return confirm('Опубликовать объявление и отправить исполнителю e-mail и push?');">
                    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                    <input type="hidden" name="set_flag" value="1">
                    <input type="hidden" name="flag" value="1">
                    <button type="submit" class="btn">Одобрить и опубликовать</button>
                </form>
                <?php crg_admin_render_performer_ad_reject_form(); ?>
            <?php } ?>
        </div>
    <?php } else { ?>
        <form method="post" action="" style="margin-bottom:1rem">
            <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
            <input type="hidden" name="set_flag" value="1">
            <input type="hidden" name="flag" value="0">
            <button type="submit" class="btn secondary">Снять с публикации (без уведомления)</button>
        </form>
        <?php if ($userCanNotify) { ?>
            <div class="card" style="margin:0;padding:0;border:none;box-shadow:none">
                <p class="meta">Отклонить опубликованное объявление — исполнителю уйдёт e-mail<?php if ($userHasPush) { ?> и push<?php } ?> с пояснением, объявление снимется с публикации.</p>
                <?php crg_admin_render_performer_ad_reject_form(); ?>
            </div>
        <?php } ?>
    <?php } ?>

    <?php crg_admin_ad_render_details_table($pdo, $row, 'performer', $type, 'Исполнитель'); ?>
</div>

<div class="card">
    <p class="meta"><strong>Фото и документы</strong> — нажмите на превью для просмотра в полном размере</p>
    <?php crg_admin_ad_render_media_gallery('performer', $type, $id, $row, crg_admin_ad_image_columns()); ?>
</div>

<?php if ($flag === 1) { ?>
<div class="card">
    <p class="meta"><strong>Предложения заказчиков</strong></p>
    <?php
    $proposals = crg_admin_performer_ad_proposals($pdo, $id, crg_admin_bd_for_performer_type($type));
    crg_admin_render_offer_rows_table($proposals, 'Заказчик', false);
    ?>
</div>
<?php } ?>

<?php crg_admin_render_performer_reviews($pdo, $userId); ?>

<form method="post" action="performer_ad_delete.php" onsubmit="return confirm('Удалить объявление?');">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
    <input type="hidden" name="type" value="<?= tp_admin_web_h($type) ?>">
    <input type="hidden" name="id" value="<?= $id ?>">
    <button type="submit" name="delete_ad" value="1" class="btn secondary">Удалить объявление</button>
</form>
<?php
tp_admin_web_layout_end();
