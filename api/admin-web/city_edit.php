<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_cities.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$id = (int) ($_GET['id'] ?? 0);
$row = crg_admin_city_get($pdo, $id);
if ($row === null) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Город не найден';
    exit;
}

$hasGeo = crg_admin_cities_has_geo($pdo);
$oldName = (string) ($row['name'] ?? '');
$name = $oldName;
$lat = $hasGeo && isset($row['lat']) && $row['lat'] !== null ? (string) $row['lat'] : '';
$lng = $hasGeo && isset($row['lng']) && $row['lng'] !== null ? (string) $row['lng'] : '';
$flashErr = '';
$flashOk = '';

if (isset($_GET['created']) && (string) $_GET['created'] === '1') {
    $flashOk = 'Город добавлен.';
}

$usageBreakdown = crg_admin_city_usage_breakdown($pdo, $oldName);
$usageTotal = array_sum($usageBreakdown);

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_city'])) {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу и повторите.';
    } else {
        $name = (string) ($_POST['name'] ?? '');
        $lat = (string) ($_POST['lat'] ?? '');
        $lng = (string) ($_POST['lng'] ?? '');
        $renameRefs = isset($_POST['rename_references']) && (string) $_POST['rename_references'] === '1';
        $res = crg_admin_city_update($pdo, $id, $name, $renameRefs, $lat, $lng);
        if ($res === true) {
            header('Location: city_edit.php?id=' . $id . '&saved=1', true, 303);
            exit;
        }
        $flashErr = is_string($res) ? $res : 'Ошибка сохранения';
    }
}

if (isset($_GET['saved']) && (string) $_GET['saved'] === '1') {
    $flashOk = 'Изменения сохранены.';
    $row = crg_admin_city_get($pdo, $id);
    if ($row !== null) {
        $oldName = (string) ($row['name'] ?? '');
        $name = $oldName;
        $lat = $hasGeo && isset($row['lat']) && $row['lat'] !== null ? (string) $row['lat'] : '';
        $lng = $hasGeo && isset($row['lng']) && $row['lng'] !== null ? (string) $row['lng'] : '';
        $usageBreakdown = crg_admin_city_usage_breakdown($pdo, $oldName);
        $usageTotal = array_sum($usageBreakdown);
    }
}

tp_admin_web_layout_start('Редактирование города', 'cities', $adminLogin !== '' ? $adminLogin : null);
?>
<p><a class="btn secondary small" href="cities.php">← К списку</a></p>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>
<?php if (!$hasGeo) { ?>
    <p class="warn">Колонки lat/lng отсутствуют. Выполните миграцию <code>sql/migrate_city_geo.sql</code>.</p>
<?php } ?>
<div class="card">
    <p class="meta">ID: <strong><?= (int) $id ?></strong></p>
    <?php if ($usageTotal > 0) { ?>
        <p class="warn">Город используется в <strong><?= (int) $usageTotal ?></strong> записях:</p>
        <ul class="meta">
            <?php foreach ($usageBreakdown as $place => $cnt) { ?>
                <li><?= tp_admin_web_h($place) ?>: <?= (int) $cnt ?></li>
            <?php } ?>
        </ul>
    <?php } else { ?>
        <p class="meta">В пользователях и объявлениях не используется — можно удалить.</p>
    <?php } ?>
</div>
<form method="post" action="">
    <input type="hidden" name="save_city" value="1">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
    <label class="b" for="name">Название</label>
    <input class="in" type="text" name="name" id="name" required maxlength="255" value="<?= tp_admin_web_h($name) ?>">
    <?php if ($hasGeo) { ?>
        <label class="b" for="lat" style="margin-top:1rem">Широта (lat)</label>
        <input class="in" type="text" name="lat" id="lat" inputmode="decimal" placeholder="57.152200" value="<?= tp_admin_web_h($lat) ?>">
        <label class="b" for="lng" style="margin-top:1rem">Долгота (lng)</label>
        <input class="in" type="text" name="lng" id="lng" inputmode="decimal" placeholder="65.527200" value="<?= tp_admin_web_h($lng) ?>">
        <p class="meta">Нужны для поиска «рядом со мной». Можно оставить пустыми.</p>
    <?php } ?>
    <?php if ($usageTotal > 0 && $name !== $oldName) { ?>
        <p class="warn">При смене названия отметьте галочку ниже, чтобы обновить имя во всех связанных таблицах.</p>
    <?php } ?>
    <?php if ($usageTotal > 0) { ?>
        <label class="b" style="margin-top:1rem">
            <input type="checkbox" name="rename_references" value="1">
            Обновить название в пользователях и объявлениях (<?= (int) $usageTotal ?> записей)
        </label>
    <?php } ?>
    <div class="form-actions">
        <button type="submit" class="btn">Сохранить</button>
        <a class="btn secondary" href="cities.php">Отмена</a>
    </div>
</form>
<?php
tp_admin_web_layout_end();
