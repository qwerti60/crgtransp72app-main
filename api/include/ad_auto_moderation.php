<?php
declare(strict_types=1);

require_once __DIR__ . '/admin_ads.php';

function crg_moderation_tables_ready(PDO $pdo): bool
{
    static $ready = null;
    if ($ready !== null) {
        return $ready;
    }
    try {
        $pdo->query('SELECT 1 FROM moderation_stop_words LIMIT 1');
        $pdo->query('SELECT 1 FROM moderation_log LIMIT 1');

        return $ready = true;
    } catch (Throwable $e) {
        return $ready = false;
    }
}

/** @return list<string> */
function crg_moderation_active_stop_words(PDO $pdo): array
{
    if (!crg_moderation_tables_ready($pdo)) {
        return [];
    }
    try {
        $rows = $pdo->query(
            'SELECT word FROM moderation_stop_words WHERE is_active = 1 ORDER BY LENGTH(word) DESC'
        )->fetchAll(PDO::FETCH_COLUMN);

        return array_values(array_filter(array_map('strval', $rows ?: [])));
    } catch (Throwable $e) {
        return [];
    }
}

function crg_moderation_log(
    PDO $pdo,
    string $adTable,
    int $adId,
    int $userId,
    string $ruleCode,
    string $action,
    string $detail = ''
): void {
    if (!crg_moderation_tables_ready($pdo)) {
        return;
    }
    try {
        $pdo->prepare(
            'INSERT INTO moderation_log (ad_table, ad_id, user_id, rule_code, action, detail)
             VALUES (?, ?, ?, ?, ?, ?)'
        )->execute([$adTable, $adId, $userId, $ruleCode, $action, $detail !== '' ? $detail : null]);
    } catch (Throwable $e) {
        // ignore
    }
}

/** @param list<string|null> $textParts */
function crg_moderation_find_stop_word(PDO $pdo, array $textParts): ?string
{
    $words = crg_moderation_active_stop_words($pdo);
    if ($words === []) {
        return null;
    }
    $haystack = mb_strtolower(implode(' ', array_filter(array_map(
        static fn ($v) => trim((string) $v),
        $textParts
    ))));
    if ($haystack === '') {
        return null;
    }
    foreach ($words as $word) {
        $w = mb_strtolower(trim($word));
        if ($w !== '' && mb_strpos($haystack, $w) !== false) {
            return $word;
        }
    }

    return null;
}

/** @param list<string|null> $images */
function crg_moderation_all_photos_empty(array $images): bool
{
    foreach ($images as $img) {
        if ($img !== null && $img !== '' && strlen((string) $img) > 32) {
            return false;
        }
    }

    return true;
}

function crg_moderation_is_duplicate(
    PDO $pdo,
    array $cfg,
    int $userId,
    int $excludeAdId,
    array $fields
): bool {
    if ($userId <= 0) {
        return false;
    }
    $table = (string) ($cfg['table'] ?? '');
    if ($table === '') {
        return false;
    }
    $city = trim((string) ($fields['city'] ?? ''));
    if ($city === '') {
        return false;
    }

    $where = ['iduser = ?', 'city = ?', 'flag = 1', 'id <> ?'];
    $params = [$userId, $city, $excludeAdId];

    if ($table === 'add_ob_gp') {
        $marka = trim((string) ($fields['marka'] ?? ''));
        if ($marka === '') {
            return false;
        }
        $where[] = 'marka = ?';
        $params[] = $marka;
    } elseif ($table === 'add_ob_vidt') {
        $vidt = trim((string) ($fields['vidt'] ?? ''));
        if ($vidt === '') {
            return false;
        }
        $where[] = 'vidt = ?';
        $params[] = $vidt;
    }

    try {
        $sql = 'SELECT id FROM `' . $table . '` WHERE ' . implode(' AND ', $where) . ' LIMIT 1';
        $st = $pdo->prepare($sql);
        $st->execute($params);

        return $st->fetch() !== false;
    } catch (Throwable $e) {
        return false;
    }
}

/**
 * Автомодерация после создания объявления исполнителя.
 *
 * @param list<string|null> $images img1..img4 blobs
 * @return array{action: string, rule?: string}
 */
function crg_ad_auto_moderate(
    PDO $pdo,
    string $adType,
    int $adId,
    int $userId,
    array $fields,
    array $images
): array {
    $cfg = crg_admin_performer_ad_config($adType);
    if ($cfg === null || $adId <= 0) {
        return ['action' => 'skip'];
    }
    if (!crg_moderation_tables_ready($pdo)) {
        return ['action' => 'skip'];
    }

    $table = (string) $cfg['table'];
    $textParts = [$fields['city'] ?? '', $fields['marka'] ?? '', $fields['vidt'] ?? ''];

    $stopWord = crg_moderation_find_stop_word($pdo, $textParts);
    if ($stopWord !== null) {
        crg_moderation_log($pdo, $table, $adId, $userId, 'stop_word', 'reject', $stopWord);
        crg_ad_auto_moderate_reject($pdo, $cfg, $adId, $userId, 'Объявление отклонено: запрещённое слово «' . $stopWord . '».');

        return ['action' => 'reject', 'rule' => 'stop_word'];
    }

    if (crg_moderation_all_photos_empty($images)) {
        crg_moderation_log($pdo, $table, $adId, $userId, 'no_photos', 'reject', '');
        crg_ad_auto_moderate_reject($pdo, $cfg, $adId, $userId, 'Объявление отклонено: добавьте хотя бы одно фото транспорта или техники.');

        return ['action' => 'reject', 'rule' => 'no_photos'];
    }

    if (crg_moderation_is_duplicate($pdo, $cfg, $userId, $adId, $fields)) {
        crg_moderation_log($pdo, $table, $adId, $userId, 'duplicate', 'queue', '');
        // Остаётся flag=0 — в очереди модерации

        return ['action' => 'queue', 'rule' => 'duplicate'];
    }

    return ['action' => 'ok'];
}

function crg_ad_auto_moderate_reject(
    PDO $pdo,
    array $cfg,
    int $adId,
    int $userId,
    string $message
): void {
    require_once __DIR__ . '/admin_mail.php';
    require_once __DIR__ . '/fcm_push.php';

    crg_admin_performer_ad_set_flag($pdo, $cfg, $adId, 0);
    crg_admin_notify_user_mail_and_push(
        $pdo,
        $userId,
        'Объявление не опубликовано',
        '№' . $adId . ': ' . crg_admin_notify_excerpt($message),
        static function () use ($pdo, $cfg, $adId, $userId, $message): bool|string {
            return crg_admin_send_performer_ad_rejection_mail($pdo, $cfg, $adId, $userId, $message);
        }
    );
}

/**
 * Хук для legacy add_ob_*.php (mysqli уже выполнил INSERT).
 *
 * @param list<string|null> $images
 */
function crg_ad_auto_moderate_hook(
    string $adType,
    int $adId,
    int $userId,
    array $fields,
    array $images
): void {
    if ($adId <= 0 || $userId <= 0) {
        return;
    }
    if (!defined('TP_PUBLIC_ROOT')) {
        define('TP_PUBLIC_ROOT', dirname(__DIR__));
    }
    require_once __DIR__ . '/api_bootstrap.php';
    try {
        crg_ad_auto_moderate(tp_pdo(), $adType, $adId, $userId, $fields, $images);
    } catch (Throwable $e) {
        // не блокируем создание объявления
    }
}
