-- После импорта CREATE+INSERT из prod-дампа у vidt/vidg/gruzchik нет AUTO_INCREMENT.
-- Запуск: mysql --default-character-set=utf8mb4 -u root crg_local < sql/fix_ref_autoincrement.sql

SET @tables = 'vidt,vidg,gruzchik';

-- vidt
ALTER TABLE `vidt` ADD PRIMARY KEY (`id`);
ALTER TABLE `vidt` MODIFY `id` INT NOT NULL AUTO_INCREMENT;
SET @ai = (SELECT COALESCE(MAX(`id`), 0) + 1 FROM `vidt`);
SET @sql = CONCAT('ALTER TABLE `vidt` AUTO_INCREMENT = ', @ai);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- vidg
ALTER TABLE `vidg` ADD PRIMARY KEY (`id`);
ALTER TABLE `vidg` MODIFY `id` INT NOT NULL AUTO_INCREMENT;
SET @ai = (SELECT COALESCE(MAX(`id`), 0) + 1 FROM `vidg`);
SET @sql = CONCAT('ALTER TABLE `vidg` AUTO_INCREMENT = ', @ai);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- gruzchik
ALTER TABLE `gruzchik` ADD PRIMARY KEY (`id`);
ALTER TABLE `gruzchik` MODIFY `id` INT NOT NULL AUTO_INCREMENT;
SET @ai = (SELECT COALESCE(MAX(`id`), 0) + 1 FROM `gruzchik`);
SET @sql = CONCAT('ALTER TABLE `gruzchik` AUTO_INCREMENT = ', @ai);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
