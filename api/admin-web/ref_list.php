<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_ref_lists.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$type = crg_admin_ref_type_from_request();
if ($type === null) {
    http_response_code(400);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Неизвестный тип справочника';
    exit;
}
$cfg = crg_admin_ref_config($type);
assert($cfg !== null);

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
$list = crg_admin_ref_list($pdo, $cfg, $search, $offset, $perPage);
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
    header('Location: ref_list.php?' . http_build_query($q), true, 302);
    exit;
}

$flashOk = '';
if (isset($_GET['saved']) && (string) $_GET['saved'] === '1') {
    $flashOk = 'Изменения сохранены.';
} elseif (isset($_GET['created']) && (string) $_GET['created'] === '1') {
    $flashOk = 'Запись добавлена.';
} elseif (isset($_GET['deleted']) && (string) $_GET['deleted'] === '1') {
    $flashOk = 'Запись удалена.';
}

$navKey = (string) $cfg['nav'];
tp_admin_web_layout_start((string) $cfg['label'], $navKey, $adminLogin !== '' ? $adminLogin : null);
?>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($listErr !== null) { ?>
    <p class="err"><?= tp_admin_web_h($listErr) ?></p>
<?php } ?>
<p class="filters">
    <a class="btn" href="ref_new.php?type=<?= tp_admin_web_h($type) ?>">+ Добавить</a>
</p>
<form class="filters" method="get" action="ref_list.php">
    <input type="hidden" name="type" value="<?= tp_admin_web_h($type) ?>">
    <label class="meta" for="q">Поиск:</label>
    <input class="in" type="search" name="q" id="q" value="<?= tp_admin_web_h($search) ?>" placeholder="Название" style="max-width:14rem">
    <button type="submit" class="btn secondary small">Найти</button>
    <?php if ($search !== '') { ?>
        <a class="btn secondary small" href="ref_list.php?type=<?= tp_admin_web_h($type) ?>">Сброс</a>
    <?php } ?>
</form>
<p class="meta">Всего: <strong><?= (int) $total ?></strong><?php if ($pages > 1) { ?> · стр. <?= (int) $page ?> / <?= (int) $pages ?><?php } ?></p>
<table class="data">
    <thead>
        <tr>
            <th>ID</th>
            <th>Название</th>
            <?php if (!empty($cfg['has_image'])) { ?><th>Картинка</th><?php } ?>
            <th class="num">Использований</th>
            <th></th>
        </tr>
    </thead>
    <tbody>
        <?php if (count($rows) === 0 && $listErr === null) { ?>
            <tr><td colspan="<?= !empty($cfg['has_image']) ? 5 : 4 ?>">Нет записей</td></tr>
        <?php } ?>
        <?php foreach ($rows as $r) {
            $id = (int) ($r['id'] ?? 0);
            $name = (string) ($r['name'] ?? '');
            $usage = crg_admin_ref_usage_total($pdo, $cfg, $name);
            ?>
            <tr>
                <td class="num"><?= $id ?></td>
                <td><?= tp_admin_web_h($name) ?></td>
                <?php if (!empty($cfg['has_image'])) { ?>
                    <td><?php if (!empty($r['has_image'])) { ?>
                        <img class="thumb-preview" src="ref_image.php?type=<?= tp_admin_web_h($type) ?>&id=<?= $id ?>" alt="">
                    <?php } else { ?><span class="meta">нет</span><?php } ?></td>
                <?php } ?>
                <td class="num"><?= $usage > 0 ? (int) $usage : '<span class="meta">0</span>' ?></td>
                <td class="row-actions">
                    <a class="btn small" href="ref_edit.php?type=<?= tp_admin_web_h($type) ?>&id=<?= $id ?>">Изменить</a>
                    <form method="post" action="ref_delete.php" style="display:inline" onsubmit="return confirm('Удалить «<?= tp_admin_web_h($name) ?>»?');">
                        <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                        <input type="hidden" name="type" value="<?= tp_admin_web_h($type) ?>">
                        <input type="hidden" name="id" value="<?= $id ?>">
                        <button type="submit" name="delete_ref" value="1" class="btn secondary small">Удалить</button>
                    </form>
                </td>
            </tr>
        <?php } ?>
    </tbody>
</table>
<p class="meta" style="margin-top:1rem">API приложения: <code>GET ../<?= tp_admin_web_h((string) $cfg['api']) ?></code></p>
<?php
tp_admin_web_layout_end();
