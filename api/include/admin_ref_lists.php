<?php
declare(strict_types=1);

/**
 * CRUD справочников vidt / vidg / vidkuzov / gruzchik для веб-админки.
 */

/** @return array<string, array<string, mixed>> */
function crg_admin_ref_types(): array
{
    return [
        'vidt' => [
            'label' => 'Вид техники',
            'table' => 'vidt',
            'name_col' => 'name',
            'nav' => 'vidt',
            'api' => 'vidt.php',
            'has_image' => true,
            'refs' => [
                ['table' => 'users', 'column' => 'vidt'],
                ['table' => 'add_ob_vidt', 'column' => 'vidt'],
                ['table' => 'orderst', 'column' => 'vidt'],
            ],
        ],
        'vidg' => [
            'label' => 'Грузоподъёмность',
            'table' => 'vidg',
            'name_col' => 'name',
            'nav' => 'vidg',
            'api' => 'get_vidgr.php',
            'has_image' => true,
            'refs' => [
                ['table' => 'users', 'column' => 'maxgruz'],
                ['table' => 'orders', 'column' => 'maxgruz'],
                ['table' => 'add_ob_gp', 'column' => 'maxgruz'],
                ['table' => 'gruz_info', 'column' => 'maxgruz'],
            ],
        ],
        'gruzchik' => [
            'label' => 'Грузчики',
            'table' => 'gruzchik',
            'name_col' => 'name',
            'nav' => 'gruzchik',
            'api' => 'gruzchik.php',
            'has_image' => true,
            'refs' => [
                ['table' => 'add_ob_gr', 'column' => 'gruzchik'],
                ['table' => 'ordersg', 'column' => 'gruzchik'],
            ],
        ],
        'vidkuzov' => [
            'label' => 'Вид кузова',
            'table' => 'vidkuzov',
            'name_col' => 'namevidk',
            'nav' => 'vidkuzov',
            'api' => 'vidk.php',
            'has_image' => false,
            'refs' => [
                ['table' => 'users', 'column' => 'vidk'],
                ['table' => 'orders', 'column' => 'vidk'],
                ['table' => 'add_ob_gp', 'column' => 'vidk'],
                ['table' => 'gruz_info', 'column' => 'vidk'],
            ],
        ],
    ];
}

/** @return array<string, mixed>|null */
function crg_admin_ref_config(string $type): ?array
{
    $types = crg_admin_ref_types();

    return $types[$type] ?? null;
}

function crg_admin_ref_normalize_name(string $name): string
{
    return trim(preg_replace('/\s+/u', ' ', $name) ?? $name);
}

/**
 * @param array<string, mixed> $cfg
 * @return array{rows: list<array<string, mixed>>, total: int}|array{error: string}
 */
function crg_admin_ref_list(PDO $pdo, array $cfg, string $search, int $offset, int $limit): array
{
    if ($limit < 1) {
        $limit = 50;
    }
    if ($limit > 500) {
        $limit = 500;
    }
    if ($offset < 0) {
        $offset = 0;
    }

    $table = (string) $cfg['table'];
    $nameCol = (string) $cfg['name_col'];
    $hasImage = !empty($cfg['has_image']);
    $search = crg_admin_ref_normalize_name($search);

    $where = '1=1';
    $params = [];
    if ($search !== '') {
        $where .= " AND `{$nameCol}` LIKE ?";
        $params[] = '%' . $search . '%';
    }

    try {
        $cntSt = $pdo->prepare("SELECT COUNT(*) AS c FROM `{$table}` WHERE {$where}");
        $cntSt->execute($params);
        $total = (int) ($cntSt->fetch()['c'] ?? 0);

        $cols = 'id, `' . $nameCol . '` AS name';
        if ($hasImage) {
            $cols .= ', (LENGTH(image) > 0) AS has_image';
        }
        $sql = "SELECT {$cols} FROM `{$table}` WHERE {$where}"
            . " ORDER BY `{$nameCol}` COLLATE utf8mb4_unicode_ci"
            . ' LIMIT ' . (int) $limit . ' OFFSET ' . (int) $offset;
        $st = $pdo->prepare($sql);
        $st->execute($params);
        $rows = $st->fetchAll();
    } catch (Throwable $e) {
        return ['error' => 'Таблица ' . $table . ' недоступна: ' . $e->getMessage()];
    }

    return ['rows' => $rows, 'total' => $total];
}

/**
 * @param array<string, mixed> $cfg
 * @return array<string, mixed>|null
 */
function crg_admin_ref_get(PDO $pdo, array $cfg, int $id): ?array
{
    if ($id <= 0) {
        return null;
    }

    $table = (string) $cfg['table'];
    $nameCol = (string) $cfg['name_col'];
    $hasImage = !empty($cfg['has_image']);
    $cols = 'id, `' . $nameCol . '` AS name';
    if ($hasImage) {
        $cols .= ', (LENGTH(image) > 0) AS has_image';
    }

    $st = $pdo->prepare("SELECT {$cols} FROM `{$table}` WHERE id = ? LIMIT 1");
    $st->execute([$id]);
    $row = $st->fetch();

    return $row === false ? null : $row;
}

/**
 * @param array<string, mixed> $cfg
 */
function crg_admin_ref_name_exists(PDO $pdo, array $cfg, string $name, int $excludeId = 0): bool
{
    $table = (string) $cfg['table'];
    $nameCol = (string) $cfg['name_col'];
    $sql = "SELECT 1 FROM `{$table}` WHERE `{$nameCol}` = ?";
    $params = [$name];
    if ($excludeId > 0) {
        $sql .= ' AND id != ?';
        $params[] = $excludeId;
    }
    $sql .= ' LIMIT 1';
    $st = $pdo->prepare($sql);
    $st->execute($params);

    return $st->fetch() !== false;
}

/**
 * @param array<string, mixed> $cfg
 * @return array<string, int>
 */
function crg_admin_ref_usage_breakdown(PDO $pdo, array $cfg, string $name): array
{
    $name = crg_admin_ref_normalize_name($name);
    if ($name === '') {
        return [];
    }

    $out = [];
    foreach ($cfg['refs'] as $ref) {
        $table = (string) $ref['table'];
        $column = (string) $ref['column'];
        $key = $table . '.' . $column;
        try {
            $st = $pdo->prepare("SELECT COUNT(*) AS c FROM `{$table}` WHERE `{$column}` = ?");
            $st->execute([$name]);
            $cnt = (int) ($st->fetch()['c'] ?? 0);
            if ($cnt > 0) {
                $out[$key] = $cnt;
            }
        } catch (Throwable $e) {
            // таблица может отсутствовать в минимальной локальной схеме
        }
    }

    return $out;
}

function crg_admin_ref_usage_total(PDO $pdo, array $cfg, string $name): int
{
    $sum = 0;
    foreach (crg_admin_ref_usage_breakdown($pdo, $cfg, $name) as $cnt) {
        $sum += $cnt;
    }

    return $sum;
}

/** @return true|string */
function crg_admin_ref_validate_name(string $name)
{
    $name = crg_admin_ref_normalize_name($name);
    if ($name === '') {
        return 'Название не может быть пустым';
    }
    if (mb_strlen($name) > 255) {
        return 'Название слишком длинное (макс. 255 символов)';
    }

    return true;
}

/**
 * @param array<string, mixed> $cfg
 * @return array{ok: true, id: int}|array{ok: false, error: string}
 */
function crg_admin_ref_insert(PDO $pdo, array $cfg, string $name): array
{
    $valid = crg_admin_ref_validate_name($name);
    if ($valid !== true) {
        return ['ok' => false, 'error' => $valid];
    }
    $name = crg_admin_ref_normalize_name($name);
    if (crg_admin_ref_name_exists($pdo, $cfg, $name)) {
        return ['ok' => false, 'error' => 'Запись с таким названием уже есть'];
    }

    $table = (string) $cfg['table'];
    $nameCol = (string) $cfg['name_col'];
    $hasImage = !empty($cfg['has_image']);

    try {
        if ($hasImage) {
            $placeholder = crg_admin_ref_placeholder_png();
            $st = $pdo->prepare("INSERT INTO `{$table}` (`{$nameCol}`, image) VALUES (?, ?)");
            $st->bindValue(1, $name);
            $st->bindValue(2, $placeholder, PDO::PARAM_LOB);
            $st->execute();
        } else {
            $st = $pdo->prepare("INSERT INTO `{$table}` (`{$nameCol}`) VALUES (?)");
            $st->execute([$name]);
        }

        return ['ok' => true, 'id' => (int) $pdo->lastInsertId()];
    } catch (Throwable $e) {
        return ['ok' => false, 'error' => 'Не удалось добавить: ' . $e->getMessage()];
    }
}

/**
 * @param array<string, mixed> $cfg
 * @return true|string
 */
function crg_admin_ref_rename_references(PDO $pdo, array $cfg, string $oldName, string $newName)
{
    $oldName = crg_admin_ref_normalize_name($oldName);
    $newName = crg_admin_ref_normalize_name($newName);
    if ($oldName === '' || $newName === '' || $oldName === $newName) {
        return true;
    }

    try {
        $pdo->beginTransaction();
        foreach ($cfg['refs'] as $ref) {
            $table = (string) $ref['table'];
            $column = (string) $ref['column'];
            $st = $pdo->prepare("UPDATE `{$table}` SET `{$column}` = ? WHERE `{$column}` = ?");
            $st->execute([$newName, $oldName]);
        }
        $pdo->commit();
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        return 'Ошибка обновления связанных записей: ' . $e->getMessage();
    }

    return true;
}

/**
 * @param array<string, mixed> $cfg
 * @return true|string
 */
function crg_admin_ref_update(PDO $pdo, array $cfg, int $id, string $name, bool $renameReferences)
{
    if ($id <= 0) {
        return 'Некорректный id';
    }

    $cur = crg_admin_ref_get($pdo, $cfg, $id);
    if ($cur === null) {
        return 'Запись не найдена';
    }

    $valid = crg_admin_ref_validate_name($name);
    if ($valid !== true) {
        return $valid;
    }

    $name = crg_admin_ref_normalize_name($name);
    $oldName = crg_admin_ref_normalize_name((string) ($cur['name'] ?? ''));
    if (crg_admin_ref_name_exists($pdo, $cfg, $name, $id)) {
        return 'Запись с таким названием уже есть';
    }

    if ($renameReferences && $oldName !== '' && $oldName !== $name) {
        $ren = crg_admin_ref_rename_references($pdo, $cfg, $oldName, $name);
        if ($ren !== true) {
            return $ren;
        }
    }

    $table = (string) $cfg['table'];
    $nameCol = (string) $cfg['name_col'];

    try {
        $st = $pdo->prepare("UPDATE `{$table}` SET `{$nameCol}` = ? WHERE id = ?");
        $st->execute([$name, $id]);
    } catch (Throwable $e) {
        return 'Не удалось сохранить: ' . $e->getMessage();
    }

    return true;
}

/**
 * @param array<string, mixed> $cfg
 * @return true|string
 */
function crg_admin_ref_delete(PDO $pdo, array $cfg, int $id)
{
    if ($id <= 0) {
        return 'Некорректный id';
    }

    $cur = crg_admin_ref_get($pdo, $cfg, $id);
    if ($cur === null) {
        return 'Запись не найдена';
    }

    $name = crg_admin_ref_normalize_name((string) ($cur['name'] ?? ''));
    $usage = crg_admin_ref_usage_total($pdo, $cfg, $name);
    if ($usage > 0) {
        return 'Нельзя удалить: используется в ' . $usage . ' записях. Переименуйте или очистите связанные данные.';
    }

    $table = (string) $cfg['table'];

    try {
        $st = $pdo->prepare("DELETE FROM `{$table}` WHERE id = ?");
        $st->execute([$id]);
    } catch (Throwable $e) {
        return 'Не удалось удалить: ' . $e->getMessage();
    }

    return true;
}

function crg_admin_ref_type_from_request(): ?string
{
    $type = trim((string) ($_GET['type'] ?? $_POST['type'] ?? ''));

    return crg_admin_ref_config($type) !== null ? $type : null;
}

/** Минимальный PNG 1×1 для placeholder в БД. */
/**
 * PDO может вернуть LONGBLOB как string или stream — приводим к строке.
 *
 * @param mixed $blob
 */
function crg_admin_ref_blob_to_string($blob): string
{
    if (is_string($blob)) {
        return $blob;
    }
    if (is_resource($blob)) {
        $data = stream_get_contents($blob);

        return is_string($data) ? $data : '';
    }

    return '';
}

function crg_admin_ref_placeholder_png(): string
{
    static $png = null;
    if ($png === null) {
        $decoded = base64_decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
            true
        );
        $png = $decoded !== false ? $decoded : '';
    }

    return $png;
}

function crg_admin_ref_image_mime(string $bytes): string
{
    if (strlen($bytes) >= 3 && strncmp($bytes, "\xFF\xD8\xFF", 3) === 0) {
        return 'image/jpeg';
    }
    if (strlen($bytes) >= 8 && strncmp($bytes, "\x89PNG\r\n\x1a\n", 8) === 0) {
        return 'image/png';
    }
    if (strlen($bytes) >= 6 && (strncmp($bytes, 'GIF87a', 6) === 0 || strncmp($bytes, 'GIF89a', 6) === 0)) {
        return 'image/gif';
    }
    if (strlen($bytes) >= 12 && strncmp($bytes, 'RIFF', 4) === 0 && substr($bytes, 8, 4) === 'WEBP') {
        return 'image/webp';
    }

    return 'application/octet-stream';
}

/**
 * Уменьшает картинку для превью в приложении (GD). Без GD — исходные байты.
 */
function crg_admin_ref_resize_image(string $bytes, int $maxWidth, int $jpegQuality = 82): string
{
    if ($maxWidth < 1 || $bytes === '' || !function_exists('imagecreatefromstring')) {
        return $bytes;
    }

    $src = @imagecreatefromstring($bytes);
    if ($src === false) {
        return $bytes;
    }

    $width = imagesx($src);
    $height = imagesy($src);
    if ($width < 1 || $height < 1) {
        imagedestroy($src);

        return $bytes;
    }
    if ($width <= $maxWidth) {
        imagedestroy($src);

        return $bytes;
    }

    $newHeight = (int) max(1, round($height * ($maxWidth / $width)));
    $dst = imagecreatetruecolor($maxWidth, $newHeight);
    if ($dst === false) {
        imagedestroy($src);

        return $bytes;
    }

    imagealphablending($dst, false);
    imagesavealpha($dst, true);
    $transparent = imagecolorallocatealpha($dst, 0, 0, 0, 127);
    if ($transparent !== false) {
        imagefill($dst, 0, 0, $transparent);
    }
    imagecopyresampled($dst, $src, 0, 0, 0, 0, $maxWidth, $newHeight, $width, $height);
    imagedestroy($src);

    ob_start();
    $mime = crg_admin_ref_image_mime($bytes);
    $ok = false;
    if ($mime === 'image/png' || $mime === 'image/gif' || $mime === 'image/webp') {
        $ok = imagepng($dst, null, 6);
    } else {
        $ok = imagejpeg($dst, null, max(50, min(95, $jpegQuality)));
    }
    imagedestroy($dst);
    $out = ob_get_clean();

    return ($ok && is_string($out) && $out !== '') ? $out : $bytes;
}

function crg_admin_ref_image_app_url(string $table, int $id, int $maxWidth = 480): string
{
    if (!function_exists('crg_site_api_url')) {
        require_once __DIR__ . '/site_config.php';
    }

    $query = http_build_query([
        'bd' => $table,
        'id' => $id,
        'w' => max(0, $maxWidth),
    ]);

    return crg_site_api_url('/ref_image_app.php?' . $query);
}

/**
 * Сжимает загруженную в админке картинку перед сохранением в БД.
 */
function crg_admin_ref_prepare_upload_binary(string $binary, int $maxWidth = 1200): string
{
    return crg_admin_ref_resize_image($binary, $maxWidth, 82);
}

/**
 * @return list<array<string, mixed>>
 */
function crg_admin_ref_image_items(
    PDO $pdo,
    string $tableName,
    int $thumbWidth,
    bool $legacyBase64 = false
): array {
    $sql = "SELECT id, name, image FROM `{$tableName}` WHERE LENGTH(image) > 0 ORDER BY id";
    $stmt = $pdo->query($sql);
    $images = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $id = (int) ($row['id'] ?? 0);
        if ($id <= 0) {
            continue;
        }
        $item = [
            'id' => $id,
            'name' => (string) ($row['name'] ?? ''),
            'image_url' => crg_admin_ref_image_app_url($tableName, $id, $thumbWidth),
        ];
        if ($legacyBase64) {
            $img = crg_admin_ref_blob_to_string($row['image'] ?? '');
            if ($img !== '') {
                $item['image'] = base64_encode($img);
            }
        }
        $images[] = $item;
    }

    return $images;
}

/**
 * @param array<string, mixed> $cfg
 * @return true|string
 */
function crg_admin_ref_validate_upload(array $file)
{
    if (!isset($file['tmp_name']) || !is_uploaded_file((string) $file['tmp_name'])) {
        return 'Файл не загружен';
    }
    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        return 'Ошибка загрузки файла';
    }
    $size = (int) ($file['size'] ?? 0);
    if ($size < 1) {
        return 'Пустой файл';
    }
    if ($size > 3 * 1024 * 1024) {
        return 'Файл слишком большой (макс. 3 МБ)';
    }

    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime = $finfo->file((string) $file['tmp_name']);
    $allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (!is_string($mime) || !in_array($mime, $allowed, true)) {
        return 'Допустимы JPEG, PNG, WebP, GIF';
    }

    return true;
}

/**
 * @param array<string, mixed> $cfg
 * @return true|string
 */
function crg_admin_ref_save_image(PDO $pdo, array $cfg, int $id, string $binary)
{
    if ($id <= 0 || empty($cfg['has_image'])) {
        return 'Некорректный запрос';
    }
    if ($binary === '') {
        return 'Пустой файл';
    }

    $binary = crg_admin_ref_prepare_upload_binary($binary);

    $table = (string) $cfg['table'];
    try {
        $st = $pdo->prepare("UPDATE `{$table}` SET image = ? WHERE id = ?");
        $st->bindValue(1, $binary, PDO::PARAM_LOB);
        $st->bindValue(2, $id, PDO::PARAM_INT);
        $st->execute();
    } catch (Throwable $e) {
        return 'Не удалось сохранить картинку: ' . $e->getMessage();
    }

    return true;
}

/**
 * @param array<string, mixed> $cfg
 */
function crg_admin_ref_clear_image(PDO $pdo, array $cfg, int $id): void
{
    if ($id <= 0 || empty($cfg['has_image'])) {
        return;
    }

    $table = (string) $cfg['table'];
    $st = $pdo->prepare("UPDATE `{$table}` SET image = '' WHERE id = ?");
    $st->execute([$id]);
}

/**
 * @param array<string, mixed> $cfg
 * @return string|null бинарные данные или null
 */
function crg_admin_ref_load_image(PDO $pdo, array $cfg, int $id): ?string
{
    if ($id <= 0 || empty($cfg['has_image'])) {
        return null;
    }

    $table = (string) $cfg['table'];
    $st = $pdo->prepare("SELECT image FROM `{$table}` WHERE id = ? AND LENGTH(image) > 0 LIMIT 1");
    $st->execute([$id]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if ($row === false) {
        return null;
    }
    $img = crg_admin_ref_blob_to_string($row['image'] ?? '');

    return $img !== '' ? $img : null;
}

/** @return list<string> */
function crg_admin_ref_image_tables(): array
{
    return ['vidt', 'vidg', 'gruzchik'];
}

function crg_admin_ref_image_table_config(string $table): ?array
{
    foreach (crg_admin_ref_types() as $cfg) {
        if (($cfg['table'] ?? '') === $table && !empty($cfg['has_image'])) {
            return $cfg;
        }
    }

    return null;
}
