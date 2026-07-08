<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_ref_lists.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$type = crg_admin_ref_type_from_request();
if ($type === null) {
    http_response_code(400);
    echo 'Неизвестный тип справочника';
    exit;
}
$cfg = crg_admin_ref_config($type);
assert($cfg !== null);

$id = (int) ($_GET['id'] ?? 0);
$row = crg_admin_ref_get($pdo, $cfg, $id);
if ($row === null) {
    http_response_code(404);
    echo 'Запись не найдена';
    exit;
}

$oldName = (string) ($row['name'] ?? '');
$name = $oldName;
$flashErr = '';
$flashOk = '';
$hasImage = !empty($cfg['has_image']);

if (isset($_GET['created']) && (string) $_GET['created'] === '1') {
    $flashOk = 'Запись добавлена.';
    if (isset($_GET['img_err'])) {
        $flashErr = (string) $_GET['img_err'];
        $flashOk = 'Запись добавлена, но картинку сохранить не удалось.';
    }
}

$usageBreakdown = crg_admin_ref_usage_breakdown($pdo, $cfg, $oldName);
$usageTotal = array_sum($usageBreakdown);

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_ref'])) {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу и повторите.';
    } else {
        $name = (string) ($_POST['name'] ?? '');
        $renameRefs = isset($_POST['rename_references']) && (string) $_POST['rename_references'] === '1';
        $res = crg_admin_ref_update($pdo, $cfg, $id, $name, $renameRefs);
        if ($res !== true) {
            $flashErr = is_string($res) ? $res : 'Ошибка сохранения';
        } elseif ($hasImage) {
            if (isset($_POST['clear_image']) && (string) $_POST['clear_image'] === '1') {
                crg_admin_ref_clear_image($pdo, $cfg, $id);
            } elseif (!empty($_FILES['image_upload']['tmp_name']) && is_uploaded_file((string) $_FILES['image_upload']['tmp_name'])) {
                $valid = crg_admin_ref_validate_upload($_FILES['image_upload']);
                if ($valid !== true) {
                    $flashErr = $valid;
                } else {
                    $bin = file_get_contents((string) $_FILES['image_upload']['tmp_name']);
                    if ($bin === false) {
                        $flashErr = 'Не удалось прочитать файл';
                    } else {
                        $imgRes = crg_admin_ref_save_image($pdo, $cfg, $id, $bin);
                        if ($imgRes !== true) {
                            $flashErr = is_string($imgRes) ? $imgRes : 'Ошибка сохранения картинки';
                        }
                    }
                }
            }
        }
        if ($flashErr === '') {
            header('Location: ref_edit.php?type=' . rawurlencode($type) . '&id=' . $id . '&saved=1', true, 303);
            exit;
        }
    }
}

if (isset($_GET['saved']) && (string) $_GET['saved'] === '1') {
    $flashOk = 'Изменения сохранены.';
    $row = crg_admin_ref_get($pdo, $cfg, $id);
    if ($row !== null) {
        $oldName = (string) ($row['name'] ?? '');
        $name = $oldName;
        $usageBreakdown = crg_admin_ref_usage_breakdown($pdo, $cfg, $oldName);
        $usageTotal = array_sum($usageBreakdown);
    }
}

$showPreview = $hasImage && !empty($row['has_image']);

tp_admin_web_layout_start('Редактирование — ' . (string) $cfg['label'], (string) $cfg['nav'], $adminLogin !== '' ? $adminLogin : null);
?>
<p><a class="btn secondary small" href="ref_list.php?type=<?= tp_admin_web_h($type) ?>">← К списку</a></p>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>
<div class="card">
    <p class="meta">ID: <strong><?= (int) $id ?></strong></p>
    <?php if ($hasImage) { ?>
        <p class="meta">Картинка для приложения (<code>getimage.php?bd=<?= tp_admin_web_h((string) $cfg['table']) ?></code>):</p>
        <?php if ($showPreview) { ?>
            <p><img class="thumb-preview" src="ref_image.php?type=<?= tp_admin_web_h($type) ?>&id=<?= (int) $id ?>&w=240" alt=""></p>
        <?php } else { ?>
            <p class="warn">Картинка не загружена — в приложении плитка может быть пустой.</p>
        <?php } ?>
    <?php } ?>
    <?php if ($usageTotal > 0) { ?>
        <p class="warn">Используется в <strong><?= (int) $usageTotal ?></strong> записях:</p>
        <ul class="meta">
            <?php foreach ($usageBreakdown as $place => $cnt) { ?>
                <li><?= tp_admin_web_h($place) ?>: <?= (int) $cnt ?></li>
            <?php } ?>
        </ul>
    <?php } else { ?>
        <p class="meta">Не используется — можно удалить из списка.</p>
    <?php } ?>
</div>
<form method="post" action="" enctype="multipart/form-data">
    <input type="hidden" name="save_ref" value="1">
    <input type="hidden" name="type" value="<?= tp_admin_web_h($type) ?>">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
    <label class="b" for="name">Название</label>
    <input class="in" type="text" name="name" id="name" required maxlength="255" value="<?= tp_admin_web_h($name) ?>">
    <?php if ($hasImage) { ?>
        <label class="b" for="image_upload">Картинка (JPEG, PNG, WebP, GIF, до 3 МБ)</label>
        <input class="in" type="file" name="image_upload" id="image_upload" accept="image/jpeg,image/png,image/webp,image/gif">
        <?php if ($showPreview) { ?>
            <label class="b" style="margin-top:1rem">
                <input type="checkbox" name="clear_image" value="1">
                Удалить текущую картинку
            </label>
        <?php } ?>
    <?php } ?>
    <?php if ($usageTotal > 0) { ?>
        <label class="b" style="margin-top:1rem">
            <input type="checkbox" name="rename_references" value="1">
            Обновить название во всех связанных таблицах (<?= (int) $usageTotal ?> записей)
        </label>
    <?php } ?>
    <div class="form-actions">
        <button type="submit" class="btn">Сохранить</button>
        <a class="btn secondary" href="ref_list.php?type=<?= tp_admin_web_h($type) ?>">Отмена</a>
    </div>
</form>
<?php
tp_admin_web_layout_end();
