-- Add uniqueness constraints for stable like toggling.
-- Safe for repeated runs due to IF NOT EXISTS checks.

ALTER TABLE likes
  ADD UNIQUE INDEX uniq_like_triplet (idusers, id, usersid);

ALTER TABLE likes1
  ADD UNIQUE INDEX uniq_like1_triplet (idusers, id, usersid);
