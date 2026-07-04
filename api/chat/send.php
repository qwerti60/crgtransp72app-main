<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

try {
    $contentLength = (int) ($_SERVER['CONTENT_LENGTH'] ?? 0);
    $hasPayload = $_POST !== [] || $_FILES !== [];
    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'POST' && $contentLength > 0 && !$hasPayload) {
        chat_api_json([
            'success' => false,
            'error' => 'Файл слишком большой для сервера (увеличьте upload_max_filesize / post_max_size)',
        ], 413);
    }

    $pdo = tp_pdo();
    $userId = chat_api_require_user($pdo);

    if (!crg_chat_tables_ready($pdo)) {
        chat_api_json(['success' => false, 'error' => 'Chat not deployed'], 503);
    }

    $threadId = (int) ($_POST['thread_id'] ?? $_GET['thread_id'] ?? 0);
    $body = (string) ($_POST['body'] ?? '');

    if ($threadId <= 0) {
        chat_api_json(['success' => false, 'error' => 'thread_id required'], 400);
    }

    if (!function_exists('crg_chat_process_upload')) {
        chat_api_json([
            'success' => false,
            'error' => 'На сервере не загружен api/include/chat_attachments.php',
        ], 503);
    }

    $attachment = null;
    foreach (['file', 'attachment'] as $key) {
        if (!isset($_FILES[$key]) || !is_array($_FILES[$key])) {
            continue;
        }
        if ((int) ($_FILES[$key]['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) {
            continue;
        }
        $upload = crg_chat_process_upload($_FILES[$key], $threadId);
        if (!($upload['success'] ?? false)) {
            $err = (string) ($upload['error'] ?? 'Не удалось загрузить файл');
            if ($err === 'no_file') {
                $err = 'Файл не получен сервером';
            }
            chat_api_json(['success' => false, 'error' => $err], 400);
        }
        $attachment = [
            'path' => (string) $upload['path'],
            'mime' => (string) $upload['mime'],
            'name' => (string) $upload['name'],
        ];
        break;
    }

    try {
        $result = crg_chat_send_user_message($pdo, $userId, $threadId, $body, $attachment);
    } catch (Throwable $e) {
        if ($attachment !== null && !empty($attachment['path'])) {
            $abs = crg_chat_attachment_abs_path((string) $attachment['path']);
            if ($abs !== null && is_file($abs)) {
                @unlink($abs);
            }
        }
        $message = 'Не удалось отправить сообщение';
        if (str_contains($e->getMessage(), 'attachment_mime')
            || str_contains($e->getMessage(), 'attachment_name')) {
            $message = 'На сервере не выполнена миграция вложений (migrate_chat_attachments.sql)';
        }
        chat_api_json(['success' => false, 'error' => $message], 500);
    }

    if (!$result['success']) {
        if ($attachment !== null && !empty($attachment['path'])) {
            $abs = crg_chat_attachment_abs_path((string) $attachment['path']);
            if ($abs !== null && is_file($abs)) {
                @unlink($abs);
            }
        }
        chat_api_json($result, 400);
    }

    chat_api_json($result);
} catch (Throwable $e) {
    chat_api_json([
        'success' => false,
        'error' => 'Ошибка сервера: ' . $e->getMessage(),
    ], 500);
}
