-- P3: B2B-счета, автомодерация, экспорт CSV (схема)
-- Выполнить один раз на БД приложения

SET @db := DATABASE();

-- Стоп-слова для автомодерации объявлений исполнителей
CREATE TABLE IF NOT EXISTS moderation_stop_words (
  id INT NOT NULL AUTO_INCREMENT,
  word VARCHAR(128) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_mod_stop_word (word)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO moderation_stop_words (word, is_active)
SELECT 'казино', 1 WHERE NOT EXISTS (SELECT 1 FROM moderation_stop_words WHERE word = 'казино');
INSERT INTO moderation_stop_words (word, is_active)
SELECT 'наркотик', 1 WHERE NOT EXISTS (SELECT 1 FROM moderation_stop_words WHERE word = 'наркотик');
INSERT INTO moderation_stop_words (word, is_active)
SELECT '18+', 1 WHERE NOT EXISTS (SELECT 1 FROM moderation_stop_words WHERE word = '18+');

-- Журнал срабатываний автомодерации
CREATE TABLE IF NOT EXISTS moderation_log (
  id INT NOT NULL AUTO_INCREMENT,
  ad_table VARCHAR(32) NOT NULL,
  ad_id INT NOT NULL,
  user_id INT NOT NULL,
  rule_code VARCHAR(32) NOT NULL,
  action VARCHAR(16) NOT NULL DEFAULT 'queue',
  detail TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_mod_log_ad (ad_table, ad_id),
  KEY idx_mod_log_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Заявки на счёт для юрлиц (подписка)
CREATE TABLE IF NOT EXISTS subscription_invoice_requests (
  id INT NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  package_id INT NULL,
  days INT NOT NULL DEFAULT 30,
  amount_rub INT NOT NULL DEFAULT 0,
  discount_rub INT NOT NULL DEFAULT 0,
  promo_code VARCHAR(64) NULL,
  company_name VARCHAR(255) NOT NULL DEFAULT '',
  inn VARCHAR(32) NOT NULL DEFAULT '',
  kpp VARCHAR(32) NULL,
  ogrn VARCHAR(32) NULL,
  status ENUM('requested','issued','paid','cancelled') NOT NULL DEFAULT 'requested',
  invoice_number VARCHAR(64) NULL,
  admin_note TEXT NULL,
  issued_at DATETIME NULL,
  paid_at DATETIME NULL,
  payment_order_id VARCHAR(128) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_inv_user (user_id),
  KEY idx_inv_status (status),
  KEY idx_inv_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Способ оплаты в журнале подписок
SET @has_pm := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'subscription_payment_log' AND COLUMN_NAME = 'payment_method'
);
SET @sql := IF(@has_pm = 0,
  "ALTER TABLE subscription_payment_log ADD COLUMN payment_method VARCHAR(16) NULL DEFAULT 'card' AFTER discount_rub",
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
