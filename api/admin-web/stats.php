<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_stats.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$period = isset($_GET['period']) ? trim((string) $_GET['period']) : 'month';
if (!in_array($period, ['day', 'week', 'month', 'custom', 'all'], true)) {
    $period = 'month';
}
$dateFrom = isset($_GET['from']) ? trim((string) $_GET['from']) : '';
$dateTo = isset($_GET['to']) ? trim((string) $_GET['to']) : '';

$stats = crg_admin_stats_dashboard($pdo, [
    'period' => $period,
    'from' => $dateFrom !== '' ? $dateFrom : null,
    'to' => $dateTo !== '' ? $dateTo : null,
]);
$kpi = $stats['kpi'] ?? [];
$sa = $stats['subscription_analytics'] ?? [];
$pf = $stats['platform_finances'] ?? [];
$saPeriod = $sa['period'] ?? [];
$saAll = $sa['all_time'] ?? [];
$saSnap = $sa['snapshot'] ?? [];
$periodLabel = (string) (($sa['period_info']['label'] ?? '') ?: ($pf['period_info']['label'] ?? ''));

tp_admin_web_layout_start('Статистика', 'stats', $adminLogin !== '' ? $adminLogin : null);
?>
<style>
    .stats-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(11rem, 1fr)); gap: 0.75rem; margin-bottom: 1.25rem; }
    .stat-card { background: #fff; border-radius: 8px; padding: 0.85rem 1rem; box-shadow: 0 1px 3px rgba(15,23,42,.08); }
    .stat-card .stat-val { font-size: 1.5rem; font-weight: 700; line-height: 1.2; margin: 0.25rem 0 0; }
    .stat-card .stat-lbl { font-size: 0.75rem; color: #64748b; font-weight: 600; text-transform: uppercase; letter-spacing: 0.03em; }
    .stat-card.warn .stat-val { color: #b45309; }
    .stat-card.ok .stat-val { color: #15803d; }
    .stat-card.money .stat-val { color: #0369a1; }
    .stats-section { margin-bottom: 1.5rem; }
    .stats-section h2 { font-size: 1rem; margin: 0 0 0.75rem; font-weight: 600; }
    .stats-two { display: grid; grid-template-columns: repeat(auto-fit, minmax(18rem, 1fr)); gap: 1rem; }
    .stats-three { display: grid; grid-template-columns: repeat(auto-fit, minmax(14rem, 1fr)); gap: 1rem; }
    .bar-row { display: flex; align-items: center; gap: 0.5rem; margin: 0.35rem 0; font-size: 0.85rem; }
    .bar-row .bar-label { min-width: 7rem; flex-shrink: 0; }
    .bar-row .bar-track { flex: 1; height: 0.55rem; background: #e2e8f0; border-radius: 4px; overflow: hidden; }
    .bar-row .bar-fill { height: 100%; background: #0369a1; border-radius: 4px; }
    .bar-row .bar-num { min-width: 2.5rem; text-align: right; color: #64748b; }
    .period-form { display: flex; flex-wrap: wrap; gap: 0.5rem 1rem; align-items: center; margin-bottom: 1rem; }
    .period-form .in { margin-left: 0.25rem; }
    .badge-new { display: inline-block; font-size: 0.7rem; padding: 0.1rem 0.4rem; border-radius: 4px; background: #dcfce7; color: #166534; }
    .badge-renew { display: inline-block; font-size: 0.7rem; padding: 0.1rem 0.4rem; border-radius: 4px; background: #e0f2fe; color: #0369a1; }
    .finance-hero { background: linear-gradient(135deg, #0369a1 0%, #0c4a6e 100%); color: #fff; border-radius: 10px; padding: 1.25rem 1.5rem; margin-bottom: 1.25rem; }
    .finance-hero h2 { margin: 0 0 0.75rem; font-size: 1rem; font-weight: 600; opacity: 0.9; }
    .finance-hero .hero-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(10rem, 1fr)); gap: 1rem; }
    .finance-hero .hero-val { font-size: 1.75rem; font-weight: 700; line-height: 1.2; }
    .finance-hero .hero-lbl { font-size: 0.75rem; opacity: 0.85; margin-top: 0.2rem; }
</style>

<p class="meta">Сводка на <?= tp_admin_web_h((string) ($stats['generated_at'] ?? '')) ?>. Данные из БД приложения; отсутствующие таблицы пропускаются.</p>

<form method="get" action="stats.php" class="card period-form">
    <strong>Период подписок и выручки:</strong>
    <label>
        <select class="in" name="period" onchange="this.form.querySelector('.custom-dates').style.display = this.value === 'custom' ? 'inline' : 'none'; if (this.value !== 'custom') this.form.submit();">
            <?php foreach ([
                'day' => 'Сегодня',
                'week' => '7 дней',
                'month' => '30 дней',
                'all' => 'Всё время',
                'custom' => 'Свой период',
            ] as $key => $label) {
                $sel = $period === $key ? ' selected' : '';
                echo '<option value="' . tp_admin_web_h($key) . '"' . $sel . '>' . tp_admin_web_h($label) . '</option>';
            } ?>
        </select>
    </label>
    <span class="custom-dates" style="display:<?= $period === 'custom' ? 'inline' : 'none' ?>">
        <label>с <input class="in" type="date" name="from" value="<?= tp_admin_web_h($dateFrom) ?>"></label>
        <label>по <input class="in" type="date" name="to" value="<?= tp_admin_web_h($dateTo) ?>"></label>
        <button class="btn secondary small" type="submit">Показать</button>
    </span>
    <?php if ($period !== 'custom') { ?>
        <span class="meta"><?= tp_admin_web_h($periodLabel) ?></span>
    <?php } ?>
</form>

<?php if ($pf !== []) { ?>
<div class="finance-hero">
    <h2>Выручка и оборот — <?= tp_admin_web_h($periodLabel) ?></h2>
    <div class="hero-grid">
        <div>
            <div class="hero-val"><?= tp_admin_web_h(crg_admin_stats_fmt_rub((float) ($pf['subscription_revenue_rub'] ?? 0))) ?></div>
            <div class="hero-lbl">Оплаты подписок</div>
        </div>
        <div>
            <div class="hero-val"><?= tp_admin_web_h(crg_admin_stats_fmt_rub((float) ($pf['deals_gmv_rub'] ?? 0))) ?></div>
            <div class="hero-lbl">Оборот сделок (GMV)</div>
        </div>
        <div>
            <div class="hero-val"><?= tp_admin_web_h(crg_admin_stats_fmt_rub((float) ($pf['total_earned_rub'] ?? 0))) ?></div>
            <div class="hero-lbl">Суммарно</div>
        </div>
        <?php if (($saAll['revenue_rub'] ?? 0) > 0 && $period !== 'all') { ?>
        <div>
            <div class="hero-val"><?= tp_admin_web_h(crg_admin_stats_fmt_rub((int) ($saAll['revenue_rub'] ?? 0))) ?></div>
            <div class="hero-lbl">Подписки за всё время</div>
        </div>
        <?php } ?>
    </div>
</div>
<?php } ?>

<?php if (($sa['has_payment_log'] ?? false) && $saPeriod !== []) { ?>
<div class="stats-grid">
    <?php
    $subCards = [
        ['revenue_rub', 'Выручка подписок', 'money', 'rub'],
        ['payments_count', 'Платежей', '', 'int'],
        ['unique_payers', 'Уникальных плательщиков', '', 'int'],
        ['new_subscriptions', 'Новые подписки', 'ok', 'int'],
        ['renewals', 'Продления', '', 'int'],
        ['avg_payment_rub', 'Средний чек', 'money', 'rub'],
    ];
    foreach ($subCards as [$key, $label, $cls, $fmt]) {
        if (!array_key_exists($key, $saPeriod)) {
            continue;
        }
        $val = $saPeriod[$key];
        $display = $fmt === 'rub'
            ? crg_admin_stats_fmt_rub(is_numeric($val) ? (float) $val : 0)
            : crg_admin_stats_fmt_int((int) $val);
        ?>
        <div class="stat-card <?= tp_admin_web_h($cls) ?>">
            <div class="stat-lbl"><?= tp_admin_web_h($label) ?></div>
            <div class="stat-val"><?= tp_admin_web_h($display) ?></div>
        </div>
    <?php } ?>
</div>
<?php } elseif (!($sa['has_payment_log'] ?? false)) { ?>
<div class="card stats-section">
    <p class="meta">Таблица <code>subscription_payment_log</code> не найдена — выполните миграцию
        <code>sql/migrate_subscription_payment_log.sql</code> для учёта реальных оплат.</p>
</div>
<?php } ?>

<div class="stats-grid">
    <?php
    $cards = [
        ['users_total', 'Пользователей', ''],
        ['users_30d', 'Регистраций за 30 дн.', ''],
        ['users_push', 'С push-токеном', ''],
        ['performer_ads_total', 'Объявления исп.', ''],
        ['performer_ads_pending', 'Объявл. на модерации', 'warn'],
        ['customer_requests_total', 'Заявки заказчиков', ''],
        ['customer_requests_active', 'Заявки активные', 'ok'],
        ['subscriptions_active', 'Подписки активные', 'ok'],
        ['subscriptions_expired', 'Подписки истекли', ''],
        ['offers_total', 'Отклики исполнит.', ''],
        ['offers_accepted', 'Отклики приняты', 'ok'],
        ['proposals_total', 'Предложения заказч.', ''],
        ['reviews_performers', 'Отзывы об исп.', ''],
        ['reviews_customers', 'Отзывы о заказч.', ''],
        ['orders_global', 'Сделки (ordersglobal)', ''],
    ];
    if (($pf['deals_count'] ?? 0) > 0) {
        $cards[] = ['deals_count_period', 'Сделок за период', 'ok'];
    }
    foreach ($cards as [$key, $label, $cls]) {
        if (!array_key_exists($key, $kpi)) {
            continue;
        }
        ?>
        <div class="stat-card <?= tp_admin_web_h($cls) ?>">
            <div class="stat-lbl"><?= tp_admin_web_h($label) ?></div>
            <div class="stat-val"><?= tp_admin_web_h(crg_admin_stats_fmt_int((int) $kpi[$key])) ?></div>
        </div>
    <?php } ?>
</div>

<?php if ($saSnap !== []) { ?>
<div class="card stats-section">
    <h2>Подписки исполнителей — срез на сейчас</h2>
    <div class="stats-three">
        <table class="data">
            <tbody>
                <tr><th>Активные</th><td class="num ok"><?= (int) ($saSnap['active'] ?? 0) ?></td></tr>
                <tr><th>Истекшие</th><td class="num"><?= (int) ($saSnap['expired'] ?? 0) ?></td></tr>
                <tr><th>Заканчиваются за 7 дней</th><td class="num warn"><?= (int) ($saSnap['ending_7'] ?? 0) ?></td></tr>
                <tr><th>Истекли в выбранном периоде</th><td class="num"><?= (int) ($saSnap['expired_in_period'] ?? 0) ?></td></tr>
            </tbody>
        </table>
        <table class="data">
            <tbody>
                <tr><th>Продлевали &gt; 1 раза</th><td class="num"><?= (int) ($saSnap['renewed_users'] ?? 0) ?></td></tr>
                <tr><th>Не продлили (истекли)</th><td class="num"><?= (int) ($saSnap['not_renewed'] ?? 0) ?></td></tr>
                <tr><th>Без подписки (исполнители)</th><td class="num"><?= (int) ($saSnap['never_subscribed'] ?? 0) ?></td></tr>
                <tr><th>Конверсия в подписку</th><td class="num"><?= tp_admin_web_h(number_format((float) ($saSnap['conversion_pct'] ?? 0), 1, ',', '')) ?>%</td></tr>
            </tbody>
        </table>
        <table class="data">
            <tbody>
                <tr><th>Исполнителей всего</th><td class="num"><?= (int) ($saSnap['performers_total'] ?? 0) ?></td></tr>
                <tr><th>Когда-либо подписывались</th><td class="num"><?= (int) ($saSnap['with_sub'] ?? 0) ?></td></tr>
                <tr><th>Доля с продлением</th><td class="num"><?= tp_admin_web_h(number_format((float) ($saSnap['renewal_rate_pct'] ?? 0), 1, ',', '')) ?>%</td></tr>
                <?php if ($stats['tariff'] !== null) {
                    $est = (int) ($saSnap['active'] ?? 0) * (int) $stats['tariff']['price_rub'];
                    ?>
                <tr><th>Оценка MRR (активные × <?= (int) $stats['tariff']['price_rub'] ?> ₽)</th>
                    <td class="num"><?= tp_admin_web_h(crg_admin_stats_fmt_rub($est)) ?></td></tr>
                <?php } ?>
            </tbody>
        </table>
    </div>
    <?php if ((int) ($saSnap['ending_7'] ?? 0) > 0) { ?>
        <p class="meta" style="margin-top:0.75rem"><a href="broadcast.php">→ Рассылка напоминаний об окончании подписки</a></p>
    <?php } ?>
    <p class="meta" style="margin-top:0.5rem"><a href="settings.php">→ Тариф подписки</a> · <a href="users.php">→ Пользователи (финансы по каждому)</a></p>
</div>
<?php } ?>

<?php if (($sa['payments_by_day'] ?? []) !== []) { ?>
<div class="card stats-section">
    <h2>Оплаты подписок по дням — <?= tp_admin_web_h($periodLabel) ?></h2>
    <?php
    $maxPay = max(array_column($sa['payments_by_day'], 'revenue_rub'));
    foreach ($sa['payments_by_day'] as $r) {
        $rev = (int) $r['revenue_rub'];
        $cnt = (int) $r['count'];
        $pct = $maxPay > 0 ? (int) round(100 * $rev / $maxPay) : 0;
        ?>
        <div class="bar-row">
            <span class="bar-label"><?= tp_admin_web_h((string) $r['date']) ?></span>
            <div class="bar-track"><div class="bar-fill" style="width:<?= $pct ?>%;background:#0369a1"></div></div>
            <span class="bar-num" title="<?= $cnt ?> платеж(ей), новых: <?= (int) $r['new_count'] ?>, продл.: <?= (int) $r['renewal_count'] ?>">
                <?= tp_admin_web_h(crg_admin_stats_fmt_rub($rev)) ?>
            </span>
        </div>
    <?php } ?>
</div>
<?php } ?>

<?php if (($sa['recent_payments'] ?? []) !== []) { ?>
<div class="card stats-section">
    <h2>Последние оплаты подписок — <?= tp_admin_web_h($periodLabel) ?></h2>
    <table class="data">
        <thead>
            <tr>
                <th>Дата</th><th>Исполнитель</th><th>Город</th><th class="num">Сумма</th>
                <th class="num">Дней</th><th>До даты</th><th>Тип</th><th></th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($sa['recent_payments'] as $p) { ?>
            <tr>
                <td><?= tp_admin_web_h(date('d.m.Y H:i', strtotime((string) $p['paid_at']))) ?></td>
                <td><?= tp_admin_web_h((string) $p['user_name']) ?></td>
                <td><?= tp_admin_web_h((string) $p['city']) ?></td>
                <td class="num"><?= (int) $p['amount_rub'] ?> ₽</td>
                <td class="num"><?= (int) $p['days_added'] ?></td>
                <td><?= tp_admin_web_h((string) ($p['subscription_until'] ?: '—')) ?></td>
                <td><?= !empty($p['is_renewal']) ? '<span class="badge-renew">Продление</span>' : '<span class="badge-new">Новая</span>' ?></td>
                <td><a href="user_edit.php?id=<?= (int) $p['iduser'] ?>#user-finances">→</a></td>
            </tr>
        <?php } ?>
        </tbody>
    </table>
</div>
<?php } ?>

<?php if (($pf['deals_by_day'] ?? []) !== []) { ?>
<div class="card stats-section">
    <h2>Оборот выполненных сделок по дням — <?= tp_admin_web_h($periodLabel) ?></h2>
    <?php
    $maxDeal = max(array_column($pf['deals_by_day'], 'total_rub'));
    foreach ($pf['deals_by_day'] as $r) {
        $total = (float) $r['total_rub'];
        $cnt = (int) $r['count'];
        $pct = $maxDeal > 0 ? (int) round(100 * $total / $maxDeal) : 0;
        ?>
        <div class="bar-row">
            <span class="bar-label"><?= tp_admin_web_h((string) $r['date']) ?></span>
            <div class="bar-track"><div class="bar-fill" style="width:<?= $pct ?>%;background:#15803d"></div></div>
            <span class="bar-num" title="<?= $cnt ?> сделок"><?= tp_admin_web_h(crg_admin_stats_fmt_rub($total)) ?></span>
        </div>
    <?php } ?>
</div>
<?php } ?>

<div class="stats-two">
    <div class="card stats-section">
        <h2>Пользователи по ролям</h2>
        <?php if (($stats['users_by_role'] ?? []) === []) { ?>
            <p class="meta">Нет данных</p>
        <?php } else { ?>
            <table class="data">
                <thead><tr><th>Роль</th><th class="num">Кол-во</th></tr></thead>
                <tbody>
                <?php foreach ($stats['users_by_role'] as $r) { ?>
                    <tr>
                        <td><?= tp_admin_web_h((string) $r['label']) ?></td>
                        <td class="num"><?= (int) $r['count'] ?></td>
                    </tr>
                <?php } ?>
                </tbody>
            </table>
        <?php } ?>
    </div>

    <div class="card stats-section">
        <h2>Топ городов (пользователи)</h2>
        <?php if (($stats['users_by_city'] ?? []) === []) { ?>
            <p class="meta">Нет данных</p>
        <?php } else {
            $maxCity = max(array_column($stats['users_by_city'], 'count'));
            foreach ($stats['users_by_city'] as $r) {
                $cnt = (int) $r['count'];
                $pct = $maxCity > 0 ? (int) round(100 * $cnt / $maxCity) : 0;
                ?>
                <div class="bar-row">
                    <span class="bar-label"><?= tp_admin_web_h((string) $r['city']) ?></span>
                    <div class="bar-track"><div class="bar-fill" style="width:<?= $pct ?>%"></div></div>
                    <span class="bar-num"><?= $cnt ?></span>
                </div>
            <?php }
        } ?>
    </div>
</div>

<?php if (($stats['registrations_30d'] ?? []) !== []) { ?>
<div class="card stats-section">
    <h2>Регистрации за 30 дней</h2>
    <?php
    $maxReg = max(array_column($stats['registrations_30d'], 'count'));
    foreach ($stats['registrations_30d'] as $r) {
        $cnt = (int) $r['count'];
        $pct = $maxReg > 0 ? (int) round(100 * $cnt / $maxReg) : 0;
        ?>
        <div class="bar-row">
            <span class="bar-label"><?= tp_admin_web_h((string) $r['date']) ?></span>
            <div class="bar-track"><div class="bar-fill" style="width:<?= $pct ?>%;background:#15803d"></div></div>
            <span class="bar-num"><?= $cnt ?></span>
        </div>
    <?php } ?>
</div>
<?php } ?>

<div class="stats-two">
    <div class="card stats-section">
        <h2>Объявления исполнителей</h2>
        <table class="data">
            <thead><tr><th>Тип</th><th class="num">Всего</th><th class="num">Опубл.</th><th class="num">На проверке</th></tr></thead>
            <tbody>
            <?php foreach ($stats['performer_ads'] as $r) { ?>
                <tr>
                    <td><?= tp_admin_web_h((string) $r['label']) ?></td>
                    <td class="num"><?= (int) $r['total'] ?></td>
                    <td class="num"><?= (int) $r['published'] ?></td>
                    <td class="num"><?= (int) $r['pending'] ?></td>
                </tr>
            <?php } ?>
            </tbody>
        </table>
        <?php if ((int) ($kpi['performer_ads_pending'] ?? 0) > 0) { ?>
            <p class="meta" style="margin-top:0.75rem"><a href="performer_ads.php?type=gp&flag=0">→ Объявления на модерации</a></p>
        <?php } ?>
    </div>

    <div class="card stats-section">
        <h2>Заявки заказчиков</h2>
        <table class="data">
            <thead><tr><th>Тип</th><th class="num">Всего</th><th class="num">Активные</th></tr></thead>
            <tbody>
            <?php foreach ($stats['customer_requests'] as $r) { ?>
                <tr>
                    <td><?= tp_admin_web_h((string) $r['label']) ?></td>
                    <td class="num"><?= (int) $r['total'] ?></td>
                    <td class="num"><?= (int) $r['active'] ?></td>
                </tr>
            <?php } ?>
            </tbody>
        </table>
    </div>
</div>

<div class="stats-two">
    <?php if (($stats['offers'] ?? []) !== []) { ?>
    <div class="card stats-section">
        <h2>Отклики на заявки (offer_data)</h2>
        <table class="data">
            <thead><tr><th>Категория</th><th class="num">Всего</th><th class="num">Принято</th><th class="num">% принятия</th><th class="num">Ср. цена</th></tr></thead>
            <tbody>
            <?php foreach ($stats['offers'] as $r) { ?>
                <tr>
                    <td><?= tp_admin_web_h((string) $r['label']) ?></td>
                    <td class="num"><?= (int) $r['total'] ?></td>
                    <td class="num"><?= (int) $r['accepted'] ?></td>
                    <td class="num"><?= tp_admin_web_h(crg_admin_stats_fmt_pct((int) $r['accepted'], (int) $r['total'])) ?></td>
                    <td class="num"><?= (int) $r['avg_price'] ?></td>
                </tr>
            <?php } ?>
            </tbody>
        </table>
    </div>
    <?php } ?>

    <?php if (($stats['proposals'] ?? []) !== []) { ?>
    <div class="card stats-section">
        <h2>Предложения на объявления (offer_dataf)</h2>
        <table class="data">
            <thead><tr><th>Категория</th><th class="num">Всего</th><th class="num">Ср. цена</th></tr></thead>
            <tbody>
            <?php foreach ($stats['proposals'] as $r) { ?>
                <tr>
                    <td><?= tp_admin_web_h((string) $r['label']) ?></td>
                    <td class="num"><?= (int) $r['total'] ?></td>
                    <td class="num"><?= (int) $r['avg_price'] ?></td>
                </tr>
            <?php } ?>
            </tbody>
        </table>
    </div>
    <?php } ?>
</div>

<div class="stats-two">
    <?php
    foreach (
        [
            ['reviews_performers', 'Отзывы об исполнителях'],
            ['reviews_customers', 'Отзывы о заказчиках'],
        ] as [$key, $title]
    ) {
        $rev = $stats[$key] ?? [];
        if ($rev === []) {
            continue;
        }
        ?>
    <div class="card stats-section">
        <h2><?= tp_admin_web_h($title) ?></h2>
        <p><strong><?= (int) ($rev['count'] ?? 0) ?></strong> отзывов, средняя оценка <strong><?= tp_admin_web_h(number_format((float) ($rev['avg'] ?? 0), 2, ',', '')) ?></strong></p>
        <?php
        $maxStar = max(1, ...array_values($rev['stars'] ?? []));
        for ($s = 5; $s >= 1; --$s) {
            $cnt = (int) ($rev['stars'][$s] ?? 0);
            $pct = (int) round(100 * $cnt / $maxStar);
            ?>
            <div class="bar-row">
                <span class="bar-label"><?= $s ?> ★</span>
                <div class="bar-track"><div class="bar-fill" style="width:<?= $pct ?>%;background:#ca8a04"></div></div>
                <span class="bar-num"><?= $cnt ?></span>
            </div>
        <?php } ?>
    </div>
    <?php } ?>
</div>

<?php if (($stats['orders_global'] ?? []) !== []) {
    $og = $stats['orders_global'];
    ?>
<div class="card stats-section">
    <h2>Сделки (ordersglobal)</h2>
    <table class="data">
        <tbody>
            <tr><th>Всего</th><td class="num"><?= (int) ($og['total'] ?? 0) ?></td></tr>
            <tr><th>Выполняются</th><td class="num"><?= (int) ($og['in_progress'] ?? 0) ?></td></tr>
            <tr><th>Выполнены</th><td class="num"><?= (int) ($og['completed'] ?? 0) ?></td></tr>
            <tr><th>Отменены</th><td class="num"><?= (int) ($og['cancelled'] ?? 0) ?></td></tr>
        </tbody>
    </table>
</div>
<?php } ?>

<?php if ((int) ($stats['cities_ref'] ?? 0) > 0) { ?>
<p class="meta">Справочник городов: <?= (int) $stats['cities_ref'] ?> записей</p>
<?php } ?>
<?php
tp_admin_web_layout_end();
