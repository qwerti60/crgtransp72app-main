<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('subscription_packages.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');
$flashOk = '';
$flashErr = '';
$ready = crg_subscription_packages_table_exists($pdo);

if ($ready && $_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу.';
    } else {
        $action = (string) ($_POST['action'] ?? '');
        try {
            if ($action === 'save') {
                $id = (int) ($_POST['id'] ?? 0);
                $code = trim((string) ($_POST['code'] ?? ''));
                $title = trim((string) ($_POST['title'] ?? ''));
                $days = max(1, (int) ($_POST['days'] ?? 30));
                $price = max(0, (int) ($_POST['price_rub'] ?? 0));
                $sort = (int) ($_POST['sort_order'] ?? 0);
                $active = isset($_POST['is_active']) ? 1 : 0;
                if ($code === '' || $title === '') {
                    $flashErr = 'Укажите код и название';
                } elseif ($id > 0) {
                    $pdo->prepare(
                        'UPDATE subscription_packages
                         SET code = ?, title = ?, days = ?, price_rub = ?, sort_order = ?, is_active = ?
                         WHERE id = ?'
                    )->execute([$code, $title, $days, $price, $sort, $active, $id]);
                    if ($code === 'month' && $active === 1) {
                        crg_subscription_sync_legacy_config($pdo, $days, $price);
                    }
                    $flashOk = 'Пакет сохранён';
                } else {
                    $pdo->prepare(
                        'INSERT INTO subscription_packages (code, title, days, price_rub, sort_order, is_active)
                         VALUES (?, ?, ?, ?, ?, ?)'
                    )->execute([$code, $title, $days, $price, $sort, $active]);
                    if ($code === 'month' && $active === 1) {
                        crg_subscription_sync_legacy_config($pdo, $days, $price);
                    }
                    $flashOk = 'Пакет добавлен';
                }
            } elseif ($action === 'delete') {
                $id = (int) ($_POST['id'] ?? 0);
                if ($id > 0) {
                    $pdo->prepare('DELETE FROM subscription_packages WHERE id = ?')->execute([$id]);
                    $flashOk = 'Пакет удалён';
                }
            }
        } catch (Throwable $e) {
            $flashErr = 'Ошибка: ' . $e->getMessage();
        }
    }
}

$rows = $ready ? $pdo->query(
    'SELECT * FROM subscription_packages ORDER BY sort_order ASC, id ASC'
)->fetchAll(PDO::FETCH_ASSOC) : [];

tp_admin_web_layout_start('Пакеты подписки', 'packages', $adminLogin !== '' ? $adminLogin : null);
?>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>
<?php if (!$ready) { ?>
    <p class="err">Выполните миграцию <code>sql/migrate_subscription_packages.sql</code>.</p>
<?php } else { ?>
    <p class="meta"><a href="promo_codes.php">Промокоды →</a> · <a href="settings.php">Старый тариф (legacy)</a></p>

    <div class="card">
        <h2 style="margin:0 0 0.75rem;font-size:1rem">Новый пакет</h2>
        <form method="post">
            <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
            <input type="hidden" name="action" value="save">
            <input type="hidden" name="id" value="0">
            <label class="b">Код</label>
            <input class="in" name="code" required maxlength="32" placeholder="month">
            <label class="b">Название</label>
            <input class="in" name="title" required maxlength="128" placeholder="Месяц">
            <label class="b">Дней</label>
            <input class="in" name="days" type="number" min="1" value="30">
            <label class="b">Цена, ₽</label>
            <input class="in" name="price_rub" type="number" min="0" value="300">
            <label class="b">Порядок</label>
            <input class="in" name="sort_order" type="number" value="0">
            <label class="b"><input type="checkbox" name="is_active" value="1" checked> Активен</label>
            <div class="form-actions"><button class="btn" type="submit">Добавить</button></div>
        </form>
    </div>

    <table class="data" style="margin-top:1rem">
        <thead>
        <tr><th>ID</th><th>Код</th><th>Название</th><th>Дни</th><th>Цена</th><th>Порядок</th><th>Активен</th><th></th></tr>
        </thead>
        <tbody>
        <?php if ($rows === []) { ?><tr><td colspan="8">Нет пакетов</td></tr><?php } ?>
        <?php foreach ($rows as $r) { ?>
            <tr>
                <td colspan="8">
                    <form method="post" style="display:grid;grid-template-columns:repeat(7,1fr) auto;gap:0.4rem;align-items:end">
                        <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                        <input type="hidden" name="action" value="save">
                        <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                        <div><label class="meta">Код</label><input class="in" name="code" value="<?= tp_admin_web_h((string) $r['code']) ?>"></div>
                        <div><label class="meta">Название</label><input class="in" name="title" value="<?= tp_admin_web_h((string) $r['title']) ?>"></div>
                        <div><label class="meta">Дни</label><input class="in" name="days" type="number" value="<?= (int) $r['days'] ?>"></div>
                        <div><label class="meta">Цена</label><input class="in" name="price_rub" type="number" value="<?= (int) $r['price_rub'] ?>"></div>
                        <div><label class="meta">Порядок</label><input class="in" name="sort_order" type="number" value="<?= (int) $r['sort_order'] ?>"></div>
                        <div><label class="meta"><input type="checkbox" name="is_active" value="1" <?= ((int) $r['is_active'] === 1) ? 'checked' : '' ?>> Активен</label></div>
                        <div class="row-actions">
                            <button class="btn small" type="submit">Сохранить</button>
                        </div>
                    </form>
                    <form method="post" style="margin-top:0.35rem" onsubmit="return confirm('Удалить пакет?');">
                        <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                        <button class="btn secondary small" type="submit">Удалить</button>
                    </form>
                </td>
            </tr>
        <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php tp_admin_web_layout_end(); ?>
