<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_cities.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$flashErr = '';
$name = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['create_city'])) {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу и повторите.';
    } else {
    $name = (string) ($_POST['name'] ?? '');
    $ins = crg_admin_city_insert($pdo, $name);
    if (($ins['ok'] ?? false) === true) {
        header('Location: city_edit.php?id=' . (int) $ins['id'] . '&created=1', true, 303);
        exit;
    }
    $flashErr = (string) ($ins['error'] ?? 'Не удалось добавить');
    }
}

tp_admin_web_layout_start('Новый город', 'cities', $adminLogin !== '' ? $adminLogin : null);
?>
<p><a class="btn secondary small" href="cities.php">← К списку</a></p>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>
<form method="post" action="">
    <input type="hidden" name="create_city" value="1">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
    <label class="b" for="name">Название</label>
    <input class="in" type="text" name="name" id="name" required maxlength="255" value="<?= tp_admin_web_h($name) ?>" autofocus>
    <div class="form-actions">
        <button type="submit" class="btn">Добавить</button>
        <a class="btn secondary" href="cities.php">Отмена</a>
    </div>
</form>
<?php
tp_admin_web_layout_end();
