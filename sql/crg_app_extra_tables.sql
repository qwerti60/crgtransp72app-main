-- Пустые таблицы приложения, которых нет в crg_local, но нужны API на production.
-- Подключается в конец дампа crg_app_deploy.sql

CREATE TABLE IF NOT EXISTS `ordersglobal` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` varchar(255) NOT NULL COMMENT 'ID пользователя',
  `order_id` varchar(255) NOT NULL COMMENT 'ID заказа',
  `user_idok` varchar(255) NOT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `cancel_time` datetime DEFAULT NULL,
  `status` enum('выполняется','выполнен','отменен') DEFAULT NULL,
  `idoffer` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `likes` (
  `ids` int(11) NOT NULL AUTO_INCREMENT,
  `idusers` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `bd` varchar(255) NOT NULL,
  `usersid` int(11) NOT NULL,
  PRIMARY KEY (`ids`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `likes1` (
  `ids` int(11) NOT NULL AUTO_INCREMENT,
  `idusers` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `bd` varchar(255) NOT NULL,
  `usersid` int(11) NOT NULL,
  PRIMARY KEY (`ids`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `password_resets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(100) NOT NULL,
  `code` varchar(6) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `email_verification_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(100) NOT NULL,
  `code` varchar(6) NOT NULL,
  `purpose` varchar(32) NOT NULL,
  `expires_at` datetime NOT NULL,
  `verified` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
