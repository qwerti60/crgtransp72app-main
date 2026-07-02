<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_ads.php');
tp_admin_web_require_include('admin_users.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$type = crg_admin_performer_type_from_request();
if ($type === null) {
    $type = 'gp';
}
$cfg = crg_admin_performer_ad_config($type);
assert($cfg !== null);

$search = trim((string) ($_GET['q'] ?? ''));
$flagFilter = isset($_GET['flag']) && $_GET['flag'] !== '' ? (int) $_GET['flag'] : null;
$userFilter = isset($_GET['user']) && $_GET['user'] !== '' ? (int) $_GET['user'] : null;
$perPage = max(10, min(200, (int) ($_GET['per'] ?? 50)));
$page = max(1, (int) ($_GET['page'] ?? 1));
$offset = ($page - 1) * $perPage;

$list = crg_admin_performer_ads_list($pdo, $cfg, $search, $flagFilter, $userFilter, $offset, $perPage);
$listErr = isset($list['error']) ? (string) $list['error'] : null;
$rows = $list['rows'] ?? [];
$total = (int) ($list['total'] ?? 0);
$pages = max(1, (int) ceil($total / $perPage));
$summaryCols = (array) ($cfg['summary'] ?? ['city']);
$userMap = crg_admin_users_map_by_ids($pdo, array_column($rows, 'iduser'));

$flashOk = '';
if (isset($_GET['saved'])) {
    $flashOk = 'Сохранено.';
} elseif (isset($_GET['created'])) {
    $flashOk = 'Объявление добавлено.';
} elseif (isset($_GET['deleted'])) {
    $flashOk = 'Удалено.';
} elseif (isset($_GET['approved'])) {
    $flashOk = 'Объявление опубликовано.';
}

$pending = crg_admin_ad_pending_count($pdo, $cfg);

tp_admin_web_layout_start('Объявления исполнителей — ' . (string) $cfg['label'], 'performer_ads', $adminLogin !== '' ? $adminLogin : null);
?>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($listErr !== null) { ?><p class="err"><?= tp_admin_web_h($listErr) ?></p><?php } ?>

<p class="filters">
    <?php foreach (crg_admin_performer_ad_types() as $tKey => $tCfg) {
        $cls = $tKey === $type ? 'btn' : 'btn secondary';
        $href = 'performer_ads.php?type=' . rawurlencode($tKey);
        if ($userFilter !== null) {
            $href .= '&user=' . $userFilter;
        }
        ?>
        <a class="<?= $cls ?> small" href="<?= tp_admin_web_h($href) ?>"><?= tp_admin_web_h((string) $tCfg['label']) ?></a>
    <?php } ?>
</p>

<p class="filters">
    <a class="btn" href="performer_ad_edit.php?type=<?= tp_admin_web_h($type) ?>&new=1">+ Добавить</a>
    <?php if ($pending > 0) { ?>
        <a class="btn secondary" href="performer_ads.php?type=<?= tp_admin_web_h($type) ?>&flag=0">На проверке (<?= (int) $pending ?>)</a>
    <?php } ?>
</p>

<form class="filters" method="get" action="performer_ads.php">
    <input type="hidden" name="type" value="<?= tp_admin_web_h($type) ?>">
    <input class="in" type="search" name="q" value="<?= tp_admin_web_h($search) ?>" placeholder="Город, марка…" style="max-width:14rem">
    <select class="in" name="flag" style="max-width:12rem;width:auto">
        <option value="">Все статусы</option>
        <option value="0"<?= $flagFilter === 0 ? ' selected' : '' ?>>На проверке</option>
        <option value="1"<?= $flagFilter === 1 ? ' selected' : '' ?>>Опубликовано</option>
    </select>
    <input class="in" type="number" name="user" value="<?= $userFilter !== null ? (int) $userFilter : '' ?>" placeholder="ID пользователя" style="max-width:8rem;width:auto">
    <button type="submit" class="btn secondary small">Найти</button>
</form>

<p class="meta">Всего: <strong><?= $total ?></strong></p>

<table class="data">
    <thead>
        <tr>
            <th>ID</th>
            <th>Исполнитель</th>
            <th>Описание</th>
            <th>Статус</th>
            <th>Дата</th>
            <th></th>
        </tr>
    </thead>
    <tbody>
        <?php if ($rows === [] && $listErr === null) { ?>
            <tr><td colspan="6">Нет объявлений</td></tr>
        <?php } ?>
        <?php foreach ($rows as $r) {
            $adId = (int) ($r['id'] ?? 0);
            $uid = (int) ($r['iduser'] ?? 0);
            $flag = (int) ($r['flag'] ?? 0);
            $userRow = $userMap[$uid] ?? ['idusers' => $uid];
            $userName = crg_admin_user_display_name($userRow);
            ?>
            <tr>
                <td class="num"><?= $adId ?></td>
                <td><a href="user_edit.php?id=<?= $uid ?>"><?= tp_admin_web_h($userName) ?></a></td>
                <td><?= tp_admin_web_h(crg_admin_ad_summary_text($r, $summaryCols)) ?></td>
                <td>
                    <?php if ($flag === 1) { ?>
                        <span class="badge badge-ok">Опубликовано</span>
                    <?php } else { ?>
                        <span class="badge badge-pending">На проверке</span>
                    <?php } ?>
                </td>
                <td class="meta"><?= tp_admin_web_h((string) ($r['created_at'] ?? '')) ?></td>
                <td class="row-actions">
                    <a class="btn small" href="performer_ad_view.php?type=<?= tp_admin_web_h($type) ?>&id=<?= $adId ?>">Открыть</a>
                    <?php if ($flag === 0) { ?>
                        <form method="post" action="performer_ad_view.php?type=<?= tp_admin_web_h($type) ?>&id=<?= $adId ?>" style="display:inline" onsubmit="return confirm('Опубликовать объявление и отправить исполнителю e-mail и push?');">
                            <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                            <input type="hidden" name="set_flag" value="1">
                            <input type="hidden" name="flag" value="1">
                            <button type="submit" class="btn small">Одобрить</button>
                        </form>
                    <?php } ?>
                </td>
            </tr>
        <?php } ?>
    </tbody>
</table>
<?php
tp_admin_web_layout_end();
