<?php
declare(strict_types=1);

/**
 * CRUD для справочника cities (веб-админка crgtransp72).
 */

/** @return list<array{table: string, column: string}> */
function crg_admin_city_ref_columns(): array
{
    return [
        ['table' => 'users', 'column' => 'city'],
        ['table' => 'orders', 'column' => 'city'],
        ['table' => 'orders', 'column' => 'city1'],
        ['table' => 'ordersg', 'column' => 'city'],
        ['table' => 'add_ob_gp', 'column' => 'city'],
        ['table' => 'add_ob_gr', 'column' => 'city'],
        ['table' => 'add_ob_vidt', 'column' => 'city'],
        ['table' => 'gruz_info', 'column' => 'city'],
        ['table' => 'gruz_info', 'column' => 'city1'],
    ];
}

function crg_admin_city_normalize_name(string $name): string
{
    return trim(preg_replace('/\s+/u', ' ', $name) ?? $name);
}

function crg_admin_cities_has_geo(PDO $pdo): bool
{
    static $cached = null;
    if ($cached !== null) {
        return $cached;
    }
    try {
        $pdo->query('SELECT lat, lng FROM cities LIMIT 1');
        $cached = true;
    } catch (Throwable $e) {
        $cached = false;
    }

    return $cached;
}

/**
 * @return true|string
 */
function crg_admin_city_validate_coords(?string $latRaw, ?string $lngRaw)
{
    $latTrim = trim((string) ($latRaw ?? ''));
    $lngTrim = trim((string) ($lngRaw ?? ''));
    if ($latTrim === '' && $lngTrim === '') {
        return true;
    }
    if ($latTrim === '' || $lngTrim === '') {
        return 'Укажите и широту, и долготу, либо очистите оба поля';
    }
    if (!is_numeric($latTrim) || !is_numeric($lngTrim)) {
        return 'Координаты должны быть числами';
    }
    $lat = (float) $latTrim;
    $lng = (float) $lngTrim;
    if ($lat < -90.0 || $lat > 90.0) {
        return 'Широта должна быть от -90 до 90';
    }
    if ($lng < -180.0 || $lng > 180.0) {
        return 'Долгота должна быть от -180 до 180';
    }

    return true;
}

/**
 * @return array{0: ?float, 1: ?float}|string
 */
function crg_admin_city_parse_coords(?string $latRaw, ?string $lngRaw)
{
    $valid = crg_admin_city_validate_coords($latRaw, $lngRaw);
    if ($valid !== true) {
        return $valid;
    }
    $latTrim = trim((string) ($latRaw ?? ''));
    $lngTrim = trim((string) ($lngRaw ?? ''));
    if ($latTrim === '' && $lngTrim === '') {
        return [null, null];
    }

    return [round((float) $latTrim, 6), round((float) $lngTrim, 6)];
}

/**
 * @return array{rows: list<array<string, mixed>>, total: int}|array{error: string}
 */
function crg_admin_cities_list(PDO $pdo, string $search, int $offset, int $limit): array
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

    $search = crg_admin_city_normalize_name($search);
    $where = '1=1';
    $params = [];
    if ($search !== '') {
        $where .= ' AND name LIKE ?';
        $params[] = '%' . $search . '%';
    }

    $hasGeo = crg_admin_cities_has_geo($pdo);
    $select = $hasGeo ? 'id, name, lat, lng' : 'id, name';

    try {
        $cntSt = $pdo->prepare('SELECT COUNT(*) AS c FROM cities WHERE ' . $where);
        $cntSt->execute($params);
        $total = (int) ($cntSt->fetch()['c'] ?? 0);

        $sql = 'SELECT ' . $select . ' FROM cities WHERE ' . $where
            . ' ORDER BY name COLLATE utf8mb4_unicode_ci LIMIT '
            . (int) $limit . ' OFFSET ' . (int) $offset;
        $st = $pdo->prepare($sql);
        $st->execute($params);
        $rows = $st->fetchAll();
    } catch (Throwable $e) {
        return ['error' => 'Таблица cities недоступна: ' . $e->getMessage()];
    }

    return ['rows' => $rows, 'total' => $total];
}

/**
 * @return array<string, mixed>|null
 */
function crg_admin_city_get(PDO $pdo, int $id): ?array
{
    if ($id <= 0) {
        return null;
    }

    $select = crg_admin_cities_has_geo($pdo) ? 'id, name, lat, lng' : 'id, name';
    $st = $pdo->prepare('SELECT ' . $select . ' FROM cities WHERE id = ? LIMIT 1');
    $st->execute([$id]);
    $row = $st->fetch();

    return $row === false ? null : $row;
}

function crg_admin_city_name_exists(PDO $pdo, string $name, int $excludeId = 0): bool
{
    $sql = 'SELECT 1 FROM cities WHERE name = ?';
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
 * @return array<string, int>
 */
function crg_admin_city_usage_breakdown(PDO $pdo, string $name): array
{
    $name = crg_admin_city_normalize_name($name);
    if ($name === '') {
        return [];
    }

    $out = [];
    foreach (crg_admin_city_ref_columns() as $ref) {
        $table = $ref['table'];
        $column = $ref['column'];
        $key = $table . '.' . $column;
        try {
            $st = $pdo->prepare("SELECT COUNT(*) AS c FROM `{$table}` WHERE `{$column}` = ?");
            $st->execute([$name]);
            $cnt = (int) ($st->fetch()['c'] ?? 0);
            if ($cnt > 0) {
                $out[$key] = $cnt;
            }
        } catch (Throwable $e) {
            // Таблица может отсутствовать на старой схеме — пропускаем.
        }
    }

    return $out;
}

function crg_admin_city_usage_total(PDO $pdo, string $name): int
{
    $sum = 0;
    foreach (crg_admin_city_usage_breakdown($pdo, $name) as $cnt) {
        $sum += $cnt;
    }

    return $sum;
}

/**
 * @return true|string
 */
function crg_admin_city_validate_name(string $name)
{
    $name = crg_admin_city_normalize_name($name);
    if ($name === '') {
        return 'Название не может быть пустым';
    }
    if (mb_strlen($name) > 255) {
        return 'Название слишком длинное (макс. 255 символов)';
    }

    return true;
}

/**
 * @return array{ok: true, id: int}|array{ok: false, error: string}
 */
function crg_admin_city_insert(PDO $pdo, string $name, ?string $latRaw = null, ?string $lngRaw = null): array
{
    $valid = crg_admin_city_validate_name($name);
    if ($valid !== true) {
        return ['ok' => false, 'error' => $valid];
    }
    $name = crg_admin_city_normalize_name($name);
    if (crg_admin_city_name_exists($pdo, $name)) {
        return ['ok' => false, 'error' => 'Город с таким названием уже есть'];
    }

    $coords = [null, null];
    $hasGeo = crg_admin_cities_has_geo($pdo);
    if ($hasGeo) {
        $coords = crg_admin_city_parse_coords($latRaw, $lngRaw);
        if (is_string($coords)) {
            return ['ok' => false, 'error' => $coords];
        }
    }

    try {
        if ($hasGeo) {
            $st = $pdo->prepare('INSERT INTO cities (name, lat, lng) VALUES (?, ?, ?)');
            $st->execute([$name, $coords[0], $coords[1]]);
        } else {
            $st = $pdo->prepare('INSERT INTO cities (name) VALUES (?)');
            $st->execute([$name]);
        }

        return ['ok' => true, 'id' => (int) $pdo->lastInsertId()];
    } catch (Throwable $e) {
        return ['ok' => false, 'error' => 'Не удалось добавить: ' . $e->getMessage()];
    }
}

/**
 * @return true|string
 */
function crg_admin_city_rename_references(PDO $pdo, string $oldName, string $newName)
{
    $oldName = crg_admin_city_normalize_name($oldName);
    $newName = crg_admin_city_normalize_name($newName);
    if ($oldName === '' || $newName === '' || $oldName === $newName) {
        return true;
    }

    try {
        $pdo->beginTransaction();
        foreach (crg_admin_city_ref_columns() as $ref) {
            $table = $ref['table'];
            $column = $ref['column'];
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
 * @return true|string
 */
function crg_admin_city_update(
    PDO $pdo,
    int $id,
    string $name,
    bool $renameReferences,
    ?string $latRaw = null,
    ?string $lngRaw = null
) {
    if ($id <= 0) {
        return 'Некорректный id';
    }

    $cur = crg_admin_city_get($pdo, $id);
    if ($cur === null) {
        return 'Город не найден';
    }

    $valid = crg_admin_city_validate_name($name);
    if ($valid !== true) {
        return $valid;
    }

    $name = crg_admin_city_normalize_name($name);
    $oldName = crg_admin_city_normalize_name((string) ($cur['name'] ?? ''));
    if (crg_admin_city_name_exists($pdo, $name, $id)) {
        return 'Город с таким названием уже есть';
    }

    $hasGeo = crg_admin_cities_has_geo($pdo);
    $coords = [null, null];
    if ($hasGeo) {
        $coords = crg_admin_city_parse_coords($latRaw, $lngRaw);
        if (is_string($coords)) {
            return $coords;
        }
    }

    if ($renameReferences && $oldName !== '' && $oldName !== $name) {
        $ren = crg_admin_city_rename_references($pdo, $oldName, $name);
        if ($ren !== true) {
            return $ren;
        }
    }

    try {
        if ($hasGeo) {
            $st = $pdo->prepare('UPDATE cities SET name = ?, lat = ?, lng = ? WHERE id = ?');
            $st->execute([$name, $coords[0], $coords[1], $id]);
        } else {
            $st = $pdo->prepare('UPDATE cities SET name = ? WHERE id = ?');
            $st->execute([$name, $id]);
        }
    } catch (Throwable $e) {
        return 'Не удалось сохранить: ' . $e->getMessage();
    }

    return true;
}

/**
 * @return true|string
 */
function crg_admin_city_delete(PDO $pdo, int $id)
{
    if ($id <= 0) {
        return 'Некорректный id';
    }

    $cur = crg_admin_city_get($pdo, $id);
    if ($cur === null) {
        return 'Город не найден';
    }

    $name = crg_admin_city_normalize_name((string) ($cur['name'] ?? ''));
    $usage = crg_admin_city_usage_total($pdo, $name);
    if ($usage > 0) {
        return 'Нельзя удалить: город используется в ' . $usage . ' записях (пользователи, объявления). Переименуйте или удалите связанные данные.';
    }

    try {
        $st = $pdo->prepare('DELETE FROM cities WHERE id = ?');
        $st->execute([$id]);
    } catch (Throwable $e) {
        return 'Не удалось удалить: ' . $e->getMessage();
    }

    return true;
}
