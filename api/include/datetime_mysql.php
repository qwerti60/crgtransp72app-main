<?php

/**
 * Преобразует ISO8601 / произвольную строку в формат MySQL DATETIME.
 */
function crg_normalize_mysql_datetime(string $raw): string
{
    $raw = trim($raw);
    if ($raw === '' || strpos($raw, '0000-00-00') === 0) {
        return date('Y-m-d H:i:s');
    }

    $ts = strtotime($raw);
    if ($ts === false) {
        return date('Y-m-d H:i:s');
    }

    return date('Y-m-d H:i:s', $ts);
}
