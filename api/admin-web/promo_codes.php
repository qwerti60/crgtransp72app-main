<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('subscription_packages.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');
$flashOk = '';
$flashErr = '';
$ready = crg_promo_codes_table_exists($pdo);

if ($ready && $_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу.';
    } else {
        $action = (string) ($_POST['action'] ?? '');
        try {
            if ($action === 'save') {
                $id = (int) ($_POST['id'] ?? 0);
                $code = strtoupper(trim((string) ($_POST['code'] ?? '')));
                $dtype = (string) ($_POST['discount_type'] ?? 'percent');
                if ($dtype !== 'fixed') {
                    $dtype = 'percent';
                }
                $dval = max(0, (int) ($_POST['discount_value'] ?? 0));
                $validUntil = trim((string) ($_POST['valid_until'] ?? ''));
                $maxUsesRaw = trim((string) ($_POST['max_uses'] ?? ''));
                $maxUses = $maxUsesRaw === '' ? null : max(1, (int) $maxUsesRaw);
                $active = isset($_POST['is_active']) ? 1 : 0;
                if ($code === '') {
                    $flashErr = 'Укажите код';
                } elseif ($id > 0) {
                    $pdo->prepare(
                        'UPDATE promo_codes
                         SET code = ?, discount_type = ?, discount_value = ?, valid_until = ?, max_uses = ?, is_active = ?
                         WHERE id = ?'
                    )->execute([
                        $code,
                        $dtype,
                        $dval,
                        $validUntil !== '' ? $validUntil : null,
                        $maxUses,
                        $active,
                        $id,
                    ]);
                    $flashOk = 'Промокод сохранён';
                } else {
                    $pdo->prepare(
                        'INSERT INTO promo_codes
                         (code, discount_type, discount_value, valid_until, max_uses, used_count, is_active)
                         VALUES (?, ?, ?, ?, ?, 0, ?)'
                    )->execute([
                        $code,
                        $dtype,
                        $dval,
                        $validUntil !== '' ? $validUntil : null,
                        $maxUses,
                        $active,
                    ]);
                    $flashOk = 'Промокод добавлен';
                }
            } elseif ($action === 'delete') {
                $id = (int) ($_POST['id'] ?? 0);
                if ($id > 0) {
                    $pdo->prepare('DELETE FROM promo_codes WHERE id = ?')->execute([$id]);
                    $flashOk = 'Промокод удалён';
                }
            }
        } catch (Throwable $e) {
            $flashErr = 'Ошибка: ' . $e->getMessage();
        }
    }
}

$rows = $ready ? $pdo->query(
    'SELECT * FROM promo_codes ORDER BY id DESC'
)->fetchAll(PDO::FETCH_ASSOC) : [];

tp_admin_web_layout_start('Промокоды', 'promos', $adminLogin !== '' ? $adminLogin : null);
?>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>
<?php if (!$ready) { ?>
    <p class="err">Выполните миграцию <code>sql/migrate_subscription_packages.sql</code>.</p>
<?php } else { ?>
    <p class="meta"><a href="packages.php">← Пакеты подписки</a></p>

    <div class="card">
        <h2 style="margin:0 0 0.75rem;font-size:1rem">Новый промокод</h2>
        <form method="post">
            <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
            <input type="hidden" name="action" value="save">
            <input type="hidden" name="id" value="0">
            <label class="b">Код</label>
            <input class="in" name="code" required maxlength="64" placeholder="WELCOME10">
            <label class="b">Тип скидки</label>
            <select class="in" name="discount_type">
                <option value="percent">Процент</option>
                <option value="fixed">Фиксированная, ₽</option>
            </select>
            <label class="b">Значение</label>
            <input class="in" name="discount_value" type="number" min="0" value="10">
            <label class="b">Действует до (YYYY-MM-DD)</label>
            <input class="in" name="valid_until" placeholder="2026-12-31">
            <label class="b">Макс. использований (пусто = без лимита)</label>
            <input class="in" name="max_uses" type="number" min="1">
            <label class="b"><input type="checkbox" name="is_active" value="1" checked> Активен</label>
            <div class="form-actions"><button class="btn" type="submit">Добавить</button></div>
        </form>
    </div>

    <table class="data" style="margin-top:1rem">
        <thead>
        <tr>
            <th>Код</th><th>Скидка</th><th>До</th><th>Использовано</th><th>Активен</th><th></th>
        </tr>
        </thead>
        <tbody>
        <?php if ($rows === []) { ?><tr><td colspan="6">Нет промокодов</td></tr><?php } ?>
        <?php foreach ($rows as $r) {
            $dtype = (string) ($r['discount_type'] ?? 'percent');
            $dval = (int) ($r['discount_value'] ?? 0);
            $label = $dtype === 'fixed' ? ($dval . ' ₽') : ($dval . '%');
            ?>
            <tr>
                <td><strong><?= tp_admin_web_h((string) $r['code']) ?></strong></td>
                <td><?= tp_admin_web_h($label) ?></td>
                <td><?= tp_admin_web_h((string) ($r['valid_until'] ?? '—')) ?></td>
                <td><?= (int) ($r['used_count'] ?? 0) ?><?php
                    if ($r['max_uses'] !== null) {
                        echo ' / ' . (int) $r['max_uses'];
                    }
                ?></td>
                <td><?= ((int) ($r['is_active'] ?? 0) === 1) ? 'да' : 'нет' ?></td>
                <td class="row-actions">
                    <form method="post" style="display:inline" onsubmit="return confirm('Удалить?');">
                        <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                        <button class="btn secondary small" type="submit">Удалить</button>
                    </form>
                </td>
            </tr>
            <tr>
                <td colspan="6">
                    <form method="post" class="filters">
                        <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                        <input type="hidden" name="action" value="save">
                        <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                        <input class="in" name="code" value="<?= tp_admin_web_h((string) $r['code']) ?>" style="max-width:8rem">
                        <select class="in" name="discount_type" style="max-width:8rem">
                            <option value="percent" <?= $dtype === 'percent' ? 'selected' : '' ?>>%</option>
                            <option value="fixed" <?= $dtype === 'fixed' ? 'selected' : '' ?>>₽</option>
                        </select>
                        <input class="in" name="discount_value" type="number" value="<?= $dval ?>" style="max-width:6rem">
                        <input class="in" name="valid_until" value="<?= tp_admin_web_h((string) ($r['valid_until'] ?? '')) ?>" style="max-width:9rem">
                        <input class="in" name="max_uses" type="number" value="<?= $r['max_uses'] !== null ? (int) $r['max_uses'] : '' ?>" style="max-width:6rem" placeholder="∞">
                        <label class="meta"><input type="checkbox" name="is_active" value="1" <?= ((int) $r['is_active'] === 1) ? 'checked' : '' ?>> акт.</label>
                        <button class="btn small" type="submit">Сохранить</button>
                    </form>
                </td>
            </tr>
        <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php tp_admin_web_layout_end(); ?>
