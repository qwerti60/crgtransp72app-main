<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap_web.php';
tp_admin_web_require_include('admin_guide_render.php');

tp_admin_web_require_login();
$adminLogin = (string) ($_SESSION['admin_web_login'] ?? '');

$root = defined('TP_PUBLIC_ROOT') ? TP_PUBLIC_ROOT : dirname(__DIR__);
$mdPath = '';
foreach ([$root . '/docs/admin_manager_guide.md', dirname($root) . '/docs/admin_manager_guide.md'] as $candidate) {
    if (is_readable($candidate)) {
        $mdPath = $candidate;
        break;
    }
}
$body = crg_admin_guide_body_from_file($mdPath);

tp_admin_web_layout_start('Руководство менеджеру', 'guide', $adminLogin !== '' ? $adminLogin : null);
crg_admin_guide_nav_links('manager');
crg_admin_guide_styles();
?>
<div class="card guide-body">
    <?= $body ?>
</div>
<?php
tp_admin_web_layout_end();
