-- Идемпотентно: таблица admin_accounts и учётка admin по умолчанию.
-- Пароль: ChangeMe_Admin1!  — смените на production.

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
