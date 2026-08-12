<?php
declare(strict_types=1);

require_once __DIR__ . '/admin_users.php';
require_once __DIR__ . '/performer_finances.php';

/**
 * @return array{from: string, to: string, label: string}
 */
function crg_admin_export_resolve_period(string $period, ?string $dateFrom, ?string $dateTo): array
{
    return crg_finances_resolve_period($period, $dateFrom, $dateTo);
}

/** @return list<array<string, scalar|null>> */
function crg_admin_export_users(PDO $pdo, int $limit = 10000): array
{
    $result = crg_admin_users_list($pdo, '', null, null, 0, min(10000, max(1, $limit)));
    if (isset($result['error'])) {
        return [];
    }
    $rows = [];
    foreach ($result['rows'] as $r) {
        $rows[] = [
            'id' => $r['idusers'] ?? '',
            'rollNum' => $r['rollNum'] ?? '',
            'statNum' => $r['statNum'] ?? '',
            'firstName' => $r['firstName'] ?? '',
            'lastName' => $r['lastName'] ?? '',
            'city' => $r['city'] ?? '',
            'phone' => $r['phone'] ?? '',
            'email' => $r['email'] ?? '',
            'company' => $r['namefirm'] ?? '',
            'flag' => $r['flag'] ?? '',
            'created_at' => $r['created_at'] ?? '',
        ];
    }

    return $rows;
}

/** @return list<array<string, scalar|null>> */
function crg_admin_export_payments(PDO $pdo, string $dateFrom, string $dateTo): array
{
    $raw = crg_finances_fetch_payments_in_range($pdo, $dateFrom, $dateTo, 10000);
    $rows = [];
    foreach ($raw as $r) {
        $rows[] = [
            'id' => $r['id'] ?? '',
            'user_id' => $r['iduser'] ?? '',
            'order_id' => $r['order_id'] ?? '',
            'amount_rub' => $r['amount_rub'] ?? '',
            'days_added' => $r['days_added'] ?? '',
            'paid_at' => $r['paid_at'] ?? '',
            'subscription_until' => $r['subscription_until'] ?? '',
            'payment_method' => $r['payment_method'] ?? 'card',
        ];
    }

    return $rows;
}

/** @return list<array<string, scalar|null>> */
function crg_admin_export_deals(PDO $pdo, string $dateFrom, string $dateTo): array
{
    try {
        $st = $pdo->prepare(
            'SELECT og.id, og.user_id, og.order_id, og.user_idok, og.idoffer,
                    og.deal_source, og.bd, og.status, og.start_time, og.end_time,
                    og.cancel_time, og.created_at
             FROM ordersglobal og
             WHERE (og.start_time IS NOT NULL AND og.start_time >= ? AND og.start_time < ?)
                OR (og.end_time IS NOT NULL AND og.end_time >= ? AND og.end_time < ?)
                OR (og.created_at IS NOT NULL AND og.created_at >= ? AND og.created_at < ?)
             ORDER BY og.id DESC
             LIMIT 10000'
        );
        $st->execute([$dateFrom, $dateTo, $dateFrom, $dateTo, $dateFrom, $dateTo]);
        $raw = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Throwable $e) {
        return [];
    }

    $rows = [];
    foreach ($raw as $r) {
        $rows[] = [
            'id' => $r['id'] ?? '',
            'performer_id' => $r['user_id'] ?? '',
            'order_id' => $r['order_id'] ?? '',
            'customer_id' => $r['user_idok'] ?? '',
            'offer_id' => $r['idoffer'] ?? '',
            'deal_source' => $r['deal_source'] ?? '',
            'bd' => $r['bd'] ?? '',
            'status' => $r['status'] ?? '',
            'start_time' => $r['start_time'] ?? '',
            'end_time' => $r['end_time'] ?? '',
            'cancel_time' => $r['cancel_time'] ?? '',
            'created_at' => $r['created_at'] ?? '',
        ];
    }

    return $rows;
}

/** @param list<array<string, scalar|null>> $rows */
function crg_admin_export_csv_stream(string $filename, array $rows): void
{
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    echo "\xEF\xBB\xBF";
    $out = fopen('php://output', 'w');
    if ($out === false) {
        return;
    }
    if ($rows === []) {
        fputcsv($out, ['empty'], ';');
        fclose($out);

        return;
    }
    $headers = array_keys($rows[0]);
    fputcsv($out, $headers, ';');
    foreach ($rows as $row) {
        $line = [];
        foreach ($headers as $h) {
            $line[] = $row[$h] ?? '';
        }
        fputcsv($out, $line, ';');
    }
    fclose($out);
}

function crg_admin_export_type_label(string $type): string
{
    return match ($type) {
        'users' => 'Пользователи',
        'payments' => 'Оплаты подписки',
        'deals' => 'Сделки',
        default => $type,
    };
}
