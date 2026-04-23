CREATE TABLE IF NOT EXISTS `subscription_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `days` int(11) NOT NULL DEFAULT 30,
  `price_rub` int(11) NOT NULL DEFAULT 300,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `subscription_config` (`days`, `price_rub`, `is_active`)
SELECT 30, 300, 1
WHERE NOT EXISTS (
  SELECT 1 FROM `subscription_config` WHERE `is_active` = 1
);
