-- Before / after photos on a task completion.
--
-- The Log screen stored the role in completion_photos.caption ('before' on the
-- first photo, 'after' on the second): a convention, not data the database can
-- check or a query can filter on. Give it a real column.
--
-- Additive. Existing rows whose caption is exactly 'before' or 'after' are
-- copied across; the caption itself is left as it was.

ALTER TABLE completion_photos
  ADD COLUMN IF NOT EXISTS kind TEXT
    CHECK (kind IS NULL OR kind IN ('before', 'after'));

UPDATE completion_photos
SET kind = caption
WHERE kind IS NULL
  AND caption IN ('before', 'after');

-- ROLLBACK (not executed):
-- ALTER TABLE completion_photos DROP COLUMN IF EXISTS kind;
