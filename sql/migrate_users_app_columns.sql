-- Колонки users, нужные мобильному приложению (после импорта crg_app_deploy.sql).
-- mysql --default-character-set=utf8mb4 -u USER -p DB_NAME < sql/migrate_users_app_columns.sql

SET @exist := (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'payment'
);
SET @sqlstmt := IF(
    @exist = 0,
    "ALTER TABLE users ADD COLUMN payment VARCHAR(255) NOT NULL DEFAULT 'За час' AFTER flag",
    "SELECT 'users.payment уже есть' AS migrate_users_app_columns"
);
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @exist := (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'typepayment'
);
SET @sqlstmt := IF(
    @exist = 0,
    "ALTER TABLE users ADD COLUMN typepayment VARCHAR(255) NOT NULL DEFAULT 'Наличными' AFTER payment",
    "SELECT 'users.typepayment уже есть' AS migrate_users_app_columns"
);
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @exist := (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'fcm_token'
);
SET @sqlstmt := IF(
    @exist = 0,
    'ALTER TABLE users ADD COLUMN fcm_token VARCHAR(255) NOT NULL DEFAULT \'\' AFTER typepayment',
    "SELECT 'users.fcm_token уже есть' AS migrate_users_app_columns"
);
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
