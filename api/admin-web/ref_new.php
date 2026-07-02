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

$flashErr = '';
$name = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['create_ref'])) {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу и повторите.';
    } else {
        $name = (string) ($_POST['name'] ?? '');
        $ins = crg_admin_ref_insert($pdo, $cfg, $name);
        if (($ins['ok'] ?? false) === true) {
            $newId = (int) $ins['id'];
            if (!empty($cfg['has_image'])
                && !empty($_FILES['image_upload']['tmp_name'])
                && is_uploaded_file((string) $_FILES['image_upload']['tmp_name'])
            ) {
                $valid = crg_admin_ref_validate_upload($_FILES['image_upload']);
                if ($valid !== true) {
                    header(
                        'Location: ref_edit.php?type=' . rawurlencode($type)
                        . '&id=' . $newId . '&created=1&img_err=' . rawurlencode((string) $valid),
                        true,
                        303
                    );
                    exit;
                }
                $bin = file_get_contents((string) $_FILES['image_upload']['tmp_name']);
                if ($bin === false) {
                    header(
                        'Location: ref_edit.php?type=' . rawurlencode($type)
                        . '&id=' . $newId . '&created=1&img_err=' . rawurlencode('Не удалось прочитать файл'),
                        true,
                        303
                    );
                    exit;
                }
                $imgRes = crg_admin_ref_save_image($pdo, $cfg, $newId, $bin);
                if ($imgRes !== true) {
                    header(
                        'Location: ref_edit.php?type=' . rawurlencode($type)
                        . '&id=' . $newId . '&created=1&img_err=' . rawurlencode(is_string($imgRes) ? $imgRes : 'Ошибка сохранения картинки'),
                        true,
                        303
                    );
                    exit;
                }
            }
            header('Location: ref_edit.php?type=' . rawurlencode($type) . '&id=' . $newId . '&created=1', true, 303);
            exit;
        }
        $flashErr = (string) ($ins['error'] ?? 'Не удалось добавить');
    }
}

tp_admin_web_layout_start('Новая запись — ' . (string) $cfg['label'], (string) $cfg['nav'], $adminLogin !== '' ? $adminLogin : null);
?>
<p><a class="btn secondary small" href="ref_list.php?type=<?= tp_admin_web_h($type) ?>">← К списку</a></p>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>
<form method="post" action="" enctype="multipart/form-data">
    <input type="hidden" name="create_ref" value="1">
    <input type="hidden" name="type" value="<?= tp_admin_web_h($type) ?>">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
    <label class="b" for="name">Название</label>
    <input class="in" type="text" name="name" id="name" required maxlength="255" value="<?= tp_admin_web_h($name) ?>" autofocus>
    <?php if (!empty($cfg['has_image'])) { ?>
        <label class="b" for="image_upload">Картинка (JPEG, PNG, WebP, GIF, до 3 МБ)</label>
        <input class="in" type="file" name="image_upload" id="image_upload" accept="image/jpeg,image/png,image/webp,image/gif">
        <p class="meta">Картинка отображается на экране «Услуги» в приложении. Можно загрузить позже при редактировании.</p>
    <?php } ?>
    <div class="form-actions">
        <button type="submit" class="btn">Добавить</button>
        <a class="btn secondary" href="ref_list.php?type=<?= tp_admin_web_h($type) ?>">Отмена</a>
    </div>
</form>
<?php
tp_admin_web_layout_end();
