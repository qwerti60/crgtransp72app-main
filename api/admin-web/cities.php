<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_cities.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$search = trim((string) ($_GET['q'] ?? ''));
$perPage = (int) ($_GET['per'] ?? 50);
if ($perPage < 10) {
    $perPage = 10;
}
if ($perPage > 200) {
    $perPage = 200;
}
$page = max(1, (int) ($_GET['page'] ?? 1));
$offset = ($page - 1) * $perPage;

$listErr = null;
$rows = [];
$total = 0;
$list = crg_admin_cities_list($pdo, $search, $offset, $perPage);
if (isset($list['error'])) {
    $listErr = (string) $list['error'];
} else {
    $rows = $list['rows'];
    $total = $list['total'];
}

$pages = $perPage > 0 ? (int) ceil($total / $perPage) : 1;
if ($pages < 1) {
    $pages = 1;
}
if ($page > $pages && $total > 0) {
    $q = $_GET;
    $q['page'] = (string) $pages;
    header('Location: cities.php?' . http_build_query($q), true, 302);
    exit;
}

$flashOk = '';
if (isset($_GET['saved']) && (string) $_GET['saved'] === '1') {
    $flashOk = 'Изменения сохранены.';
} elseif (isset($_GET['created']) && (string) $_GET['created'] === '1') {
    $flashOk = 'Город добавлен.';
} elseif (isset($_GET['deleted']) && (string) $_GET['deleted'] === '1') {
    $flashOk = 'Город удалён.';
}

tp_admin_web_layout_start('Города', 'cities', $adminLogin !== '' ? $adminLogin : null);
?>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($listErr !== null) { ?>
    <p class="err"><?= tp_admin_web_h($listErr) ?></p>
<?php } ?>
<p class="filters">
    <a class="btn" href="city_new.php">+ Добавить город</a>
</p>
<form class="filters" method="get" action="cities.php">
    <label class="meta" for="q">Поиск:</label>
    <input class="in" type="search" name="q" id="q" value="<?= tp_admin_web_h($search) ?>" placeholder="Название" style="max-width:14rem">
    <button type="submit" class="btn secondary small">Найти</button>
    <?php if ($search !== '') { ?>
        <a class="btn secondary small" href="cities.php">Сброс</a>
    <?php } ?>
    <span class="meta" style="margin-left:0.5rem">На странице:</span>
    <?php foreach ([25, 50, 100] as $n) {
        $href = 'cities.php?' . http_build_query(array_filter([
            'q' => $search !== '' ? $search : null,
            'per' => (string) $n,
            'page' => '1',
        ]));
        ?>
        <a class="btn secondary small" href="<?= tp_admin_web_h($href) ?>" style="<?= $perPage === $n ? 'outline:2px solid #0369a1' : '' ?>"><?= $n ?></a>
    <?php } ?>
</form>
<p class="meta">Всего городов: <strong><?= (int) $total ?></strong><?php if ($pages > 1) { ?> · страница <?= (int) $page ?> из <?= (int) $pages ?><?php } ?></p>
<?php $hasGeo = crg_admin_cities_has_geo($pdo); ?>
<?php if (!$hasGeo) { ?>
    <p class="warn">Колонки lat/lng отсутствуют. Выполните миграцию <code>sql/migrate_city_geo.sql</code> для геопоиска.</p>
<?php } ?>
<table class="data">
    <thead>
        <tr>
            <th>ID</th>
            <th>Название</th>
            <?php if ($hasGeo) { ?><th class="num">Координаты</th><?php } ?>
            <th class="num">Использований</th>
            <th></th>
        </tr>
    </thead>
    <tbody>
        <?php if (count($rows) === 0 && $listErr === null) { ?>
            <tr><td colspan="<?= $hasGeo ? 5 : 4 ?>">Нет записей</td></tr>
        <?php } ?>
        <?php foreach ($rows as $r) {
            $id = (int) ($r['id'] ?? 0);
            $name = (string) ($r['name'] ?? '');
            $usage = crg_admin_city_usage_total($pdo, $name);
            $latVal = isset($r['lat']) && $r['lat'] !== null && $r['lat'] !== '' ? (string) $r['lat'] : '';
            $lngVal = isset($r['lng']) && $r['lng'] !== null && $r['lng'] !== '' ? (string) $r['lng'] : '';
            $coordsLabel = ($latVal !== '' && $lngVal !== '')
                ? tp_admin_web_h($latVal . ', ' . $lngVal)
                : '<span class="meta">—</span>';
            ?>
            <tr>
                <td class="num"><?= $id ?></td>
                <td><?= tp_admin_web_h($name) ?></td>
                <?php if ($hasGeo) { ?><td class="num meta"><?= $coordsLabel ?></td><?php } ?>
                <td class="num"><?= $usage > 0 ? (int) $usage : '<span class="meta">0</span>' ?></td>
                <td class="row-actions">
                    <a class="btn small" href="city_edit.php?id=<?= $id ?>">Изменить</a>
                    <form method="post" action="city_delete.php" style="display:inline" onsubmit="return confirm('Удалить «<?= tp_admin_web_h($name) ?>»?');">
                        <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                        <input type="hidden" name="id" value="<?= $id ?>">
                        <button type="submit" name="delete_city" value="1" class="btn secondary small">Удалить</button>
                    </form>
                </td>
            </tr>
        <?php } ?>
    </tbody>
</table>
<?php if ($pages > 1 && $listErr === null) {
    $baseQ = array_filter(['q' => $search !== '' ? $search : null, 'per' => $perPage !== 50 ? (string) $perPage : null]);
    ?>
    <p class="filters" style="margin-top:1rem">
        <?php if ($page > 1) {
            $baseQ['page'] = (string) ($page - 1);
            ?>
            <a class="btn secondary small" href="cities.php?<?= tp_admin_web_h(http_build_query($baseQ)) ?>">← Назад</a>
        <?php }
        if ($page < $pages) {
            $baseQ['page'] = (string) ($page + 1);
            ?>
            <a class="btn secondary small" href="cities.php?<?= tp_admin_web_h(http_build_query($baseQ)) ?>">Вперёд →</a>
        <?php } ?>
    </p>
<?php } ?>
<p class="meta" style="margin-top:1rem">Список в приложении: <code>GET ../cities.php</code></p>
<?php
tp_admin_web_layout_end();
