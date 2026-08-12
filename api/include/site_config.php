<?php
declare(strict_types=1);

/**
 * Базовый URL сайта и домен (единая точка для PHP).
 * Папка API определяется автоматически: api / api_test (и т.п.).
 */
function crg_site_base_url(): string
{
    return 'http://gruzoperevozki72.ru';
}

function crg_site_host(): string
{
    return 'gruzoperevozki72.ru';
}

/**
 * Префикс папки API: /api или /api_test.
 * Можно переопределить: putenv('CRG_API_PREFIX=/api_test') или файл api_prefix.local.php
 */
function crg_api_prefix(): string
{
    static $cached = null;
    if (is_string($cached)) {
        return $cached;
    }

    $env = getenv('CRG_API_PREFIX');
    if (is_string($env) && $env !== '') {
        $cached = str_starts_with($env, '/') ? $env : '/' . $env;
        return $cached;
    }

    $root = dirname(__DIR__); // …/api или …/api_test
    $overrideFile = $root . '/api_prefix.local.php';
    if (is_readable($overrideFile)) {
        /** @var mixed $prefix */
        $prefix = require $overrideFile;
        if (is_string($prefix) && $prefix !== '') {
            $cached = str_starts_with($prefix, '/') ? $prefix : '/' . $prefix;
            return $cached;
        }
    }

    $base = basename($root);
    if ($base !== '' && $base !== 'api' && preg_match('/^api[_-]/i', $base)) {
        $cached = '/' . $base;
        return $cached;
    }

    $cached = '/api';
    return $cached;
}

function crg_site_mail_from(): string
{
    $from = getenv('CRG_MAIL_FROM');
    if (is_string($from) && $from !== '' && filter_var($from, FILTER_VALIDATE_EMAIL)) {
        return $from;
    }

    // На shared hosting письма чаще доходят с ящика домена (создайте в панели хостинга).
    return 'noreply@' . crg_site_host();
}

function crg_site_api_url(string $path): string
{
    $normalized = str_starts_with($path, '/') ? $path : '/' . $path;
    $prefix = crg_api_prefix();

    // Срезать старый /api/ или текущий префикс, чтобы не задвоить.
    if (str_starts_with($normalized, $prefix . '/')) {
        $apiPath = $normalized;
    } elseif (str_starts_with($normalized, '/api/')) {
        $apiPath = $prefix . substr($normalized, 4);
    } else {
        $apiPath = $prefix . $normalized;
    }

    return rtrim(crg_site_base_url(), '/') . $apiPath;
}
