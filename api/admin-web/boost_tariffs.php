<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('ad_boost.php');

$pdo = tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$flashErr = '';
$flashOk = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_tariffs'])) {
    if (!tp_admin_web_csrf_check($_POST['csrf'] ?? null)) {
        $flashErr = 'CSRF: обновите страницу.';
    } elseif (crg_boost_table_exists($pdo, 'ad_boost_tariffs')) {
        foreach ($_POST['tariff'] ?? [] as $id => $row) {
            if (!is_array($row)) {
                continue;
            }
            $tid = (int) $id;
            if ($tid <= 0) {
                continue;
            }
            $st = $pdo->prepare(
                'UPDATE ad_boost_tariffs SET title = ?, hours = ?, price_rub = ?, sort_order = ?, is_active = ?
                 WHERE id = ?'
            );
            $st->execute([
                trim((string) ($row['title'] ?? '')),
                max(1, (int) ($row['hours'] ?? 24)),
                max(0, (int) ($row['price_rub'] ?? 0)),
                (int) ($row['sort_order'] ?? 0),
                isset($row['is_active']) ? 1 : 0,
                $tid,
            ]);
        }
        $flashOk = 'Тарифы сохранены.';
    }
}

$tariffs = crg_boost_active_tariffs($pdo);
if (crg_boost_table_exists($pdo, 'ad_boost_tariffs')) {
    $st = $pdo->query('SELECT * FROM ad_boost_tariffs ORDER BY sort_order, id');
    $tariffs = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
}

tp_admin_web_layout_start('Поднятие объявлений', 'boost', $adminLogin !== '' ? $adminLogin : null);
?>
<p class="meta">Тарифы «В топ» для объявлений исполнителей (P2).</p>
<?php if ($flashOk !== '') { ?><p class="ok"><?= tp_admin_web_h($flashOk) ?></p><?php } ?>
<?php if ($flashErr !== '') { ?><p class="err"><?= tp_admin_web_h($flashErr) ?></p><?php } ?>

<form method="post">
    <input type="hidden" name="save_tariffs" value="1">
    <input type="hidden" name="csrf" value="<?= tp_admin_web_h(tp_admin_web_csrf_token()) ?>">
    <div class="card">
        <table>
            <thead>
                <tr>
                    <th>Код</th>
                    <th>Название</th>
                    <th>Часы</th>
                    <th>Цена ₽</th>
                    <th>Порядок</th>
                    <th>Акт.</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($tariffs as $r) {
                $id = (int) ($r['id'] ?? 0); ?>
                <tr>
                    <td><?= tp_admin_web_h((string) ($r['code'] ?? '')) ?></td>
                    <td><input class="in" name="tariff[<?= $id ?>][title]" value="<?= tp_admin_web_h((string) ($r['title'] ?? '')) ?>"></td>
                    <td><input class="in" type="number" name="tariff[<?= $id ?>][hours]" value="<?= (int) ($r['hours'] ?? 24) ?>"></td>
                    <td><input class="in" type="number" name="tariff[<?= $id ?>][price_rub]" value="<?= (int) ($r['price_rub'] ?? 0) ?>"></td>
                    <td><input class="in" type="number" name="tariff[<?= $id ?>][sort_order]" value="<?= (int) ($r['sort_order'] ?? 0) ?>"></td>
                    <td><label class="meta"><input type="checkbox" name="tariff[<?= $id ?>][is_active]" value="1" <?= ((int) ($r['is_active'] ?? 1) === 1) ? 'checked' : '' ?>></label></td>
                </tr>
            <?php } ?>
            </tbody>
        </table>
    </div>
    <p><button class="btn" type="submit">Сохранить</button></p>
</form>
<?php tp_admin_web_layout_end(); ?>
