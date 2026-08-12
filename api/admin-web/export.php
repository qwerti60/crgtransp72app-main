<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_export.php');

$pdo = tp_admin_web_require_login();

$type = isset($_GET['type']) ? trim((string) $_GET['type']) : '';
$period = isset($_GET['period']) ? trim((string) $_GET['period']) : 'month';
$dateFrom = isset($_GET['from']) ? trim((string) $_GET['from']) : '';
$dateTo = isset($_GET['to']) ? trim((string) $_GET['to']) : '';

if ($type !== '' && in_array($type, ['users', 'payments', 'deals'], true)) {
    $range = crg_admin_export_resolve_period($period, $dateFrom !== '' ? $dateFrom : null, $dateTo !== '' ? $dateTo : null);
    $rows = match ($type) {
        'users' => crg_admin_export_users($pdo),
        'payments' => crg_admin_export_payments($pdo, $range['from'], $range['to']),
        'deals' => crg_admin_export_deals($pdo, $range['from'], $range['to']),
        default => [],
    };
    $stamp = date('Y-m-d');
    crg_admin_export_csv_stream($type . '_' . $stamp . '.csv', $rows);
    exit;
}

$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');
tp_admin_web_layout_start('Экспорт CSV', 'export', $adminLogin !== '' ? $adminLogin : null);
?>
<p class="meta">Выгрузка для бухгалтерии. Разделитель — точка с запятой, кодировка UTF-8 с BOM.</p>

<div class="card">
    <h2 style="margin:0 0 0.75rem;font-size:1rem">Пользователи</h2>
    <p class="meta">Все зарегистрированные пользователи (до 10 000 последних).</p>
    <a class="btn" href="export.php?type=users">Скачать users.csv</a>
</div>

<div class="card">
    <h2 style="margin:0 0 0.75rem;font-size:1rem">Оплаты подписки</h2>
    <form method="get" class="period-form">
        <input type="hidden" name="type" value="payments">
        <label>Период:
            <select class="in" name="period">
                <?php foreach (['day' => 'Сегодня', 'week' => '7 дней', 'month' => '30 дней', 'all' => 'Всё время', 'custom' => 'Свой'] as $k => $lbl) {
                    $sel = $period === $k ? ' selected' : '';
                    echo '<option value="' . tp_admin_web_h($k) . '"' . $sel . '>' . tp_admin_web_h($lbl) . '</option>';
                } ?>
            </select>
        </label>
        <label>с <input class="in" type="date" name="from" value="<?= tp_admin_web_h($dateFrom) ?>"></label>
        <label>по <input class="in" type="date" name="to" value="<?= tp_admin_web_h($dateTo) ?>"></label>
        <button class="btn" type="submit">Скачать payments.csv</button>
    </form>
</div>

<div class="card">
    <h2 style="margin:0 0 0.75rem;font-size:1rem">Сделки</h2>
    <form method="get" class="period-form">
        <input type="hidden" name="type" value="deals">
        <label>Период:
            <select class="in" name="period">
                <?php foreach (['day' => 'Сегодня', 'week' => '7 дней', 'month' => '30 дней', 'all' => 'Всё время', 'custom' => 'Свой'] as $k => $lbl) {
                    $sel = $period === $k ? ' selected' : '';
                    echo '<option value="' . tp_admin_web_h($k) . '"' . $sel . '>' . tp_admin_web_h($lbl) . '</option>';
                } ?>
            </select>
        </label>
        <label>с <input class="in" type="date" name="from" value="<?= tp_admin_web_h($dateFrom) ?>"></label>
        <label>по <input class="in" type="date" name="to" value="<?= tp_admin_web_h($dateTo) ?>"></label>
        <button class="btn" type="submit">Скачать deals.csv</button>
    </form>
</div>

<?php tp_admin_web_layout_end(); ?>
