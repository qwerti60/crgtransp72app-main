-- Отзывы: один отзыв на пару автор → получатель.
-- reviewsisp: user_id = исполнитель, target_user_id = заказчик (автор).
-- reviews: user_id = исполнитель (автор), target_user_id = заказчик.

DELETE r1 FROM reviewsisp r1
INNER JOIN reviewsisp r2
  ON r1.user_id = r2.user_id
 AND r1.target_user_id = r2.target_user_id
 AND r1.id < r2.id;

DELETE r1 FROM reviews r1
INNER JOIN reviews r2
  ON r1.user_id = r2.user_id
 AND r1.target_user_id = r2.target_user_id
 AND r1.id < r2.id;

-- Некорректные строки, где автор и получатель совпали (старый баг save_reviewzaka).
DELETE FROM reviewsisp WHERE user_id = target_user_id;

ALTER TABLE reviewsisp
  ADD UNIQUE KEY uq_reviewsisp_performer_customer (user_id, target_user_id);

ALTER TABLE reviews
  ADD UNIQUE KEY uq_reviews_performer_customer (user_id, target_user_id);
