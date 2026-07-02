<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_ads.php');

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

$isNew = isset($_GET['new']) && (string) $_GET['new'] === '1';
$id = (int) ($_GET['id'] ?? 0);
$row = $isNew ? null : crg_admin_ad_get($pdo, $cfg, $id);
if (!$isNew && $row === null) {
    http_response_code(404);
    echo 'Не найдено';
    exit;
}

$flashErr = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_ad'])) {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF';
    } elseif ($isNew) {
        $ins = crg_admin_ad_insert($pdo, $cfg, $_POST, true);
        if (($ins['ok'] ?? false) === true) {
            header('Location: performer_ad_view.php?type=' . rawurlencode($type) . '&id=' . (int) $ins['id'] . '&created=1', true, 303);
            exit;
        }
        $flashErr = (string) ($ins['error'] ?? 'Ошибка');
    } else {
        $res = crg_admin_ad_update($pdo, $cfg, $id, $_POST, true);
        if ($res === true) {
            header('Location: performer_ad_view.php?type=' . rawurlencode($type) . '&id=' . $id . '&saved=1', true, 303);
            exit;
        }
        $flashErr = is_string($res) ? $res : 'Ошибка';
    }
}

$fields = [
    'iduser' => 'ID пользователя *',
    'city' => 'Город',
    'marka' => 'Марка',
    'godv' => 'Год выпуска',
    'maxgruz' => 'Грузоподъёмность',
    'dkuzov' => 'Длина кузова',
    'shkuzov' => 'Ширина кузова',
    'vidk' => 'Вид кузова',
    'vidt' => 'Вид техники',
    'cenahaurs' => 'Цена / час',
    'cenasmena' => 'Цена / смена',
    'cenakm' => 'Цена / км',
    'flag' => 'Статус (0=на проверке, 1=опубликовано)',
];

tp_admin_web_layout_start($isNew ? 'Новое объявление' : ('Редактирование #' . $id), 'performer_ads', $adminLogin !== '' ? $adminLogin : null);
?>
<p><a class="btn secondary small" href="performer_ads.php?type=<?= tp_admin_web_h($type) ?>">← К списку</a></p>
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
        <?php if ($name === 'flag') { ?>
            <select class="in" name="flag" id="flag">
                <option value="0"<?= (int) $val === 0 ? ' selected' : '' ?>>На проверке</option>
                <option value="1"<?= (int) $val === 1 ? ' selected' : '' ?>>Опубликовано</option>
            </select>
        <?php } else { ?>
            <input class="in" type="text" name="<?= tp_admin_web_h($name) ?>" id="<?= tp_admin_web_h($name) ?>"
                value="<?= tp_admin_web_h($val) ?>"<?= $isNew && $name === 'iduser' ? ' required' : '' ?>>
        <?php } ?>
    <?php } ?>

    <?php if (!$isNew) { ?>
        <input type="hidden" name="iduser" value="<?= tp_admin_web_h((string) ($row['iduser'] ?? '')) ?>">
        <p class="meta">Пользователь: #<?= (int) ($row['iduser'] ?? 0) ?></p>
    <?php } ?>

    <div class="form-actions">
        <button type="submit" class="btn"><?= $isNew ? 'Добавить' : 'Сохранить' ?></button>
    </div>
</form>
<?php
tp_admin_web_layout_end();
