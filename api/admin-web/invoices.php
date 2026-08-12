<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('subscription_invoices.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');
$flashOk = '';
$flashErr = '';
$ready = crg_invoice_table_exists($pdo);
$filter = isset($_GET['status']) ? trim((string) $_GET['status']) : '';

if ($ready && $_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу.';
    } else {
        $action = (string) ($_POST['action'] ?? '');
        $id = (int) ($_POST['id'] ?? 0);
        try {
            if ($action === 'issue' && $id > 0) {
                $num = trim((string) ($_POST['invoice_number'] ?? ''));
                $note = trim((string) ($_POST['admin_note'] ?? ''));
                $res = crg_invoice_mark_issued($pdo, $id, $num, $note);
                $flashOk = ($res['ok'] ?? false) ? 'Счёт выставлен' : '';
                $flashErr = ($res['ok'] ?? false) ? '' : (string) ($res['error'] ?? 'Ошибка');
            } elseif ($action === 'paid' && $id > 0) {
                $note = trim((string) ($_POST['admin_note'] ?? ''));
                $res = crg_invoice_mark_paid($pdo, $id, $note);
                $flashOk = ($res['ok'] ?? false) ? 'Оплата зафиксирована, подписка продлена до ' . ($res['date'] ?? '') : '';
                $flashErr = ($res['ok'] ?? false) ? '' : (string) ($res['error'] ?? 'Ошибка');
            } elseif ($action === 'cancel' && $id > 0) {
                $res = crg_invoice_cancel($pdo, $id);
                $flashOk = ($res['ok'] ?? false) ? 'Заявка отменена' : '';
                $flashErr = ($res['ok'] ?? false) ? '' : (string) ($res['error'] ?? 'Ошибка');
            }
        } catch (Throwable $e) {
            $flashErr = 'Ошибка: ' . $e->getMessage();
        }
    }
}

$rows = $ready ? crg_invoice_list_admin($pdo, $filter !== '' ? $filter : null) : [];

tp_admin_web_layout_start('Счета B2B', 'invoices', $adminLogin !== '' ? $adminLogin : null);
?>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>
<?php if (!$ready) { ?>
    <p class="err">Выполните миграцию <code>sql/migrate_p3_features.sql</code>.</p>
<?php } else { ?>
    <div class="filters">
        <strong>Фильтр:</strong>
        <a class="btn small secondary" href="invoices.php">Все</a>
        <?php foreach (['requested', 'issued', 'paid', 'cancelled'] as $st) {
            $cls = $filter === $st ? '' : ' secondary';
            echo '<a class="btn small' . $cls . '" href="invoices.php?status=' . tp_admin_web_h($st) . '">'
                . tp_admin_web_h(crg_invoice_status_label($st)) . '</a>';
        } ?>
    </div>

    <table class="data">
        <thead>
        <tr>
            <th>ID</th><th>Дата</th><th>Пользователь</th><th>Компания / ИНН</th>
            <th>Пакет</th><th>Сумма</th><th>Статус</th><th>Действия</th>
        </tr>
        </thead>
        <tbody>
        <?php if ($rows === []) { ?><tr><td colspan="8">Нет заявок</td></tr><?php } ?>
        <?php foreach ($rows as $r) {
            $status = (string) ($r['status'] ?? '');
            $userLabel = trim((string) (($r['lastName'] ?? '') . ' ' . ($r['firstName'] ?? '')));
            if ($userLabel === '') {
                $userLabel = (string) ($r['email'] ?? $r['phone'] ?? '');
            }
            ?>
            <tr>
                <td><?= (int) $r['id'] ?></td>
                <td><?= tp_admin_web_h((string) ($r['created_at'] ?? '')) ?></td>
                <td>#<?= (int) ($r['user_id'] ?? 0) ?><br><span class="meta"><?= tp_admin_web_h($userLabel) ?></span></td>
                <td><?= tp_admin_web_h((string) ($r['company_name'] ?? '')) ?><br><span class="meta">ИНН <?= tp_admin_web_h((string) ($r['inn'] ?? '')) ?></span></td>
                <td><?= (int) ($r['days'] ?? 0) ?> дн.<br><span class="meta">pkg #<?= (int) ($r['package_id'] ?? 0) ?></span></td>
                <td class="num"><?= (int) ($r['amount_rub'] ?? 0) ?> ₽</td>
                <td>
                    <span class="badge badge-<?= $status === 'paid' ? 'ok' : ($status === 'cancelled' ? 'muted' : 'pending') ?>">
                        <?= tp_admin_web_h(crg_invoice_status_label($status)) ?>
                    </span>
                    <?php if (!empty($r['invoice_number'])) { ?>
                        <div class="meta">№ <?= tp_admin_web_h((string) $r['invoice_number']) ?></div>
                    <?php } ?>
                </td>
                <td>
                    <?php if ($status === 'requested') { ?>
                        <form method="post" style="margin-bottom:0.35rem">
                            <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                            <input type="hidden" name="action" value="issue">
                            <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                            <input class="in" name="invoice_number" placeholder="№ счёта" required maxlength="64">
                            <input class="in" name="admin_note" placeholder="Комментарий">
                            <button class="btn small" type="submit">Выставить</button>
                        </form>
                    <?php } ?>
                    <?php if ($status === 'issued' || $status === 'requested') { ?>
                        <form method="post" style="margin-bottom:0.35rem" onsubmit="return confirm('Зафиксировать оплату и продлить подписку?');">
                            <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                            <input type="hidden" name="action" value="paid">
                            <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                            <button class="btn small" type="submit">Оплачен</button>
                        </form>
                        <form method="post" onsubmit="return confirm('Отменить заявку?');">
                            <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                            <input type="hidden" name="action" value="cancel">
                            <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                            <button class="btn small danger" type="submit">Отмена</button>
                        </form>
                    <?php } ?>
                </td>
            </tr>
        <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php tp_admin_web_layout_end(); ?>
