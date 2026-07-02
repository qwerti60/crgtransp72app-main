<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_subscriptions.php');
tp_admin_web_require_include('admin_password_service.php');
tp_admin_web_require_include('admin_auth.php');

$pdo = tp_admin_web_require_login();
$bearer = (string) ($_SESSION['admin_web_token'] ?? '');
$account = tp_admin_session_from_bearer($pdo, $bearer);
if ($account === null) {
    header('Location: login.php', true, 302);
    exit;
}

$adminId = (int) $account['id'];
$adminLogin = (string) $account['login'];
$adminEmail = (string) ($account['email'] ?? '');

$configRow = crg_admin_subscription_config_row($pdo);
$days = (int) ($configRow['days'] ?? 30);
$priceRub = (int) ($configRow['price_rub'] ?? 300);
$subUpdatedAt = (string) ($configRow['updated_at'] ?? '');

$flashErr = '';
$flashOk = '';
$tableExists = crg_admin_subscription_config_table_exists($pdo);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу и повторите.';
    } else {
        $action = (string) ($_POST['action'] ?? '');

        if ($action === 'save_subscription') {
            $days = (int) ($_POST['days'] ?? 0);
            $priceRub = (int) ($_POST['price_rub'] ?? 0);
            $res = crg_admin_subscription_config_save($pdo, $days, $priceRub);
            if ($res === true) {
                header('Location: settings.php?saved=sub', true, 303);
                exit;
            }
            $flashErr = is_string($res) ? $res : 'Ошибка сохранения тарифа';
        } elseif ($action === 'save_email') {
            $adminEmail = trim((string) ($_POST['email'] ?? ''));
            $res = crg_admin_account_update_email($pdo, $adminId, $adminEmail);
            if ($res === true) {
                header('Location: settings.php?saved=email', true, 303);
                exit;
            }
            $flashErr = is_string($res) ? $res : 'Ошибка сохранения e-mail';
        } elseif ($action === 'change_password') {
            $old = (string) ($_POST['old_password'] ?? '');
            $p1 = (string) ($_POST['new_password'] ?? '');
            $p2 = (string) ($_POST['new_password2'] ?? '');
            $res = tp_admin_password_change_with_old($pdo, $adminId, $old, $p1, $p2);
            if ($res === true) {
                $_SESSION = [];
                if (session_status() === PHP_SESSION_ACTIVE) {
                    session_destroy();
                }
                header('Location: login.php?pw=1', true, 303);
                exit;
            }
            $flashErr = is_string($res) ? $res : 'Ошибка смены пароля';
        } elseif ($action === 'request_otp') {
            $r = tp_admin_password_request_reset_otp($pdo, $adminLogin);
            if ($r['ok'] === true) {
                $flashOk = (string) $r['message'];
            } else {
                $flashErr = (string) $r['message'];
            }
        } elseif ($action === 'reset_code') {
            $code = (string) ($_POST['code'] ?? '');
            $p1 = (string) ($_POST['new_password'] ?? '');
            $p2 = (string) ($_POST['new_password2'] ?? '');
            $res = tp_admin_password_reset_logged_in_with_code($pdo, $adminLogin, $code, $p1, $p2);
            if ($res === true) {
                $_SESSION = [];
                if (session_status() === PHP_SESSION_ACTIVE) {
                    session_destroy();
                }
                header('Location: login.php?pw=1', true, 303);
                exit;
            }
            $flashErr = is_string($res) ? $res : 'Ошибка смены пароля';
        }
    }
}

if (isset($_GET['saved'])) {
    $saved = (string) $_GET['saved'];
    if ($saved === 'sub') {
        $flashOk = 'Тариф подписки сохранён. Новые значения сразу видны в приложении.';
        $configRow = crg_admin_subscription_config_row($pdo);
        $days = (int) ($configRow['days'] ?? $days);
        $priceRub = (int) ($configRow['price_rub'] ?? $priceRub);
        $subUpdatedAt = (string) ($configRow['updated_at'] ?? '');
    } elseif ($saved === 'email') {
        $flashOk = 'E-mail учётной записи сохранён.';
        $refreshed = tp_admin_session_from_bearer($pdo, $bearer);
        if ($refreshed !== null) {
            $adminEmail = (string) ($refreshed['email'] ?? '');
        }
    }
}

$csrf = tp_admin_web_csrf_token();
$minLen = (int) TP_ADMIN_PASSWORD_MIN_LEN;

tp_admin_web_layout_start('Настройки', 'settings', $adminLogin !== '' ? $adminLogin : null);
?>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>

<div class="card">
    <p class="meta"><strong>Учётная запись администратора</strong></p>
    <p class="meta">Логин: <strong><?= tp_admin_web_h($adminLogin) ?></strong></p>
    <p class="meta">E-mail нужен для восстановления пароля по коду из письма (на странице входа и здесь).</p>

    <form method="post" action="">
        <input type="hidden" name="csrf" value="<?= tp_admin_web_h($csrf) ?>">
        <input type="hidden" name="action" value="save_email">
        <label class="b" for="email">E-mail</label>
        <input class="in" type="email" name="email" id="email" required maxlength="255"
               value="<?= tp_admin_web_h($adminEmail) ?>" autocomplete="email">
        <div class="form-actions">
            <button type="submit" class="btn secondary">Сохранить e-mail</button>
        </div>
    </form>
</div>

<div class="card">
    <p class="meta"><strong>Смена пароля</strong></p>
    <p class="meta">После смены пароля сессия завершается — войдите снова.</p>

    <form method="post" action="" autocomplete="off">
        <input type="hidden" name="csrf" value="<?= tp_admin_web_h($csrf) ?>">
        <input type="hidden" name="action" value="change_password">
        <label class="b" for="old_password">Текущий пароль</label>
        <input class="in" type="password" name="old_password" id="old_password" required maxlength="256" autocomplete="current-password">
        <label class="b" for="new_password">Новый пароль (не короче <?= $minLen ?> символов)</label>
        <input class="in" type="password" name="new_password" id="new_password" required minlength="<?= $minLen ?>" maxlength="256" autocomplete="new-password">
        <label class="b" for="new_password2">Повторите новый пароль</label>
        <input class="in" type="password" name="new_password2" id="new_password2" required minlength="<?= $minLen ?>" maxlength="256" autocomplete="new-password">
        <div class="form-actions">
            <button type="submit" class="btn">Сменить пароль</button>
        </div>
    </form>
</div>

<div class="card">
    <p class="meta"><strong>Сброс пароля по коду из e-mail</strong></p>
    <p class="meta">Если забыли текущий пароль — сначала сохраните e-mail выше, затем запросите код.</p>

    <form method="post" action="" style="margin-bottom:1rem">
        <input type="hidden" name="csrf" value="<?= tp_admin_web_h($csrf) ?>">
        <input type="hidden" name="action" value="request_otp">
        <button type="submit" class="btn secondary">Выслать код на e-mail</button>
    </form>

    <form method="post" action="" autocomplete="off">
        <input type="hidden" name="csrf" value="<?= tp_admin_web_h($csrf) ?>">
        <input type="hidden" name="action" value="reset_code">
        <label class="b" for="code">Код из письма</label>
        <input class="in" type="text" name="code" id="code" required maxlength="6" pattern="[0-9]{6}" inputmode="numeric" placeholder="000000">
        <label class="b" for="reset_new_password">Новый пароль</label>
        <input class="in" type="password" name="new_password" id="reset_new_password" required minlength="<?= $minLen ?>" maxlength="256" autocomplete="new-password">
        <label class="b" for="reset_new_password2">Повторите пароль</label>
        <input class="in" type="password" name="new_password2" id="reset_new_password2" required minlength="<?= $minLen ?>" maxlength="256" autocomplete="new-password">
        <div class="form-actions">
            <button type="submit" class="btn">Установить пароль по коду</button>
        </div>
    </form>
</div>

<div class="card">
    <p class="meta"><strong>Подписка исполнителя</strong></p>
    <p class="meta">Цена и срок — таблица <code>subscription_config</code>, API <code>get_subscription_config.php</code>.</p>
    <?php if (!$tableExists) { ?>
        <p class="err">Таблица subscription_config не найдена. Выполните миграцию <code>sql/migrate_admin_users_ads.sql</code>.</p>
    <?php } elseif ($subUpdatedAt !== '') { ?>
        <p class="meta">Последнее изменение тарифа: <?= tp_admin_web_h($subUpdatedAt) ?></p>
    <?php } ?>
</div>

<form method="post" action="">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h($csrf) ?>">
    <input type="hidden" name="action" value="save_subscription">

    <div class="card">
        <label class="b" for="price_rub">Цена, ₽</label>
        <input class="in" type="number" name="price_rub" id="price_rub" required min="1" max="9999999" step="1"
               value="<?= (int) $priceRub ?>"<?= $tableExists ? '' : ' disabled' ?>>

        <label class="b" for="days">Срок подписки, дней</label>
        <input class="in" type="number" name="days" id="days" required min="1" max="3650" step="1"
               value="<?= (int) $days ?>"<?= $tableExists ? '' : ' disabled' ?>>
        <p class="meta">На этот срок продлевается доступ исполнителя после успешной оплаты.</p>
    </div>

    <div class="form-actions">
        <button type="submit" class="btn"<?= $tableExists ? '' : ' disabled' ?>>Сохранить тариф</button>
    </div>
</form>
<?php
tp_admin_web_layout_end();
