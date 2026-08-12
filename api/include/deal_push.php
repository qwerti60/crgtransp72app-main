<?php
declare(strict_types=1);

/**
 * Системные push по событиям сделки и подписки.
 */

require_once __DIR__ . '/fcm_push.php';

/** @return array{title: string, body: string} */
function crg_deal_push_copy(string $event): array
{
    switch ($event) {
        case 'offer_received':
            return ['title' => 'Новое предложение', 'body' => 'Поступил отклик по заказу'];
        case 'offer_accepted':
            return ['title' => 'Предложение принято', 'body' => 'Ваше предложение приняли'];
        case 'offer_rejected':
            return ['title' => 'Отказ по предложению', 'body' => 'По вашему предложению отказали'];
        case 'deal_started':
            return ['title' => 'Заказ начат', 'body' => 'Исполнение заказа началось'];
        case 'deal_completed':
            return ['title' => 'Заказ выполнен', 'body' => 'Заказ отмечен как выполненный'];
        case 'deal_cancelled':
            return ['title' => 'Сделка отменена', 'body' => 'Заказ был отменён'];
        case 'in_transit':
            return ['title' => 'Исполнитель в пути', 'body' => 'Заказ в пути — см. ETA в приложении'];
        case 'subscription_ending':
            return ['title' => 'Подписка заканчивается', 'body' => 'Через 3 дня истекает доступ исполнителя'];
        case 'subscription_expired':
            return ['title' => 'Подписка истекла', 'body' => 'Продлите подписку, чтобы снова видеть заявки'];
        default:
            return ['title' => 'Уведомление', 'body' => 'Обновление по заказу'];
    }
}

/**
 * @param array<string, scalar|null> $extra
 * @return true|string|null
 */
function crg_push_deal_event(PDO $pdo, int $userId, string $event, array $extra = [])
{
    if ($userId <= 0 || $event === '') {
        return null;
    }
    $copy = crg_deal_push_copy($event);
    $data = [
        'type' => (strpos($event, 'subscription_') === 0) ? 'subscription_reminder' : 'deal_event',
        'event' => $event,
    ];
    foreach ($extra as $key => $value) {
        if ($value === null) {
            continue;
        }
        $data[(string) $key] = (string) $value;
    }

    return crg_fcm_send_to_user($pdo, $userId, $copy['title'], $copy['body'], $data);
}

function crg_push_deal_event_safe(PDO $pdo, int $userId, string $event, array $extra = []): void
{
    try {
        crg_push_deal_event($pdo, $userId, $event, $extra);
    } catch (Throwable $e) {
        // не ломаем основной поток сделки
    }
}
