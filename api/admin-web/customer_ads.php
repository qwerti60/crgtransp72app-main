<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_ads.php');
tp_admin_web_require_include('admin_users.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$type = crg_admin_customer_type_from_request();
if ($type === null) {
    $type = 'orders';
}
$cfg = crg_admin_customer_ad_config($type);
assert($cfg !== null);

$search = trim((string) ($_GET['q'] ?? ''));
$userFilter = isset($_GET['user']) && $_GET['user'] !== '' ? (int) $_GET['user'] : null;
$perPage = max(10, min(200, (int) ($_GET['per'] ?? 50)));
$page = max(1, (int) ($_GET['page'] ?? 1));
$offset = ($page - 1) * $perPage;

$list = crg_admin_customer_ads_list($pdo, $cfg, $search, $userFilter, $offset, $perPage);
$listErr = isset($list['error']) ? (string) $list['error'] : null;
$rows = $list['rows'] ?? [];
$total = (int) ($list['total'] ?? 0);
$summaryCols = (array) ($cfg['summary'] ?? ['city']);
$userMap = crg_admin_users_map_by_ids($pdo, array_column($rows, 'iduser'));

$flashOk = isset($_GET['deleted']) ? 'Удалено.' : (isset($_GET['saved']) ? 'Сохранено.' : (isset($_GET['created']) ? 'Добавлено.' : ''));

tp_admin_web_layout_start('Заявки заказчиков — ' . (string) $cfg['label'], 'customer_ads', $adminLogin !== '' ? $adminLogin : null);
?>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($listErr !== null) { ?><p class="err"><?= tp_admin_web_h($listErr) ?></p><?php } ?>

<p class="filters">
    <?php foreach (crg_admin_customer_ad_types() as $tKey => $tCfg) {
        $cls = $tKey === $type ? 'btn' : 'btn secondary';
        ?>
        <a class="<?= $cls ?> small" href="customer_ads.php?type=<?= tp_admin_web_h($tKey) ?>"><?= tp_admin_web_h((string) $tCfg['label']) ?></a>
    <?php } ?>
</p>

<p class="filters">
    <a class="btn" href="customer_ad_edit.php?type=<?= tp_admin_web_h($type) ?>&new=1">+ Добавить заявку</a>
</p>

<form class="filters" method="get" action="customer_ads.php">
    <input type="hidden" name="type" value="<?= tp_admin_web_h($type) ?>">
    <input class="in" type="search" name="q" value="<?= tp_admin_web_h($search) ?>" placeholder="Город, маршрут…" style="max-width:14rem">
    <input class="in" type="number" name="user" value="<?= $userFilter !== null ? (int) $userFilter : '' ?>" placeholder="ID пользователя" style="max-width:8rem;width:auto">
    <button type="submit" class="btn secondary small">Найти</button>
</form>

<p class="meta">Всего: <strong><?= $total ?></strong></p>

<table class="data">
    <thead>
        <tr>
            <th>ID</th>
            <th>Заказчик</th>
            <th>Описание</th>
            <th>Активна до</th>
            <th>Дата</th>
            <th></th>
        </tr>
    </thead>
    <tbody>
        <?php if ($rows === [] && $listErr === null) { ?>
            <tr><td colspan="6">Нет заявок</td></tr>
        <?php } ?>
        <?php foreach ($rows as $r) {
            $adId = (int) ($r['id'] ?? 0);
            $uid = (int) ($r['iduser'] ?? 0);
            $userRow = $userMap[$uid] ?? ['idusers' => $uid];
            $userName = crg_admin_user_display_name($userRow);
            ?>
            <tr>
                <td class="num"><?= $adId ?></td>
                <td><a href="user_edit.php?id=<?= $uid ?>"><?= tp_admin_web_h($userName) ?></a></td>
                <td><?= tp_admin_web_h(crg_admin_ad_summary_text($r, $summaryCols)) ?></td>
                <td><?= tp_admin_web_h((string) ($r['enddatez'] ?? '')) ?></td>
                <td class="meta"><?= tp_admin_web_h((string) ($r['created_at'] ?? '')) ?></td>
                <td><a class="btn small" href="customer_ad_view.php?type=<?= tp_admin_web_h($type) ?>&id=<?= $adId ?>">Открыть</a></td>
            </tr>
        <?php } ?>
    </tbody>
</table>
<?php
tp_admin_web_layout_end();
