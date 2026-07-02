<?php
declare(strict_types=1);

/**
 * Отзывы об исполнителях — таблица reviewsisp (как в review_apiz.php / get_ads2_new.php).
 * user_id = исполнитель, target_user_id = автор отзыва (заказчик).
 *
 * Отзывы о заказчиках — таблица reviews (как в review_api.php / save_review.php).
 * user_id = автор отзыва (исполнитель), target_user_id = заказчик.
 */

function crg_admin_reviews_table_exists(PDO $pdo, string $table): bool
{
    static $cache = [];
    if (isset($cache[$table])) {
        return $cache[$table];
    }
    try {
        $st = $pdo->query("SELECT 1 FROM `{$table}` LIMIT 1");
        $st->fetch();

        return $cache[$table] = true;
    } catch (Throwable $e) {
        return $cache[$table] = false;
    }
}

/** @return array{avg: float, count: int} */
function crg_admin_performer_review_summary(PDO $pdo, int $performerId): array
{
    if ($performerId <= 0 || !crg_admin_reviews_table_exists($pdo, 'reviewsisp')) {
        return ['avg' => 0.0, 'count' => 0];
    }

    try {
        $st = $pdo->prepare(
            'SELECT COALESCE(AVG(rating), 0) AS avg_rating, COUNT(*) AS cnt
             FROM reviewsisp WHERE user_id = ?'
        );
        $st->execute([$performerId]);
        $row = $st->fetch();

        return [
            'avg' => round((float) ($row['avg_rating'] ?? 0), 1),
            'count' => (int) ($row['cnt'] ?? 0),
        ];
    } catch (Throwable $e) {
        return ['avg' => 0.0, 'count' => 0];
    }
}

/** @return array{avg: float, count: int} */
function crg_admin_customer_review_summary(PDO $pdo, int $customerId): array
{
    if ($customerId <= 0 || !crg_admin_reviews_table_exists($pdo, 'reviews')) {
        return ['avg' => 0.0, 'count' => 0];
    }

    try {
        $st = $pdo->prepare(
            'SELECT COALESCE(AVG(rating), 0) AS avg_rating, COUNT(*) AS cnt
             FROM reviews WHERE target_user_id = ?'
        );
        $st->execute([$customerId]);
        $row = $st->fetch();

        return [
            'avg' => round((float) ($row['avg_rating'] ?? 0), 1),
            'count' => (int) ($row['cnt'] ?? 0),
        ];
    } catch (Throwable $e) {
        return ['avg' => 0.0, 'count' => 0];
    }
}

/**
 * @return list<array<string, mixed>>
 */
function crg_admin_reviews_about_performer(PDO $pdo, int $performerId): array
{
    if ($performerId <= 0 || !crg_admin_reviews_table_exists($pdo, 'reviewsisp')) {
        return [];
    }

    try {
        $st = $pdo->prepare(
            'SELECT r.rating, r.comment, r.datastamp,
                    u.idusers AS author_id, u.firstName, u.lastName, u.middleName, u.namefirm, u.phone
             FROM reviewsisp r
             LEFT JOIN users u ON u.idusers = r.target_user_id
             WHERE r.user_id = ?
             ORDER BY r.datastamp DESC'
        );
        $st->execute([$performerId]);

        return $st->fetchAll();
    } catch (Throwable $e) {
        return [];
    }
}

/**
 * @return list<array<string, mixed>>
 */
function crg_admin_reviews_about_customer(PDO $pdo, int $customerId): array
{
    if ($customerId <= 0 || !crg_admin_reviews_table_exists($pdo, 'reviews')) {
        return [];
    }

    try {
        $st = $pdo->prepare(
            'SELECT r.rating, r.comment, r.datastamp,
                    u.idusers AS author_id, u.firstName, u.lastName, u.middleName, u.namefirm, u.phone
             FROM reviews r
             LEFT JOIN users u ON u.idusers = r.user_id
             WHERE r.target_user_id = ?
             ORDER BY r.datastamp DESC'
        );
        $st->execute([$customerId]);

        return $st->fetchAll();
    } catch (Throwable $e) {
        return [];
    }
}

function crg_admin_render_rating_stars(int $rating): string
{
    $rating = max(0, min(5, $rating));

    return str_repeat('★', $rating) . str_repeat('☆', 5 - $rating);
}

/**
 * @param array{avg: float, count: int} $summary
 * @param list<array<string, mixed>> $rows
 */
function crg_admin_render_reviews_section(
    string $title,
    array $summary,
    array $rows,
    string $authorLabel
): void {
    tp_admin_web_require_include('admin_users.php');

    echo '<div class="card">';
    echo '<p class="meta"><strong>' . tp_admin_web_h($title) . '</strong></p>';

    if ($summary['count'] === 0) {
        echo '<p class="meta">Нет отзывов.</p>';
        echo '</div>';

        return;
    }

    echo '<p><span class="rating-stars">' . crg_admin_render_rating_stars((int) round($summary['avg'])) . '</span>';
    echo ' <strong>' . tp_admin_web_h(number_format($summary['avg'], 1, '.', '')) . '</strong>';
    echo ' <span class="meta">(' . (int) $summary['count'] . ' ' . crg_admin_review_count_label($summary['count']) . ')</span></p>';

    echo '<table class="data"><thead><tr>';
    echo '<th>' . tp_admin_web_h($authorLabel) . '</th>';
    echo '<th>Оценка</th><th>Комментарий</th><th>Дата</th></tr></thead><tbody>';

    foreach ($rows as $r) {
        $authorId = (int) ($r['author_id'] ?? 0);
        $name = crg_admin_user_display_name($r);
        $rating = (int) ($r['rating'] ?? 0);
        echo '<tr>';
        echo '<td>';
        if ($authorId > 0) {
            echo '<a href="user_edit.php?id=' . $authorId . '">' . tp_admin_web_h($name) . '</a>';
        } else {
            echo tp_admin_web_h($name);
        }
        echo '</td>';
        echo '<td><span class="rating-stars" title="' . $rating . '/5">' . crg_admin_render_rating_stars($rating) . '</span></td>';
        echo '<td>' . tp_admin_web_h((string) ($r['comment'] ?? '')) . '</td>';
        echo '<td class="meta">' . tp_admin_web_h((string) ($r['datastamp'] ?? '')) . '</td>';
        echo '</tr>';
    }

    echo '</tbody></table></div>';
}

function crg_admin_review_count_label(int $count): string
{
    $n = abs($count) % 100;
    $n1 = $n % 10;
    if ($n > 10 && $n < 20) {
        return 'отзывов';
    }
    if ($n1 === 1) {
        return 'отзыв';
    }
    if ($n1 >= 2 && $n1 <= 4) {
        return 'отзыва';
    }

    return 'отзывов';
}

function crg_admin_render_performer_reviews(PDO $pdo, int $performerId): void
{
    crg_admin_render_reviews_section(
        'Отзывы об исполнителе',
        crg_admin_performer_review_summary($pdo, $performerId),
        crg_admin_reviews_about_performer($pdo, $performerId),
        'Заказчик'
    );
}

function crg_admin_render_customer_reviews(PDO $pdo, int $customerId): void
{
    crg_admin_render_reviews_section(
        'Отзывы о заказчике',
        crg_admin_customer_review_summary($pdo, $customerId),
        crg_admin_reviews_about_customer($pdo, $customerId),
        'Исполнитель'
    );
}
