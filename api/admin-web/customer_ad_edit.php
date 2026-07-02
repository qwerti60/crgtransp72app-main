<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_ads.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$type = crg_admin_customer_type_from_request();
if ($type === null) {
    http_response_code(400);
    exit;
}
$cfg = crg_admin_customer_ad_config($type);
assert($cfg !== null);

$isNew = isset($_GET['new']) && (string) $_GET['new'] === '1';
$id = (int) ($_GET['id'] ?? 0);
$row = $isNew ? null : crg_admin_ad_get($pdo, $cfg, $id);
if (!$isNew && $row === null) {
    http_response_code(404);
    exit;
}

$flashErr = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_ad'])) {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF';
    } elseif ($isNew) {
        $ins = crg_admin_ad_insert($pdo, $cfg, $_POST, false);
        if (($ins['ok'] ?? false) === true) {
            header('Location: customer_ad_view.php?type=' . rawurlencode($type) . '&id=' . (int) $ins['id'] . '&created=1', true, 303);
            exit;
        }
        $flashErr = (string) ($ins['error'] ?? 'Ошибка');
    } else {
        $res = crg_admin_ad_update($pdo, $cfg, $id, $_POST, false);
        if ($res === true) {
            header('Location: customer_ad_view.php?type=' . rawurlencode($type) . '&id=' . $id . '&saved=1', true, 303);
            exit;
        }
        $flashErr = is_string($res) ? $res : 'Ошибка';
    }
}

$fields = [
    'iduser' => 'ID пользователя *',
    'city' => 'Город',
    'city1' => 'Город (куда)',
    'maxgruz' => 'Грузоподъёмность',
    'vidk' => 'Вид кузова',
    'vidt' => 'Вид техники',
    'zagr' => 'Загрузка',
    'typepr' => 'Тип перевозки',
    'startdate' => 'Дата начала',
    'enddate' => 'Дата окончания',
    'enddatez' => 'Активна до *',
    'cena' => 'Цена',
    'about' => 'Описание',
];

tp_admin_web_layout_start($isNew ? 'Новая заявка' : ('Редактирование #' . $id), 'customer_ads', $adminLogin !== '' ? $adminLogin : null);
?>
<p><a class="btn secondary small" href="customer_ads.php?type=<?= tp_admin_web_h($type) ?>">← К списку</a></p>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>

<form method="post" action="">
    <input type="hidden" name="type" value="<?= tp_admin_web_h($type) ?>">
    <input type="hidden" name="save_ad" value="1">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">

    <?php foreach ($fields as $name => $label) {
        if (!$isNew && $name === 'iduser') {
            continue;
        }
        $val = $isNew ? '' : (string) ($row[$name] ?? '');
        ?>
        <label class="b" for="<?= tp_admin_web_h($name) ?>"><?= tp_admin_web_h($label) ?></label>
        <?php if ($name === 'about') { ?>
            <textarea class="in" name="about" id="about" rows="4"><?= tp_admin_web_h($val) ?></textarea>
        <?php } else { ?>
            <input class="in" type="text" name="<?= tp_admin_web_h($name) ?>" id="<?= tp_admin_web_h($name) ?>"
                value="<?= tp_admin_web_h($val) ?>"<?= ($isNew && in_array($name, ['iduser', 'enddatez', 'cena'], true)) ? ' required' : '' ?>>
        <?php } ?>
    <?php } ?>

    <?php if (!$isNew) { ?>
        <input type="hidden" name="iduser" value="<?= tp_admin_web_h((string) ($row['iduser'] ?? '')) ?>">
    <?php } ?>

    <div class="form-actions">
        <button type="submit" class="btn"><?= $isNew ? 'Добавить' : 'Сохранить' ?></button>
    </div>
</form>
<?php
tp_admin_web_layout_end();
