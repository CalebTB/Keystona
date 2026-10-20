-- Follow-up to 20261020130000_home_profile_gaps.sql (found by the commit
-- security review).
--
-- The UPDATE policy only re-checked the property, not the item, so a user could
-- edit their own log row to point at ANOTHER user's system/appliance. And
-- neither policy checked document_id, so a row could point at another user's
-- document. The attacker could not read anything of the victim's (rows are
-- selected by user_id), but the foreign key error would reveal whether an id
-- exists, and the row would be deleted along with the victim's system.
--
-- Both write policies now prove ownership of the property, the item AND the
-- linked document (when there is one).

DROP POLICY IF EXISTS "Users can insert own item service log" ON item_service_log;
DROP POLICY IF EXISTS "Users can update own item service log" ON item_service_log;

CREATE POLICY "Users can insert own item service log"
  ON item_service_log FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
    AND (
      (system_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM systems s
        WHERE s.id = item_service_log.system_id
          AND s.user_id = auth.uid()
          AND s.property_id = item_service_log.property_id))
      OR
      (appliance_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM appliances a
        WHERE a.id = item_service_log.appliance_id
          AND a.user_id = auth.uid()
          AND a.property_id = item_service_log.property_id))
    )
    AND (document_id IS NULL OR EXISTS (
      SELECT 1 FROM documents d
      WHERE d.id = item_service_log.document_id AND d.user_id = auth.uid()))
  );

CREATE POLICY "Users can update own item service log"
  ON item_service_log FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
    AND (
      (system_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM systems s
        WHERE s.id = item_service_log.system_id
          AND s.user_id = auth.uid()
          AND s.property_id = item_service_log.property_id))
      OR
      (appliance_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM appliances a
        WHERE a.id = item_service_log.appliance_id
          AND a.user_id = auth.uid()
          AND a.property_id = item_service_log.property_id))
    )
    AND (document_id IS NULL OR EXISTS (
      SELECT 1 FROM documents d
      WHERE d.id = item_service_log.document_id AND d.user_id = auth.uid()))
  );

-- ROLLBACK (not executed): restore the policies from 20261020130000.
