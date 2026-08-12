-- P2: онбординг, поднятие объявлений, верификация, шаблоны, «в пути», воронка
-- Выполнить один раз на БД приложения

SET @db := DATABASE();

-- users: верификация исполнителя
SET @has_ver := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'users' AND COLUMN_NAME = 'is_verified'
);
SET @sql := IF(@has_ver = 0,
  'ALTER TABLE users ADD COLUMN is_verified TINYINT(1) NOT NULL DEFAULT 0 AFTER flag',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_ver_at := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'users' AND COLUMN_NAME = 'verified_at'
);
SET @sql := IF(@has_ver_at = 0,
  'ALTER TABLE users ADD COLUMN verified_at DATETIME NULL AFTER is_verified',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Поднятие объявлений (исполнитель)
CREATE TABLE IF NOT EXISTS ad_boost_tariffs (
  id INT NOT NULL AUTO_INCREMENT,
  code VARCHAR(32) NOT NULL,
  title VARCHAR(128) NOT NULL,
  hours INT NOT NULL,
  price_rub INT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_boost_tariff_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ad_boosts (
  id INT NOT NULL AUTO_INCREMENT,
  bd TINYINT NOT NULL,
  ad_id INT NOT NULL,
  user_id INT NOT NULL,
  tariff_id INT NULL,
  boosted_until DATETIME NOT NULL,
  price_rub INT NOT NULL DEFAULT 0,
  payment_order_id VARCHAR(128) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_boost_active (boosted_until, bd, ad_id),
  KEY idx_boost_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO ad_boost_tariffs (code, title, hours, price_rub, sort_order, is_active)
SELECT '24h', 'В топ 24 ч', 24, 199, 10, 1
WHERE NOT EXISTS (SELECT 1 FROM ad_boost_tariffs WHERE code = '24h');

INSERT INTO ad_boost_tariffs (code, title, hours, price_rub, sort_order, is_active)
SELECT '72h', 'В топ 72 ч', 72, 399, 20, 1
WHERE NOT EXISTS (SELECT 1 FROM ad_boost_tariffs WHERE code = '72h');

-- ordersglobal: статус «в пути» + ETA + геоточка
SET @og_status := (
  SELECT COLUMN_TYPE FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'ordersglobal' AND COLUMN_NAME = 'status'
);
SET @sql := IF(@og_status IS NOT NULL AND @og_status NOT LIKE '%в_пути%',
  "ALTER TABLE ordersglobal MODIFY COLUMN status ENUM('выполняется','в_пути','выполнен','отменен') DEFAULT NULL",
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_it := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'ordersglobal' AND COLUMN_NAME = 'in_transit_at'
);
SET @sql := IF(@has_it = 0,
  'ALTER TABLE ordersglobal ADD COLUMN in_transit_at DATETIME NULL AFTER start_time',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_eta := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'ordersglobal' AND COLUMN_NAME = 'eta_at'
);
SET @sql := IF(@has_eta = 0,
  'ALTER TABLE ordersglobal ADD COLUMN eta_at DATETIME NULL AFTER in_transit_at',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_tlat := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'ordersglobal' AND COLUMN_NAME = 'transit_lat'
);
SET @sql := IF(@has_tlat = 0,
  'ALTER TABLE ordersglobal ADD COLUMN transit_lat DECIMAL(10,7) NULL AFTER eta_at',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_tlng := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'ordersglobal' AND COLUMN_NAME = 'transit_lng'
);
SET @sql := IF(@has_tlng = 0,
  'ALTER TABLE ordersglobal ADD COLUMN transit_lng DECIMAL(10,7) NULL AFTER transit_lat',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
