-- Геокоординаты городов для поиска «рядом со мной»
-- Выполнить один раз на БД приложения

ALTER TABLE cities
  ADD COLUMN lat DECIMAL(9,6) NULL AFTER name,
  ADD COLUMN lng DECIMAL(9,6) NULL AFTER lat;

-- Сид координат (Тюмень и населённые пункты области)
UPDATE cities SET lat = 57.152200, lng = 65.527200 WHERE name = 'Тюмень';
UPDATE cities SET lat = 58.198400, lng = 68.251700 WHERE name = 'Тобольск';
UPDATE cities SET lat = 56.101700, lng = 69.484500 WHERE name = 'Ишим';
UPDATE cities SET lat = 56.654700, lng = 66.300600 WHERE name = 'Ялуторовск';
UPDATE cities SET lat = 56.501400, lng = 66.551700 WHERE name = 'Заводоуковск';
UPDATE cities SET lat = 57.000000, lng = 65.550000 WHERE name = 'Винзили';
UPDATE cities SET lat = 56.966700, lng = 65.633300 WHERE name = 'Богандинский';
UPDATE cities SET lat = 57.050000, lng = 65.716700 WHERE name = 'Боровский';
UPDATE cities SET lat = 57.016700, lng = 65.450000 WHERE name = 'Московский';
UPDATE cities SET lat = 56.950000, lng = 65.833300 WHERE name = 'Червишево';
UPDATE cities SET lat = 57.000000, lng = 65.366700 WHERE name = 'Онохино';
UPDATE cities SET lat = 57.116700, lng = 65.383300 WHERE name = 'Каскара';
UPDATE cities SET lat = 57.133300, lng = 65.300000 WHERE name = 'Антипино';
UPDATE cities SET lat = 57.200000, lng = 65.300000 WHERE name = 'Матмассы';
UPDATE cities SET lat = 57.066700, lng = 65.216700 WHERE name = 'Новотарманский';
UPDATE cities SET lat = 57.050000, lng = 65.183300 WHERE name = 'Тарманы';
UPDATE cities SET lat = 56.800000, lng = 65.900000 WHERE name = 'Ярково';
UPDATE cities SET lat = 56.483300, lng = 65.333300 WHERE name = 'Исетское';
UPDATE cities SET lat = 56.416700, lng = 67.583300 WHERE name = 'Омутинское';
UPDATE cities SET lat = 56.400000, lng = 66.366700 WHERE name = 'Новая Заимка';
UPDATE cities SET lat = 55.850000, lng = 68.700000 WHERE name = 'Голышманово';
UPDATE cities SET lat = 56.366700, lng = 70.183300 WHERE name = 'Абатское';
UPDATE cities SET lat = 55.983300, lng = 67.883300 WHERE name = 'Армизонское';
UPDATE cities SET lat = 56.866700, lng = 68.650000 WHERE name = 'Аромашево';
UPDATE cities SET lat = 57.983300, lng = 69.016700 WHERE name = 'Вагай';
UPDATE cities SET lat = 56.816700, lng = 70.450000 WHERE name = 'Викулово';
UPDATE cities SET lat = 55.683300, lng = 68.300000 WHERE name = 'Бердюжье';
UPDATE cities SET lat = 56.566700, lng = 69.766700 WHERE name = 'Большое Сорокино';
UPDATE cities SET lat = 55.783300, lng = 69.233300 WHERE name = 'Казанское';
UPDATE cities SET lat = 57.350000, lng = 66.166700 WHERE name = 'Нижняя Тавда';
UPDATE cities SET lat = 55.683300, lng = 70.350000 WHERE name = 'Сладково';
UPDATE cities SET lat = 56.316700, lng = 66.500000 WHERE name = 'Новоселезнево';
UPDATE cities SET lat = 58.116700, lng = 68.600000 WHERE name = 'Сумкино';
UPDATE cities SET lat = 59.133300, lng = 68.900000 WHERE name = 'Уват';
UPDATE cities SET lat = 56.183300, lng = 66.266700 WHERE name = 'Упорово';
UPDATE cities SET lat = 57.066700, lng = 65.066700 WHERE name = 'Успенка';
UPDATE cities SET lat = 56.816700, lng = 67.383300 WHERE name = 'Юргинское';
UPDATE cities SET lat = 58.983300, lng = 68.016700 WHERE name = 'Туртас';
UPDATE cities SET lat = 56.550000, lng = 66.083300 WHERE name = 'Заводопетровский';
UPDATE cities SET lat = 56.983300, lng = 65.933300 WHERE name = 'Стрехнино';
UPDATE cities SET lat = 63.683300, lng = 66.600000 WHERE name = 'Белоярский';
UPDATE cities SET lat = 66.550000, lng = 67.800000 WHERE name = 'Аксарка';
