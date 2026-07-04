<?php
declare(strict_types=1);

function crg_admin_support_tables_ready(PDO $pdo): bool
{
    return function_exists('crg_chat_tables_ready') && crg_chat_tables_ready($pdo);
}

function crg_admin_support_new_count(PDO $pdo): int
{
    if (!crg_admin_support_tables_ready($pdo)) {
        return 0;
    }
    try {
        $st = $pdo->query("SELECT COUNT(*) FROM support_tickets WHERE status = 'new'");

        return (int) $st->fetchColumn();
    } catch (Throwable $e) {
        return 0;
    }
}

/**
 * @return list<array<string, mixed>>
 */
function crg_admin_support_queue(PDO $pdo, string $statusFilter, int $limit, int $offset): array
{
    if (!crg_admin_support_tables_ready($pdo)) {
        return [];
    }
    $where = '1=1';
    $params = [];
    if ($statusFilter !== '' && $statusFilter !== 'all') {
        $where .= ' AND tk.status = ?';
        $params[] = $statusFilter;
    }
    $limit = max(1, min(100, $limit));
    $offset = max(0, $offset);

    $sql = "
        SELECT tk.*, u.firstName, u.lastName, u.middleName, u.namefirm, u.city, u.phone, u.email,
               th.id AS thread_id
        FROM support_tickets tk
        INNER JOIN users u ON u.idusers = tk.user_id
        LEFT JOIN chat_threads th ON th.support_ticket_id = tk.id AND th.type = 'support'
        WHERE {$where}
        ORDER BY tk.created_at DESC
        LIMIT " . $limit . ' OFFSET ' . $offset;
    $st = $pdo->prepare($sql);
    $st->execute($params);

    return $st->fetchAll(PDO::FETCH_ASSOC);
}

function crg_admin_support_queue_total(PDO $pdo, string $statusFilter): int
{
    if (!crg_admin_support_tables_ready($pdo)) {
        return 0;
    }
    if ($statusFilter === '' || $statusFilter === 'all') {
        $st = $pdo->query('SELECT COUNT(*) FROM support_tickets');

        return (int) $st->fetchColumn();
    }
    $st = $pdo->prepare('SELECT COUNT(*) FROM support_tickets WHERE status = ?');
    $st->execute([$statusFilter]);

    return (int) $st->fetchColumn();
}

/**
 * @return array<string, mixed>|null
 */
function crg_admin_support_ticket(PDO $pdo, int $ticketId): ?array
{
    if (!crg_admin_support_tables_ready($pdo)) {
        return null;
    }
    $st = $pdo->prepare(
        'SELECT tk.*, u.firstName, u.lastName, u.middleName, u.namefirm, u.city, u.phone, u.email,
                u.rollNum, u.flag, th.id AS thread_id
         FROM support_tickets tk
         INNER JOIN users u ON u.idusers = tk.user_id
         LEFT JOIN chat_threads th ON th.support_ticket_id = tk.id AND th.type = \'support\'
         WHERE tk.id = ?
         LIMIT 1'
    );
    $st->execute([$ticketId]);
    $row = $st->fetch(PDO::FETCH_ASSOC);

    return $row !== false ? $row : null;
}

/**
 * @return list<array<string, mixed>>
 */
function crg_admin_support_messages(PDO $pdo, int $threadId): array
{
    if ($threadId <= 0) {
        return [];
    }
    $st = $pdo->prepare(
        'SELECT m.*, aa.login AS admin_login
         FROM chat_messages m
         LEFT JOIN admin_accounts aa ON aa.id = m.sender_admin_id
         WHERE m.thread_id = ? AND m.is_deleted = 0
         ORDER BY m.id ASC'
    );
    $st->execute([$threadId]);

    return $st->fetchAll(PDO::FETCH_ASSOC);
}

/**
 * @return list<array<string, mixed>>
 */
function crg_admin_support_messages_since(PDO $pdo, int $threadId, int $afterId): array
{
    if ($threadId <= 0) {
        return [];
    }
    $st = $pdo->prepare(
        'SELECT m.*, aa.login AS admin_login
         FROM chat_messages m
         LEFT JOIN admin_accounts aa ON aa.id = m.sender_admin_id
         WHERE m.thread_id = ? AND m.id > ? AND m.is_deleted = 0
         ORDER BY m.id ASC'
    );
    $st->execute([$threadId, max(0, $afterId)]);

    return $st->fetchAll(PDO::FETCH_ASSOC);
}

function crg_admin_support_message_to_json(array $msg): array
{
    $attachmentPath = trim((string) ($msg['attachment_path'] ?? ''));
    $attachmentMime = trim((string) ($msg['attachment_mime'] ?? ''));

    return [
        'id' => (int) ($msg['id'] ?? 0),
        'sender_type' => (string) ($msg['sender_type'] ?? 'user'),
        'body' => (string) ($msg['body'] ?? ''),
        'created_at' => (string) ($msg['created_at'] ?? ''),
        'admin_login' => (string) ($msg['admin_login'] ?? ''),
        'has_attachment' => $attachmentPath !== '',
        'attachment_mime' => $attachmentMime !== '' ? $attachmentMime : null,
        'attachment_name' => trim((string) ($msg['attachment_name'] ?? '')) ?: null,
        'is_image_attachment' => $attachmentPath !== '' && crg_chat_is_image_mime($attachmentMime),
    ];
}

/**
 * @return array<string, mixed>|null
 */
function crg_admin_support_message_attachment(PDO $pdo, int $messageId): ?array
{
    $st = $pdo->prepare(
        'SELECT m.attachment_path, m.attachment_mime, m.attachment_name
         FROM chat_messages m
         INNER JOIN chat_threads t ON t.id = m.thread_id
         WHERE m.id = ? AND m.is_deleted = 0 AND t.type = "support"
         LIMIT 1'
    );
    $st->execute([$messageId]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if ($row === false) {
        return null;
    }
    $path = trim((string) ($row['attachment_path'] ?? ''));
    if ($path === '') {
        return null;
    }
    $abs = crg_chat_attachment_abs_path($path);
    if ($abs === null) {
        return null;
    }

    return [
        'abs_path' => $abs,
        'mime' => (string) ($row['attachment_mime'] ?? 'application/octet-stream'),
        'name' => (string) ($row['attachment_name'] ?? basename($path)),
    ];
}

function crg_admin_support_assign(PDO $pdo, int $ticketId, int $adminId): ?string
{
    $ticket = crg_admin_support_ticket($pdo, $ticketId);
    if ($ticket === null) {
        return 'Обращение не найдено';
    }
    if (in_array((string) ($ticket['status'] ?? ''), ['closed', 'resolved'], true)) {
        return 'Обращение уже закрыто';
    }
    $pdo->prepare(
        'UPDATE support_tickets SET status = \'assigned\', assigned_admin_id = ?, assigned_at = NOW() WHERE id = ?'
    )->execute([$adminId, $ticketId]);

    return null;
}

function crg_admin_support_send_reply(PDO $pdo, int $ticketId, int $adminId, string $body): ?string
{
    $ticket = crg_admin_support_ticket($pdo, $ticketId);
    if ($ticket === null) {
        return 'Обращение не найдено';
    }
    $threadId = (int) ($ticket['thread_id'] ?? 0);
    if ($threadId <= 0) {
        return 'Диалог не найден';
    }
    if (in_array((string) ($ticket['status'] ?? ''), ['closed'], true)) {
        return 'Обращение закрыто';
    }

    $body = crg_chat_sanitize_body($body);
    if ($body === '') {
        return 'Введите текст ответа';
    }

    if ((int) ($ticket['assigned_admin_id'] ?? 0) === 0) {
        crg_admin_support_assign($pdo, $ticketId, $adminId);
    }

    $preview = crg_chat_preview($body);
    $st = $pdo->prepare(
        'INSERT INTO chat_messages (thread_id, sender_type, sender_admin_id, body, created_at)
         VALUES (?, \'admin\', ?, ?, NOW())'
    );
    $st->execute([$threadId, $adminId, $body]);

    $pdo->prepare(
        'UPDATE chat_threads SET last_message_at = NOW(), last_message_preview = ?, updated_at = NOW() WHERE id = ?'
    )->execute([$preview, $threadId]);

    $pdo->prepare(
        'UPDATE support_tickets SET status = \'waiting_user\' WHERE id = ?'
    )->execute([$ticketId]);

    crg_chat_notify_user_support_reply($pdo, (int) ($ticket['user_id'] ?? 0), $threadId);

    return null;
}

function crg_admin_support_set_status(PDO $pdo, int $ticketId, string $status): ?string
{
    $allowed = ['new', 'assigned', 'waiting_user', 'resolved', 'closed'];
    if (!in_array($status, $allowed, true)) {
        return 'Недопустимый статус';
    }
    $ticket = crg_admin_support_ticket($pdo, $ticketId);
    if ($ticket === null) {
        return 'Обращение не найдено';
    }
    $threadId = (int) ($ticket['thread_id'] ?? 0);
    $closedAt = in_array($status, ['closed', 'resolved'], true) ? date('Y-m-d H:i:s') : null;

    $st = $pdo->prepare(
        'UPDATE support_tickets SET status = ?, closed_at = COALESCE(?, closed_at) WHERE id = ?'
    );
    $st->execute([$status, $closedAt, $ticketId]);

    if ($threadId > 0 && in_array($status, ['closed', 'resolved'], true)) {
        $threadStatus = $status === 'resolved' ? 'readonly' : 'closed';
        $pdo->prepare('UPDATE chat_threads SET status = ? WHERE id = ?')->execute([$threadStatus, $threadId]);
    }

    if ($status === 'resolved') {
        $userId = (int) ($ticket['user_id'] ?? 0);
        if ($userId > 0 && $threadId > 0) {
            crg_chat_push_user(
                $pdo,
                $userId,
                'Обращение решено',
                'Оцените ответ службы поддержки',
                $threadId,
                'support',
                [
                    'needs_rating' => '1',
                    'ticket_id' => (string) $ticketId,
                ]
            );
        }
    }

    return null;
}

function crg_admin_support_user_name(array $row): string
{
    $parts = array_filter([
        trim((string) ($row['lastName'] ?? '')),
        trim((string) ($row['firstName'] ?? '')),
        trim((string) ($row['middleName'] ?? '')),
    ]);
    if ($parts !== []) {
        return implode(' ', $parts);
    }
    $firm = trim((string) ($row['namefirm'] ?? ''));

    return $firm !== '' ? $firm : ('#' . (int) ($row['user_id'] ?? 0));
}

/** @return array<string, string> */
function crg_admin_support_status_labels(): array
{
    return [
        'new' => 'Новое',
        'assigned' => 'В работе',
        'waiting_user' => 'Ждём пользователя',
        'resolved' => 'Решено',
        'closed' => 'Закрыто',
    ];
}

/** @return array<int, string> */
function crg_admin_support_templates(): array
{
    return [
        1 => 'Здравствуйте! Мы получили ваше обращение и уже проверяем информацию.',
        2 => 'Пожалуйста, пришлите скриншот ошибки и номер объявления.',
        3 => 'Ваше объявление находится на модерации, обычно это занимает до 24 часов.',
        4 => 'Обращение закрыто. Если вопрос остался — создайте новое обращение.',
    ];
}
