-- Тип сделки и категория (bd) в ordersglobal.
-- Выполнить один раз на production. При повторном запуске игнорировать ошибку «Duplicate column».

ALTER TABLE ordersglobal
  ADD COLUMN deal_source ENUM('customer_order', 'performer_ad') NULL
    COMMENT 'customer_order: order_id = заявка; performer_ad: order_id = объявление исполнителя'
    AFTER order_id;

ALTER TABLE ordersglobal
  ADD COLUMN bd TINYINT NULL
    COMMENT '1 перевозки, 2 спецтехника, 3 грузчики'
    AFTER deal_source;

UPDATE ordersglobal og
INNER JOIN offer_data od ON od.id = og.idoffer
SET og.deal_source = 'customer_order',
    og.bd = od.bd
WHERE og.deal_source IS NULL;

UPDATE ordersglobal og
INNER JOIN offer_dataf odf ON odf.id = og.idoffer
SET og.deal_source = 'performer_ad',
    og.bd = odf.bd
WHERE og.deal_source IS NULL;
