-- Пакеты подписки и промокоды
-- Выполнить один раз на БД приложения

CREATE TABLE IF NOT EXISTS subscription_packages (
  id INT NOT NULL AUTO_INCREMENT,
  code VARCHAR(32) NOT NULL,
  title VARCHAR(128) NOT NULL,
  days INT NOT NULL,
  price_rub INT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sub_pkg_code (code),
  KEY idx_sub_pkg_active (is_active, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS promo_codes (
  id INT NOT NULL AUTO_INCREMENT,
  code VARCHAR(64) NOT NULL,
  discount_type ENUM('percent','fixed') NOT NULL DEFAULT 'percent',
  discount_value INT NOT NULL DEFAULT 0,
  valid_until DATE NULL,
  max_uses INT NULL,
  used_count INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_promo_code (code),
  KEY idx_promo_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS promo_redemptions (
  id INT NOT NULL AUTO_INCREMENT,
  promo_id INT NOT NULL,
  user_id INT NOT NULL,
  package_id INT NULL,
  order_id VARCHAR(128) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_promo_red_promo (promo_id),
  KEY idx_promo_red_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Расширение журнала оплат (идемпотентно через процедуру проверки)
SET @db := DATABASE();

SET @has_pkg := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'subscription_payment_log' AND COLUMN_NAME = 'package_id'
);
SET @sql := IF(@has_pkg = 0,
  'ALTER TABLE subscription_payment_log ADD COLUMN package_id INT NULL AFTER days_added',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_promo := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'subscription_payment_log' AND COLUMN_NAME = 'promo_code'
);
SET @sql := IF(@has_promo = 0,
  'ALTER TABLE subscription_payment_log ADD COLUMN promo_code VARCHAR(64) NULL AFTER package_id',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_disc := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'subscription_payment_log' AND COLUMN_NAME = 'discount_rub'
);
SET @sql := IF(@has_disc = 0,
  'ALTER TABLE subscription_payment_log ADD COLUMN discount_rub INT NOT NULL DEFAULT 0 AFTER promo_code',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Сиды пакетов из текущего тарифа (или дефолт 300₽ / 30 дн.)
INSERT INTO subscription_packages (code, title, days, price_rub, sort_order, is_active)
SELECT 'month', 'Месяц', 30,
       COALESCE((SELECT price_rub FROM subscription_config WHERE is_active = 1 ORDER BY id DESC LIMIT 1), 300),
       10, 1
WHERE NOT EXISTS (SELECT 1 FROM subscription_packages WHERE code = 'month');

INSERT INTO subscription_packages (code, title, days, price_rub, sort_order, is_active)
SELECT 'quarter', 'Квартал', 90,
       ROUND(COALESCE((SELECT price_rub FROM subscription_config WHERE is_active = 1 ORDER BY id DESC LIMIT 1), 300) * 2.5),
       20, 1
WHERE NOT EXISTS (SELECT 1 FROM subscription_packages WHERE code = 'quarter');

INSERT INTO subscription_packages (code, title, days, price_rub, sort_order, is_active)
SELECT 'year', 'Год', 365,
       COALESCE((SELECT price_rub FROM subscription_config WHERE is_active = 1 ORDER BY id DESC LIMIT 1), 300) * 8,
       30, 1
WHERE NOT EXISTS (SELECT 1 FROM subscription_packages WHERE code = 'year');
