<?php
declare(strict_types=1);

function crg_admin_finances_module_ready(): bool
{
    return is_readable(__DIR__ . '/performer_finances.php');
}

function crg_admin_finances_format_rub(float $amount): string
{
    return number_format($amount, $amount === floor($amount) ? 0 : 2, ',', ' ') . ' ₽';
}

function crg_admin_finances_format_dt(?string $raw): string
{
    if ($raw === null || trim($raw) === '') {
        return '—';
    }
    $ts = strtotime($raw);

    return $ts !== false ? date('d.m.Y H:i', $ts) : tp_admin_web_h($raw);
}

function crg_admin_finances_deal_source_label(string $source): string
{
    return $source === 'performer_ad' ? 'Объявление исполнителя' : 'Заказ заказчика';
}

function crg_admin_render_performer_finances(PDO $pdo, int $userId, ?int $rollNum = null): void
{
    echo '<div class="card" id="user-finances">';
    echo '<p class="meta"><strong>Финансы пользователя</strong></p>';

    if ($userId <= 0) {
        echo '<p class="meta">Некорректный ID пользователя.</p></div>';
        return;
    }

    if (!crg_admin_finances_module_ready()) {
        echo '<p class="err">На сервере не найден файл <code>api/include/performer_finances.php</code>. '
            . 'Загрузите его вместе с <code>api/include/admin_finances.php</code>.</p></div>';
        return;
    }

    try {
        require_once __DIR__ . '/performer_finances.php';

        $isPerformer = $rollNum !== null && crg_admin_user_is_performer($rollNum);
        if ($rollNum !== null && !$isPerformer) {
            echo '<p class="meta">Роль «' . tp_admin_web_h(crg_admin_user_roll_label($rollNum))
                . '». Подписка и доходы исполнителя обычно относятся к ролям '
                . 'грузоперевозчик / спецтехника / грузчики. Ниже — данные, если они есть в БД.</p>';
        }

        $period = isset($_GET['fin_period']) ? trim((string) $_GET['fin_period']) : 'month';
        $dateFrom = isset($_GET['fin_from']) ? trim((string) $_GET['fin_from']) : '';
        $dateTo = isset($_GET['fin_to']) ? trim((string) $_GET['fin_to']) : '';

        $report = crg_finances_build_report(
            $pdo,
            $userId,
            $period,
            $dateFrom !== '' ? $dateFrom : null,
            $dateTo !== '' ? $dateTo : null
        );

        $periodInfo = $report['period'] ?? [];
        $payments = $report['subscription_payments'] ?? [];
        $incomeItems = $report['income_items'] ?? [];

        echo '<form method="get" action="" class="meta" style="margin-bottom:1rem;">';
        echo '<input type="hidden" name="id" value="' . (int) $userId . '">';
        echo '<label>Период доходов: ';
        echo '<select class="in" name="fin_period" onchange="this.form.submit()">';
        foreach ([
            'day' => 'Сегодня',
            'week' => '7 дней',
            'month' => '30 дней',
            'custom' => 'Свой период',
        ] as $key => $label) {
            $sel = $period === $key ? ' selected' : '';
            echo '<option value="' . tp_admin_web_h($key) . '"' . $sel . '>' . tp_admin_web_h($label) . '</option>';
        }
        echo '</select></label> ';
        if ($period === 'custom') {
            echo '<label>с <input class="in" type="date" name="fin_from" value="' . tp_admin_web_h($dateFrom) . '"></label> ';
            echo '<label>по <input class="in" type="date" name="fin_to" value="' . tp_admin_web_h($dateTo) . '"></label> ';
            echo '<button class="btn secondary small" type="submit">Показать</button>';
        }
        echo '</form>';

        if (!crg_finances_payment_log_table_exists($pdo)) {
            echo '<p class="meta">Таблица <code>subscription_payment_log</code> не найдена — выполните миграцию '
                . '<code>sql/migrate_subscription_payment_log.sql</code>.</p>';
        }

        echo '<p class="meta"><strong>Оплаты подписки</strong> — всего '
            . crg_admin_finances_format_rub((float) ($report['subscription_total_rub'] ?? 0))
            . ' (' . count($payments) . ')</p>';

        if ($payments === []) {
            echo '<p class="meta">Записей об оплатах пока нет.</p>';
        } else {
            echo '<table class="data"><thead><tr>';
            echo '<th>Дата</th><th>Сумма</th><th>Дней</th><th>До даты</th><th>ID платежа</th>';
            echo '</tr></thead><tbody>';
            foreach ($payments as $row) {
                echo '<tr>';
                echo '<td>' . crg_admin_finances_format_dt((string) ($row['paid_at'] ?? '')) . '</td>';
                echo '<td class="num">' . (int) ($row['amount_rub'] ?? 0) . ' ₽</td>';
                echo '<td class="num">' . (int) ($row['days_added'] ?? 0) . '</td>';
                $until = trim((string) ($row['subscription_until'] ?? ''));
                echo '<td>' . ($until !== '' ? tp_admin_web_h($until) : '—') . '</td>';
                echo '<td>' . tp_admin_web_h((string) ($row['order_id'] ?? '')) . '</td>';
                echo '</tr>';
            }
            echo '</tbody></table>';
        }

        $incomeLabel = (string) ($periodInfo['label'] ?? 'За период');
        echo '<p class="meta" style="margin-top:1.5rem;"><strong>Доходы</strong> — '
            . tp_admin_web_h($incomeLabel) . ', '
            . crg_admin_finances_format_rub((float) ($report['income_total_rub'] ?? 0))
            . ' (' . (int) ($report['income_count'] ?? 0) . ' сделок)</p>';

        if ($incomeItems === []) {
            echo '<p class="meta">За выбранный период выполненных сделок нет.</p>';
        } else {
            echo '<table class="data"><thead><tr>';
            echo '<th>Дата</th><th>Сумма</th><th>Заказчик</th><th>Источник</th><th>Описание</th>';
            echo '</tr></thead><tbody>';
            foreach ($incomeItems as $row) {
                echo '<tr>';
                $time = (string) ($row['income_time'] ?? $row['end_time'] ?? '');
                echo '<td>' . crg_admin_finances_format_dt($time) . '</td>';
                echo '<td class="num">' . crg_admin_finances_format_rub((float) ($row['amount_rub'] ?? 0)) . '</td>';
                echo '<td>' . tp_admin_web_h((string) ($row['counterparty'] ?? '')) . '</td>';
                echo '<td>' . tp_admin_web_h(crg_admin_finances_deal_source_label((string) ($row['deal_source'] ?? ''))) . '</td>';
                $about = trim((string) ($row['about'] ?? ''));
                echo '<td>' . ($about !== '' ? tp_admin_web_h($about) : '—') . '</td>';
                echo '</tr>';
            }
            echo '</tbody></table>';
        }
    } catch (Throwable $e) {
        echo '<p class="err">Не удалось загрузить финансы: ' . tp_admin_web_h($e->getMessage()) . '</p>';
    }

    echo '</div>';
}
