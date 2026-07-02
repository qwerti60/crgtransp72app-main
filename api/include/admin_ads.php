<?php
declare(strict_types=1);

require_once __DIR__ . '/admin_ref_lists.php';

/** @return array<string, array<string, mixed>> */
function crg_admin_performer_ad_types(): array
{
    return [
        'gp' => [
            'label' => 'Грузоперевозки',
            'table' => 'add_ob_gp',
            'nav' => 'performer_gp',
            'summary' => ['city', 'marka', 'maxgruz', 'vidk'],
        ],
        'vidt' => [
            'label' => 'Спецтехника',
            'table' => 'add_ob_vidt',
            'nav' => 'performer_vidt',
            'summary' => ['city', 'vidt'],
        ],
        'gr' => [
            'label' => 'Грузчики',
            'table' => 'add_ob_gr',
            'nav' => 'performer_gr',
            'summary' => ['city'],
        ],
    ];
}

/** @return array<string, array<string, mixed>> */
function crg_admin_customer_ad_types(): array
{
    return [
        'orders' => [
            'label' => 'Грузоперевозки',
            'table' => 'orders',
            'nav' => 'customer_orders',
            'summary' => ['city', 'city1', 'maxgruz', 'vidk'],
        ],
        'orderst' => [
            'label' => 'Спецтехника',
            'table' => 'orderst',
            'nav' => 'customer_orderst',
            'summary' => ['city', 'vidt'],
        ],
        'ordersg' => [
            'label' => 'Грузчики',
            'table' => 'ordersg',
            'nav' => 'customer_ordersg',
            'summary' => ['city'],
        ],
    ];
}

function crg_admin_performer_ad_config(string $type): ?array
{
    $types = crg_admin_performer_ad_types();

    return $types[$type] ?? null;
}

function crg_admin_customer_ad_config(string $type): ?array
{
    $types = crg_admin_customer_ad_types();

    return $types[$type] ?? null;
}

function crg_admin_ad_flag_label(int $flag): string
{
    return $flag === 1 ? 'Опубликовано' : 'На проверке';
}

/** @return list<string> */
function crg_admin_ad_image_columns(): array
{
    return ['img1', 'img2', 'img3', 'img4', 'imgdoc1', 'imgdoc2', 'imgdoc3', 'imgdoc4'];
}

/**
 * @param array<string, mixed> $cfg
 * @return array{rows: list<array<string, mixed>>, total: int}|array{error: string}
 */
function crg_admin_performer_ads_list(
    PDO $pdo,
    array $cfg,
    string $search,
    ?int $flag,
    ?int $userId,
    int $offset,
    int $limit
): array {
    return crg_admin_ads_list_internal($pdo, $cfg, true, $search, $flag, $userId, $offset, $limit);
}

/**
 * @param array<string, mixed> $cfg
 * @return array{rows: list<array<string, mixed>>, total: int}|array{error: string}
 */
function crg_admin_customer_ads_list(
    PDO $pdo,
    array $cfg,
    string $search,
    ?int $userId,
    int $offset,
    int $limit
): array {
    return crg_admin_ads_list_internal($pdo, $cfg, false, $search, null, $userId, $offset, $limit);
}

/**
 * @param array<string, mixed> $cfg
 * @return array{rows: list<array<string, mixed>>, total: int}|array{error: string}
 */
function crg_admin_ads_list_internal(
    PDO $pdo,
    array $cfg,
    bool $hasFlag,
    string $search,
    ?int $flag,
    ?int $userId,
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

    $table = (string) $cfg['table'];
    $summary = (array) ($cfg['summary'] ?? ['city']);
    $cols = array_unique(array_merge(['id', 'iduser', 'city', 'created_at'], $summary));
    if ($hasFlag) {
        $cols[] = 'flag';
    }
    $cols = array_values(array_filter($cols, static fn ($c) => is_string($c) && $c !== ''));

    $where = ['1=1'];
    $params = [];

    $search = trim(preg_replace('/\s+/u', ' ', $search) ?? $search);
    if ($search !== '') {
        $parts = [];
        foreach ($cols as $col) {
            if (in_array($col, ['id', 'created_at'], true)) {
                continue;
            }
            $parts[] = "`{$col}` LIKE ?";
            $params[] = '%' . $search . '%';
        }
        if ($parts !== []) {
            $where[] = '(' . implode(' OR ', $parts) . ')';
        }
    }
    if ($hasFlag && $flag !== null && ($flag === 0 || $flag === 1)) {
        $where[] = 'flag = ?';
        $params[] = $flag;
    }
    if ($userId !== null && $userId > 0) {
        $where[] = 'iduser = ?';
        $params[] = (string) $userId;
    }

    $whereSql = implode(' AND ', $where);
    $selectCols = implode(', ', array_map(static fn ($c) => "`{$c}`", $cols));

    try {
        $cntSt = $pdo->prepare("SELECT COUNT(*) AS c FROM `{$table}` WHERE {$whereSql}");
        $cntSt->execute($params);
        $total = (int) ($cntSt->fetch()['c'] ?? 0);

        $sql = "SELECT {$selectCols} FROM `{$table}` WHERE {$whereSql} ORDER BY id DESC"
            . ' LIMIT ' . (int) $limit . ' OFFSET ' . (int) $offset;
        $st = $pdo->prepare($sql);
        $st->execute($params);

        return ['rows' => $st->fetchAll(), 'total' => $total];
    } catch (Throwable $e) {
        return ['error' => 'Таблица ' . $table . ' недоступна: ' . $e->getMessage()];
    }
}

/**
 * @param array<string, mixed> $cfg
 * @return array<string, mixed>|null
 */
function crg_admin_ad_get(PDO $pdo, array $cfg, int $id): ?array
{
    if ($id <= 0) {
        return null;
    }

    $table = (string) $cfg['table'];
    try {
        $st = $pdo->prepare("SELECT * FROM `{$table}` WHERE id = ? LIMIT 1");
        $st->execute([$id]);
        $row = $st->fetch();

        return $row === false ? null : $row;
    } catch (Throwable $e) {
        return null;
    }
}

/** @return true|string */
function crg_admin_performer_ad_set_flag(PDO $pdo, array $cfg, int $id, int $flag)
{
    if ($id <= 0) {
        return 'Некорректный id';
    }
    $flag = $flag === 1 ? 1 : 0;
    $table = (string) $cfg['table'];

    try {
        $st = $pdo->prepare("UPDATE `{$table}` SET flag = ? WHERE id = ?");
        $st->execute([$flag, $id]);
    } catch (Throwable $e) {
        return 'Ошибка: ' . $e->getMessage();
    }

    return true;
}

/** @return list<string> */
function crg_admin_performer_ad_editable_columns(): array
{
    return [
        'city', 'marka', 'godv', 'maxgruz', 'dkuzov', 'shkuzov', 'vidk', 'vidt',
        'cenahaurs', 'cenasmena', 'cenakm', 'flag',
    ];
}

/** @return list<string> */
function crg_admin_customer_ad_editable_columns(): array
{
    return [
        'city', 'city1', 'maxgruz', 'vidk', 'vidt', 'zagr', 'typepr',
        'startdate', 'enddate', 'enddatez', 'cena', 'about',
    ];
}

/**
 * @param array<string, mixed> $data
 * @return true|string
 */
function crg_admin_ad_update(PDO $pdo, array $cfg, int $id, array $data, bool $performer)
{
    if ($id <= 0) {
        return 'Некорректный id';
    }
    if (crg_admin_ad_get($pdo, $cfg, $id) === null) {
        return 'Объявление не найдено';
    }

    $editable = $performer
        ? crg_admin_performer_ad_editable_columns()
        : crg_admin_customer_ad_editable_columns();

    $table = (string) $cfg['table'];
    $sets = [];
    $values = [];
    foreach ($editable as $col) {
        if (!array_key_exists($col, $data)) {
            continue;
        }
        $val = $data[$col];
        if ($col === 'flag') {
            $val = (int) $val === 1 ? 1 : 0;
        } elseif (in_array($col, ['godv', 'dkuzov', 'shkuzov'], true)) {
            $val = $val === '' || $val === null ? null : (int) $val;
        } elseif (in_array($col, ['startdate', 'enddate', 'enddatez'], true)) {
            $val = trim((string) $val);
            $val = $val === '' ? null : $val;
        } else {
            $val = trim((string) $val);
            if ($val === '' && $col !== 'about') {
                $val = null;
            }
        }
        $sets[] = "`{$col}` = ?";
        $values[] = $val;
    }

    if ($sets === []) {
        return true;
    }

    $values[] = $id;
    $sql = "UPDATE `{$table}` SET " . implode(', ', $sets) . ' WHERE id = ?';

    try {
        $st = $pdo->prepare($sql);
        $st->execute($values);
    } catch (Throwable $e) {
        return 'Не удалось сохранить: ' . $e->getMessage();
    }

    return true;
}

/**
 * @param array<string, mixed> $data
 * @return array{ok: true, id: int}|array{ok: false, error: string}
 */
function crg_admin_ad_insert(PDO $pdo, array $cfg, array $data, bool $performer): array
{
    $table = (string) $cfg['table'];
    $iduser = trim((string) ($data['iduser'] ?? ''));
    if ($iduser === '') {
        return ['ok' => false, 'error' => 'Укажите id пользователя'];
    }

    $editable = $performer
        ? crg_admin_performer_ad_editable_columns()
        : crg_admin_customer_ad_editable_columns();

    $fields = ['iduser'];
    $placeholders = ['?'];
    $values = [$iduser];

    foreach ($editable as $col) {
        if ($col === 'flag' && !$performer) {
            continue;
        }
        if (!array_key_exists($col, $data)) {
            if ($col === 'flag' && $performer) {
                $fields[] = 'flag';
                $placeholders[] = '?';
                $values[] = 0;
            }
            continue;
        }
        $val = $data[$col];
        if ($col === 'flag') {
            $val = (int) $val === 1 ? 1 : 0;
        } elseif (in_array($col, ['godv', 'dkuzov', 'shkuzov'], true)) {
            $val = $val === '' || $val === null ? 0 : (int) $val;
        } else {
            $val = trim((string) $val);
        }
        $fields[] = $col;
        $placeholders[] = '?';
        $values[] = $val;
    }

    if ($performer && !in_array('flag', $fields, true)) {
        $fields[] = 'flag';
        $placeholders[] = '?';
        $values[] = 0;
    }

    $sql = 'INSERT INTO `' . $table . '` (' . implode(', ', array_map(static fn ($f) => "`{$f}`", $fields)) . ')'
        . ' VALUES (' . implode(', ', $placeholders) . ')';

    try {
        $st = $pdo->prepare($sql);
        $st->execute($values);

        return ['ok' => true, 'id' => (int) $pdo->lastInsertId()];
    } catch (Throwable $e) {
        return ['ok' => false, 'error' => 'Не удалось добавить: ' . $e->getMessage()];
    }
}

/** @return true|string */
function crg_admin_ad_delete(PDO $pdo, array $cfg, int $id)
{
    if ($id <= 0) {
        return 'Некорректный id';
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

/**
 * @param array<string, mixed> $row
 */
function crg_admin_ad_summary_text(array $row, array $summaryCols): string
{
    $parts = [];
    foreach ($summaryCols as $col) {
        $v = trim((string) ($row[$col] ?? ''));
        if ($v !== '') {
            $parts[] = $v;
        }
    }

    return $parts !== [] ? implode(' · ', $parts) : '—';
}

function crg_admin_ad_load_image_blob($blob): ?string
{
    $bytes = crg_admin_ref_blob_to_string($blob);

    return $bytes !== '' ? $bytes : null;
}

function crg_admin_ad_image_mime(string $bytes): string
{
    if (strncmp($bytes, '%PDF', 4) === 0) {
        return 'application/pdf';
    }

    return crg_admin_ref_image_mime($bytes);
}

function crg_admin_ad_media_view_type(string $bytes): string
{
    $mime = crg_admin_ad_image_mime($bytes);
    if (str_starts_with($mime, 'image/')) {
        return 'image';
    }
    if ($mime === 'application/pdf' || strncmp($bytes, '%PDF', 4) === 0) {
        return 'pdf';
    }

    return 'file';
}

function crg_admin_ad_image_slot_label(string $slot): string
{
    $map = [
        'img1' => 'Фото 1',
        'img2' => 'Фото 2',
        'img3' => 'Фото 3',
        'img4' => 'Фото 4',
        'imgdoc1' => 'Документ 1',
        'imgdoc2' => 'Документ 2',
        'imgdoc3' => 'Документ 3',
        'imgdoc4' => 'Документ 4',
    ];

    return $map[$slot] ?? $slot;
}

/** @return list<string> */
function crg_admin_ad_customer_image_slots(): array
{
    return ['img1', 'img2', 'img3', 'img4'];
}

/**
 * @param array<string, mixed> $row
 * @param list<string> $slots
 */
function crg_admin_ad_render_media_gallery(string $kind, string $type, int $id, array $row, array $slots): void
{
    $photos = [];
    $docs = [];
    foreach ($slots as $col) {
        $bytes = crg_admin_ad_load_image_blob($row[$col] ?? null);
        if ($bytes === null) {
            continue;
        }
        $url = 'ad_image.php?kind=' . rawurlencode($kind)
            . '&type=' . rawurlencode($type)
            . '&id=' . $id
            . '&slot=' . rawurlencode($col);
        $item = [
            'slot' => $col,
            'label' => crg_admin_ad_image_slot_label($col),
            'url' => $url,
            'view' => crg_admin_ad_media_view_type($bytes),
        ];
        if (str_starts_with($col, 'imgdoc')) {
            $docs[] = $item;
        } else {
            $photos[] = $item;
        }
    }

    if ($photos === [] && $docs === []) {
        echo '<p class="meta">Нет загруженных файлов.</p>';

        return;
    }

    $renderGroup = static function (string $title, array $items): void {
        if ($items === []) {
            return;
        }
        echo '<p class="meta"><strong>' . tp_admin_web_h($title) . '</strong></p>';
        echo '<div class="blob-gallery">';
        foreach ($items as $item) {
            $label = (string) $item['label'];
            $url = (string) $item['url'];
            $view = (string) $item['view'];
            $lightboxType = $view === 'pdf' ? 'pdf' : 'image';
            ?>
            <figure class="blob-gallery-item">
                <figcaption><?= tp_admin_web_h($label) ?></figcaption>
                <button type="button" class="blob-thumb"
                    data-lightbox-src="<?= tp_admin_web_h($url) ?>"
                    data-lightbox-type="<?= tp_admin_web_h($lightboxType) ?>"
                    data-lightbox-label="<?= tp_admin_web_h($label) ?>"
                    title="Открыть для просмотра">
                    <?php if ($view === 'pdf') { ?>
                        <iframe class="blob-thumb-frame" src="<?= tp_admin_web_h($url) ?>#view=FitH" title="<?= tp_admin_web_h($label) ?>" tabindex="-1"></iframe>
                    <?php } else { ?>
                        <img src="<?= tp_admin_web_h($url) ?>" alt="<?= tp_admin_web_h($label) ?>" loading="lazy">
                    <?php } ?>
                </button>
            </figure>
            <?php
        }
        echo '</div>';
    };

    $renderGroup('Фото', $photos);
    if ($photos !== [] && $docs !== []) {
        echo '<hr class="blob-gallery-sep">';
    }
    $renderGroup('Документы', $docs);
}

/** @return list<string> */
function crg_admin_ad_hidden_columns(): array
{
    return [
        'id', 'flag',
        'img1', 'img2', 'img3', 'img4',
        'imgdoc1', 'imgdoc2', 'imgdoc3', 'imgdoc4',
    ];
}

/** @return array<string, string> */
function crg_admin_ad_field_labels(): array
{
    return [
        'iduser' => 'Исполнитель',
        'city' => 'Город',
        'city1' => 'Пункт назначения',
        'marka' => 'Марка',
        'godv' => 'Год выпуска',
        'maxgruz' => 'Грузоподъёмность',
        'dkuzov' => 'Длина кузова',
        'shkuzov' => 'Ширина кузова',
        'vidk' => 'Вид кузова',
        'vidt' => 'Вид техники',
        'cenahaurs' => 'Цена за час',
        'cenasmena' => 'Цена за смену',
        'cenakm' => 'Цена за км',
        'startdate' => 'Дата начала',
        'enddate' => 'Дата окончания',
        'enddatez' => 'Активна до',
        'cena' => 'Цена',
        'about' => 'Описание',
        'zagr' => 'Загрузка',
        'typepr' => 'Тип перевозки',
        'created_at' => 'Дата создания',
    ];
}

function crg_admin_ad_field_label(string $key, string $personLabel = 'Исполнитель'): string
{
    if ($key === 'iduser') {
        return $personLabel;
    }

    return crg_admin_ad_field_labels()[$key] ?? $key;
}

/** @return list<string> */
function crg_admin_ad_fields_order(string $kind, string $type): array
{
    if ($kind === 'performer') {
        return match ($type) {
            'vidt' => ['iduser', 'city', 'vidt', 'cenahaurs', 'cenasmena', 'cenakm', 'created_at'],
            'gr' => ['iduser', 'city', 'cenahaurs', 'cenasmena', 'cenakm', 'created_at'],
            default => ['iduser', 'city', 'marka', 'godv', 'maxgruz', 'dkuzov', 'shkuzov', 'vidk', 'cenahaurs', 'cenasmena', 'cenakm', 'created_at'],
        };
    }

    return match ($type) {
        'orderst' => ['iduser', 'city', 'vidt', 'startdate', 'enddate', 'enddatez', 'cena', 'about', 'created_at'],
        'ordersg' => ['iduser', 'city', 'startdate', 'enddate', 'enddatez', 'cena', 'about', 'created_at'],
        default => ['iduser', 'city', 'city1', 'maxgruz', 'vidk', 'zagr', 'typepr', 'startdate', 'enddate', 'enddatez', 'cena', 'about', 'created_at'],
    };
}

function crg_admin_ad_format_value(string $key, mixed $value): string
{
    if ($value === null || $value === '') {
        return '';
    }
    if (in_array($key, ['godv', 'dkuzov', 'shkuzov'], true) && is_numeric($value) && (int) $value === 0) {
        return '';
    }
    if ($key === 'startdate' || $key === 'enddate' || $key === 'enddatez') {
        $s = trim((string) $value);

        return ($s === '' || $s === '0000-00-00') ? '' : $s;
    }

    return is_scalar($value) ? trim((string) $value) : '';
}

/**
 * @param array<string, mixed> $row
 */
function crg_admin_ad_render_details_table(PDO $pdo, array $row, string $kind, string $type, string $personLabel): void
{
    tp_admin_web_require_include('admin_users.php');

    $uid = (int) ($row['iduser'] ?? 0);
    $userName = '';
    if ($uid > 0) {
        $u = crg_admin_user_get($pdo, $uid);
        if ($u !== null) {
            $userName = crg_admin_user_display_name($u);
        }
    }

    echo '<table class="data"><tbody>';
    foreach (crg_admin_ad_fields_order($kind, $type) as $key) {
        if (in_array($key, crg_admin_ad_hidden_columns(), true)) {
            continue;
        }

        if ($key === 'iduser') {
            if ($userName === '') {
                continue;
            }
            $display = $userName;
        } else {
            $display = crg_admin_ad_format_value($key, $row[$key] ?? null);
            if ($display === '') {
                continue;
            }
        }

        echo '<tr><th style="width:30%">' . tp_admin_web_h(crg_admin_ad_field_label($key, $personLabel)) . '</th><td>';
        if ($key === 'iduser' && $uid > 0) {
            echo '<a href="user_edit.php?id=' . $uid . '">' . tp_admin_web_h($display) . '</a>';
        } else {
            echo tp_admin_web_h($display);
        }
        echo '</td></tr>';
    }
    echo '</tbody></table>';
}

function crg_admin_performer_type_from_request(): ?string
{
    $type = trim((string) ($_GET['type'] ?? $_POST['type'] ?? ''));

    return crg_admin_performer_ad_config($type) !== null ? $type : null;
}

function crg_admin_customer_type_from_request(): ?string
{
    $type = trim((string) ($_GET['type'] ?? $_POST['type'] ?? ''));

    return crg_admin_customer_ad_config($type) !== null ? $type : null;
}

/**
 * @param array<string, mixed> $cfg
 */
function crg_admin_ad_pending_count(PDO $pdo, array $cfg): int
{
    $table = (string) $cfg['table'];
    try {
        $st = $pdo->query("SELECT COUNT(*) AS c FROM `{$table}` WHERE flag = 0");

        return (int) ($st->fetch()['c'] ?? 0);
    } catch (Throwable $e) {
        return 0;
    }
}

function crg_admin_performer_ads_pending_total(PDO $pdo): int
{
    $sum = 0;
    foreach (crg_admin_performer_ad_types() as $cfg) {
        $sum += crg_admin_ad_pending_count($pdo, $cfg);
    }

    return $sum;
}

function crg_admin_bd_for_performer_type(string $type): int
{
    return match ($type) {
        'gp' => 1,
        'vidt' => 2,
        'gr' => 3,
        default => 0,
    };
}

function crg_admin_bd_for_customer_type(string $type): int
{
    return match ($type) {
        'orders' => 1,
        'orderst' => 2,
        'ordersg' => 3,
        default => 0,
    };
}

function crg_admin_offer_status_label(int $status): string
{
    return $status === 1 ? 'Принят' : 'Активный';
}

/**
 * Отклики исполнителей на заявку заказчика (offer_data).
 *
 * @return list<array<string, mixed>>
 */
function crg_admin_customer_ad_offers(PDO $pdo, int $adId, int $bd): array
{
    if ($adId <= 0) {
        return [];
    }

    try {
        $sql = 'SELECT od.cena, od.about, od.status, od.timestamp, od.iduserp,
                       u.firstName, u.lastName, u.middleName, u.namefirm, u.phone
                FROM offer_data od
                LEFT JOIN users u ON u.idusers = od.iduserp
                WHERE od.iduser = ?';
        $params = [$adId];
        if ($bd > 0) {
            $sql .= ' AND od.bd = ?';
            $params[] = $bd;
        }
        $sql .= ' ORDER BY od.timestamp DESC';
        $st = $pdo->prepare($sql);
        $st->execute($params);

        return $st->fetchAll();
    } catch (Throwable $e) {
        return [];
    }
}

/**
 * Предложения заказчиков на объявление исполнителя (offer_dataf).
 *
 * @return list<array<string, mixed>>
 */
function crg_admin_performer_ad_proposals(PDO $pdo, int $adId, int $bd): array
{
    if ($adId <= 0) {
        return [];
    }

    try {
        $sql = 'SELECT od.cena, od.about, od.ds, od.iduserp,
                       u.firstName, u.lastName, u.middleName, u.namefirm, u.phone
                FROM offer_dataf od
                LEFT JOIN users u ON u.idusers = od.iduserp
                WHERE od.iduser = ?';
        $params = [$adId];
        if ($bd > 0) {
            $sql .= ' AND od.bd = ?';
            $params[] = $bd;
        }
        $sql .= ' ORDER BY od.ds DESC';
        $st = $pdo->prepare($sql);
        $st->execute($params);

        return $st->fetchAll();
    } catch (Throwable $e) {
        return [];
    }
}

/**
 * @param list<array<string, mixed>> $rows
 */
function crg_admin_render_offer_rows_table(array $rows, string $personLabel, bool $withStatus): void
{
    tp_admin_web_require_include('admin_users.php');

    if ($rows === []) {
        echo '<p class="meta">Нет записей.</p>';

        return;
    }

    echo '<table class="data"><thead><tr>';
    echo '<th>' . tp_admin_web_h($personLabel) . '</th>';
    echo '<th>Цена</th><th>Описание</th>';
    if ($withStatus) {
        echo '<th>Статус</th>';
    }
    echo '<th>Дата</th></tr></thead><tbody>';

    foreach ($rows as $r) {
        $uid = (int) ($r['iduserp'] ?? 0);
        $name = crg_admin_user_display_name($r);
        $date = (string) ($r['timestamp'] ?? $r['ds'] ?? '');
        echo '<tr>';
        echo '<td>';
        if ($uid > 0) {
            echo '<a href="user_edit.php?id=' . $uid . '">' . tp_admin_web_h($name) . '</a>';
            if (!empty($r['phone'])) {
                echo '<div class="meta">' . tp_admin_web_h((string) $r['phone']) . '</div>';
            }
        } else {
            echo tp_admin_web_h($name);
        }
        echo '</td>';
        echo '<td class="num">' . tp_admin_web_h((string) ($r['cena'] ?? '')) . '</td>';
        echo '<td>' . tp_admin_web_h((string) ($r['about'] ?? '')) . '</td>';
        if ($withStatus) {
            $st = (int) ($r['status'] ?? 0);
            $cls = $st === 1 ? 'badge-ok' : 'badge-pending';
            echo '<td><span class="badge ' . $cls . '">' . tp_admin_web_h(crg_admin_offer_status_label($st)) . '</span></td>';
        }
        echo '<td class="meta">' . tp_admin_web_h($date) . '</td>';
        echo '</tr>';
    }

    echo '</tbody></table>';
}
