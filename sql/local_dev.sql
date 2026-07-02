-- Минимальная локальная БД для веб-админки городов (без полного prod-дампа).
-- mysql --default-character-set=utf8mb4 -u root < sql/local_dev.sql

SET NAMES utf8mb4;

DROP DATABASE IF EXISTS crg_local;
CREATE DATABASE crg_local CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE crg_local;

CREATE TABLE cities (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO cities (id, name) VALUES
(50, 'Абатское'),
(51, 'Аксарка'),
(52, 'Антипино'),
(53, 'Армизонское'),
(54, 'Аромашево'),
(55, 'Вагай'),
(56, 'Викулово'),
(57, 'Винзили'),
(58, 'Заводопетровский'),
(73, 'Белоярский'),
(74, 'Бердюжье'),
(75, 'Богандинский'),
(76, 'Большое Сорокино'),
(77, 'Боровский'),
(78, 'Голышманово'),
(101, 'Заводоуковск'),
(102, 'Казанское'),
(103, 'Каскара'),
(104, 'Нижняя Тавда'),
(105, 'Новая Заимка'),
(106, 'Новоселезнево'),
(107, 'Новотарманский'),
(108, 'Сладково'),
(109, 'Стрехнино'),
(110, 'Сумкино'),
(111, 'Уват'),
(112, 'Упорово'),
(113, 'Успенка'),
(114, 'Юргинское'),
(121, 'Исетское'),
(122, 'Ишим'),
(123, 'Матмассы'),
(124, 'Московский'),
(125, 'Омутинское'),
(126, 'Онохино'),
(127, 'Тарманы'),
(128, 'Тобольск'),
(129, 'Туртас'),
(130, 'Тюмень'),
(131, 'Червишево'),
(132, 'Ялуторовск'),
(133, 'Ярково');

ALTER TABLE cities AUTO_INCREMENT = 134;

CREATE TABLE users (
    idusers INT NOT NULL,
    city VARCHAR(50) DEFAULT NULL,
    vidt VARCHAR(50) DEFAULT NULL,
    maxgruz VARCHAR(255) DEFAULT NULL,
    vidk VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (idusers)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO users (idusers, city, vidt, maxgruz, vidk) VALUES
(1, 'Тюмень', 'Экскаватор', 'до 5 т.', 'Тентовый'),
(2, 'Тобольск', 'Автокран', 'до 10 т.', 'Бортовой');

CREATE TABLE orders (
    id INT NOT NULL AUTO_INCREMENT,
    city VARCHAR(255) DEFAULT NULL,
    city1 VARCHAR(255) DEFAULT NULL,
    maxgruz VARCHAR(255) DEFAULT NULL,
    vidk VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO orders (city, city1, maxgruz, vidk) VALUES ('Ишим', 'Тюмень', 'до 5 т.', 'Фургон');

CREATE TABLE ordersg (
    id INT NOT NULL AUTO_INCREMENT,
    city VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE add_ob_gp (id INT PRIMARY KEY, city VARCHAR(255), maxgruz VARCHAR(255), vidk VARCHAR(255));
CREATE TABLE add_ob_gr (id INT PRIMARY KEY, city VARCHAR(255));
CREATE TABLE add_ob_vidt (id INT PRIMARY KEY, city VARCHAR(255), vidt VARCHAR(255));
CREATE TABLE orderst (id INT PRIMARY KEY AUTO_INCREMENT, vidt VARCHAR(255));
INSERT INTO orderst (vidt) VALUES ('Экскаватор');
CREATE TABLE gruz_info (id INT PRIMARY KEY, city VARCHAR(255), city1 VARCHAR(255), maxgruz VARCHAR(255), vidk VARCHAR(255));

CREATE TABLE vidt (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    image LONGBLOB NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO vidt (id, name, image) VALUES
(1, 'Экскаватор', ''),
(2, 'Автокран', ''),
(3, 'Бульдозер', ''),
(4, 'Погрузчик', ''),
(5, 'Автовышка', '');

CREATE TABLE vidg (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    image LONGBLOB NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO vidg (id, name, image) VALUES
(1, 'до 1 т.', ''),
(2, 'до 3 т.', ''),
(3, 'до 5 т.', ''),
(4, 'до 10 т.', ''),
(5, 'до 20 т.', '');

CREATE TABLE vidkuzov (
    id INT NOT NULL AUTO_INCREMENT,
    namevidk VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO vidkuzov (id, namevidk) VALUES
(1, 'Тентовый'),
(2, 'Контейнер'),
(3, 'Фургон'),
(4, 'Изотермический'),
(5, 'Рефрижиратор'),
(6, 'Бортовой'),
(7, 'Самосвал'),
(8, 'Шаланда');

-- Placeholder PNG 1×1 для локальной проверки getimage.php (замените через админку)
SET @img_png = UNHEX('89504E470D0A1A0A0000000D49484452000000010000000108060000001F15C4890000000A49444154789C6300010000000500010D0A2DB40000000049454E44AE426082');
UPDATE vidt SET image = @img_png;
UPDATE vidg SET image = @img_png;

CREATE TABLE gruzchik (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    image LONGBLOB NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO gruzchik (name, image) VALUES ('Грузчики', @img_png);

CREATE TABLE IF NOT EXISTS admin_accounts (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    login VARCHAR(64) NOT NULL,
    email VARCHAR(255) NULL DEFAULT NULL,
    password_hash VARCHAR(255) NOT NULL,
    token CHAR(64) NULL DEFAULT NULL,
    token_updated_at DATETIME NULL DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_admin_accounts_login (login),
    UNIQUE KEY uq_admin_accounts_token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO admin_accounts (login, password_hash)
VALUES (
    'admin',
    '$2y$12$9QgZFcwb/w0hdx3jtgcTC.T6DmphFwccA6VDq8BmuBzfdd3.2dq0u'
);

CREATE TABLE IF NOT EXISTS admin_password_reset_otp (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    login VARCHAR(64) NOT NULL,
    code CHAR(6) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_apro_login (login),
    KEY idx_apro_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
