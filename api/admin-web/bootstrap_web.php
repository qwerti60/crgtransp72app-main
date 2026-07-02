<?php
declare(strict_types=1);

if (!defined('TP_PUBLIC_ROOT')) {
    define('TP_PUBLIC_ROOT', dirname(__DIR__));
}

function tp_admin_web_require_include(string $file): void
{
    $path = TP_PUBLIC_ROOT . '/include/' . $file;
    if (!is_readable($path)) {
        http_response_code(500);
        header('Content-Type: text/plain; charset=utf-8');
        echo "Не найден файл:\n{$path}\n";
        exit;
    }
    require_once $path;
}

tp_admin_web_require_include('api_bootstrap.php');

if (session_status() === PHP_SESSION_NONE) {
    $secure = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off');
    session_start([
        'cookie_httponly' => true,
        'cookie_samesite' => 'Lax',
        'cookie_secure' => $secure,
        'use_strict_mode' => true,
    ]);
}

function tp_admin_web_h(string $s): string
{
    return htmlspecialchars($s, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function tp_admin_web_csrf_token(): string
{
    if (empty($_SESSION['admin_web_csrf'])) {
        $_SESSION['admin_web_csrf'] = bin2hex(random_bytes(16));
    }

    return (string) $_SESSION['admin_web_csrf'];
}

function tp_admin_web_csrf_check(?string $token): bool
{
    return is_string($token)
        && isset($_SESSION['admin_web_csrf'])
        && hash_equals((string) $_SESSION['admin_web_csrf'], $token);
}

function tp_admin_web_clear_auth_session(): void
{
    unset($_SESSION['admin_web_token'], $_SESSION['admin_web_login']);
}

/** Если сессия уже валидна — редирект в админку; иначе сброс устаревшего токена. */
function tp_admin_web_redirect_if_logged_in(): void
{
    tp_admin_web_require_include('admin_auth.php');
    $pdo = tp_pdo();
    if (tp_admin_authorized($pdo)) {
        header('Location: stats.php', true, 302);
        exit;
    }
    tp_admin_web_clear_auth_session();
}

function tp_admin_web_require_login(): PDO
{
    tp_admin_web_require_include('admin_auth.php');
    $pdo = tp_pdo();
    if (!tp_admin_authorized($pdo)) {
        tp_admin_web_clear_auth_session();
        header('Location: login.php', true, 302);
        exit;
    }

    return $pdo;
}

/**
 * @param 'stats'|'cities'|'vidt'|'vidg'|'vidkuzov'|'users'|'performer_ads'|'customer_ads'|'broadcast'|'settings' $activeNav
 */
function tp_admin_web_layout_start(string $pageTitle, string $activeNav, ?string $adminLogin = null): void
{
    $nav = [
        'stats' => ['Статистика', 'stats.php'],
        'cities' => ['Города', 'cities.php'],
        'vidt' => ['Вид техники', 'ref_list.php?type=vidt'],
        'vidg' => ['Грузоподъёмность', 'ref_list.php?type=vidg'],
        'vidkuzov' => ['Вид кузова', 'ref_list.php?type=vidkuzov'],
        'users' => ['Пользователи', 'users.php'],
        'performer_ads' => ['Объявления исполнителей', 'performer_ads.php?type=gp'],
        'customer_ads' => ['Заявки заказчиков', 'customer_ads.php?type=orders'],
        'broadcast' => ['Рассылка', 'broadcast.php'],
        'settings' => ['Настройки', 'settings.php'],
    ];

    $performerAdsPending = 0;
    if ($adminLogin !== null && $adminLogin !== '') {
        tp_admin_web_require_include('admin_ads.php');
        try {
            $performerAdsPending = crg_admin_performer_ads_pending_total(tp_pdo());
        } catch (Throwable $e) {
            $performerAdsPending = 0;
        }
    }

    header('Content-Type: text/html; charset=utf-8');
    ?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= tp_admin_web_h($pageTitle) ?> — админ</title>
    <style>
        :root { --nav-bg: #0f172a; --nav-hover: #1e293b; --accent: #38bdf8; --main-bg: #f1f5f9; }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: system-ui, -apple-system, sans-serif; background: var(--main-bg); color: #0f172a; min-height: 100vh; }
        .admin-shell { display: flex; flex-direction: row; width: 100%; min-height: 100vh; align-items: stretch; }
        .admin-nav { min-width: 14rem; width: 16rem; flex-shrink: 0; background: var(--nav-bg); color: #e2e8f0; padding: 1rem 0; display: flex; flex-direction: column; }
        .admin-nav h2 { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.06em; color: #94a3b8; margin: 0 1rem 0.5rem; font-weight: 600; }
        .admin-nav a { display: flex; align-items: center; justify-content: space-between; gap: 0.5rem; padding: 0.55rem 1rem; color: #e2e8f0; text-decoration: none; font-size: 0.9rem; border-left: 3px solid transparent; }
        .admin-nav a:hover { background: var(--nav-hover); }
        .admin-nav a.nav-active { background: var(--nav-hover); border-left-color: var(--accent); color: #fff; }
        .nav-dot { width: 9px; height: 9px; border-radius: 50%; background: #ef4444; flex-shrink: 0; box-shadow: 0 0 0 2px rgba(239,68,68,.35); }
        .admin-nav .nav-foot { margin-top: auto; padding: 1rem; font-size: 0.8rem; color: #94a3b8; border-top: 1px solid #334155; }
        .admin-nav .nav-foot a { display: inline; padding: 0; color: var(--accent); border: none; }
        .admin-nav .nav-foot .nav-foot-guide { margin: 0.5rem 0 0.35rem; line-height: 1.35; }
        .admin-nav .nav-foot .meta-link { color: #94a3b8; font-size: 0.75rem; }
        .admin-nav .nav-foot .meta-link:hover { color: var(--accent); }
        .admin-main { flex: 1; min-width: 0; padding: 1rem 1.25rem; overflow-x: auto; }
        .admin-main h1 { font-size: 1.25rem; margin: 0 0 1rem; font-weight: 600; }
        a.btn, button.btn { display: inline-block; padding: 0.4rem 0.75rem; background: #0369a1; color: #fff; text-decoration: none; border: none; border-radius: 6px; font-size: 0.875rem; cursor: pointer; }
        a.btn.secondary, button.btn.secondary { background: #475569; }
        a.btn.danger, button.btn.danger { background: #b91c1c; }
        a.btn.danger:hover, button.btn.danger:hover { background: #991b1b; }
        a.btn.small, button.btn.small { font-size: 0.8rem; padding: 0.3rem 0.55rem; }
        table.data { width: 100%; border-collapse: collapse; background: #fff; font-size: 0.85rem; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(15,23,42,.08); }
        table.data th, table.data td { border: 1px solid #e2e8f0; padding: 0.4rem 0.5rem; text-align: left; vertical-align: top; }
        table.data th { background: #e2e8f0; font-weight: 600; }
        table.data tr:nth-child(even) { background: #f8fafc; }
        .meta { color: #64748b; font-size: 0.8rem; }
        .err { color: #b91c1c; margin: 0 0 1rem; }
        .ok { color: #15803d; margin: 0 0 1rem; }
        .filters { margin-bottom: 1rem; display: flex; flex-wrap: wrap; gap: 0.4rem; align-items: center; }
        .num { text-align: right; white-space: nowrap; }
        label.b { display: block; font-weight: 600; margin-top: 0.75rem; font-size: 0.85rem; }
        input.in, textarea.in, select.in { width: 100%; max-width: 32rem; padding: 0.45rem 0.5rem; margin-top: 0.2rem; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 0.9rem; }
        .form-actions { margin-top: 1.25rem; display: flex; gap: 0.5rem; flex-wrap: wrap; }
        .card { background: #fff; padding: 1rem; margin-bottom: 1rem; border-radius: 8px; box-shadow: 0 1px 3px rgba(15,23,42,.08); }
        .row-actions { display: flex; flex-wrap: wrap; gap: 0.35rem; align-items: center; }
        .warn { color: #b45309; font-size: 0.85rem; margin: 0.5rem 0; }
        .thumb-preview { width: 72px; height: 54px; object-fit: contain; display: block; }
        .badge { display: inline-block; padding: 0.15rem 0.45rem; border-radius: 4px; font-size: 0.75rem; font-weight: 600; }
        .badge-pending { background: #fef3c7; color: #92400e; }
        .badge-ok { background: #dcfce7; color: #166534; }
        .badge-muted { background: #e2e8f0; color: #475569; }
        .rating-stars { color: #ca8a04; letter-spacing: 0.05em; white-space: nowrap; }
        .img-grid { display: flex; flex-wrap: wrap; gap: 0.75rem; }
        .img-grid figure { margin: 0; }
        .img-grid figcaption { font-size: 0.75rem; color: #64748b; margin-bottom: 0.25rem; }
        .blob-gallery { display: flex; flex-wrap: wrap; gap: 1rem; margin-top: 0.5rem; }
        .blob-gallery-item { margin: 0; }
        .blob-gallery-item figcaption { font-size: 0.75rem; color: #64748b; margin-bottom: 0.35rem; }
        .blob-gallery-sep { border: none; border-top: 1px solid #e2e8f0; margin: 1rem 0; }
        .blob-thumb { display: block; border: 1px solid #cbd5e1; background: #f8fafc; padding: 4px; border-radius: 8px; cursor: zoom-in; line-height: 0; }
        .blob-thumb:hover { border-color: #0369a1; box-shadow: 0 2px 8px rgba(3,105,161,.15); }
        .blob-thumb img { width: 120px; height: 90px; object-fit: contain; display: block; pointer-events: none; }
        .blob-thumb-frame { width: 120px; height: 90px; border: 0; display: block; pointer-events: none; background: #fff; }
        .lightbox { position: fixed; inset: 0; z-index: 2000; display: flex; align-items: center; justify-content: center; padding: 1rem; }
        .lightbox[hidden] { display: none !important; }
        .lightbox-backdrop { position: absolute; inset: 0; background: rgba(15,23,42,.82); cursor: pointer; }
        .lightbox-dialog { position: relative; z-index: 1; width: min(96vw, 1200px); max-height: 96vh; background: #fff; border-radius: 10px; box-shadow: 0 20px 50px rgba(0,0,0,.35); display: flex; flex-direction: column; overflow: hidden; }
        .lightbox-close { position: absolute; top: 0.35rem; right: 0.5rem; z-index: 2; border: none; background: transparent; font-size: 1.75rem; line-height: 1; color: #64748b; cursor: pointer; padding: 0.25rem 0.5rem; }
        .lightbox-close:hover { color: #0f172a; }
        .lightbox-caption { margin: 0; padding: 0.75rem 3rem 0.5rem 1rem; font-size: 0.9rem; font-weight: 600; border-bottom: 1px solid #e2e8f0; }
        .lightbox-body { padding: 1rem; overflow: auto; text-align: center; flex: 1; min-height: 0; }
        .lightbox-img { max-width: 100%; max-height: calc(96vh - 6rem); object-fit: contain; vertical-align: top; }
        .lightbox-pdf { width: 100%; height: calc(96vh - 6rem); min-height: 420px; border: 0; background: #fff; }
    </style>
</head>
<body>
<div class="admin-shell">
    <nav class="admin-nav" aria-label="Разделы админки">
        <h2>CRG Transp72</h2>
        <?php foreach ($nav as $key => $pair) {
            [$label, $href] = $pair;
            $cls = $activeNav === $key ? 'nav-active' : '';
            ?>
            <a class="<?= tp_admin_web_h($cls) ?>" href="<?= tp_admin_web_h($href) ?>">
                <span><?= tp_admin_web_h($label) ?></span>
                <?php if ($key === 'performer_ads' && $performerAdsPending > 0) { ?>
                    <span class="nav-dot" title="На проверке: <?= (int) $performerAdsPending ?>"></span>
                <?php } ?>
            </a>
        <?php } ?>
        <div class="nav-foot">
            <?php if ($adminLogin !== null && $adminLogin !== '') { ?>
                <div><?= tp_admin_web_h($adminLogin) ?></div>
                <div class="nav-foot-guide"><a href="manager_guide.php">Руководство</a></div>
                <div class="nav-foot-guide"><a href="guide.php" class="meta-link">Техническое</a></div>
            <?php } ?>
            <a href="logout.php">Выйти</a>
        </div>
    </nav>
    <div class="admin-main">
        <h1><?= tp_admin_web_h($pageTitle) ?></h1>
    <?php
}

function tp_admin_web_layout_end(): void
{
    ?>
    </div>
</div>
<div id="admin-lightbox" class="lightbox" hidden aria-hidden="true">
    <div class="lightbox-backdrop" data-lightbox-close tabindex="-1"></div>
    <div class="lightbox-dialog" role="dialog" aria-modal="true" aria-labelledby="admin-lightbox-caption">
        <button type="button" class="lightbox-close" data-lightbox-close aria-label="Закрыть">&times;</button>
        <p class="lightbox-caption" id="admin-lightbox-caption"></p>
        <div class="lightbox-body" id="admin-lightbox-body"></div>
    </div>
</div>
<script>
(function () {
    var lb = document.getElementById('admin-lightbox');
    if (!lb) return;
    var body = document.getElementById('admin-lightbox-body');
    var cap = document.getElementById('admin-lightbox-caption');

    function closeLightbox() {
        lb.hidden = true;
        lb.setAttribute('aria-hidden', 'true');
        body.innerHTML = '';
        cap.textContent = '';
        document.body.style.overflow = '';
    }

    function openLightbox(src, type, label) {
        cap.textContent = label || '';
        body.innerHTML = '';
        if (type === 'pdf') {
            var frame = document.createElement('iframe');
            frame.className = 'lightbox-pdf';
            frame.src = src + (src.indexOf('#') >= 0 ? '' : '#view=FitH');
            frame.title = label || 'Документ';
            body.appendChild(frame);
        } else {
            var img = document.createElement('img');
            img.className = 'lightbox-img';
            img.src = src;
            img.alt = label || '';
            body.appendChild(img);
        }
        lb.hidden = false;
        lb.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';
    }

    document.addEventListener('click', function (e) {
        var trigger = e.target.closest('[data-lightbox-src]');
        if (trigger) {
            e.preventDefault();
            openLightbox(
                trigger.getAttribute('data-lightbox-src') || '',
                trigger.getAttribute('data-lightbox-type') || 'image',
                trigger.getAttribute('data-lightbox-label') || ''
            );
            return;
        }
        if (e.target.closest('[data-lightbox-close]')) {
            closeLightbox();
        }
    });

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && !lb.hidden) {
            closeLightbox();
        }
    });
})();
</script>
</body>
</html>
    <?php
}
