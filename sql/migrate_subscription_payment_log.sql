-- Журнал оплат подписки исполнителя (история для раздела «Финансы»).
CREATE TABLE IF NOT EXISTS subscription_payment_log (
    id INT NOT NULL AUTO_INCREMENT,
    iduser INT NOT NULL,
    order_id VARCHAR(128) NOT NULL,
    amount_rub INT NOT NULL DEFAULT 0,
    days_added INT NOT NULL DEFAULT 30,
    paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subscription_until DATE NULL,
    PRIMARY KEY (id),
    KEY idx_sub_pay_user (iduser),
    KEY idx_sub_pay_paid (paid_at),
    KEY idx_sub_pay_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
