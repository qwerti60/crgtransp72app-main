<?php
declare(strict_types=1);

/**
 * Базовый URL сайта и домен (единая точка для PHP).
 */
function crg_site_base_url(): string
{
    return 'http://gruzoperevozki72.ru';
}

function crg_site_host(): string
{
    return 'gruzoperevozki72.ru';
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
    $apiPath = str_starts_with($normalized, '/api/')
        ? $normalized
        : '/api' . $normalized;

    return rtrim(crg_site_base_url(), '/') . $apiPath;
}
