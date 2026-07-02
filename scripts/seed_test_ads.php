<?php
declare(strict_types=1);

/**
 * Тестовые объявления с картинками и документами (BLOB).
 * php scripts/seed_test_ads.php
 */

$root = dirname(__DIR__);
require $root . '/api/include/api_bootstrap.php';

function seed_png(string $label, int $r, int $g, int $b): string
{
    if (!function_exists('imagecreatetruecolor')) {
        static $fallback = null;
        if ($fallback === null) {
            $fallback = hex2bin(
                '89504E470D0A1A0A0000000D4948445200000060000000400806000000'
                . '57FAC6AE0000000A49444154789C630001000005000108D4'
                . '0000000049454E44AE426082'
            ) ?: '';
        }

        return $fallback;
    }

    $w = 240;
    $h = 160;
    $im = imagecreatetruecolor($w, $h);
    $bg = imagecolorallocate($im, $r, $g, $b);
    imagefilledrectangle($im, 0, 0, $w - 1, $h - 1, $bg);
    $fg = imagecolorallocate($im, 255, 255, 255);
    imagestring($im, 5, 10, 70, $label, $fg);
    ob_start();
    imagepng($im);

    return ob_get_clean() ?: '';
}

function seed_pdf(string $title): string
{
    $safe = preg_replace('/[^\x20-\x7E]/', '', $title) ?: 'Test-doc';

    return "%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n"
        . "2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n"
        . "3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 400 200]/Contents 4 0 R>>endobj\n"
        . "4 0 obj<</Length 50>>stream\nBT /F1 14 Tf 40 100 Td ({$safe}) Tj ET\nendstream\nendobj\n"
        . "trailer<</Size 5/Root 1 0 R>>\nstartxref\n300\n%%EOF\n";
}

/** @return array<string, string> */
function seed_performer_blobs(int $idx): array
{
    $palette = [[52, 152, 219], [46, 204, 113], [155, 89, 182], [230, 126, 34], [231, 76, 60], [26, 188, 156]];
    $c = $palette[$idx % count($palette)];
    $n = $idx + 1;

    return [
        'img1' => seed_png("FOTO1-{$n}", $c[0], $c[1], $c[2]),
        'img2' => seed_png("FOTO2-{$n}", $c[1], $c[2], $c[0]),
        'img3' => seed_png("FOTO3-{$n}", $c[2], $c[0], $c[1]),
        'imgdoc1' => seed_pdf("DOC-{$n}-license"),
        'imgdoc2' => seed_png("SCAN-{$n}", 90, 90, 90),
    ];
}

/** @return array<string, string> */
function seed_customer_blobs(int $idx): array
{
    $palette = [[41, 128, 185], [39, 174, 96], [142, 68, 173], [243, 156, 18]];
    $c = $palette[$idx % count($palette)];
    $n = $idx + 1;

    return [
        'img1' => seed_png("ZAYAVKA-{$n}", $c[0], $c[1], $c[2]),
        'img2' => seed_png("GRUZ-{$n}", 100, 149, 237),
    ];
}

function seed_update_blobs(PDO $pdo, string $table, int $id, array $blobs): void
{
    foreach ($blobs as $col => $bin) {
        if ($bin === '') {
            continue;
        }
        $st = $pdo->prepare("UPDATE `{$table}` SET `{$col}` = ? WHERE id = ?");
        $st->bindValue(1, $bin, PDO::PARAM_LOB);
        $st->bindValue(2, $id, PDO::PARAM_INT);
        $st->execute();
    }
}

function seed_ensure_user(PDO $pdo, int $id, array $u): void
{
    $st = $pdo->prepare('SELECT 1 FROM users WHERE idusers = ?');
    $st->execute([$id]);
    if ($st->fetch() !== false) {
        return;
    }
    $ins = $pdo->prepare(
        'INSERT INTO users (idusers, rollNum, statNum, firstName, lastName, email, phone, city, flag, namefirm, maxgruz, vidk, password, fotouser)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, \'\')'
    );
    $ins->execute([
        $id, $u['roll'], $u['stat'], $u['first'], $u['last'], $u['email'], $u['phone'], $u['city'],
        $u['flag'], $u['firm'], $u['maxgruz'], $u['vidk'],
        '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    ]);
}

$pdo = tp_pdo();
echo "Seed test ads\n";

seed_ensure_user($pdo, 4, [
    'roll' => 4, 'stat' => 1, 'first' => 'Алексей', 'last' => 'Грузчиков',
    'email' => 'loader1@test.local', 'phone' => '+79004444444', 'city' => 'Тюмень',
    'flag' => 1, 'firm' => 'Бригада 72', 'maxgruz' => null, 'vidk' => null,
]);
seed_ensure_user($pdo, 5, [
    'roll' => 2, 'stat' => 2, 'first' => 'Михаил', 'last' => 'Водителев',
    'email' => 'performer2@test.local', 'phone' => '+79005555555', 'city' => 'Ишим',
    'flag' => 0, 'firm' => null, 'maxgruz' => 'до 3 т.', 'vidk' => 'Фургон',
]);
seed_ensure_user($pdo, 6, [
    'roll' => 1, 'stat' => 2, 'first' => 'Анна', 'last' => 'Заказова',
    'email' => 'customer2@test.local', 'phone' => '+79006666666', 'city' => 'Тюмень',
    'flag' => 1, 'firm' => null, 'maxgruz' => null, 'vidk' => null,
]);

$gpAds = [
    [1, 'Тюмень', 'КамАЗ', 'до 5 т.', 'Тентовый', 0],
    [1, 'Тобольск', 'МАЗ', 'до 10 т.', 'Бортовой', 1],
    [5, 'Ишим', 'ГАЗель', 'до 1.5 т.', 'Фургон', 0],
    [5, 'Ялуторовск', 'Ford', 'до 3 т.', 'Тентовый', 1],
    [5, 'Тюмень', 'Volvo', 'до 20 т.', 'Рефрижератор', 0],
];
$vidtAds = [
    [3, 'Ишим', 'Экскаватор', 0],
    [3, 'Тюмень', 'Автокран', 1],
    [3, 'Тобольск', 'Бульдozer', 0],
    [3, 'Ялуторовск', 'Погрузчик', 1],
];
$grAds = [
    [4, 'Тюмень', 0],
    [4, 'Тобольск', 1],
    [4, 'Ишим', 0],
    [4, 'Вагай', 1],
];

$idx = 0;
foreach ($gpAds as $a) {
    [$uid, $city, $marka, $maxgruz, $vidk, $flag] = $a;
    $st = $pdo->prepare(
        'SELECT id FROM add_ob_gp WHERE iduser = ? AND city = ? AND marka = ? LIMIT 1'
    );
    $st->execute([$uid, $city, $marka]);
    $row = $st->fetch();
    if ($row === false) {
        $ins = $pdo->prepare(
            'INSERT INTO add_ob_gp (iduser, city, marka, godv, maxgruz, dkuzov, shkuzov, vidk, cenahaurs, flag)
             VALUES (?, ?, ?, 2018, ?, 4, 2, ?, \'1500\', ?)'
        );
        $ins->execute([$uid, $city, $marka, $maxgruz, $vidk, $flag]);
        $adId = (int) $pdo->lastInsertId();
    } else {
        $adId = (int) $row['id'];
    }
    seed_update_blobs($pdo, 'add_ob_gp', $adId, seed_performer_blobs($idx));
    echo "  add_ob_gp #{$adId} {$city}\n";
    ++$idx;
}

foreach ($vidtAds as $a) {
    [$uid, $city, $vidt, $flag] = $a;
    $st = $pdo->prepare('SELECT id FROM add_ob_vidt WHERE iduser = ? AND city = ? AND vidt = ? LIMIT 1');
    $st->execute([$uid, $city, $vidt]);
    $row = $st->fetch();
    if ($row === false) {
        $ins = $pdo->prepare(
            'INSERT INTO add_ob_vidt (iduser, city, vidt, cenahaurs, flag) VALUES (?, ?, ?, \'2500\', ?)'
        );
        $ins->execute([$uid, $city, $vidt, $flag]);
        $adId = (int) $pdo->lastInsertId();
    } else {
        $adId = (int) $row['id'];
    }
    seed_update_blobs($pdo, 'add_ob_vidt', $adId, seed_performer_blobs($idx));
    echo "  add_ob_vidt #{$adId} {$city}\n";
    ++$idx;
}

foreach ($grAds as $a) {
    [$uid, $city, $flag] = $a;
    $st = $pdo->prepare('SELECT id FROM add_ob_gr WHERE iduser = ? AND city = ? LIMIT 1');
    $st->execute([$uid, $city]);
    $row = $st->fetch();
    if ($row === false) {
        $ins = $pdo->prepare('INSERT INTO add_ob_gr (iduser, city, cenahaurs, flag) VALUES (?, ?, \'500\', ?)');
        $ins->execute([$uid, $city, $flag]);
        $adId = (int) $pdo->lastInsertId();
    } else {
        $adId = (int) $row['id'];
    }
    seed_update_blobs($pdo, 'add_ob_gr', $adId, seed_performer_blobs($idx));
    echo "  add_ob_gr #{$adId} {$city}\n";
    ++$idx;
}

$ordersAds = [
    ['2', 'Тобольск', 'Тюмень', 'до 5 т.', 'Тентовый', '5000', 'Перевозка мебели'],
    ['6', 'Тюмень', 'Ишим', 'до 3 т.', 'Фургон', '8000', 'Доставка стройматериалов'],
    ['6', 'Ялуторовск', 'Тюмень', 'до 10 т.', 'Бортовой', '12000', 'Переезд офиса'],
    ['2', 'Ишим', 'Тобольск', 'до 5 т.', 'Тентовый', '6500', 'Перевозка техники'],
];
$orderstAds = [
    ['2', 'Тюмень', 'Экскаватор', '15000', 'Копка траншеи'],
    ['6', 'Тобольск', 'Автокран', '20000', 'Монтаж конструкций'],
    ['6', 'Ишим', 'Бульдozer', '18000', 'Планировка участка'],
];
$ordersgAds = [
    ['2', 'Тюмень', '3000', 'Грузчики на склад'],
    ['6', 'Ишим', '4500', 'Погрузка фуры'],
    ['2', 'Тобольск', '3500', 'Разгрузка контейнера'],
];

$idx = 0;
foreach ($ordersAds as $a) {
    [$uid, $city, $city1, $maxgruz, $vidk, $cena, $about] = $a;
    $st = $pdo->prepare('SELECT id FROM orders WHERE iduser = ? AND city = ? AND about = ? LIMIT 1');
    $st->execute([$uid, $city, $about]);
    $row = $st->fetch();
    if ($row === false) {
        $ins = $pdo->prepare(
            'INSERT INTO orders (iduser, city, city1, maxgruz, vidk, cena, about, enddatez)
             VALUES (?, ?, ?, ?, ?, ?, ?, \'2026-12-31\')'
        );
        $ins->execute([$uid, $city, $city1, $maxgruz, $vidk, $cena, $about]);
        $adId = (int) $pdo->lastInsertId();
    } else {
        $adId = (int) $row['id'];
    }
    seed_update_blobs($pdo, 'orders', $adId, seed_customer_blobs($idx));
    echo "  orders #{$adId} {$city}\n";
    ++$idx;
}

foreach ($orderstAds as $a) {
    [$uid, $city, $vidt, $cena, $about] = $a;
    $st = $pdo->prepare('SELECT id FROM orderst WHERE iduser = ? AND city = ? AND about = ? LIMIT 1');
    $st->execute([$uid, $city, $about]);
    $row = $st->fetch();
    if ($row === false) {
        $ins = $pdo->prepare(
            'INSERT INTO orderst (iduser, city, vidt, cena, about, enddatez) VALUES (?, ?, ?, ?, ?, \'2026-12-31\')'
        );
        $ins->execute([$uid, $city, $vidt, $cena, $about]);
        $adId = (int) $pdo->lastInsertId();
    } else {
        $adId = (int) $row['id'];
    }
    seed_update_blobs($pdo, 'orderst', $adId, seed_customer_blobs($idx));
    echo "  orderst #{$adId} {$city}\n";
    ++$idx;
}

foreach ($ordersgAds as $a) {
    [$uid, $city, $cena, $about] = $a;
    $st = $pdo->prepare('SELECT id FROM ordersg WHERE iduser = ? AND city = ? AND about = ? LIMIT 1');
    $st->execute([$uid, $city, $about]);
    $row = $st->fetch();
    if ($row === false) {
        $ins = $pdo->prepare(
            'INSERT INTO ordersg (iduser, city, cena, about, enddatez) VALUES (?, ?, ?, ?, \'2026-12-31\')'
        );
        $ins->execute([$uid, $city, $cena, $about]);
        $adId = (int) $pdo->lastInsertId();
    } else {
        $adId = (int) $row['id'];
    }
    seed_update_blobs($pdo, 'ordersg', $adId, seed_customer_blobs($idx));
    echo "  ordersg #{$adId} {$city}\n";
    ++$idx;
}

$pdo->exec(
    'CREATE TABLE IF NOT EXISTS offer_data (
        id INT NOT NULL AUTO_INCREMENT,
        cena DECIMAL(10,2) NOT NULL,
        about TEXT,
        iduserp INT NOT NULL,
        iduser INT NOT NULL,
        bd INT NOT NULL,
        isp TINYINT NOT NULL DEFAULT 0,
        status TINYINT NOT NULL DEFAULT 0,
        timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        KEY idx_offer_data_ad (iduser, bd)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
);
$pdo->exec(
    'CREATE TABLE IF NOT EXISTS offer_dataf (
        id INT NOT NULL AUTO_INCREMENT,
        cena DECIMAL(10,2) NOT NULL,
        about TEXT,
        iduserp INT NOT NULL,
        iduser INT NOT NULL,
        bd INT NOT NULL,
        isp TINYINT NOT NULL DEFAULT 0,
        ds TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        KEY idx_offer_dataf_ad (iduser, bd)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
);

function seed_dedupe_offer_data(PDO $pdo): void
{
    $pdo->exec(
        'DELETE od1 FROM offer_data od1
         INNER JOIN offer_data od2
           ON od1.iduserp = od2.iduserp
          AND od1.iduser = od2.iduser
          AND od1.bd = od2.bd
          AND od1.id < od2.id
          AND (od1.status = 0 OR od1.status IS NULL)
          AND (od2.status = 0 OR od2.status IS NULL)'
    );
}

function seed_ensure_offer_data(PDO $pdo, int $performerId, int $customerAdId, int $bd, string $cena, string $about, int $status): void
{
    $st = $pdo->prepare(
        'SELECT id FROM offer_data
         WHERE iduserp = ? AND iduser = ? AND bd = ?
           AND (status = 0 OR status IS NULL)
         LIMIT 1'
    );
    $st->execute([$performerId, $customerAdId, $bd]);
    $row = $st->fetch();
    if ($row !== false) {
        $upd = $pdo->prepare(
            'UPDATE offer_data SET cena = ?, about = ?, status = ? WHERE id = ?'
        );
        $upd->execute([$cena, $about, $status, (int) $row['id']]);

        return;
    }
    $ins = $pdo->prepare(
        'INSERT INTO offer_data (cena, about, iduserp, iduser, bd, status) VALUES (?, ?, ?, ?, ?, ?)'
    );
    $ins->execute([$cena, $about, $performerId, $customerAdId, $bd, $status]);
}

function seed_ensure_offer_dataf(PDO $pdo, int $customerId, int $performerAdId, int $bd, string $cena, string $about): void
{
    $st = $pdo->prepare(
        'SELECT id FROM offer_dataf WHERE iduserp = ? AND iduser = ? AND bd = ? AND about = ? LIMIT 1'
    );
    $st->execute([$customerId, $performerAdId, $bd, $about]);
    if ($st->fetch() !== false) {
        return;
    }
    $ins = $pdo->prepare(
        'INSERT INTO offer_dataf (cena, about, iduserp, iduser, bd) VALUES (?, ?, ?, ?, ?)'
    );
    $ins->execute([$cena, $about, $customerId, $performerAdId, $bd]);
}

function seed_cleanup_proposals_on_unpublished(PDO $pdo): void
{
    $pdo->exec(
        'DELETE od FROM offer_dataf od
         INNER JOIN add_ob_gp a ON a.id = od.iduser AND od.bd = 1
         WHERE a.flag = 0'
    );
    $pdo->exec(
        'DELETE od FROM offer_dataf od
         INNER JOIN add_ob_vidt a ON a.id = od.iduser AND od.bd = 2
         WHERE a.flag = 0'
    );
    $pdo->exec(
        'DELETE od FROM offer_dataf od
         INNER JOIN add_ob_gr a ON a.id = od.iduser AND od.bd = 3
         WHERE a.flag = 0'
    );
}

seed_cleanup_proposals_on_unpublished($pdo);
seed_dedupe_offer_data($pdo);

/**
 * @param list<array{int, string, int, int}> $offers [performerId, cena, about, status]
 */
function seed_offers_for_customer_ad(PDO $pdo, string $table, string $about, int $bd, array $offers): void
{
    $st = $pdo->prepare("SELECT id FROM `{$table}` WHERE about = ? ORDER BY id LIMIT 1");
    $st->execute([$about]);
    $row = $st->fetch();
    if ($row === false) {
        return;
    }
    $adId = (int) $row['id'];
    foreach ($offers as $o) {
        [$performerId, $cena, $text, $status] = $o;
        seed_ensure_offer_data($pdo, $performerId, $adId, $bd, $cena, $text, $status);
    }
    echo "  offer_data on {$table} #{$adId} ({$about})\n";
}

seed_offers_for_customer_ad($pdo, 'orders', 'Нужна перевозка мебели', 1, [
    [5, '4800.00', 'Готов выполнить завтра, свой тент', 0],
    [1, '5200.00', 'КамАЗ 5 т, опыт 10 лет', 1],
]);
seed_offers_for_customer_ad($pdo, 'orders', 'Перевозка мебели', 1, [
    [5, '4700.00', 'ГАЗель + грузчики', 0],
    [1, '5100.00', 'Выезд в день обращения', 0],
]);
seed_offers_for_customer_ad($pdo, 'orders', 'Доставка стройматериалов', 1, [
    [1, '7500.00', 'Длинномер 6 м', 0],
]);
seed_offers_for_customer_ad($pdo, 'orderst', 'Копка траншеи', 2, [
    [3, '14000.00', 'Экскаватор свободен с понедельника', 0],
    [3, '13500.00', 'Можем начать в пятницу', 0],
]);
seed_offers_for_customer_ad($pdo, 'orderst', 'Монтаж конструкций', 2, [
    [3, '19500.00', 'Автокран 25 т', 1],
]);
seed_offers_for_customer_ad($pdo, 'ordersg', 'Нужны грузчики', 3, [
    [4, '2800.00', 'Бригада 4 человека, свой инструмент', 0],
    [4, '3200.00', '6 человек, опыт на складах', 0],
]);
seed_offers_for_customer_ad($pdo, 'ordersg', 'Грузчики на склад', 3, [
    [4, '2900.00', 'Приедем через 2 часа', 0],
]);
seed_dedupe_offer_data($pdo);

$st = $pdo->prepare('SELECT id FROM add_ob_gp WHERE marka = ? AND city = ? AND flag = 1 LIMIT 1');
$st->execute(['МАЗ', 'Тобольск']);
$gpRow = $st->fetch();
if ($gpRow !== false) {
    $gpId = (int) $gpRow['id'];
    seed_ensure_offer_dataf($pdo, 6, $gpId, 1, '7000.00', 'Нужна перевозка на следующей неделе', 0);
    seed_ensure_offer_dataf($pdo, 2, $gpId, 1, '6500.00', 'Регулярные рейсы, готов обсудить', 0);
    echo "  offer_dataf on add_ob_gp #{$gpId}\n";
}

$st = $pdo->prepare('SELECT id FROM add_ob_vidt WHERE vidt = ? AND flag = 1 LIMIT 1');
$st->execute(['Автокран']);
$vidtRow = $st->fetch();
if ($vidtRow !== false) {
    $vidtId = (int) $vidtRow['id'];
    seed_ensure_offer_dataf($pdo, 6, $vidtId, 2, '16000.00', 'Копка котлована, 3 дня', 0);
    echo "  offer_dataf on add_ob_vidt #{$vidtId}\n";
}

$pdo->exec(
    'CREATE TABLE IF NOT EXISTS reviews (
        id INT NOT NULL AUTO_INCREMENT,
        user_id INT NOT NULL,
        target_user_id INT NOT NULL,
        rating INT UNSIGNED NOT NULL DEFAULT 0,
        comment TEXT NOT NULL,
        datastamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        UNIQUE KEY uq_reviews_performer_customer (user_id, target_user_id),
        KEY idx_reviews_target (target_user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
);
$pdo->exec(
    'CREATE TABLE IF NOT EXISTS reviewsisp (
        id INT NOT NULL AUTO_INCREMENT,
        user_id INT NOT NULL,
        target_user_id INT NOT NULL,
        rating INT UNSIGNED NOT NULL DEFAULT 0,
        comment TEXT NOT NULL,
        datastamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        UNIQUE KEY uq_reviewsisp_performer_customer (user_id, target_user_id),
        KEY idx_reviewsisp_user (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
);

function seed_ensure_review_isp(
    PDO $pdo,
    int $performerId,
    int $customerId,
    int $rating,
    string $comment
): void {
    $st = $pdo->prepare(
        'SELECT id FROM reviewsisp WHERE user_id = ? AND target_user_id = ? LIMIT 1'
    );
    $st->execute([$performerId, $customerId]);
    if ($st->fetch() !== false) {
        return;
    }
    $ins = $pdo->prepare(
        'INSERT INTO reviewsisp (user_id, target_user_id, rating, comment) VALUES (?, ?, ?, ?)'
    );
    $ins->execute([$performerId, $customerId, $rating, $comment]);
}

function seed_ensure_review_customer(
    PDO $pdo,
    int $performerId,
    int $customerId,
    int $rating,
    string $comment
): void {
    $st = $pdo->prepare(
        'SELECT id FROM reviews WHERE user_id = ? AND target_user_id = ? LIMIT 1'
    );
    $st->execute([$performerId, $customerId]);
    if ($st->fetch() !== false) {
        return;
    }
    $ins = $pdo->prepare(
        'INSERT INTO reviews (user_id, target_user_id, rating, comment) VALUES (?, ?, ?, ?)'
    );
    $ins->execute([$performerId, $customerId, $rating, $comment]);
}

seed_ensure_review_isp($pdo, 1, 2, 5, 'Отличный водитель, всё доставил в срок');
seed_ensure_review_isp($pdo, 1, 6, 4, 'Хорошая коммуникация, рекомендую');
seed_ensure_review_isp($pdo, 3, 2, 4, 'Экскаватор приехал вовремя, работа аккуратная');
seed_ensure_review_isp($pdo, 5, 6, 5, 'Быстро и аккуратно');
seed_ensure_review_customer($pdo, 1, 2, 5, 'Адекватный заказчик, оплата без задержек');
seed_ensure_review_customer($pdo, 3, 2, 4, 'Чёткое ТЗ, приятно работать');
seed_ensure_review_customer($pdo, 5, 2, 5, 'Всё по договорённости');
seed_ensure_review_customer($pdo, 1, 6, 4, 'Нормальный заказчик');
echo "  reviews + reviewsisp seeded\n";

$pdo->exec(
    'CREATE TABLE IF NOT EXISTS subscription_config (
        id INT NOT NULL AUTO_INCREMENT,
        days INT NOT NULL DEFAULT 30,
        price_rub INT NOT NULL DEFAULT 300,
        is_active TINYINT NOT NULL DEFAULT 1,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
);
$pdo->exec(
    'CREATE TABLE IF NOT EXISTS subscriptions (
        id INT NOT NULL AUTO_INCREMENT,
        iduser INT NOT NULL,
        date DATE NOT NULL,
        payment VARCHAR(255) NOT NULL DEFAULT \'\',
        count INT NOT NULL DEFAULT 0,
        PRIMARY KEY (id),
        KEY idx_subscriptions_user (iduser)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
);
$st = $pdo->query('SELECT id FROM subscription_config LIMIT 1');
if ($st->fetch() === false) {
    $pdo->exec('INSERT INTO subscription_config (days, price_rub, is_active) VALUES (30, 300, 1)');
}

function seed_ensure_subscription(PDO $pdo, int $userId, string $endDate, string $payment, int $count): void
{
    $st = $pdo->prepare('SELECT id FROM subscriptions WHERE iduser = ? LIMIT 1');
    $st->execute([$userId]);
    if ($st->fetch() !== false) {
        return;
    }
    $ins = $pdo->prepare('INSERT INTO subscriptions (iduser, date, payment, count) VALUES (?, ?, ?, ?)');
    $ins->execute([$userId, $endDate, $payment, $count]);
}

seed_ensure_subscription($pdo, 1, '2026-12-31', 'test-payment-active-001', 2);
seed_ensure_subscription($pdo, 3, '2025-01-01', 'test-payment-expired-001', 1);
seed_ensure_subscription($pdo, 5, '2026-08-15', 'test-payment-active-002', 1);
echo "  subscriptions seeded\n";

echo "Done.\n";
