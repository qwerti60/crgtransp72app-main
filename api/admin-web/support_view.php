<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('chat_core.php');
tp_admin_web_require_include('admin_support.php');
tp_admin_web_require_include('admin_users.php');

$pdo = tp_admin_web_require_login();
$admin = tp_admin_current_account($pdo);
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$ticketId = (int) ($_GET['id'] ?? 0);
$flashOk = '';
$flashErr = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'Неверный CSRF-токен';
    } elseif ($admin === null) {
        $flashErr = 'Сессия администратора';
    } else {
        $action = (string) ($_POST['action'] ?? '');
        if ($action === 'reply') {
            $err = crg_admin_support_send_reply(
                $pdo,
                $ticketId,
                (int) $admin['id'],
                (string) ($_POST['body'] ?? '')
            );
            if ($err !== null) {
                $flashErr = $err;
            } else {
                $flashOk = 'Ответ отправлен';
            }
        } elseif ($action === 'assign') {
            $err = crg_admin_support_assign($pdo, $ticketId, (int) $admin['id']);
            $flashOk = $err === null ? 'Обращение взято в работу' : '';
            $flashErr = $err ?? '';
        } elseif ($action === 'status') {
            $err = crg_admin_support_set_status($pdo, $ticketId, (string) ($_POST['status'] ?? ''));
            if ($err !== null) {
                $flashErr = $err;
            } else {
                $flashOk = 'Статус обновлён';
            }
        }
    }
}

$ticket = $ticketId > 0 ? crg_admin_support_ticket($pdo, $ticketId) : null;
$messages = $ticket !== null ? crg_admin_support_messages($pdo, (int) ($ticket['thread_id'] ?? 0)) : [];
$statusLabels = crg_admin_support_status_labels();
$categoryLabels = crg_chat_support_category_labels();
$templates = crg_admin_support_templates();

tp_admin_web_layout_start('Обращение #' . $ticketId, 'support', $adminLogin !== '' ? $adminLogin : null);
?>
<style>
    .chat-feed { max-height: 28rem; overflow-y: auto; background: #fff; border-radius: 8px; padding: 1rem; margin: 1rem 0; }
    .chat-msg { margin: 0.5rem 0; max-width: 85%; padding: 0.5rem 0.75rem; border-radius: 8px; font-size: 0.9rem; }
    .chat-msg.user { background: #e2e8f0; margin-right: auto; }
    .chat-msg.admin { background: #dbeafe; margin-left: auto; }
    .chat-msg.system { background: #f8fafc; margin: 0.5rem auto; text-align: center; color: #64748b; font-size: 0.8rem; }
    .chat-meta { font-size: 0.75rem; color: #64748b; margin-top: 0.2rem; }
    .chat-poll-status { font-size: 0.8rem; color: #64748b; margin: 0.25rem 0 0.5rem; }
    .chat-poll-status.err { color: #b91c1c; }
    .chat-attachment { margin: 0.35rem 0; }
    .chat-attachment img { max-width: 220px; max-height: 180px; border-radius: 6px; display: block; }
    .chat-attachment a { color: #1d4ed8; text-decoration: none; }
    .chat-attachment a:hover { text-decoration: underline; }
</style>

<p><a href="support_queue.php">← К очереди</a></p>

<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>

<?php if ($ticket === null) { ?>
    <p class="err">Обращение не найдено</p>
<?php } else { ?>
    <div class="card">
        <h2 style="margin:0 0 0.5rem;font-size:1rem"><?= tp_admin_web_h((string) ($ticket['subject'] ?? '')) ?></h2>
        <p class="meta">
            №<?= (int) ($ticket['id'] ?? 0) ?> ·
            <?= tp_admin_web_h($categoryLabels[(string) ($ticket['category'] ?? 'other')] ?? '') ?> ·
            <?= tp_admin_web_h($statusLabels[(string) ($ticket['status'] ?? '')] ?? '') ?> ·
            <?= tp_admin_web_h((string) ($ticket['created_at'] ?? '')) ?>
        </p>
        <p>
            <strong><?= tp_admin_web_h(crg_admin_support_user_name($ticket)) ?></strong>
            (#<?= (int) ($ticket['user_id'] ?? 0) ?>)<br>
            <?= tp_admin_web_h((string) ($ticket['city'] ?? '')) ?> ·
            <?= tp_admin_web_h((string) ($ticket['phone'] ?? '')) ?> ·
            <?= tp_admin_web_h((string) ($ticket['email'] ?? '')) ?>
        </p>
        <p class="row-actions">
            <a class="btn secondary small" href="user_edit.php?id=<?= (int) ($ticket['user_id'] ?? 0) ?>">Профиль</a>
            <?php if ((int) ($ticket['assigned_admin_id'] ?? 0) === 0) { ?>
                <form method="post" style="display:inline">
                    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                    <input type="hidden" name="action" value="assign">
                    <button class="btn small" type="submit">Взять в работу</button>
                </form>
            <?php } ?>
        </p>
        <?php
        $context = crg_admin_parse_ticket_context(
            isset($ticket['context_json']) ? (string) $ticket['context_json'] : null
        );
        $dealThreadId = crg_admin_resolve_deal_thread_id($pdo, $context);
        ?>
        <?php if ($context !== null) { ?>
            <p class="meta"><strong>Контекст:</strong></p>
            <ul class="meta">
                <?php foreach ($context as $ck => $cv) { ?>
                    <li><?= tp_admin_web_h((string) $ck) ?>: <?= tp_admin_web_h(is_scalar($cv) ? (string) $cv : json_encode($cv, JSON_UNESCAPED_UNICODE)) ?></li>
                <?php } ?>
            </ul>
        <?php } elseif (!empty($ticket['context_json'])) { ?>
            <p class="meta"><strong>Контекст:</strong> <?= tp_admin_web_h((string) $ticket['context_json']) ?></p>
        <?php } ?>
        <?php if ($dealThreadId > 0) { ?>
            <p class="row-actions">
                <a class="btn small" href="deal_chat_view.php?thread_id=<?= $dealThreadId ?>&amp;ticket_id=<?= (int) $ticketId ?>">
                    Открыть deal-чат
                </a>
            </p>
        <?php } ?>
    </div>

    <div class="chat-feed" id="chat-feed">
        <?php foreach ($messages as $msg) { ?>
            <?php
            $type = (string) ($msg['sender_type'] ?? 'user');
            $cls = $type === 'admin' ? 'admin' : ($type === 'system' ? 'system' : 'user');
            $msgId = (int) ($msg['id'] ?? 0);
            ?>
            <div class="chat-msg <?= tp_admin_web_h($cls) ?>" data-msg-id="<?= $msgId ?>">
                <?php
                $hasAttachment = trim((string) ($msg['attachment_path'] ?? '')) !== '';
                $attachmentMime = trim((string) ($msg['attachment_mime'] ?? ''));
                $attachmentName = trim((string) ($msg['attachment_name'] ?? ''));
                $isImage = $hasAttachment && function_exists('crg_chat_is_image_mime') && crg_chat_is_image_mime($attachmentMime);
                $bodyText = (string) ($msg['body'] ?? '');
                ?>
                <?php if ($hasAttachment) { ?>
                    <div class="chat-attachment">
                        <?php if ($isImage) { ?>
                            <a href="support_attachment.php?message_id=<?= $msgId ?>" target="_blank" rel="noopener">
                                <img src="support_attachment.php?message_id=<?= $msgId ?>" alt="<?= tp_admin_web_h($attachmentName !== '' ? $attachmentName : 'Изображение') ?>">
                            </a>
                        <?php } else { ?>
                            <a href="support_attachment.php?message_id=<?= $msgId ?>" target="_blank" rel="noopener">
                                📎 <?= tp_admin_web_h($attachmentName !== '' ? $attachmentName : 'Документ') ?>
                            </a>
                        <?php } ?>
                    </div>
                <?php } ?>
                <?php if ($bodyText !== '' && !($hasAttachment && str_starts_with($bodyText, '📎'))) { ?>
                    <?= nl2br(tp_admin_web_h($bodyText)) ?>
                <?php } ?>
                <div class="chat-meta">
                    <?= tp_admin_web_h((string) ($msg['created_at'] ?? '')) ?>
                    <?php if ($type === 'admin') { ?>
                        · <?= tp_admin_web_h((string) ($msg['admin_login'] ?? 'оператор')) ?>
                    <?php } ?>
                </div>
            </div>
        <?php } ?>
        <?php if ($messages === []) { ?>
            <p class="meta" data-empty-placeholder="1">Сообщений пока нет</p>
        <?php } ?>
    </div>

    <p class="chat-poll-status" id="chat-poll-status">Ожидание сообщений…</p>

    <?php if (!in_array((string) ($ticket['status'] ?? ''), ['closed'], true)) { ?>
        <div class="card">
            <form method="post">
                <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                <input type="hidden" name="action" value="reply">
                <label class="b" for="body">Ответ пользователю</label>
                <textarea class="in" id="body" name="body" rows="4" required></textarea>
                <p class="meta">Шаблоны:</p>
                <p class="row-actions">
                    <?php foreach ($templates as $tid => $text) { ?>
                        <button type="button" class="btn secondary small tpl-btn" data-text="<?= tp_admin_web_h($text) ?>">t<?= (int) $tid ?></button>
                    <?php } ?>
                </p>
                <div class="form-actions">
                    <button class="btn" type="submit">Отправить</button>
                </div>
            </form>
            <form method="post" class="form-actions">
                <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                <input type="hidden" name="action" value="status">
                <select class="in" name="status" style="max-width:14rem;width:auto">
                    <?php foreach ($statusLabels as $k => $label) { ?>
                        <option value="<?= tp_admin_web_h($k) ?>"<?= ($ticket['status'] ?? '') === $k ? ' selected' : '' ?>><?= tp_admin_web_h($label) ?></option>
                    <?php } ?>
                </select>
                <button class="btn secondary" type="submit">Обновить статус</button>
            </form>
        </div>
    <?php } ?>
    <?php } ?>

<script>
document.querySelectorAll('.tpl-btn').forEach(function(btn) {
    btn.addEventListener('click', function() {
        var ta = document.getElementById('body');
        if (ta) ta.value = btn.getAttribute('data-text') || '';
    });
});

(function() {
    var ticketId = <?= (int) $ticketId ?>;
    var feed = document.getElementById('chat-feed');
    var statusEl = document.getElementById('chat-poll-status');
    if (!feed || !statusEl || ticketId <= 0) return;

    var pollUrl = window.location.pathname.replace(/[^/]+$/, 'support_poll.php');

    function lastMsgId() {
        var nodes = feed.querySelectorAll('[data-msg-id]');
        var max = 0;
        nodes.forEach(function(n) {
            var id = parseInt(n.getAttribute('data-msg-id') || '0', 10);
            if (id > max) max = id;
        });
        return max;
    }

    function escapeHtml(s) {
        return String(s)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function removeEmptyPlaceholder() {
        var empty = feed.querySelector('[data-empty-placeholder="1"]');
        if (empty) empty.remove();
    }

    function attachmentHtml(item) {
        if (!item || !item.has_attachment || !item.id) return '';
        var url = 'support_attachment.php?message_id=' + encodeURIComponent(String(item.id));
        var name = item.attachment_name || 'Документ';
        if (item.is_image_attachment) {
            return '<div class="chat-attachment"><a href="' + url + '" target="_blank" rel="noopener">' +
                '<img src="' + url + '" alt="' + escapeHtml(name) + '"></a></div>';
        }
        return '<div class="chat-attachment"><a href="' + url + '" target="_blank" rel="noopener">' +
            '📎 ' + escapeHtml(name) + '</a></div>';
    }

    function bodyHtml(item) {
        var body = item.body || '';
        if (item.has_attachment && body.indexOf('📎') === 0) return '';
        return escapeHtml(body).replace(/\n/g, '<br>');
    }

    function appendMessage(item) {
        if (!item || !item.id) return;
        if (feed.querySelector('[data-msg-id="' + item.id + '"]')) return;
        removeEmptyPlaceholder();
        var type = item.sender_type || 'user';
        var cls = type === 'admin' ? 'admin' : (type === 'system' ? 'system' : 'user');
        var meta = escapeHtml(item.created_at || '');
        if (type === 'admin' && item.admin_login) {
            meta += ' · ' + escapeHtml(item.admin_login);
        }
        var div = document.createElement('div');
        div.className = 'chat-msg ' + cls;
        div.setAttribute('data-msg-id', String(item.id));
        div.innerHTML = attachmentHtml(item) + bodyHtml(item) +
            '<div class="chat-meta">' + meta + '</div>';
        feed.appendChild(div);
        feed.scrollTop = feed.scrollHeight;
    }

    function setStatus(text, isError) {
        statusEl.textContent = text;
        statusEl.className = isError ? 'chat-poll-status err' : 'chat-poll-status';
    }

    function parseJsonResponse(r) {
        return r.text().then(function(text) {
            if (!text) {
                throw new Error('Пустой ответ сервера');
            }
            try {
                return JSON.parse(text);
            } catch (e) {
                var preview = text.replace(/\s+/g, ' ').substring(0, 160);
                throw new Error('Не JSON: ' + preview);
            }
        });
    }

    function poll() {
        var afterId = lastMsgId();
        var url = pollUrl + '?id=' + encodeURIComponent(String(ticketId)) +
            '&after_id=' + encodeURIComponent(String(afterId)) + '&_=' + Date.now();
        fetch(url, {
            method: 'GET',
            credentials: 'same-origin',
            cache: 'no-store',
            headers: {
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            }
        })
        .then(function(r) {
            if (r.status === 401) {
                setStatus('Сессия истекла — обновите страницу (F5)', true);
                throw new Error('unauthorized');
            }
            return parseJsonResponse(r).then(function(data) {
                if (!r.ok) {
                    var errText = (data && (data.error || data.message)) ? (data.error || data.message) : ('HTTP ' + r.status);
                    throw new Error(errText);
                }
                return data;
            });
        })
        .then(function(data) {
            if (!data || !data.success) {
                var errText = (data && (data.error || data.message)) ? (data.error || data.message) : '?';
                setStatus('Ошибка опроса: ' + errText, true);
                return;
            }
            if (Array.isArray(data.items) && data.items.length) {
                data.items.forEach(appendMessage);
            }
            var now = new Date();
            var t = now.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
            setStatus('Обновлено ' + t + ' · авто каждые 3 с', false);
        })
        .catch(function(err) {
            if (err && err.message === 'unauthorized') return;
            setStatus((err && err.message) ? err.message : 'Не удалось обновить чат', true);
        });
    }

    poll();
    setInterval(poll, 3000);
    document.addEventListener('visibilitychange', function() {
        if (!document.hidden) poll();
    });
})();
</script>

<?php tp_admin_web_layout_end(); ?>
