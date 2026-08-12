<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('chat_core.php');
tp_admin_web_require_include('admin_support.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$statusFilter = trim((string) ($_GET['status'] ?? 'new'));
if ($statusFilter === '') {
    $statusFilter = 'new';
}
$categoryFilter = trim((string) ($_GET['category'] ?? 'all'));
if ($categoryFilter === '') {
    $categoryFilter = 'all';
}
$perPage = max(10, min(100, (int) ($_GET['per'] ?? 30)));
$page = max(1, (int) ($_GET['page'] ?? 1));
$offset = ($page - 1) * $perPage;

$tablesReady = crg_admin_support_tables_ready($pdo);
$rows = $tablesReady
    ? crg_admin_support_queue($pdo, $statusFilter, $perPage, $offset, $categoryFilter)
    : [];
$total = $tablesReady
    ? crg_admin_support_queue_total($pdo, $statusFilter, $categoryFilter)
    : 0;
$pages = max(1, (int) ceil($total / $perPage));
$statusLabels = crg_admin_support_status_labels();
$categoryLabels = crg_chat_support_category_labels();

tp_admin_web_layout_start('Поддержка', 'support', $adminLogin !== '' ? $adminLogin : null);
?>
<?php if (!$tablesReady) { ?>
    <p class="err">Таблицы чата не созданы. Выполните <code>sql/migrate_chat_support.sql</code> на сервере.</p>
<?php } ?>

<p class="filters">
    <a class="btn<?= $statusFilter === 'new' ? '' : ' secondary' ?>" href="support_queue.php?status=new&amp;category=<?= urlencode($categoryFilter) ?>">Новые</a>
    <a class="btn<?= $statusFilter === 'assigned' ? '' : ' secondary' ?>" href="support_queue.php?status=assigned&amp;category=<?= urlencode($categoryFilter) ?>">В работе</a>
    <a class="btn<?= $statusFilter === 'waiting_user' ? '' : ' secondary' ?>" href="support_queue.php?status=waiting_user&amp;category=<?= urlencode($categoryFilter) ?>">Ждём ответа</a>
    <a class="btn<?= $statusFilter === 'all' ? '' : ' secondary' ?>" href="support_queue.php?status=all&amp;category=<?= urlencode($categoryFilter) ?>">Все</a>
</p>
<p class="filters">
    <a class="btn<?= $categoryFilter === 'all' ? '' : ' secondary' ?>" href="support_queue.php?status=<?= urlencode($statusFilter) ?>&amp;category=all">Все категории</a>
    <a class="btn<?= $categoryFilter === 'reports' ? '' : ' secondary' ?>" href="support_queue.php?status=<?= urlencode($statusFilter) ?>&amp;category=reports">Жалобы</a>
    <a class="btn<?= $categoryFilter === 'deal_dispute' ? '' : ' secondary' ?>" href="support_queue.php?status=<?= urlencode($statusFilter) ?>&amp;category=deal_dispute">Споры</a>
    <a class="btn<?= $categoryFilter === 'ad_moderation' ? '' : ' secondary' ?>" href="support_queue.php?status=<?= urlencode($statusFilter) ?>&amp;category=ad_moderation">Объявления</a>
</p>

<p class="meta">Всего: <?= (int) $total ?></p>

<table class="data">
    <thead>
    <tr>
        <th>№</th>
        <th>Дата</th>
        <th>Пользователь</th>
        <th>Категория</th>
        <th>Тема</th>
        <th>Статус</th>
        <th></th>
    </tr>
    </thead>
    <tbody>
    <?php if ($rows === []) { ?>
        <tr><td colspan="7">Нет обращений</td></tr>
    <?php } ?>
    <?php foreach ($rows as $row) { ?>
        <tr>
            <td><?= (int) ($row['id'] ?? 0) ?></td>
            <td><?= tp_admin_web_h((string) ($row['created_at'] ?? '')) ?></td>
            <td>
                <?= tp_admin_web_h(crg_admin_support_user_name($row)) ?><br>
                <span class="meta">#<?= (int) ($row['user_id'] ?? 0) ?> · <?= tp_admin_web_h((string) ($row['city'] ?? '')) ?></span>
            </td>
            <td><?= tp_admin_web_h($categoryLabels[(string) ($row['category'] ?? 'other')] ?? 'Другое') ?></td>
            <td><?= tp_admin_web_h((string) ($row['subject'] ?? '')) ?></td>
            <td><?= tp_admin_web_h($statusLabels[(string) ($row['status'] ?? '')] ?? '') ?></td>
            <td class="row-actions">
                <a class="btn small" href="support_view.php?id=<?= (int) ($row['id'] ?? 0) ?>">Открыть</a>
            </td>
        </tr>
    <?php } ?>
    </tbody>
</table>

<?php if ($pages > 1) { ?>
    <p class="meta">Страница <?= $page ?> из <?= $pages ?></p>
<?php } ?>

<?php tp_admin_web_layout_end(); ?>
