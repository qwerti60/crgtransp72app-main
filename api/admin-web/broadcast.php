<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_broadcast.php');
tp_admin_web_require_include('admin_users.php');
tp_admin_web_require_include('fcm_push.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');
$fcmStatus = crg_fcm_config_status();

$cities = crg_admin_broadcast_city_options($pdo);
$audiences = crg_admin_broadcast_audience_labels();
$roles = crg_admin_user_roll_labels();

$form = [
    'audience' => 'all',
    'cities' => [],
    'roles' => [],
    'user_ids' => '',
    'subject' => '',
    'message' => '',
    'send_mail' => true,
    'send_push' => false,
];

$flashErr = '';
$previewCount = null;
$previewPushReady = null;
$resultStats = null;
$resultSummary = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу.';
    } else {
        $parsed = crg_admin_broadcast_parse_form($_POST);
        $form = [
            'audience' => $parsed['audience'],
            'cities' => $parsed['cities'],
            'roles' => $parsed['roles'],
            'user_ids' => implode(', ', $parsed['user_ids']),
            'subject' => $parsed['subject'],
            'message' => $parsed['message'],
            'send_mail' => $parsed['send_mail'],
            'send_push' => $parsed['send_push'],
        ];

        $err = crg_admin_broadcast_validate_form($parsed);
        if ($err !== null) {
            $flashErr = $err;
        } else {
            $recipients = crg_admin_broadcast_recipients($pdo, $parsed);
            if ($recipients === [] && $parsed['audience'] !== 'all') {
                $flashErr = 'По выбранным условиям никого не найдено.';
            } elseif (isset($_POST['preview'])) {
                $previewCount = count($recipients);
                $previewPushReady = crg_admin_broadcast_push_ready_count($recipients);
            } elseif (isset($_POST['send'])) {
                if (count($recipients) > 2000) {
                    $flashErr = 'Слишком много получателей (' . count($recipients) . '). Сузьте выборку.';
                } else {
                    $resultStats = crg_admin_broadcast_send($pdo, $recipients, $parsed);
                    $resultSummary = crg_admin_broadcast_stats_summary(
                        $resultStats,
                        $parsed['send_mail'],
                        $parsed['send_push']
                    );
                }
            }
        }
    }
}

tp_admin_web_layout_start('Рассылка', 'broadcast', $adminLogin !== '' ? $adminLogin : null);
?>
<?php if (!$fcmStatus['ok']) { ?>
    <p class="err"><strong>Push недоступен:</strong> <?= tp_admin_web_h($fcmStatus['hint']) ?></p>
<?php } ?>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>
<?php if ($previewCount !== null) { ?>
    <p class="ok">В выборку попадает <strong><?= (int) $previewCount ?></strong> пользователей<?php if ($previewPushReady !== null) { ?>, с push-токеном в БД: <strong><?= (int) $previewPushReady ?></strong><?php } ?>. Проверьте фильтры и нажмите «Отправить».</p>
    <?php if ($previewPushReady !== null && $previewPushReady < $previewCount) { ?>
        <p class="meta">Без push-токена: пользователь не открывал приложение после входа или не разрешил уведомления. Попросите открыть приложение на телефоне.</p>
    <?php } ?>
<?php } ?>
<?php if ($resultSummary !== '') { ?>
    <p class="ok"><?= tp_admin_web_h($resultSummary) ?></p>
    <?php if ($resultStats !== null && ($resultStats['errors'] ?? []) !== []) { ?>
        <ul class="meta">
            <?php foreach ($resultStats['errors'] as $e) { ?>
                <li><?= tp_admin_web_h($e) ?></li>
            <?php } ?>
        </ul>
    <?php } ?>
<?php } ?>

<form method="post" action="" id="broadcast-form">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">

    <div class="card">
        <p class="meta"><strong>Аудитория</strong></p>
        <label class="b" for="audience">Кому отправить</label>
        <select class="in" name="audience" id="audience">
            <?php foreach ($audiences as $key => $label) { ?>
                <option value="<?= tp_admin_web_h($key) ?>"<?= $form['audience'] === $key ? ' selected' : '' ?>><?= tp_admin_web_h($label) ?></option>
            <?php } ?>
        </select>

        <div class="broadcast-panel" id="panel-city" hidden>
            <label class="b">Города</label>
            <p class="meta">Удерживайте Ctrl (Cmd) для выбора нескольких.</p>
            <select class="in" name="cities[]" id="cities" multiple size="8" style="max-width:24rem;height:auto">
                <?php foreach ($cities as $city) { ?>
                    <option value="<?= tp_admin_web_h($city) ?>"<?= in_array($city, $form['cities'], true) ? ' selected' : '' ?>><?= tp_admin_web_h($city) ?></option>
                <?php } ?>
            </select>
        </div>

        <div class="broadcast-panel" id="panel-role" hidden>
            <label class="b">Роли</label>
            <?php foreach ($roles as $k => $label) { ?>
                <label style="display:block;margin:0.35rem 0">
                    <input type="checkbox" name="roles[]" value="<?= $k ?>"<?= in_array($k, $form['roles'], true) ? ' checked' : '' ?>>
                    <?= tp_admin_web_h($label) ?>
                </label>
            <?php } ?>
        </div>

        <div class="broadcast-panel" id="panel-selected" hidden>
            <label class="b" for="user_ids">ID пользователей</label>
            <input class="in" type="text" name="user_ids" id="user_ids" value="<?= tp_admin_web_h($form['user_ids']) ?>" placeholder="1, 5, 12">
            <p class="meta">Через запятую. ID смотрите в разделе <a href="users.php">Пользователи</a>.</p>
        </div>

        <p class="meta broadcast-panel" id="panel-sub" hidden>Фильтр по таблице подписок исполнителей (дата окончания).</p>
    </div>

    <div class="card">
        <p class="meta"><strong>Сообщение</strong></p>
        <label class="b" for="subject">Тема (e-mail и заголовок push)</label>
        <input class="in" type="text" name="subject" id="subject" maxlength="200" value="<?= tp_admin_web_h($form['subject']) ?>">

        <label class="b" for="message">Текст</label>
        <textarea class="in" name="message" id="message" rows="8" required minlength="5" maxlength="8000"><?= tp_admin_web_h($form['message']) ?></textarea>

        <p class="meta"><strong>Каналы</strong></p>
        <label style="display:block;margin:0.35rem 0">
            <input type="checkbox" name="send_mail" value="1"<?= $form['send_mail'] ? ' checked' : '' ?>> E-mail
        </label>
        <label style="display:block;margin:0.35rem 0">
            <input type="checkbox" name="send_push" value="1"<?= $form['send_push'] ? ' checked' : '' ?>> Push в приложение
        </label>
        <p class="meta">Push — краткий текст (до ~240 символов). Полный текст — в письме.</p>
    </div>

    <div class="form-actions">
        <button type="submit" name="preview" value="1" class="btn secondary">Проверить выборку</button>
        <button type="submit" name="send" value="1" class="btn" onclick="return confirm('Отправить рассылку выбранной аудитории?');">Отправить</button>
    </div>
</form>

<script>
(function () {
    var sel = document.getElementById('audience');
    var panelCity = document.getElementById('panel-city');
    var panelRole = document.getElementById('panel-role');
    var panelSelected = document.getElementById('panel-selected');
    var panelSub = document.getElementById('panel-sub');

    function sync() {
        var v = sel.value;
        if (panelCity) panelCity.hidden = v !== 'city';
        if (panelRole) panelRole.hidden = v !== 'role';
        if (panelSelected) panelSelected.hidden = v !== 'selected';
        if (panelSub) panelSub.hidden = v !== 'subscription_ending_3' && v !== 'subscription_expired';
    }
    sel.addEventListener('change', sync);
    sync();
})();
</script>
<?php
tp_admin_web_layout_end();
