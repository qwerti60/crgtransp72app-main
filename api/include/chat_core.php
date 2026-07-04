<?php
declare(strict_types=1);

require_once __DIR__ . '/api_bootstrap.php';
require_once __DIR__ . '/chat_attachments.php';

/** @var array<string, string> */
function crg_chat_support_category_labels(): array
{
    return [
        'account' => 'Аккаунт и вход',
        'ad_moderation' => 'Модерация объявления',
        'payment' => 'Подписка и оплата',
        'deal_dispute' => 'Спор по заказу',
        'bug' => 'Ошибка приложения',
        'other' => 'Другое',
    ];
}

function crg_chat_tables_ready(PDO $pdo): bool
{
    static $ready = null;
    if ($ready !== null) {
        return $ready;
    }
    try {
        $st = $pdo->query("SHOW TABLES LIKE 'chat_threads'");
        $ready = $st !== false && $st->fetch() !== false;
    } catch (Throwable $e) {
        $ready = false;
    }

    return $ready;
}

function crg_chat_user_display_name(PDO $pdo, int $userId): string
{
    if ($userId <= 0) {
        return 'Пользователь';
    }
    $st = $pdo->prepare(
        'SELECT firstName, lastName, middleName, namefirm FROM users WHERE idusers = ? LIMIT 1'
    );
    $st->execute([$userId]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if ($row === false) {
        return 'Пользователь #' . $userId;
    }
    $parts = array_filter([
        trim((string) ($row['lastName'] ?? '')),
        trim((string) ($row['firstName'] ?? '')),
        trim((string) ($row['middleName'] ?? '')),
    ]);
    if ($parts !== []) {
        return implode(' ', $parts);
    }
    $firm = trim((string) ($row['namefirm'] ?? ''));

    return $firm !== '' ? $firm : ('Пользователь #' . $userId);
}

function crg_chat_is_customer(int $rollNum): bool
{
    return $rollNum === 1;
}

function crg_chat_is_performer(int $rollNum): bool
{
    return in_array($rollNum, [2, 3, 4], true);
}

function crg_chat_sanitize_body(string $body): string
{
    $body = trim($body);
    if (mb_strlen($body) > 4000) {
        $body = mb_substr($body, 0, 4000);
    }

    return $body;
}

function crg_chat_preview(string $body): string
{
    $body = preg_replace('/\s+/u', ' ', trim($body)) ?? trim($body);
    if (mb_strlen($body) <= 255) {
        return $body;
    }

    return mb_substr($body, 0, 252) . '…';
}

/**
 * @return array{success: bool, error?: string, thread_id?: int}
 */
function crg_chat_open_deal_thread(
    PDO $pdo,
    int $currentUserId,
    int $counterpartUserId,
    int $bd,
    int $adId
): array {
    if (!crg_chat_tables_ready($pdo)) {
        return ['success' => false, 'error' => 'Chat tables not deployed'];
    }
    if ($currentUserId <= 0 || $counterpartUserId <= 0) {
        return ['success' => false, 'error' => 'Invalid user'];
    }
    if ($currentUserId === $counterpartUserId) {
        return ['success' => false, 'error' => 'Нельзя написать самому себе'];
    }
    if ($bd < 1 || $bd > 3 || $adId <= 0) {
        return ['success' => false, 'error' => 'Invalid ad context'];
    }

    $st = $pdo->prepare('SELECT rollNum FROM users WHERE idusers = ? LIMIT 1');
    $st->execute([$currentUserId]);
    $me = $st->fetch(PDO::FETCH_ASSOC);
    $st->execute([$counterpartUserId]);
    $other = $st->fetch(PDO::FETCH_ASSOC);
    if ($me === false || $other === false) {
        return ['success' => false, 'error' => 'User not found'];
    }

    $myRoll = (int) ($me['rollNum'] ?? 0);
    $otherRoll = (int) ($other['rollNum'] ?? 0);

    $customerId = 0;
    $performerId = 0;
    if (crg_chat_is_customer($myRoll) && crg_chat_is_performer($otherRoll)) {
        $customerId = $currentUserId;
        $performerId = $counterpartUserId;
    } elseif (crg_chat_is_performer($myRoll) && crg_chat_is_customer($otherRoll)) {
        $customerId = $counterpartUserId;
        $performerId = $currentUserId;
    } else {
        // fallback: текущий — заказчик, второй — исполнитель
        $customerId = $currentUserId;
        $performerId = $counterpartUserId;
    }

    $find = $pdo->prepare(
        'SELECT id, status FROM chat_threads
         WHERE type = \'deal\' AND bd = ? AND ad_id = ?
           AND user_id_customer = ? AND user_id_performer = ?
         LIMIT 1'
    );
    $find->execute([$bd, $adId, $customerId, $performerId]);
    $existing = $find->fetch(PDO::FETCH_ASSOC);
    if ($existing !== false) {
        return ['success' => true, 'thread_id' => (int) $existing['id']];
    }

    $ins = $pdo->prepare(
        'INSERT INTO chat_threads
         (type, status, user_id_customer, user_id_performer, bd, ad_id, created_at, updated_at)
         VALUES (\'deal\', \'draft\', ?, ?, ?, ?, NOW(), NOW())'
    );
    $ins->execute([$customerId, $performerId, $bd, $adId]);

    return ['success' => true, 'thread_id' => (int) $pdo->lastInsertId()];
}

/**
 * @return array{success: bool, error?: string, thread_id?: int, ticket_id?: int}
 */
function crg_chat_create_support_ticket(
    PDO $pdo,
    int $userId,
    string $subject,
    string $category,
    string $body,
    ?string $contextJson
): array {
    if (!crg_chat_tables_ready($pdo)) {
        return ['success' => false, 'error' => 'Chat tables not deployed'];
    }

    $labels = crg_chat_support_category_labels();
    if (!isset($labels[$category])) {
        $category = 'other';
    }
    $subject = trim($subject);
    if ($subject === '') {
        $subject = $labels[$category];
    }
    if (mb_strlen($subject) > 255) {
        $subject = mb_substr($subject, 0, 255);
    }
    $body = crg_chat_sanitize_body($body);
    if ($body === '') {
        return ['success' => false, 'error' => 'Текст сообщения обязателен'];
    }

    $open = $pdo->prepare(
        "SELECT COUNT(*) FROM support_tickets
         WHERE user_id = ? AND status NOT IN ('resolved','closed')"
    );
    $open->execute([$userId]);
    if ((int) $open->fetchColumn() >= 3) {
        return ['success' => false, 'error' => 'Слишком много открытых обращений. Дождитесь ответа.'];
    }

    $recent = $pdo->prepare(
        'SELECT id FROM support_tickets WHERE user_id = ? AND created_at > DATE_SUB(NOW(), INTERVAL 60 SECOND) LIMIT 1'
    );
    $recent->execute([$userId]);
    if ($recent->fetch() !== false) {
        return ['success' => false, 'error' => 'Подождите минуту перед новым обращением'];
    }

    $pdo->beginTransaction();
    try {
        $st = $pdo->prepare(
            'INSERT INTO support_tickets (user_id, subject, category, status, context_json, created_at)
             VALUES (?, ?, ?, \'new\', ?, NOW())'
        );
        $ctx = $contextJson !== null && $contextJson !== '' ? $contextJson : null;
        $st->execute([$userId, $subject, $category, $ctx]);
        $ticketId = (int) $pdo->lastInsertId();

        $st = $pdo->prepare(
            'INSERT INTO chat_threads
             (type, status, user_id_customer, support_ticket_id, last_message_at, last_message_preview, created_at, updated_at)
             VALUES (\'support\', \'active\', ?, ?, NOW(), ?, NOW(), NOW())'
        );
        $preview = crg_chat_preview($body);
        $st->execute([$userId, $ticketId, $preview]);
        $threadId = (int) $pdo->lastInsertId();

        $st = $pdo->prepare(
            'INSERT INTO chat_messages (thread_id, sender_type, sender_user_id, body, created_at)
             VALUES (?, \'user\', ?, ?, NOW())'
        );
        $st->execute([$threadId, $userId, $body]);

        $pdo->commit();

        return ['success' => true, 'thread_id' => $threadId, 'ticket_id' => $ticketId];
    } catch (Throwable $e) {
        $pdo->rollBack();

        return ['success' => false, 'error' => 'Не удалось создать обращение'];
    }
}

function crg_chat_user_can_access_thread(PDO $pdo, int $userId, int $threadId): bool
{
    $st = $pdo->prepare(
        'SELECT id FROM chat_threads
         WHERE id = ? AND (
           user_id_customer = ? OR user_id_performer = ?
           OR (type = \'support\' AND user_id_customer = ?)
         ) LIMIT 1'
    );
    $st->execute([$threadId, $userId, $userId, $userId]);

    return $st->fetch() !== false;
}

function crg_chat_thread_can_write(PDO $pdo, int $threadId): bool
{
    $st = $pdo->prepare('SELECT type, status, support_ticket_id FROM chat_threads WHERE id = ? LIMIT 1');
    $st->execute([$threadId]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if ($row === false) {
        return false;
    }
    $status = (string) ($row['status'] ?? '');
    if (in_array($status, ['readonly', 'closed'], true)) {
        return false;
    }
    if (($row['type'] ?? '') === 'support' && !empty($row['support_ticket_id'])) {
        $st2 = $pdo->prepare('SELECT status FROM support_tickets WHERE id = ? LIMIT 1');
        $st2->execute([(int) $row['support_ticket_id']]);
        $ticket = $st2->fetch(PDO::FETCH_ASSOC);
        if ($ticket !== false && in_array((string) $ticket['status'], ['closed', 'resolved'], true)) {
            return false;
        }
    }

    return in_array($status, ['draft', 'active'], true);
}

function crg_chat_unread_count(PDO $pdo, int $threadId, int $userId): int
{
    try {
        $st = $pdo->prepare(
            'SELECT last_read_message_id FROM chat_read_state
             WHERE thread_id = ? AND user_id = ? LIMIT 1'
        );
        $st->execute([$threadId, $userId]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        $lastRead = $row !== false ? (int) ($row['last_read_message_id'] ?? 0) : 0;

        $st = $pdo->prepare(
            'SELECT COUNT(*) FROM chat_messages
             WHERE thread_id = ? AND id > ? AND is_deleted = 0
               AND NOT (sender_type = \'user\' AND sender_user_id = ?)'
        );
        $st->execute([$threadId, $lastRead, $userId]);

        return (int) $st->fetchColumn();
    } catch (Throwable $e) {
        return 0;
    }
}

/**
 * @return list<array<string, mixed>>
 */
function crg_chat_list_threads(PDO $pdo, int $userId, ?string $type, int $limit, int $offset): array
{
    $where = '(t.user_id_customer = ? OR t.user_id_performer = ?)';
    $params = [$userId, $userId];
    if ($type === 'deal' || $type === 'support') {
        $where .= ' AND t.type = ?';
        $params[] = $type;
    }
    $limit = max(1, min(100, $limit));
    $offset = max(0, $offset);

    $sql = "
        SELECT t.*,
               tk.subject AS support_subject,
               tk.category AS support_category,
               tk.status AS ticket_status,
               tk.rating AS ticket_rating
        FROM chat_threads t
        LEFT JOIN support_tickets tk ON tk.id = t.support_ticket_id
        WHERE {$where}
        ORDER BY COALESCE(t.last_message_at, t.created_at) DESC
        LIMIT " . $limit . ' OFFSET ' . $offset;
    $st = $pdo->prepare($sql);
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);
    $out = [];
    foreach ($rows as $row) {
        $threadId = (int) ($row['id'] ?? 0);
        $threadType = (string) ($row['type'] ?? '');
        $counterpartId = 0;
        $title = '';
        if ($threadType === 'support') {
            $title = (string) ($row['support_subject'] ?? 'Поддержка');
            $counterpartName = 'Служба поддержки';
        } else {
            $customerId = (int) ($row['user_id_customer'] ?? 0);
            $performerId = (int) ($row['user_id_performer'] ?? 0);
            $counterpartId = $userId === $customerId ? $performerId : $customerId;
            $counterpartName = crg_chat_user_display_name($pdo, $counterpartId);
            $title = 'Диалог · объявление #' . (int) ($row['ad_id'] ?? 0);
        }
        $out[] = [
            'id' => $threadId,
            'type' => $threadType,
            'status' => (string) ($row['status'] ?? ''),
            'title' => $title,
            'counterpart_name' => $counterpartName ?? 'Служба поддержки',
            'counterpart_user_id' => $counterpartId,
            'unread_count' => crg_chat_unread_count($pdo, $threadId, $userId),
            'last_message_preview' => (string) ($row['last_message_preview'] ?? ''),
            'last_message_at' => $row['last_message_at'] ?? $row['created_at'],
            'bd' => isset($row['bd']) ? (int) $row['bd'] : null,
            'ad_id' => isset($row['ad_id']) ? (int) $row['ad_id'] : null,
            'support_ticket_id' => isset($row['support_ticket_id']) ? (int) $row['support_ticket_id'] : null,
            'ticket_status' => $row['ticket_status'] ?? null,
            'needs_rating' => $threadType === 'support'
                && ($row['ticket_status'] ?? '') === 'resolved'
                && ($row['ticket_rating'] ?? null) === null,
        ];
    }

    return $out;
}

/**
 * @return list<array<string, mixed>>
 */
function crg_chat_get_messages(PDO $pdo, int $threadId, int $userId, ?int $beforeId, int $limit): array
{
    if (!crg_chat_user_can_access_thread($pdo, $userId, $threadId)) {
        return [];
    }
    $params = [$threadId];
    $beforeSql = '';
    if ($beforeId !== null && $beforeId > 0) {
        $beforeSql = ' AND id < ?';
        $params[] = $beforeId;
    }
    $limit = max(1, min(100, $limit));
    $st = $pdo->prepare(
        'SELECT ' . crg_chat_message_select_sql() . "
         FROM chat_messages
         WHERE thread_id = ? AND is_deleted = 0{$beforeSql}
         ORDER BY id DESC
         LIMIT {$limit}"
    );
    $st->execute($params);
    $rows = array_reverse($st->fetchAll(PDO::FETCH_ASSOC));
    $out = [];
    foreach ($rows as $row) {
        $out[] = crg_chat_format_message($row, $userId);
    }

    return $out;
}

/**
 * @param array{path: string, mime: string, name: string}|null $attachment
 * @return array{success: bool, error?: string, message_id?: int}
 */
function crg_chat_send_user_message(
    PDO $pdo,
    int $userId,
    int $threadId,
    string $body,
    ?array $attachment = null
): array {
    if (!crg_chat_user_can_access_thread($pdo, $userId, $threadId)) {
        return ['success' => false, 'error' => 'Нет доступа'];
    }
    if (!crg_chat_thread_can_write($pdo, $threadId)) {
        return ['success' => false, 'error' => 'Диалог закрыт для сообщений'];
    }
    $body = crg_chat_sanitize_body($body);
    $hasAttachment = is_array($attachment) && !empty($attachment['path']);
    if ($body === '' && !$hasAttachment) {
        return ['success' => false, 'error' => 'Пустое сообщение'];
    }
    if ($body === '' && $hasAttachment) {
        $body = '📎 ' . (string) ($attachment['name'] ?? 'Файл');
    }

    $rate = $pdo->prepare(
        'SELECT COUNT(*) FROM chat_messages
         WHERE sender_user_id = ? AND created_at > DATE_SUB(NOW(), INTERVAL 1 MINUTE)'
    );
    $rate->execute([$userId]);
    if ((int) $rate->fetchColumn() >= 20) {
        return ['success' => false, 'error' => 'Слишком много сообщений. Подождите.'];
    }

    $preview = crg_chat_preview($body);
    $st = $pdo->prepare(
        'INSERT INTO chat_messages
         (thread_id, sender_type, sender_user_id, body, attachment_path, attachment_mime, attachment_name, created_at)
         VALUES (?, \'user\', ?, ?, ?, ?, ?, NOW())'
    );
    $st->execute([
        $threadId,
        $userId,
        $body,
        $hasAttachment ? (string) $attachment['path'] : null,
        $hasAttachment ? (string) ($attachment['mime'] ?? '') : null,
        $hasAttachment ? (string) ($attachment['name'] ?? '') : null,
    ]);
    $messageId = (int) $pdo->lastInsertId();

    $pdo->prepare(
        'UPDATE chat_threads SET last_message_at = NOW(), last_message_preview = ?, updated_at = NOW() WHERE id = ?'
    )->execute([$preview, $threadId]);

    crg_chat_on_support_user_message($pdo, $threadId);
    crg_chat_notify_counterpart($pdo, $threadId, $userId);

    return ['success' => true, 'message_id' => $messageId];
}

function crg_chat_fcm_data(int $threadId, string $chatType, array $extra = []): array
{
    return array_merge([
        'type' => 'chat_message',
        'thread_id' => (string) $threadId,
        'chat_type' => $chatType,
    ], $extra);
}

function crg_chat_push_user(
    PDO $pdo,
    int $userId,
    string $title,
    string $body,
    int $threadId,
    string $chatType,
    array $extra = []
): void {
    if (!function_exists('crg_fcm_send_to_user')) {
        $fcmPath = __DIR__ . '/fcm_push.php';
        if (is_readable($fcmPath)) {
            require_once $fcmPath;
        }
    }
    if (!function_exists('crg_fcm_send_to_user')) {
        return;
    }
    crg_fcm_send_to_user(
        $pdo,
        $userId,
        $title,
        $body,
        crg_chat_fcm_data($threadId, $chatType, $extra)
    );
}

function crg_chat_on_support_user_message(PDO $pdo, int $threadId): void
{
    $st = $pdo->prepare(
        'SELECT type, support_ticket_id FROM chat_threads WHERE id = ? LIMIT 1'
    );
    $st->execute([$threadId]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if ($row === false || ($row['type'] ?? '') !== 'support') {
        return;
    }
    $ticketId = (int) ($row['support_ticket_id'] ?? 0);
    if ($ticketId <= 0) {
        return;
    }
    $pdo->prepare(
        "UPDATE support_tickets SET status = 'assigned'
         WHERE id = ? AND status IN ('waiting_user', 'new')"
    )->execute([$ticketId]);
}

function crg_chat_mark_read(PDO $pdo, int $userId, int $threadId, int $lastMessageId): void
{
    if (!crg_chat_user_can_access_thread($pdo, $userId, $threadId)) {
        return;
    }
    $st = $pdo->prepare(
        'INSERT INTO chat_read_state (thread_id, user_id, last_read_message_id)
         VALUES (?, ?, ?)
         ON DUPLICATE KEY UPDATE last_read_message_id = GREATEST(last_read_message_id, VALUES(last_read_message_id))'
    );
    $st->execute([$threadId, $userId, $lastMessageId]);
}

function crg_chat_notify_counterpart(PDO $pdo, int $threadId, int $senderUserId): void
{
    if (!function_exists('crg_fcm_send_to_user')) {
        $fcmPath = __DIR__ . '/fcm_push.php';
        if (is_readable($fcmPath)) {
            require_once $fcmPath;
        }
    }
    if (!function_exists('crg_fcm_send_to_user')) {
        return;
    }

    $st = $pdo->prepare(
        'SELECT type, user_id_customer, user_id_performer FROM chat_threads WHERE id = ? LIMIT 1'
    );
    $st->execute([$threadId]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if ($row === false) {
        return;
    }

    $recipientId = 0;
    $title = 'Новое сообщение';
    if (($row['type'] ?? '') === 'support') {
        return;
    }
    $customerId = (int) ($row['user_id_customer'] ?? 0);
    $performerId = (int) ($row['user_id_performer'] ?? 0);
    if ($senderUserId === $customerId) {
        $recipientId = $performerId;
    } elseif ($senderUserId === $performerId) {
        $recipientId = $customerId;
    }
    if ($recipientId <= 0) {
        return;
    }

    crg_chat_push_user(
        $pdo,
        $recipientId,
        $title,
        'У вас новое сообщение в приложении',
        $threadId,
        'deal'
    );
}

function crg_chat_notify_user_support_reply(PDO $pdo, int $userId, int $threadId): void
{
    crg_chat_push_user(
        $pdo,
        $userId,
        'Ответ службы поддержки',
        'Проверьте сообщения в приложении',
        $threadId,
        'support'
    );
}

/**
 * @return list<array<string, mixed>>
 */
function crg_chat_poll_messages(PDO $pdo, int $userId, int $threadId, int $afterId): array
{
    if (!crg_chat_user_can_access_thread($pdo, $userId, $threadId)) {
        return [];
    }
    $st = $pdo->prepare(
        'SELECT ' . crg_chat_message_select_sql() . '
         FROM chat_messages
         WHERE thread_id = ? AND id > ? AND is_deleted = 0
         ORDER BY id ASC'
    );
    $st->execute([$threadId, $afterId]);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);
    $out = [];
    foreach ($rows as $row) {
        $out[] = crg_chat_format_message($row, $userId);
    }

    return $out;
}

function crg_chat_customer_order_table(int $bd): ?string
{
    return match ($bd) {
        1 => 'orders',
        2 => 'orderst',
        3 => 'ordersg',
        default => null,
    };
}

function crg_chat_performer_ad_table(int $bd): ?string
{
    return match ($bd) {
        1 => 'add_ob_gp',
        2 => 'add_ob_vidt',
        3 => 'add_ob_gr',
        default => null,
    };
}

function crg_chat_customer_id_from_order(PDO $pdo, int $bd, int $orderId): int
{
    $table = crg_chat_customer_order_table($bd);
    if ($table === null || $orderId <= 0) {
        return 0;
    }
    try {
        $st = $pdo->prepare("SELECT iduser FROM {$table} WHERE id = ? LIMIT 1");
        $st->execute([$orderId]);

        return (int) $st->fetchColumn();
    } catch (Throwable $e) {
        return 0;
    }
}

function crg_chat_performer_id_from_ad(PDO $pdo, int $bd, int $adId): int
{
    $table = crg_chat_performer_ad_table($bd);
    if ($table === null || $adId <= 0) {
        return 0;
    }
    try {
        $st = $pdo->prepare("SELECT iduser FROM {$table} WHERE id = ? LIMIT 1");
        $st->execute([$adId]);

        return (int) $st->fetchColumn();
    } catch (Throwable $e) {
        return 0;
    }
}

function crg_chat_add_system_message(PDO $pdo, int $threadId, string $body): void
{
    if ($threadId <= 0 || !crg_chat_tables_ready($pdo)) {
        return;
    }
    $body = crg_chat_sanitize_body($body);
    if ($body === '') {
        return;
    }
    $preview = crg_chat_preview($body);
    $st = $pdo->prepare(
        'INSERT INTO chat_messages (thread_id, sender_type, body, created_at)
         VALUES (?, \'system\', ?, NOW())'
    );
    $st->execute([$threadId, $body]);
    $pdo->prepare(
        'UPDATE chat_threads SET last_message_at = NOW(), last_message_preview = ?, updated_at = NOW() WHERE id = ?'
    )->execute([$preview, $threadId]);
}

function crg_chat_find_deal_thread_id(
    PDO $pdo,
    int $customerId,
    int $performerId,
    int $bd,
    int $adId
): int {
    if (!crg_chat_tables_ready($pdo)) {
        return 0;
    }
    $st = $pdo->prepare(
        'SELECT id FROM chat_threads
         WHERE type = \'deal\' AND bd = ? AND ad_id = ?
           AND user_id_customer = ? AND user_id_performer = ?
         LIMIT 1'
    );
    $st->execute([$bd, $adId, $customerId, $performerId]);
    $id = $st->fetchColumn();

    return $id !== false ? (int) $id : 0;
}

function crg_chat_ensure_deal_thread(
    PDO $pdo,
    int $customerId,
    int $performerId,
    int $bd,
    int $adId,
    ?int $offerDataId = null,
    ?int $orderGlobalId = null,
    ?string $status = null
): int {
    if (!crg_chat_tables_ready($pdo) || $customerId <= 0 || $performerId <= 0 || $bd <= 0 || $adId <= 0) {
        return 0;
    }

    $threadId = crg_chat_find_deal_thread_id($pdo, $customerId, $performerId, $bd, $adId);
    if ($threadId > 0) {
        $updates = [];
        $params = [];
        if ($offerDataId !== null && $offerDataId > 0) {
            $updates[] = 'offer_data_id = ?';
            $params[] = $offerDataId;
        }
        if ($orderGlobalId !== null && $orderGlobalId > 0) {
            $updates[] = 'order_global_id = ?';
            $params[] = $orderGlobalId;
        }
        if ($status !== null && $status !== '') {
            $updates[] = 'status = ?';
            $params[] = $status;
        }
        if ($updates !== []) {
            $params[] = $threadId;
            $pdo->prepare(
                'UPDATE chat_threads SET ' . implode(', ', $updates) . ', updated_at = NOW() WHERE id = ?'
            )->execute($params);
        }

        return $threadId;
    }

    $threadStatus = $status ?? 'draft';
    $st = $pdo->prepare(
        'INSERT INTO chat_threads
         (type, status, user_id_customer, user_id_performer, bd, ad_id, offer_data_id, order_global_id, created_at, updated_at)
         VALUES (\'deal\', ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())'
    );
    $st->execute([
        $threadStatus,
        $customerId,
        $performerId,
        $bd,
        $adId,
        $offerDataId !== null && $offerDataId > 0 ? $offerDataId : null,
        $orderGlobalId !== null && $orderGlobalId > 0 ? $orderGlobalId : null,
    ]);

    return (int) $pdo->lastInsertId();
}

function crg_chat_on_offer_data(PDO $pdo, int $offerId, int $performerId, int $orderId, int $bd): void
{
    if ($offerId <= 0 || $performerId <= 0 || $orderId <= 0 || $bd <= 0) {
        return;
    }
    $customerId = crg_chat_customer_id_from_order($pdo, $bd, $orderId);
    if ($customerId <= 0) {
        return;
    }
    $threadId = crg_chat_ensure_deal_thread($pdo, $customerId, $performerId, $bd, $orderId, $offerId, null, 'draft');
    if ($threadId <= 0) {
        return;
    }
    crg_chat_add_system_message($pdo, $threadId, 'Исполнитель отправил предложение');
}

function crg_chat_on_offer_dataf(PDO $pdo, int $offerId, int $customerId, int $performerAdId, int $bd): void
{
    if ($offerId <= 0 || $customerId <= 0 || $performerAdId <= 0 || $bd <= 0) {
        return;
    }
    $performerId = crg_chat_performer_id_from_ad($pdo, $bd, $performerAdId);
    if ($performerId <= 0) {
        return;
    }
    $threadId = crg_chat_ensure_deal_thread($pdo, $customerId, $performerId, $bd, $performerAdId, $offerId, null, 'draft');
    if ($threadId <= 0) {
        return;
    }
    crg_chat_add_system_message($pdo, $threadId, 'Заказчик отправил предложение');
}

/**
 * @return array<string, mixed>|null
 */
function crg_chat_load_offer_row(PDO $pdo, int $offerId): ?array
{
    if ($offerId <= 0) {
        return null;
    }
    foreach (['offer_data', 'offer_dataf'] as $table) {
        try {
            $st = $pdo->prepare("SELECT * FROM {$table} WHERE id = ? LIMIT 1");
            $st->execute([$offerId]);
            $row = $st->fetch(PDO::FETCH_ASSOC);
            if ($row !== false) {
                $row['_table'] = $table;

                return $row;
            }
        } catch (Throwable $e) {
            continue;
        }
    }

    return null;
}

function crg_chat_deal_context_from_offer(PDO $pdo, array $offer): ?array
{
    $bd = (int) ($offer['bd'] ?? 0);
    if (($offer['_table'] ?? '') === 'offer_dataf') {
        $adId = (int) ($offer['iduser'] ?? 0);
        $customerId = (int) ($offer['iduserp'] ?? 0);
        $performerId = crg_chat_performer_id_from_ad($pdo, $bd, $adId);
    } else {
        $adId = (int) ($offer['iduser'] ?? 0);
        $performerId = (int) ($offer['iduserp'] ?? 0);
        $customerId = crg_chat_customer_id_from_order($pdo, $bd, $adId);
    }
    if ($customerId <= 0 || $performerId <= 0 || $adId <= 0 || $bd <= 0) {
        return null;
    }

    return [
        'customer_id' => $customerId,
        'performer_id' => $performerId,
        'bd' => $bd,
        'ad_id' => $adId,
        'offer_id' => (int) ($offer['id'] ?? 0),
    ];
}

function crg_chat_on_ordersglobal_created(PDO $pdo, int $orderGlobalId): void
{
    if ($orderGlobalId <= 0) {
        return;
    }
    $st = $pdo->prepare('SELECT * FROM ordersglobal WHERE id = ? LIMIT 1');
    $st->execute([$orderGlobalId]);
    $order = $st->fetch(PDO::FETCH_ASSOC);
    if ($order === false) {
        return;
    }
    $offerId = (int) ($order['idoffer'] ?? 0);
    $offer = crg_chat_load_offer_row($pdo, $offerId);
    if ($offer === null) {
        return;
    }
    $ctx = crg_chat_deal_context_from_offer($pdo, $offer);
    if ($ctx === null) {
        return;
    }
    $threadId = crg_chat_ensure_deal_thread(
        $pdo,
        (int) $ctx['customer_id'],
        (int) $ctx['performer_id'],
        (int) $ctx['bd'],
        (int) $ctx['ad_id'],
        (int) $ctx['offer_id'],
        $orderGlobalId,
        'active'
    );
    if ($threadId <= 0) {
        return;
    }
    crg_chat_add_system_message($pdo, $threadId, 'Заказ принят к выполнению');
    crg_chat_push_user(
        $pdo,
        (int) $ctx['customer_id'],
        'Новое сообщение по заказу',
        'Заказ принят к выполнению',
        $threadId,
        'deal'
    );
    crg_chat_push_user(
        $pdo,
        (int) $ctx['performer_id'],
        'Новое сообщение по заказу',
        'Заказ принят к выполнению',
        $threadId,
        'deal'
    );
}

function crg_chat_on_ordersglobal_status(PDO $pdo, int $orderGlobalId, string $newStatus): void
{
    if ($orderGlobalId <= 0) {
        return;
    }
    $st = $pdo->prepare('SELECT * FROM ordersglobal WHERE id = ? LIMIT 1');
    $st->execute([$orderGlobalId]);
    $order = $st->fetch(PDO::FETCH_ASSOC);
    if ($order === false) {
        return;
    }
    $offer = crg_chat_load_offer_row($pdo, (int) ($order['idoffer'] ?? 0));
    if ($offer === null) {
        return;
    }
    $ctx = crg_chat_deal_context_from_offer($pdo, $offer);
    if ($ctx === null) {
        return;
    }
    $threadId = crg_chat_find_deal_thread_id(
        $pdo,
        (int) $ctx['customer_id'],
        (int) $ctx['performer_id'],
        (int) $ctx['bd'],
        (int) $ctx['ad_id']
    );
    if ($threadId <= 0) {
        $threadId = crg_chat_ensure_deal_thread(
            $pdo,
            (int) $ctx['customer_id'],
            (int) $ctx['performer_id'],
            (int) $ctx['bd'],
            (int) $ctx['ad_id'],
            (int) $ctx['offer_id'],
            $orderGlobalId,
            'active'
        );
    }
    if ($threadId <= 0) {
        return;
    }

    if ($newStatus === 'выполнен') {
        $pdo->prepare('UPDATE chat_threads SET status = \'readonly\' WHERE id = ?')->execute([$threadId]);
        crg_chat_add_system_message($pdo, $threadId, 'Заказ отмечен как выполненный');
        $msg = 'Заказ отмечен как выполненный';
    } elseif ($newStatus === 'отменен') {
        $pdo->prepare('UPDATE chat_threads SET status = \'readonly\' WHERE id = ?')->execute([$threadId]);
        crg_chat_add_system_message($pdo, $threadId, 'Сделка отменена');
        $msg = 'Сделка отменена';
    } else {
        return;
    }

    crg_chat_push_user($pdo, (int) $ctx['customer_id'], 'Обновление по заказу', $msg, $threadId, 'deal');
    crg_chat_push_user($pdo, (int) $ctx['performer_id'], 'Обновление по заказу', $msg, $threadId, 'deal');
}

function crg_chat_rate_support_ticket(PDO $pdo, int $userId, int $ticketId, int $rating, string $comment): array
{
    if (!crg_chat_tables_ready($pdo)) {
        return ['success' => false, 'error' => 'Chat not deployed'];
    }
    if ($ticketId <= 0) {
        return ['success' => false, 'error' => 'ticket_id required'];
    }
    if ($rating < 1 || $rating > 5) {
        return ['success' => false, 'error' => 'Оценка от 1 до 5'];
    }
    $st = $pdo->prepare('SELECT id, user_id, status, rating FROM support_tickets WHERE id = ? LIMIT 1');
    $st->execute([$ticketId]);
    $ticket = $st->fetch(PDO::FETCH_ASSOC);
    if ($ticket === false) {
        return ['success' => false, 'error' => 'Обращение не найдено'];
    }
    if ((int) ($ticket['user_id'] ?? 0) !== $userId) {
        return ['success' => false, 'error' => 'Нет доступа'];
    }
    if ((string) ($ticket['status'] ?? '') !== 'resolved') {
        return ['success' => false, 'error' => 'Оценка доступна после решения обращения'];
    }
    if ($ticket['rating'] !== null && (int) $ticket['rating'] > 0) {
        return ['success' => false, 'error' => 'Оценка уже отправлена'];
    }
    $comment = trim($comment);
    if (mb_strlen($comment) > 2000) {
        $comment = mb_substr($comment, 0, 2000);
    }
    $pdo->prepare(
        'UPDATE support_tickets SET rating = ?, rating_comment = ? WHERE id = ?'
    )->execute([$rating, $comment !== '' ? $comment : null, $ticketId]);

    return ['success' => true];
}
