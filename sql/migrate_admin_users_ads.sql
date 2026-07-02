-- Расширение локальной схемы для разделов «Пользователи» и «Объявления» в админке.
-- mysql --default-character-set=utf8mb4 -u root crg_local < sql/migrate_admin_users_ads.sql
-- php scripts/seed_test_ads.php
-- или: ./scripts/seed_test_ads.sh

USE crg_local;

DROP TABLE IF EXISTS add_ob_gp;
DROP TABLE IF EXISTS add_ob_vidt;
DROP TABLE IF EXISTS add_ob_gr;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS orderst;
DROP TABLE IF EXISTS ordersg;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    idusers INT NOT NULL AUTO_INCREMENT,
    fotouser LONGBLOB NOT NULL DEFAULT (''),
    rollNum INT DEFAULT NULL,
    statNum INT DEFAULT NULL,
    firstName VARCHAR(50) DEFAULT NULL,
    lastName VARCHAR(50) DEFAULT NULL,
    middleName VARCHAR(50) DEFAULT NULL,
    city VARCHAR(50) DEFAULT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    email VARCHAR(100) DEFAULT NULL,
    password VARCHAR(255) DEFAULT NULL,
    namefirm VARCHAR(255) DEFAULT NULL,
    innStr VARCHAR(20) DEFAULT NULL,
    ogrnStr VARCHAR(20) DEFAULT NULL,
    kppStr VARCHAR(20) DEFAULT NULL,
    vidt VARCHAR(50) DEFAULT NULL,
    marka VARCHAR(255) DEFAULT NULL,
    godv INT DEFAULT NULL,
    maxgruz VARCHAR(255) DEFAULT NULL,
    dkuzov INT DEFAULT NULL,
    shkuzov INT DEFAULT NULL,
    vidk VARCHAR(255) DEFAULT NULL,
    cenahaurs DECIMAL(10,2) DEFAULT NULL,
    cenasmena DECIMAL(10,2) DEFAULT NULL,
    cenakm DECIMAL(10,2) DEFAULT NULL,
    flag TINYINT(1) NOT NULL DEFAULT 0,
    payment VARCHAR(255) NOT NULL DEFAULT 'За час',
    typepayment VARCHAR(255) NOT NULL DEFAULT 'Наличными',
    fcm_token VARCHAR(255) NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (idusers)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO users (rollNum, statNum, firstName, lastName, email, phone, city, password, flag, namefirm, maxgruz, vidk) VALUES
(2, 1, 'Иван', 'Перевозов', 'performer1@test.local', '+79001111111', 'Тюмень', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 0, 'ООО Груз', 'до 5 т.', 'Тентовый'),
(1, 2, 'Пётр', 'Заказов', 'customer1@test.local', '+79002222222', 'Тобольск', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1, NULL, NULL, NULL),
(3, 1, 'Сергей', 'Техник', 'spec1@test.local', '+79003333333', 'Ишим', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1, 'СпецТех', NULL, NULL);

CREATE TABLE add_ob_gp (
    id INT NOT NULL AUTO_INCREMENT,
    iduser INT NOT NULL,
    city VARCHAR(255) DEFAULT NULL,
    marka VARCHAR(255) DEFAULT NULL,
    godv INT NOT NULL DEFAULT 0,
    maxgruz VARCHAR(255) NOT NULL DEFAULT '',
    dkuzov INT NOT NULL DEFAULT 0,
    shkuzov INT NOT NULL DEFAULT 0,
    vidk VARCHAR(255) NOT NULL DEFAULT '',
    cenahaurs VARCHAR(255) DEFAULT NULL,
    cenasmena VARCHAR(255) DEFAULT NULL,
    cenakm VARCHAR(255) DEFAULT NULL,
    img1 LONGBLOB,
    img2 LONGBLOB,
    img3 LONGBLOB,
    img4 LONGBLOB,
    imgdoc1 LONGBLOB,
    imgdoc2 LONGBLOB,
    imgdoc3 LONGBLOB,
    imgdoc4 LONGBLOB,
    flag TINYINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO add_ob_gp (iduser, city, marka, maxgruz, vidk, flag) VALUES
(1, 'Тюмень', 'КамАЗ', 'до 5 т.', 'Тентовый', 0),
(1, 'Тобольск', 'МАЗ', 'до 10 т.', 'Бортовой', 1);

CREATE TABLE add_ob_vidt (
    id INT NOT NULL AUTO_INCREMENT,
    iduser INT NOT NULL,
    city VARCHAR(255) DEFAULT NULL,
    vidt VARCHAR(255) DEFAULT NULL,
    cenahaurs VARCHAR(255) DEFAULT NULL,
    cenasmena VARCHAR(255) DEFAULT NULL,
    cenakm VARCHAR(255) DEFAULT NULL,
    img1 LONGBLOB, img2 LONGBLOB, img3 LONGBLOB, img4 LONGBLOB,
    imgdoc1 LONGBLOB, imgdoc2 LONGBLOB, imgdoc3 LONGBLOB, imgdoc4 LONGBLOB,
    flag TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO add_ob_vidt (iduser, city, vidt, flag) VALUES (3, 'Ишим', 'Экскаватор', 0);

CREATE TABLE add_ob_gr (
    id INT NOT NULL AUTO_INCREMENT,
    iduser INT NOT NULL,
    city VARCHAR(255) DEFAULT NULL,
    cenahaurs VARCHAR(255) DEFAULT NULL,
    cenasmena VARCHAR(255) DEFAULT NULL,
    cenakm VARCHAR(255) DEFAULT NULL,
    img1 LONGBLOB, img2 LONGBLOB, img3 LONGBLOB, img4 LONGBLOB,
    imgdoc1 LONGBLOB, imgdoc2 LONGBLOB, imgdoc3 LONGBLOB, imgdoc4 LONGBLOB,
    flag TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE orders (
    id INT NOT NULL AUTO_INCREMENT,
    iduser VARCHAR(255) DEFAULT NULL,
    maxgruz VARCHAR(255) DEFAULT NULL,
    city VARCHAR(255) DEFAULT NULL,
    startdate DATE DEFAULT NULL,
    enddate DATE DEFAULT NULL,
    city1 VARCHAR(255) DEFAULT NULL,
    vidk VARCHAR(255) DEFAULT NULL,
    zagr VARCHAR(255) DEFAULT NULL,
    typepr VARCHAR(255) DEFAULT NULL,
    cena VARCHAR(255) NOT NULL DEFAULT '',
    about TEXT,
    enddatez DATE NOT NULL,
    img1 LONGBLOB, img2 LONGBLOB, img3 LONGBLOB, img4 LONGBLOB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO orders (iduser, city, city1, maxgruz, vidk, cena, about, enddatez) VALUES
('2', 'Тобольск', 'Тюмень', 'до 5 т.', 'Тентовый', '5000', 'Нужна перевозка мебели', '2026-12-31');

CREATE TABLE orderst (
    id INT NOT NULL AUTO_INCREMENT,
    iduser VARCHAR(255) DEFAULT NULL,
    vidt VARCHAR(255) DEFAULT NULL,
    city VARCHAR(255) DEFAULT NULL,
    startdate DATE DEFAULT NULL,
    enddate DATE DEFAULT NULL,
    cena VARCHAR(255) NOT NULL DEFAULT '',
    about TEXT,
    enddatez DATE NOT NULL,
    img1 LONGBLOB, img2 LONGBLOB, img3 LONGBLOB, img4 LONGBLOB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ordersg (
    id INT NOT NULL AUTO_INCREMENT,
    iduser VARCHAR(255) DEFAULT NULL,
    city VARCHAR(255) DEFAULT NULL,
    startdate DATE DEFAULT NULL,
    enddate DATE DEFAULT NULL,
    cena VARCHAR(255) NOT NULL DEFAULT '',
    about TEXT,
    enddatez DATE NOT NULL,
    img1 LONGBLOB, img2 LONGBLOB, img3 LONGBLOB, img4 LONGBLOB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO ordersg (iduser, city, cena, about, enddatez) VALUES ('2', 'Тюмень', '3000', 'Нужны грузчики', '2026-12-31');

INSERT INTO orderst (iduser, city, vidt, cena, about, enddatez) VALUES
('2', 'Тюмень', 'Экскаватор', '15000', 'Копка траншеи', '2026-12-31');

-- Отклики и предложения (для просмотра в админке)
CREATE TABLE IF NOT EXISTS offer_data (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS offer_dataf (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- iduser = id заявки заказчика; iduserp = id исполнителя (users.idusers)
INSERT INTO offer_data (cena, about, iduserp, iduser, bd, status) VALUES
('4800.00', 'Готов выполнить завтра, свой тент', 5, 1, 1, 0),
('5200.00', 'КамАЗ 5 т, опыт 10 лет', 1, 1, 1, 1),
('14000.00', 'Экскаватор свободен с понедельника', 3, 1, 2, 0),
('2800.00', 'Бригада 4 человека, свой инструмент', 4, 1, 3, 0);

-- Отзывы: reviewsisp — об исполнителе, reviews — о заказчике (как в приложении)
CREATE TABLE IF NOT EXISTS reviews (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL COMMENT 'автор отзыва (исполнитель)',
    target_user_id INT NOT NULL COMMENT 'заказчик',
    rating INT UNSIGNED NOT NULL DEFAULT 0,
    comment TEXT NOT NULL,
    datastamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_reviews_target (target_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS reviewsisp (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL COMMENT 'исполнитель',
    target_user_id INT NOT NULL COMMENT 'автор отзыва (заказчик)',
    rating INT UNSIGNED NOT NULL DEFAULT 0,
    comment TEXT NOT NULL,
    datastamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_reviewsisp_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO reviewsisp (user_id, target_user_id, rating, comment) VALUES
(1, 2, 5, 'Отличный водитель, всё доставил в срок'),
(3, 2, 4, 'Экскаватор приехал вовремя, работа аккуратная');

INSERT INTO reviews (user_id, target_user_id, rating, comment) VALUES
(1, 2, 5, 'Адекватный заказчик, оплата без задержек'),
(3, 2, 4, 'Чёткое ТЗ, приятно работать');

-- Подписки исполнителей (доступ к функциям приложения)
CREATE TABLE IF NOT EXISTS subscription_config (
    id INT NOT NULL AUTO_INCREMENT,
    days INT NOT NULL DEFAULT 30,
    price_rub INT NOT NULL DEFAULT 300,
    is_active TINYINT NOT NULL DEFAULT 1,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS subscriptions (
    id INT NOT NULL AUTO_INCREMENT,
    iduser INT NOT NULL,
    date DATE NOT NULL COMMENT 'дата окончания',
    payment VARCHAR(255) NOT NULL DEFAULT '',
    count INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY idx_subscriptions_user (iduser)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO subscription_config (days, price_rub, is_active) VALUES (30, 300, 1);

INSERT INTO subscriptions (iduser, date, payment, count) VALUES
(1, '2026-12-31', 'test-payment-active-001', 2),
(3, '2025-01-01', 'test-payment-expired-001', 1);
