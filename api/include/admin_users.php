<?php
declare(strict_types=1);

/** @return array<int, string> */
function crg_admin_user_roll_labels(): array
{
    return [
        1 => 'Заказчик',
        2 => 'Грузоперевозчик',
        3 => 'Спецтехника',
        4 => 'Грузчики',
    ];
}

/** @return array<int, string> */
function crg_admin_user_stat_labels(): array
{
    return [
        1 => 'Юр. лицо',
        2 => 'Физ. лицо',
    ];
}

function crg_admin_user_roll_label(int $rollNum): string
{
    return crg_admin_user_roll_labels()[$rollNum] ?? ('Роль ' . $rollNum);
}

function crg_admin_user_stat_label(int $statNum): string
{
    return crg_admin_user_stat_labels()[$statNum] ?? ('Статус ' . $statNum);
}

function crg_admin_user_flag_label(int $flag): string
{
    return $flag === 1 ? 'Одобрен' : 'На проверке';
}

function crg_admin_user_is_performer(int $rollNum): bool
{
    return in_array($rollNum, [2, 3, 4], true);
}

function crg_admin_user_is_customer(int $rollNum): bool
{
    return $rollNum === 1;
}

function crg_admin_user_display_name(array $row): string
{
    $parts = array_filter([
        trim((string) ($row['lastName'] ?? '')),
        trim((string) ($row['firstName'] ?? '')),
        trim((string) ($row['middleName'] ?? '')),
    ]);

    if ($parts !== []) {
        return implode(' ', $parts);
    }

    $firm = trim((string) ($row['namefirm'] ?? ''));

    return $firm !== '' ? $firm : ('#' . (int) ($row['idusers'] ?? 0));
}

/**
 * @param list<int|string> $ids
 * @return array<int, array<string, mixed>>
 */
function crg_admin_users_map_by_ids(PDO $pdo, array $ids): array
{
    $clean = [];
    foreach ($ids as $id) {
        $id = (int) $id;
        if ($id > 0) {
            $clean[$id] = $id;
        }
    }
    if ($clean === []) {
        return [];
    }

    $placeholders = implode(',', array_fill(0, count($clean), '?'));
    try {
        $st = $pdo->prepare(
            'SELECT idusers, firstName, lastName, middleName, namefirm FROM users WHERE idusers IN ('
            . $placeholders . ')'
        );
        $st->execute(array_values($clean));
        $map = [];
        foreach ($st->fetchAll() as $row) {
            $map[(int) ($row['idusers'] ?? 0)] = $row;
        }

        return $map;
    } catch (Throwable $e) {
        return [];
    }
}

/** @return list<string> */
function crg_admin_user_editable_columns(): array
{
    return [
        'rollNum', 'statNum', 'firstName', 'lastName', 'middleName', 'city', 'phone', 'email',
        'namefirm', 'innStr', 'ogrnStr', 'kppStr', 'vidt', 'marka', 'godv', 'maxgruz',
        'dkuzov', 'shkuzov', 'vidk',         'cenahaurs', 'cenasmena', 'cenakm', 'flag', 'is_verified',
    ];
}

/**
 * @return array{rows: list<array<string, mixed>>, total: int}|array{error: string}
 */
function crg_admin_users_list(
    PDO $pdo,
    string $search,
    ?int $rollNum,
    ?int $flag,
    int $offset,
    int $limit
): array {
    if ($limit < 1) {
        $limit = 50;
    }
    if ($limit > 200) {
        $limit = 200;
    }
    if ($offset < 0) {
        $offset = 0;
    }

    $where = ['1=1'];
    $params = [];

    $search = trim(preg_replace('/\s+/u', ' ', $search) ?? $search);
    if ($search !== '') {
        $where[] = '(email LIKE ? OR phone LIKE ? OR firstName LIKE ? OR lastName LIKE ? OR namefirm LIKE ? OR city LIKE ?)';
        $like = '%' . $search . '%';
        array_push($params, $like, $like, $like, $like, $like, $like);
    }
    if ($rollNum !== null && $rollNum > 0) {
        $where[] = 'rollNum = ?';
        $params[] = $rollNum;
    }
    if ($flag !== null && ($flag === 0 || $flag === 1)) {
        $where[] = 'flag = ?';
        $params[] = $flag;
    }

    $whereSql = implode(' AND ', $where);

    try {
        $cntSt = $pdo->prepare('SELECT COUNT(*) AS c FROM users WHERE ' . $whereSql);
        $cntSt->execute($params);
        $total = (int) ($cntSt->fetch()['c'] ?? 0);

        $sql = 'SELECT idusers, rollNum, statNum, firstName, lastName, middleName, city, phone, email,'
            . ' namefirm, flag, created_at'
            . ' FROM users WHERE ' . $whereSql
            . ' ORDER BY idusers DESC LIMIT ' . (int) $limit . ' OFFSET ' . (int) $offset;
        $st = $pdo->prepare($sql);
        $st->execute($params);

        return ['rows' => $st->fetchAll(), 'total' => $total];
    } catch (Throwable $e) {
        return ['error' => 'Таблица users недоступна: ' . $e->getMessage()];
    }
}

/** @return array<string, mixed>|null */
function crg_admin_user_get(PDO $pdo, int $id): ?array
{
    if ($id <= 0) {
        return null;
    }

    try {
        $st = $pdo->prepare('SELECT * FROM users WHERE idusers = ? LIMIT 1');
        $st->execute([$id]);
        $row = $st->fetch();

        return $row === false ? null : $row;
    } catch (Throwable $e) {
        return null;
    }
}

/** @return array<string, int> */
function crg_admin_user_ad_counts(PDO $pdo, int $userId): array
{
    $out = [];
    $tables = [
        'add_ob_gp' => 'Исп. грузоперевозки',
        'add_ob_vidt' => 'Исп. спецтехника',
        'add_ob_gr' => 'Исп. грузчики',
        'orders' => 'Зак. грузоперевозки',
        'orderst' => 'Зак. спецтехника',
        'ordersg' => 'Зак. грузчики',
    ];
    foreach ($tables as $table => $label) {
        try {
            $st = $pdo->prepare("SELECT COUNT(*) AS c FROM `{$table}` WHERE iduser = ?");
            $st->execute([(string) $userId]);
            $cnt = (int) ($st->fetch()['c'] ?? 0);
            if ($cnt > 0) {
                $out[$label] = $cnt;
            }
        } catch (Throwable $e) {
            // таблица может отсутствовать локально
        }
    }

    return $out;
}

/**
 * @param array<string, mixed> $data
 * @return true|string
 */
function crg_admin_user_validate(array $data, bool $isNew)
{
    $email = trim((string) ($data['email'] ?? ''));
    if ($email === '') {
        return 'E-mail обязателен';
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        return 'Некорректный e-mail';
    }

    $rollNum = (int) ($data['rollNum'] ?? 0);
    if (!isset(crg_admin_user_roll_labels()[$rollNum])) {
        return 'Выберите роль';
    }

    $statNum = (int) ($data['statNum'] ?? 0);
    if (!isset(crg_admin_user_stat_labels()[$statNum])) {
        return 'Выберите тип (юр./физ. лицо)';
    }

    if ($isNew) {
        $password = (string) ($data['password'] ?? '');
        if (strlen($password) < 6) {
            return 'Пароль не менее 6 символов';
        }
    } else {
        $password = (string) ($data['password'] ?? '');
        if ($password !== '' && strlen($password) < 6) {
            return 'Пароль не менее 6 символов';
        }
    }

    return true;
}

/**
 * @param array<string, mixed> $data
 * @return array{ok: true, id: int}|array{ok: false, error: string}
 */
function crg_admin_user_insert(PDO $pdo, array $data): array
{
    $valid = crg_admin_user_validate($data, true);
    if ($valid !== true) {
        return ['ok' => false, 'error' => $valid];
    }

    $email = trim((string) $data['email']);
    try {
        $st = $pdo->prepare('SELECT 1 FROM users WHERE email = ? LIMIT 1');
        $st->execute([$email]);
        if ($st->fetch() !== false) {
            return ['ok' => false, 'error' => 'Пользователь с таким e-mail уже есть'];
        }
    } catch (Throwable $e) {
        return ['ok' => false, 'error' => $e->getMessage()];
    }

    $cols = crg_admin_user_editable_columns();
    $fields = [];
    $placeholders = [];
    $values = [];
    $hasFlag = false;
    foreach ($cols as $col) {
        if (!array_key_exists($col, $data)) {
            continue;
        }
        $val = $data[$col];
        if ($col === 'flag' || $col === 'is_verified') {
            $hasFlag = $col === 'flag' ? true : $hasFlag;
            $val = (int) $val === 1 ? 1 : 0;
        } elseif (in_array($col, ['rollNum', 'statNum', 'godv', 'dkuzov', 'shkuzov'], true)) {
            $val = $val === '' || $val === null ? null : (int) $val;
        } elseif (in_array($col, ['cenahaurs', 'cenasmena', 'cenakm'], true)) {
            $val = $val === '' || $val === null ? null : (float) str_replace(',', '.', (string) $val);
        } else {
            $val = trim((string) $val);
            if ($val === '') {
                $val = null;
            }
        }
        $fields[] = "`{$col}`";
        $placeholders[] = '?';
        $values[] = $val;
    }

    $password = password_hash((string) $data['password'], PASSWORD_DEFAULT);
    $fields[] = 'password';
    $fields[] = 'fotouser';
    $placeholders[] = '?';
    $placeholders[] = '?';
    $values[] = $password;
    $values[] = '';

    if (!$hasFlag) {
        $fields[] = '`flag`';
        $placeholders[] = '?';
        $values[] = 1;
    }

    $sql = 'INSERT INTO users (' . implode(', ', $fields) . ') VALUES (' . implode(', ', $placeholders) . ')';

    try {
        $st = $pdo->prepare($sql);
        $st->execute($values);

        return ['ok' => true, 'id' => (int) $pdo->lastInsertId()];
    } catch (Throwable $e) {
        return ['ok' => false, 'error' => 'Не удалось добавить: ' . $e->getMessage()];
    }
}

/**
 * @param array<string, mixed> $data
 * @return true|string
 */
function crg_admin_user_update(PDO $pdo, int $id, array $data)
{
    if ($id <= 0) {
        return 'Некорректный id';
    }
    if (crg_admin_user_get($pdo, $id) === null) {
        return 'Пользователь не найден';
    }

    $valid = crg_admin_user_validate($data, false);
    if ($valid !== true) {
        return $valid;
    }

    $email = trim((string) $data['email']);
    try {
        $st = $pdo->prepare('SELECT 1 FROM users WHERE email = ? AND idusers != ? LIMIT 1');
        $st->execute([$email, $id]);
        if ($st->fetch() !== false) {
            return 'E-mail уже занят другим пользователем';
        }
    } catch (Throwable $e) {
        return $e->getMessage();
    }

    $sets = [];
    $values = [];
    foreach (crg_admin_user_editable_columns() as $col) {
        if (!array_key_exists($col, $data)) {
            continue;
        }
        $val = $data[$col];
        if ($col === 'flag' || $col === 'is_verified') {
            $val = (int) $val === 1 ? 1 : 0;
        } elseif (in_array($col, ['rollNum', 'statNum', 'godv', 'dkuzov', 'shkuzov'], true)) {
            $val = $val === '' || $val === null ? null : (int) $val;
        } elseif (in_array($col, ['cenahaurs', 'cenasmena', 'cenakm'], true)) {
            $val = $val === '' || $val === null ? null : (float) str_replace(',', '.', (string) $val);
        } else {
            $val = trim((string) $val);
            if ($val === '') {
                $val = null;
            }
        }
        $sets[] = "`{$col}` = ?";
        $values[] = $val;
    }

    $password = trim((string) ($data['password'] ?? ''));
    if ($password !== '') {
        $sets[] = 'password = ?';
        $values[] = password_hash($password, PASSWORD_DEFAULT);
    }

    if ($sets === []) {
        return true;
    }

    $values[] = $id;
    $sql = 'UPDATE users SET ' . implode(', ', $sets) . ' WHERE idusers = ?';

    try {
        $st = $pdo->prepare($sql);
        $st->execute($values);
    } catch (Throwable $e) {
        return 'Не удалось сохранить: ' . $e->getMessage();
    }

    return true;
}

/** @return true|string */
function crg_admin_user_set_flag(PDO $pdo, int $id, int $flag)
{
    if ($id <= 0) {
        return 'Некорректный id';
    }
    $flag = $flag === 1 ? 1 : 0;

    try {
        $st = $pdo->prepare('UPDATE users SET flag = ? WHERE idusers = ?');
        $st->execute([$flag, $id]);
    } catch (Throwable $e) {
        return 'Ошибка: ' . $e->getMessage();
    }

    return true;
}

/** @return true|string */
function crg_admin_user_delete(PDO $pdo, int $id)
{
    if ($id <= 0) {
        return 'Некорректный id';
    }
    if (crg_admin_user_get($pdo, $id) === null) {
        return 'Пользователь не найден';
    }

    try {
        $pdo->beginTransaction();
        foreach (['add_ob_gp', 'add_ob_vidt', 'add_ob_gr', 'orders', 'orderst', 'ordersg'] as $table) {
            try {
                $st = $pdo->prepare("DELETE FROM `{$table}` WHERE iduser = ?");
                $st->execute([(string) $id]);
            } catch (Throwable $e) {
                // skip missing tables
            }
        }
        $st = $pdo->prepare('DELETE FROM users WHERE idusers = ?');
        $st->execute([$id]);
        $pdo->commit();
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        return 'Не удалось удалить: ' . $e->getMessage();
    }

    return true;
}

function crg_admin_users_pending_count(PDO $pdo): int
{
    try {
        $st = $pdo->query('SELECT COUNT(*) AS c FROM users WHERE flag = 0 AND rollNum IN (2, 3)');

        return (int) ($st->fetch()['c'] ?? 0);
    } catch (Throwable $e) {
        return 0;
    }
}
