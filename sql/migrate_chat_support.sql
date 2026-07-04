-- Чаты и техподдержка CRG Transp 72
-- Выполнить один раз на БД u2395188_apps

CREATE TABLE IF NOT EXISTS support_tickets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  subject VARCHAR(255) NOT NULL,
  category ENUM('account','ad_moderation','payment','deal_dispute','bug','other') NOT NULL DEFAULT 'other',
  status ENUM('new','assigned','waiting_user','resolved','closed') NOT NULL DEFAULT 'new',
  priority ENUM('normal','high') NOT NULL DEFAULT 'normal',
  assigned_admin_id INT NULL,
  context_json JSON NULL,
  rating TINYINT NULL,
  rating_comment TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  assigned_at DATETIME NULL,
  closed_at DATETIME NULL,
  INDEX idx_support_status_created (status, created_at),
  INDEX idx_support_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS chat_threads (
  id INT AUTO_INCREMENT PRIMARY KEY,
  type ENUM('deal','support') NOT NULL,
  status ENUM('draft','active','readonly','closed') NOT NULL DEFAULT 'draft',
  user_id_customer INT NULL,
  user_id_performer INT NULL,
  bd TINYINT NULL,
  ad_id INT NULL,
  offer_data_id INT NULL,
  order_global_id INT NULL,
  support_ticket_id INT NULL,
  last_message_at DATETIME NULL,
  last_message_preview VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_threads_customer (user_id_customer, last_message_at),
  INDEX idx_threads_performer (user_id_performer, last_message_at),
  INDEX idx_threads_support (support_ticket_id),
  UNIQUE KEY uq_deal_pair (type, bd, ad_id, user_id_customer, user_id_performer)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS chat_messages (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  thread_id INT NOT NULL,
  sender_type ENUM('user','admin','system') NOT NULL,
  sender_user_id INT NULL,
  sender_admin_id INT NULL,
  body TEXT NOT NULL,
  attachment_path VARCHAR(512) NULL,
  read_at DATETIME NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_messages_thread (thread_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS chat_read_state (
  thread_id INT NOT NULL,
  user_id INT NOT NULL,
  last_read_message_id BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (thread_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
