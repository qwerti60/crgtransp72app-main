<?php
declare(strict_types=1);

function crg_admin_guide_inline_md(string $s): string
{
    $s = tp_admin_web_h($s);
    $s = preg_replace('/\*\*(.+?)\*\*/', '<strong>$1</strong>', $s) ?? $s;
    $s = preg_replace('/`([^`]+)`/', '<code>$1</code>', $s) ?? $s;

    return $s;
}

function crg_admin_guide_md_to_html(string $md): string
{
    $md = str_replace(["\r\n", "\r"], "\n", $md);
    $lines = explode("\n", $md);
    $html = '';
    $inPre = false;
    $inUl = false;

    $closeUl = static function () use (&$html, &$inUl): void {
        if ($inUl) {
            $html .= "</ul>\n";
            $inUl = false;
        }
    };

    $closeTable = static function () use (&$html, &$inTable): void {
        if ($inTable) {
            $html .= "</tbody></table>\n";
            $inTable = false;
        }
    };
    $inTable = false;

    foreach ($lines as $line) {
        if (str_starts_with($line, '```')) {
            $closeUl();
            $closeTable();
            if ($inPre) {
                $html .= "</code></pre>\n";
                $inPre = false;
            } else {
                $html .= "<pre><code>";
                $inPre = true;
            }
            continue;
        }
        if ($inPre) {
            $html .= tp_admin_web_h($line) . "\n";
            continue;
        }

        if (preg_match('/^\|(.+)\|$/', $line, $m)) {
            $closeUl();
            $cells = array_map('trim', explode('|', trim($m[1], '|')));
            if (str_contains($line, '---')) {
                continue;
            }
            if (!$inTable) {
                $html .= '<table class="data guide-table"><thead><tr>';
                foreach ($cells as $c) {
                    $html .= '<th>' . tp_admin_web_h($c) . '</th>';
                }
                $html .= '</tr></thead><tbody>';
                $inTable = true;
                continue;
            }
            $html .= '<tr>';
            foreach ($cells as $c) {
                $html .= '<td>' . crg_admin_guide_inline_md($c) . '</td>';
            }
            $html .= '</tr>';
            continue;
        }

        $closeTable();

        if ($line === '---') {
            $closeUl();
            $html .= "<hr>\n";
            continue;
        }

        if (preg_match('/^### (.+)$/', $line, $m)) {
            $closeUl();
            $html .= '<h3>' . crg_admin_guide_inline_md($m[1]) . "</h3>\n";
            continue;
        }
        if (preg_match('/^## (.+)$/', $line, $m)) {
            $closeUl();
            $html .= '<h2>' . crg_admin_guide_inline_md($m[1]) . "</h2>\n";
            continue;
        }
        if (preg_match('/^# (.+)$/', $line, $m)) {
            $closeUl();
            $html .= '<p class="guide-lead">' . crg_admin_guide_inline_md($m[1]) . "</p>\n";
            continue;
        }

        if (preg_match('/^- (.+)$/', $line, $m)) {
            if (!$inUl) {
                $html .= "<ul>\n";
                $inUl = true;
            }
            $html .= '<li>' . crg_admin_guide_inline_md($m[1]) . "</li>\n";
            continue;
        }

        if (trim($line) === '') {
            $closeUl();
            continue;
        }

        $closeUl();
        $html .= '<p>' . crg_admin_guide_inline_md($line) . "</p>\n";
    }

    $closeUl();
    $closeTable();
    if ($inPre) {
        $html .= "</code></pre>\n";
    }

    return $html;
}

function crg_admin_guide_md_path(string $filename): ?string
{
    $root = defined('TP_PUBLIC_ROOT') ? TP_PUBLIC_ROOT : dirname(__DIR__);
    $candidates = [
        $root . '/docs/' . $filename,
        dirname($root) . '/docs/' . $filename,
    ];
    foreach ($candidates as $path) {
        if (is_readable($path)) {
            return $path;
        }
    }

    return null;
}

function crg_admin_guide_body_from_file(string $mdPath): string
{
    if (!is_readable($mdPath)) {
        return '<p class="err">Файл руководства не найден.</p>'
            . '<p class="meta">Ожидается файл в <code>api/docs/</code> или <code>docs/</code> в корне проекта. '
            . 'Залейте на сервер каталог <code>api/docs/</code> с markdown-файлами.</p>';
    }
    $raw = (string) file_get_contents($mdPath);
    $raw = preg_replace('/^# .+\n+/u', '', $raw, 1) ?? $raw;

    return crg_admin_guide_md_to_html($raw);
}

function crg_admin_guide_nav_links(string $active): void
{
    $mgr = $active === 'manager' ? 'btn' : 'btn secondary';
    $dev = $active === 'dev' ? 'btn' : 'btn secondary';
    echo '<p class="filters guide-nav">';
    echo '<a class="' . $mgr . ' small" href="manager_guide.php">Для менеджера</a> ';
    echo '<a class="' . $dev . ' small" href="guide.php">Техническое</a>';
    echo '</p>';
}

function crg_admin_guide_styles(): void
{
    ?>
<style>
    .guide-body h2 { font-size: 1.05rem; margin: 1.25rem 0 0.5rem; font-weight: 600; }
    .guide-body h3 { font-size: 0.95rem; margin: 1rem 0 0.4rem; font-weight: 600; }
    .guide-body p, .guide-body li { font-size: 0.9rem; line-height: 1.55; }
    .guide-body ul { margin: 0.35rem 0 0.75rem 1.25rem; padding: 0; }
    .guide-body pre { background: #0f172a; color: #e2e8f0; padding: 0.75rem 1rem; border-radius: 8px; overflow-x: auto; font-size: 0.82rem; line-height: 1.45; }
    .guide-body pre code { display: block; background: transparent; padding: 0; border-radius: 0; color: inherit; font-size: inherit; white-space: pre-wrap; word-break: break-word; }
    .guide-body :not(pre) > code { background: #e2e8f0; padding: 0.1rem 0.35rem; border-radius: 4px; font-size: 0.85em; }
    .guide-body hr { border: none; border-top: 1px solid #e2e8f0; margin: 1.25rem 0; }
    .guide-body .guide-lead { color: #64748b; margin-top: 0; }
    .guide-body .guide-table { margin: 0.5rem 0 1rem; }
    .guide-body .guide-note { background: #eff6ff; border-left: 4px solid #0369a1; padding: 0.65rem 0.85rem; margin: 0.75rem 0; font-size: 0.9rem; }
</style>
    <?php
}
