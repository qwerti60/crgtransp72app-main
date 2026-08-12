<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('ad_auto_moderation.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');
$flashOk = '';
$flashErr = '';
$ready = crg_moderation_tables_ready($pdo);

if ($ready && $_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу.';
    } else {
        $action = (string) ($_POST['action'] ?? '');
        try {
            if ($action === 'add_word') {
                $word = mb_strtolower(trim((string) ($_POST['word'] ?? '')));
                if ($word === '') {
                    $flashErr = 'Введите слово';
                } else {
                    $pdo->prepare(
                        'INSERT INTO moderation_stop_words (word, is_active) VALUES (?, 1)
                         ON DUPLICATE KEY UPDATE is_active = 1'
                    )->execute([$word]);
                    $flashOk = 'Слово добавлено';
                }
            } elseif ($action === 'toggle') {
                $id = (int) ($_POST['id'] ?? 0);
                $active = isset($_POST['is_active']) ? 1 : 0;
                if ($id > 0) {
                    $pdo->prepare('UPDATE moderation_stop_words SET is_active = ? WHERE id = ?')->execute([$active, $id]);
                    $flashOk = 'Сохранено';
                }
            } elseif ($action === 'delete') {
                $id = (int) ($_POST['id'] ?? 0);
                if ($id > 0) {
                    $pdo->prepare('DELETE FROM moderation_stop_words WHERE id = ?')->execute([$id]);
                    $flashOk = 'Удалено';
                }
            }
        } catch (Throwable $e) {
            $flashErr = 'Ошибка: ' . $e->getMessage();
        }
    }
}

$words = [];
$recentLog = [];
if ($ready) {
    $words = $pdo->query(
        'SELECT * FROM moderation_stop_words ORDER BY word ASC'
    )->fetchAll(PDO::FETCH_ASSOC) ?: [];
    $recentLog = $pdo->query(
        'SELECT * FROM moderation_log ORDER BY created_at DESC LIMIT 50'
    )->fetchAll(PDO::FETCH_ASSOC) ?: [];
}

tp_admin_web_layout_start('Автомодерация', 'moderation', $adminLogin !== '' ? $adminLogin : null);
?>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>
<?php if (!$ready) { ?>
    <p class="err">Выполните миграцию <code>sql/migrate_p3_features.sql</code>.</p>
<?php } else { ?>
    <p class="meta">Правила при создании объявления исполнителя: стоп-слова → автоотклонение; без фото → автоотклонение; дубль опубликованного → очередь модерации.</p>

    <div class="card">
        <h2 style="margin:0 0 0.75rem;font-size:1rem">Добавить стоп-слово</h2>
        <form method="post">
            <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
            <input type="hidden" name="action" value="add_word">
            <label class="b">Слово или фраза</label>
            <input class="in" name="word" required maxlength="128" placeholder="казино">
            <div class="form-actions"><button class="btn" type="submit">Добавить</button></div>
        </form>
    </div>

    <table class="data" style="margin-top:1rem">
        <thead><tr><th>ID</th><th>Слово</th><th>Активно</th><th></th></tr></thead>
        <tbody>
        <?php if ($words === []) { ?><tr><td colspan="4">Нет стоп-слов</td></tr><?php } ?>
        <?php foreach ($words as $w) { ?>
            <tr>
                <td><?= (int) $w['id'] ?></td>
                <td><?= tp_admin_web_h((string) $w['word']) ?></td>
                <td>
                    <form method="post" style="display:inline">
                        <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                        <input type="hidden" name="action" value="toggle">
                        <input type="hidden" name="id" value="<?= (int) $w['id'] ?>">
                        <label><input type="checkbox" name="is_active" value="1" <?= ((int) $w['is_active'] === 1) ? 'checked' : '' ?> onchange="this.form.submit()"> да</label>
                    </form>
                </td>
                <td>
                    <form method="post" onsubmit="return confirm('Удалить?');">
                        <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="<?= (int) $w['id'] ?>">
                        <button class="btn small danger" type="submit">×</button>
                    </form>
                </td>
            </tr>
        <?php } ?>
        </tbody>
    </table>

    <h2 style="margin-top:1.5rem;font-size:1rem">Последние срабатывания</h2>
    <table class="data">
        <thead><tr><th>Дата</th><th>Объявление</th><th>Пользователь</th><th>Правило</th><th>Действие</th><th>Детали</th></tr></thead>
        <tbody>
        <?php if ($recentLog === []) { ?><tr><td colspan="6">Пока нет записей</td></tr><?php } ?>
        <?php foreach ($recentLog as $log) { ?>
            <tr>
                <td><?= tp_admin_web_h((string) ($log['created_at'] ?? '')) ?></td>
                <td><?= tp_admin_web_h((string) ($log['ad_table'] ?? '') . ' #' . ($log['ad_id'] ?? '')) ?></td>
                <td><?= (int) ($log['user_id'] ?? 0) ?></td>
                <td><?= tp_admin_web_h((string) ($log['rule_code'] ?? '')) ?></td>
                <td><?= tp_admin_web_h((string) ($log['action'] ?? '')) ?></td>
                <td><?= tp_admin_web_h((string) ($log['detail'] ?? '')) ?></td>
            </tr>
        <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php tp_admin_web_layout_end(); ?>
