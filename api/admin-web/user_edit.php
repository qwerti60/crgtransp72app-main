<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_users.php');
tp_admin_web_require_include('admin_ads.php');
tp_admin_web_require_include('admin_reviews.php');
tp_admin_web_require_include('admin_subscriptions.php');
tp_admin_web_require_include('admin_finances.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$isNew = isset($_GET['new']) && (string) $_GET['new'] === '1';
$id = (int) ($_GET['id'] ?? 0);
$row = null;
if (!$isNew) {
    if ($id <= 0) {
        http_response_code(400);
        echo 'Укажите id или ?new=1';
        exit;
    }
    $row = crg_admin_user_get($pdo, $id);
    if ($row === null) {
        http_response_code(404);
        echo 'Пользователь не найден';
        exit;
    }
}

$flashErr = '';
$flashOk = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_user'])) {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу.';
    } else {
        $data = $_POST;
        if ($isNew) {
            $ins = crg_admin_user_insert($pdo, $data);
            if (($ins['ok'] ?? false) === true) {
                header('Location: user_edit.php?id=' . (int) $ins['id'] . '&created=1', true, 303);
                exit;
            }
            $flashErr = (string) ($ins['error'] ?? 'Ошибка');
        } else {
            $res = crg_admin_user_update($pdo, $id, $data);
            if ($res === true) {
                header('Location: user_edit.php?id=' . $id . '&saved=1', true, 303);
                exit;
            }
            $flashErr = is_string($res) ? $res : 'Ошибка';
        }
    }
}

if (isset($_GET['saved'])) {
    $flashOk = 'Сохранено.';
} elseif (isset($_GET['created'])) {
    $flashOk = 'Пользователь создан.';
}

if (!$isNew && $row !== null) {
    $id = (int) ($row['idusers'] ?? $id);
    $adCounts = crg_admin_user_ad_counts($pdo, $id);
} else {
    $adCounts = [];
}

$pageTitle = $isNew ? 'Новый пользователь' : ('Пользователь #' . $id);
tp_admin_web_layout_start($pageTitle, 'users', $adminLogin !== '' ? $adminLogin : null);
?>
<p><a class="btn secondary small" href="users.php">← К списку</a></p>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>

<?php if (!$isNew && $adCounts !== []) { ?>
<div class="card">
    <p class="meta"><strong>Объявления пользователя:</strong></p>
    <ul class="meta">
        <?php foreach ($adCounts as $label => $cnt) { ?>
            <li><?= tp_admin_web_h($label) ?>: <?= (int) $cnt ?>
                <?php
                $link = 'performer_ads.php?type=gp&user=' . $id;
                if (str_starts_with($label, 'Зак.')) {
                    $link = 'customer_ads.php?type=orders&user=' . $id;
                } elseif (str_contains($label, 'спецтехника')) {
                    $link = str_starts_with($label, 'Исп.') ? 'performer_ads.php?type=vidt&user=' . $id : 'customer_ads.php?type=orderst&user=' . $id;
                } elseif (str_contains($label, 'грузчики')) {
                    $link = str_starts_with($label, 'Исп.') ? 'performer_ads.php?type=gr&user=' . $id : 'customer_ads.php?type=ordersg&user=' . $id;
                }
                ?>
                — <a href="<?= tp_admin_web_h($link) ?>">открыть</a>
            </li>
        <?php } ?>
    </ul>
</div>
<?php } ?>

<?php if (!$isNew && $row !== null) {
    $rollNum = (int) ($row['rollNum'] ?? 0);
    if (crg_admin_user_is_performer($rollNum)) {
        crg_admin_render_performer_subscription($pdo, $id);
    }
    crg_admin_render_performer_finances($pdo, $id, $rollNum);
    if (crg_admin_user_is_performer($rollNum) || crg_admin_performer_review_summary($pdo, $id)['count'] > 0) {
        crg_admin_render_performer_reviews($pdo, $id);
    }
    if (crg_admin_user_is_customer($rollNum) || crg_admin_customer_review_summary($pdo, $id)['count'] > 0) {
        crg_admin_render_customer_reviews($pdo, $id);
    }
} ?>

<form method="post" action="">
    <input type="hidden" name="save_user" value="1">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">

    <div class="card">
        <label class="b" for="rollNum">Роль</label>
        <select class="in" name="rollNum" id="rollNum" required>
            <?php foreach (crg_admin_user_roll_labels() as $k => $label) { ?>
                <option value="<?= $k ?>"<?= (int) ($row['rollNum'] ?? 2) === $k ? ' selected' : '' ?>><?= tp_admin_web_h($label) ?></option>
            <?php } ?>
        </select>

        <label class="b" for="statNum">Тип</label>
        <select class="in" name="statNum" id="statNum" required>
            <?php foreach (crg_admin_user_stat_labels() as $k => $label) { ?>
                <option value="<?= $k ?>"<?= (int) ($row['statNum'] ?? 1) === $k ? ' selected' : '' ?>><?= tp_admin_web_h($label) ?></option>
            <?php } ?>
        </select>

        <input type="hidden" name="flag" value="1">
    </div>

    <div class="card">
        <label class="b" for="lastName">Фамилия</label>
        <input class="in" type="text" name="lastName" id="lastName" value="<?= tp_admin_web_h((string) ($row['lastName'] ?? '')) ?>">

        <label class="b" for="firstName">Имя</label>
        <input class="in" type="text" name="firstName" id="firstName" value="<?= tp_admin_web_h((string) ($row['firstName'] ?? '')) ?>">

        <label class="b" for="middleName">Отчество</label>
        <input class="in" type="text" name="middleName" id="middleName" value="<?= tp_admin_web_h((string) ($row['middleName'] ?? '')) ?>">

        <label class="b" for="city">Город</label>
        <input class="in" type="text" name="city" id="city" value="<?= tp_admin_web_h((string) ($row['city'] ?? '')) ?>">

        <label class="b" for="phone">Телефон</label>
        <input class="in" type="text" name="phone" id="phone" value="<?= tp_admin_web_h((string) ($row['phone'] ?? '')) ?>">

        <label class="b" for="email">E-mail *</label>
        <input class="in" type="email" name="email" id="email" required value="<?= tp_admin_web_h((string) ($row['email'] ?? '')) ?>">

        <label class="b" for="password">Пароль<?= $isNew ? ' *' : ' (оставьте пустым, чтобы не менять)' ?></label>
        <input class="in" type="password" name="password" id="password" autocomplete="new-password"<?= $isNew ? ' required minlength="6"' : '' ?>>
    </div>

    <div class="card">
        <p class="meta"><strong>Организация / исполнитель</strong></p>
        <label class="b" for="namefirm">Организация</label>
        <input class="in" type="text" name="namefirm" id="namefirm" value="<?= tp_admin_web_h((string) ($row['namefirm'] ?? '')) ?>">

        <label class="b" for="innStr">ИНН</label>
        <input class="in" type="text" name="innStr" id="innStr" value="<?= tp_admin_web_h((string) ($row['innStr'] ?? '')) ?>">

        <label class="b" for="ogrnStr">ОГРН</label>
        <input class="in" type="text" name="ogrnStr" id="ogrnStr" value="<?= tp_admin_web_h((string) ($row['ogrnStr'] ?? '')) ?>">

        <label class="b" for="kppStr">КПП</label>
        <input class="in" type="text" name="kppStr" id="kppStr" value="<?= tp_admin_web_h((string) ($row['kppStr'] ?? '')) ?>">

        <label class="b" for="vidt">Вид техники</label>
        <input class="in" type="text" name="vidt" id="vidt" value="<?= tp_admin_web_h((string) ($row['vidt'] ?? '')) ?>">

        <label class="b" for="marka">Марка</label>
        <input class="in" type="text" name="marka" id="marka" value="<?= tp_admin_web_h((string) ($row['marka'] ?? '')) ?>">

        <label class="b" for="maxgruz">Грузоподъёмность</label>
        <input class="in" type="text" name="maxgruz" id="maxgruz" value="<?= tp_admin_web_h((string) ($row['maxgruz'] ?? '')) ?>">

        <label class="b" for="vidk">Вид кузова</label>
        <input class="in" type="text" name="vidk" id="vidk" value="<?= tp_admin_web_h((string) ($row['vidk'] ?? '')) ?>">

        <label class="b" for="cenahaurs">Цена / час</label>
        <input class="in" type="text" name="cenahaurs" id="cenahaurs" value="<?= tp_admin_web_h((string) ($row['cenahaurs'] ?? '')) ?>">
    </div>

    <div class="form-actions">
        <button type="submit" class="btn"><?= $isNew ? 'Добавить' : 'Сохранить' ?></button>
        <a class="btn secondary" href="users.php">Отмена</a>
    </div>
</form>
<?php if (!$isNew) { ?>
<form method="post" action="user_delete.php" style="margin-top:0.5rem" onsubmit="return confirm('Удалить пользователя и все его объявления?');">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
    <input type="hidden" name="id" value="<?= $id ?>">
    <button type="submit" name="delete_user" value="1" class="btn secondary">Удалить пользователя</button>
</form>
<?php } ?>
<?php
tp_admin_web_layout_end();
