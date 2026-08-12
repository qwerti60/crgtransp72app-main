<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('chat_core.php');
tp_admin_web_require_include('admin_support.php');
tp_admin_web_require_include('admin_users.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$threadId = (int) ($_GET['thread_id'] ?? 0);
$ticketId = (int) ($_GET['ticket_id'] ?? 0);
$thread = $threadId > 0 ? crg_admin_deal_thread($pdo, $threadId) : null;
$messages = $thread !== null ? crg_admin_support_messages($pdo, $threadId) : [];

$customerName = '';
$performerName = '';
if ($thread !== null) {
    $customerId = (int) ($thread['user_id_customer'] ?? 0);
    $performerId = (int) ($thread['user_id_performer'] ?? 0);
    if ($customerId > 0 && function_exists('crg_chat_user_display_name')) {
        $customerName = crg_chat_user_display_name($pdo, $customerId);
    }
    if ($performerId > 0 && function_exists('crg_chat_user_display_name')) {
        $performerName = crg_chat_user_display_name($pdo, $performerId);
    }
}

tp_admin_web_layout_start('Deal-чат #' . $threadId, 'support', $adminLogin !== '' ? $adminLogin : null);
?>
<style>
    .chat-feed { max-height: 32rem; overflow-y: auto; background: #fff; border-radius: 8px; padding: 1rem; margin: 1rem 0; }
    .chat-msg { margin: 0.5rem 0; max-width: 85%; padding: 0.5rem 0.75rem; border-radius: 8px; font-size: 0.9rem; }
    .chat-msg.user { background: #e2e8f0; margin-right: auto; }
    .chat-msg.admin { background: #dbeafe; margin-left: auto; }
    .chat-msg.system { background: #f8fafc; margin: 0.5rem auto; text-align: center; color: #64748b; font-size: 0.8rem; }
    .chat-meta { font-size: 0.75rem; color: #64748b; margin-top: 0.2rem; }
</style>

<p>
    <?php if ($ticketId > 0) { ?>
        <a class="btn secondary small" href="support_view.php?id=<?= $ticketId ?>">← К обращению</a>
    <?php } else { ?>
        <a class="btn secondary small" href="support_queue.php?category=reports">← К жалобам</a>
    <?php } ?>
</p>

<?php if ($thread === null) { ?>
    <p class="err">Deal-чат не найден</p>
<?php } else { ?>
    <div class="card">
        <h2 style="margin:0 0 0.5rem;font-size:1rem">Переписка по сделке (только чтение)</h2>
        <p class="meta">
            Thread #<?= (int) $threadId ?> ·
            статус <?= tp_admin_web_h((string) ($thread['status'] ?? '')) ?> ·
            bd=<?= (int) ($thread['bd'] ?? 0) ?> ·
            ad_id=<?= (int) ($thread['ad_id'] ?? 0) ?>
            <?php if ((int) ($thread['offer_data_id'] ?? 0) > 0) { ?>
                · offer=<?= (int) $thread['offer_data_id'] ?>
            <?php } ?>
            <?php if ((int) ($thread['order_global_id'] ?? 0) > 0) { ?>
                · order=<?= (int) $thread['order_global_id'] ?>
            <?php } ?>
        </p>
        <p>
            Заказчик:
            <a href="user_edit.php?id=<?= (int) ($thread['user_id_customer'] ?? 0) ?>">
                <?= tp_admin_web_h($customerName !== '' ? $customerName : ('#' . (int) ($thread['user_id_customer'] ?? 0))) ?>
            </a>
            · Исполнитель:
            <a href="user_edit.php?id=<?= (int) ($thread['user_id_performer'] ?? 0) ?>">
                <?= tp_admin_web_h($performerName !== '' ? $performerName : ('#' . (int) ($thread['user_id_performer'] ?? 0))) ?>
            </a>
        </p>
    </div>

    <div class="chat-feed">
        <?php if ($messages === []) { ?>
            <p class="meta">Сообщений пока нет</p>
        <?php } ?>
        <?php foreach ($messages as $msg) {
            $type = (string) ($msg['sender_type'] ?? 'user');
            $cls = $type === 'admin' ? 'admin' : ($type === 'system' ? 'system' : 'user');
            $senderId = (int) ($msg['sender_user_id'] ?? 0);
            $label = $type === 'system'
                ? 'Система'
                : ($type === 'admin'
                    ? ('Админ ' . (string) ($msg['admin_login'] ?? ''))
                    : ('User #' . $senderId));
            ?>
            <div class="chat-msg <?= tp_admin_web_h($cls) ?>">
                <?php if (trim((string) ($msg['body'] ?? '')) !== '') { ?>
                    <div><?= nl2br(tp_admin_web_h((string) $msg['body'])) ?></div>
                <?php } ?>
                <?php if (trim((string) ($msg['attachment_path'] ?? '')) !== '') { ?>
                    <div class="chat-meta">Вложение: <?= tp_admin_web_h((string) ($msg['attachment_name'] ?? 'файл')) ?></div>
                <?php } ?>
                <div class="chat-meta">
                    <?= tp_admin_web_h($label) ?> ·
                    <?= tp_admin_web_h((string) ($msg['created_at'] ?? '')) ?>
                </div>
            </div>
        <?php } ?>
    </div>
<?php } ?>

<?php tp_admin_web_layout_end(); ?>
