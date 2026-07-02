<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_stats.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$stats = crg_admin_stats_dashboard($pdo);
$kpi = $stats['kpi'] ?? [];

tp_admin_web_layout_start('Статистика', 'stats', $adminLogin !== '' ? $adminLogin : null);
?>
<style>
    .stats-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(11rem, 1fr)); gap: 0.75rem; margin-bottom: 1.25rem; }
    .stat-card { background: #fff; border-radius: 8px; padding: 0.85rem 1rem; box-shadow: 0 1px 3px rgba(15,23,42,.08); }
    .stat-card .stat-val { font-size: 1.5rem; font-weight: 700; line-height: 1.2; margin: 0.25rem 0 0; }
    .stat-card .stat-lbl { font-size: 0.75rem; color: #64748b; font-weight: 600; text-transform: uppercase; letter-spacing: 0.03em; }
    .stat-card.warn .stat-val { color: #b45309; }
    .stat-card.ok .stat-val { color: #15803d; }
    .stats-section { margin-bottom: 1.5rem; }
    .stats-section h2 { font-size: 1rem; margin: 0 0 0.75rem; font-weight: 600; }
    .stats-two { display: grid; grid-template-columns: repeat(auto-fit, minmax(18rem, 1fr)); gap: 1rem; }
    .bar-row { display: flex; align-items: center; gap: 0.5rem; margin: 0.35rem 0; font-size: 0.85rem; }
    .bar-row .bar-label { min-width: 7rem; flex-shrink: 0; }
    .bar-row .bar-track { flex: 1; height: 0.55rem; background: #e2e8f0; border-radius: 4px; overflow: hidden; }
    .bar-row .bar-fill { height: 100%; background: #0369a1; border-radius: 4px; }
    .bar-row .bar-num { min-width: 2.5rem; text-align: right; color: #64748b; }
</style>

<p class="meta">Сводка на <?= tp_admin_web_h((string) ($stats['generated_at'] ?? '')) ?>. Данные из БД приложения; отсутствующие таблицы пропускаются.</p>

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

<?php if (($stats['subscriptions'] ?? []) !== []) {
    $sub = $stats['subscriptions'];
    ?>
<div class="card stats-section">
    <h2>Подписки исполнителей</h2>
    <table class="data">
        <tbody>
            <tr><th>Активные</th><td class="num"><?= (int) ($sub['active'] ?? 0) ?></td></tr>
            <tr><th>Истекшие</th><td class="num"><?= (int) ($sub['expired'] ?? 0) ?></td></tr>
            <tr><th>Заканчиваются за 7 дней</th><td class="num"><?= (int) ($sub['ending_7'] ?? 0) ?></td></tr>
            <tr><th>Продлевали более 1 раза</th><td class="num"><?= (int) ($sub['renewed'] ?? 0) ?></td></tr>
            <?php if (isset($sub['never_subscribed'])) { ?>
                <tr><th>Исполнители без подписки</th><td class="num"><?= (int) $sub['never_subscribed'] ?></td></tr>
            <?php } ?>
            <?php if ($stats['tariff'] !== null && isset($sub['est_revenue_rub'])) { ?>
                <tr><th>Оценка выручки (активные × <?= (int) $stats['tariff']['price_rub'] ?> ₽)</th>
                    <td class="num"><?= tp_admin_web_h(crg_admin_stats_fmt_int((int) $sub['est_revenue_rub'])) ?> ₽</td></tr>
            <?php } ?>
        </tbody>
    </table>
    <?php if ((int) ($sub['ending_7'] ?? 0) > 0) { ?>
        <p class="meta" style="margin-top:0.75rem"><a href="broadcast.php">→ Рассылка напоминаний</a></p>
    <?php } ?>
</div>
<?php } ?>

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
