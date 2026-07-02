<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_users.php');
tp_admin_web_require_include('admin_subscriptions.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$search = trim((string) ($_GET['q'] ?? ''));
$rollFilter = isset($_GET['roll']) && $_GET['roll'] !== '' ? (int) $_GET['roll'] : null;
$perPage = max(10, min(200, (int) ($_GET['per'] ?? 50)));
$page = max(1, (int) ($_GET['page'] ?? 1));
$offset = ($page - 1) * $perPage;

$list = crg_admin_users_list($pdo, $search, $rollFilter, null, $offset, $perPage);
$listErr = isset($list['error']) ? (string) $list['error'] : null;
$rows = $list['rows'] ?? [];
$total = (int) ($list['total'] ?? 0);
$pages = max(1, (int) ceil($total / $perPage));

$flashOk = '';
if (isset($_GET['saved'])) {
    $flashOk = 'Изменения сохранены.';
} elseif (isset($_GET['created'])) {
    $flashOk = 'Пользователь добавлен.';
} elseif (isset($_GET['deleted'])) {
    $flashOk = 'Пользователь удалён.';
}

$userIds = array_map(static fn (array $r): int => (int) ($r['idusers'] ?? 0), $rows);
$subscriptionMap = crg_admin_subscription_map_for_users($pdo, $userIds);

tp_admin_web_layout_start('Пользователи', 'users', $adminLogin !== '' ? $adminLogin : null);
?>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($listErr !== null) { ?><p class="err"><?= tp_admin_web_h($listErr) ?></p><?php } ?>

<p class="filters">
    <a class="btn" href="user_edit.php?new=1">+ Добавить пользователя</a>
</p>

<form class="filters" method="get" action="users.php">
    <input class="in" type="search" name="q" value="<?= tp_admin_web_h($search) ?>" placeholder="Имя, e-mail, телефон, город" style="max-width:16rem">
    <select class="in" name="roll" style="max-width:12rem;width:auto">
        <option value="">Все роли</option>
        <?php foreach (crg_admin_user_roll_labels() as $k => $label) { ?>
            <option value="<?= $k ?>"<?= $rollFilter === $k ? ' selected' : '' ?>><?= tp_admin_web_h($label) ?></option>
        <?php } ?>
    </select>
    <button type="submit" class="btn secondary small">Найти</button>
    <?php if ($search !== '' || $rollFilter !== null) { ?>
        <a class="btn secondary small" href="users.php">Сброс</a>
    <?php } ?>
</form>

<p class="meta">Всего: <strong><?= $total ?></strong><?php if ($pages > 1) { ?> · стр. <?= $page ?> / <?= $pages ?><?php } ?></p>

<table class="data">
    <thead>
        <tr>
            <th>ID</th>
            <th>ФИО / организация</th>
            <th>Роль</th>
            <th>Город</th>
            <th>Контакты</th>
            <th>Подписка</th>
            <th></th>
        </tr>
    </thead>
    <tbody>
        <?php if ($rows === [] && $listErr === null) { ?>
            <tr><td colspan="7">Нет записей</td></tr>
        <?php } ?>
        <?php foreach ($rows as $r) {
            $id = (int) ($r['idusers'] ?? 0);
            $rollNum = (int) ($r['rollNum'] ?? 0);
            $subRow = $subscriptionMap[$id] ?? null;
            ?>
            <tr>
                <td class="num"><?= $id ?></td>
                <td>
                    <a href="user_edit.php?id=<?= $id ?>"><?= tp_admin_web_h(crg_admin_user_display_name($r)) ?></a>
                    <?php if (trim((string) ($r['namefirm'] ?? '')) !== '') { ?>
                        <div class="meta"><?= tp_admin_web_h((string) $r['namefirm']) ?></div>
                    <?php } ?>
                </td>
                <td><?= tp_admin_web_h(crg_admin_user_roll_label((int) ($r['rollNum'] ?? 0))) ?></td>
                <td><?= tp_admin_web_h((string) ($r['city'] ?? '')) ?></td>
                <td class="meta">
                    <?= tp_admin_web_h((string) ($r['email'] ?? '')) ?><br>
                    <?= tp_admin_web_h((string) ($r['phone'] ?? '')) ?>
                </td>
                <td>
                    <?php if (crg_admin_user_is_performer($rollNum)) {
                        crg_admin_render_subscription_badge($subRow);
                    } else {
                        echo '<span class="meta">—</span>';
                    } ?>
                </td>
                <td class="row-actions">
                    <a class="btn small" href="user_edit.php?id=<?= $id ?>">Изменить</a>
                </td>
            </tr>
        <?php } ?>
    </tbody>
</table>
<?php
tp_admin_web_layout_end();
