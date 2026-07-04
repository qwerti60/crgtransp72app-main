-- Вложения в chat_messages (изображения и документы)
-- Выполнить один раз после migrate_chat_support.sql

ALTER TABLE chat_messages
  ADD COLUMN attachment_mime VARCHAR(128) NULL AFTER attachment_path,
  ADD COLUMN attachment_name VARCHAR(255) NULL AFTER attachment_mime;
