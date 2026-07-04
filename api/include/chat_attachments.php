<?php
declare(strict_types=1);

function crg_chat_upload_root(): string
{
    $root = defined('TP_PUBLIC_ROOT') ? TP_PUBLIC_ROOT : dirname(__DIR__);

    return $root . '/uploads/chat';
}

function crg_chat_attachment_allowed_mimes(): array
{
    return [
        'image/jpeg' => ['jpg', 'jpeg'],
        'image/png' => ['png'],
        'image/gif' => ['gif'],
        'image/webp' => ['webp'],
        'application/pdf' => ['pdf'],
        'application/msword' => ['doc'],
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => ['docx'],
        'application/vnd.ms-excel' => ['xls'],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => ['xlsx'],
        'text/plain' => ['txt'],
    ];
}

function crg_chat_is_image_mime(string $mime): bool
{
    return str_starts_with($mime, 'image/');
}

function crg_chat_mime_from_extension(string $ext): ?string
{
    $ext = strtolower(ltrim($ext, '.'));
    if ($ext === '') {
        return null;
    }
    foreach (crg_chat_attachment_allowed_mimes() as $mime => $exts) {
        if (in_array($ext, $exts, true)) {
            return $mime;
        }
    }

    return null;
}

function crg_chat_normalize_upload_mime(string $mime, string $filename): string
{
    $ext = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
    if ($ext === '') {
        return $mime;
    }

    if ($mime === 'application/zip' || $mime === 'application/octet-stream') {
        if ($ext === 'docx') {
            return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        }
        if ($ext === 'xlsx') {
            return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        }
        if ($ext === 'doc') {
            return 'application/msword';
        }
        if ($ext === 'xls') {
            return 'application/vnd.ms-excel';
        }
    }

    $fromExt = crg_chat_mime_from_extension($ext);
    if ($fromExt !== null && !isset(crg_chat_attachment_allowed_mimes()[$mime])) {
        return $fromExt;
    }

    return $mime;
}

function crg_chat_str_len(string $value): int
{
    return function_exists('mb_strlen') ? mb_strlen($value) : strlen($value);
}

function crg_chat_str_sub(string $value, int $start, int $length): string
{
    if (function_exists('mb_substr')) {
        return mb_substr($value, $start, $length);
    }

    return substr($value, $start, $length);
}

/**
 * @return array{success: bool, error?: string, path?: string, mime?: string, name?: string}
 */
function crg_chat_process_upload(array $file, int $threadId): array
{
    $err = (int) ($file['error'] ?? UPLOAD_ERR_NO_FILE);
    if ($err === UPLOAD_ERR_NO_FILE) {
        return ['success' => false, 'error' => 'no_file'];
    }
    if ($err === UPLOAD_ERR_INI_SIZE || $err === UPLOAD_ERR_FORM_SIZE) {
        return ['success' => false, 'error' => 'Файл слишком большой (макс. 12 МБ)'];
    }
    if ($err !== UPLOAD_ERR_OK) {
        return ['success' => false, 'error' => 'Ошибка загрузки файла (код ' . $err . ')'];
    }

    $size = (int) ($file['size'] ?? 0);
    if ($size <= 0 || $size > 12 * 1024 * 1024) {
        return ['success' => false, 'error' => 'Файл слишком большой (макс. 12 МБ)'];
    }

    $tmp = (string) ($file['tmp_name'] ?? '');
    if ($tmp === '' || (!is_uploaded_file($tmp) && !is_readable($tmp))) {
        return ['success' => false, 'error' => 'Некорректный файл'];
    }

    $origName = basename((string) ($file['name'] ?? 'file'));
    $origName = preg_replace('/[^\p{L}\p{N}\.\-_\s]/u', '_', $origName) ?? 'file';
    if (crg_chat_str_len($origName) > 200) {
        $origName = crg_chat_str_sub($origName, 0, 200);
    }

    $mime = 'application/octet-stream';
    if (function_exists('finfo_open')) {
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        if ($finfo !== false) {
            $detected = finfo_file($finfo, $tmp);
            finfo_close($finfo);
            if (is_string($detected) && $detected !== '') {
                $mime = $detected;
            }
        }
    }
    $mime = crg_chat_normalize_upload_mime($mime, $origName);

    $allowed = crg_chat_attachment_allowed_mimes();
    if (!isset($allowed[$mime])) {
        return ['success' => false, 'error' => 'Тип файла не поддерживается'];
    }

    $ext = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
    if ($ext === '' || !in_array($ext, $allowed[$mime], true)) {
        $ext = $allowed[$mime][0];
    }

    $filename = date('Ymd_His') . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
    $dir = crg_chat_upload_root() . '/' . $threadId;
    if (!is_dir($dir) && !mkdir($dir, 0755, true) && !is_dir($dir)) {
        return ['success' => false, 'error' => 'Не удалось создать папку для файлов'];
    }

    $dest = $dir . '/' . $filename;
    $moved = is_uploaded_file($tmp) ? move_uploaded_file($tmp, $dest) : copy($tmp, $dest);
    if (!$moved) {
        return ['success' => false, 'error' => 'Не удалось сохранить файл на сервере'];
    }

    return [
        'success' => true,
        'path' => 'uploads/chat/' . $threadId . '/' . $filename,
        'mime' => $mime,
        'name' => $origName,
    ];
}

function crg_chat_attachment_abs_path(string $relativePath): ?string
{
    $relativePath = str_replace('\\', '/', trim($relativePath));
    if ($relativePath === '' || str_contains($relativePath, '..')) {
        return null;
    }
    if (!str_starts_with($relativePath, 'uploads/chat/')) {
        return null;
    }

    $root = defined('TP_PUBLIC_ROOT') ? TP_PUBLIC_ROOT : dirname(__DIR__);
    $full = $root . '/' . $relativePath;

    return is_readable($full) ? $full : null;
}

/**
 * @return array<string, mixed>|null
 */
function crg_chat_message_attachment(PDO $pdo, int $messageId, int $userId): ?array
{
    $st = $pdo->prepare(
        'SELECT m.id, m.thread_id, m.attachment_path, m.attachment_mime, m.attachment_name
         FROM chat_messages m
         WHERE m.id = ? AND m.is_deleted = 0
         LIMIT 1'
    );
    $st->execute([$messageId]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if ($row === false) {
        return null;
    }
    $threadId = (int) ($row['thread_id'] ?? 0);
    if (!crg_chat_user_can_access_thread($pdo, $userId, $threadId)) {
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

/**
 * @param array<string, mixed> $row
 * @return array<string, mixed>
 */
function crg_chat_format_message(array $row, int $userId): array
{
    $senderType = (string) ($row['sender_type'] ?? '');
    $senderUserId = isset($row['sender_user_id']) ? (int) $row['sender_user_id'] : 0;
    $attachmentPath = trim((string) ($row['attachment_path'] ?? ''));
    $attachmentMime = trim((string) ($row['attachment_mime'] ?? ''));
    $attachmentName = trim((string) ($row['attachment_name'] ?? ''));

    return [
        'id' => (int) ($row['id'] ?? 0),
        'thread_id' => (int) ($row['thread_id'] ?? 0),
        'sender_type' => $senderType,
        'sender_user_id' => $senderUserId > 0 ? $senderUserId : null,
        'body' => (string) ($row['body'] ?? ''),
        'is_mine' => ($senderType === 'user' && $senderUserId === $userId),
        'created_at' => (string) ($row['created_at'] ?? ''),
        'has_attachment' => $attachmentPath !== '',
        'attachment_mime' => $attachmentMime !== '' ? $attachmentMime : null,
        'attachment_name' => $attachmentName !== '' ? $attachmentName : null,
        'is_image_attachment' => $attachmentPath !== '' && crg_chat_is_image_mime($attachmentMime),
    ];
}

function crg_chat_message_select_sql(): string
{
    return 'id, thread_id, sender_type, sender_user_id, sender_admin_id, body,
            attachment_path, attachment_mime, attachment_name, read_at, created_at';
}
