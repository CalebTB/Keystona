-- ============================================================
-- RPC: get_system_lifespan_overview
-- Returns calculated lifespan fields per system for a property.
-- SECURITY DEFINER: verifies property ownership before any data read.
-- ============================================================

CREATE OR REPLACE FUNCTION get_system_lifespan_overview(p_property_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  category system_category,
  system_type TEXT,
  installation_date DATE,
  age_years NUMERIC,
  lifespan_min SMALLINT,
  lifespan_max SMALLINT,
  lifespan_percentage NUMERIC,
  health_status TEXT,
  estimated_replacement_cost NUMERIC,
  years_until_replacement_min NUMERIC,
  years_until_replacement_max NUMERIC
) AS $$
BEGIN
  -- Verify that the calling user owns this property.
  IF NOT EXISTS (
    SELECT 1 FROM properties
    WHERE properties.id = p_property_id
      AND properties.user_id = auth.uid()
      AND properties.deleted_at IS NULL
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    s.id,
    s.name,
    s.category,
    s.system_type,
    s.installation_date,
    ROUND(
      EXTRACT(EPOCH FROM (NOW() - s.installation_date::TIMESTAMPTZ)) / 31557600.0,
      1
    ) AS age_years,
    COALESCE(s.lifespan_override, s.expected_lifespan_min)::SMALLINT AS lifespan_min,
    COALESCE(s.lifespan_override, s.expected_lifespan_max)::SMALLINT AS lifespan_max,
    CASE
      WHEN s.installation_date IS NOT NULL
        AND ((COALESCE(s.lifespan_override, s.expected_lifespan_min) + COALESCE(s.lifespan_override, s.expected_lifespan_max)) / 2.0) > 0
      THEN
        ROUND(
          EXTRACT(EPOCH FROM (NOW() - s.installation_date::TIMESTAMPTZ)) / 31557600.0
          / ((COALESCE(s.lifespan_override, s.expected_lifespan_min) + COALESCE(s.lifespan_override, s.expected_lifespan_max)) / 2.0)
          * 100.0,
          0
        )
      ELSE NULL
    END AS lifespan_percentage,
    CASE
      WHEN s.installation_date IS NULL
        OR COALESCE(s.lifespan_override, s.expected_lifespan_max) IS NULL THEN 'unknown'
      WHEN EXTRACT(EPOCH FROM (NOW() - s.installation_date::TIMESTAMPTZ)) / 31557600.0
           >= COALESCE(s.lifespan_override, s.expected_lifespan_max)::NUMERIC THEN 'end_of_life'
      WHEN EXTRACT(EPOCH FROM (NOW() - s.installation_date::TIMESTAMPTZ)) / 31557600.0
           >= COALESCE(s.lifespan_override, s.expected_lifespan_min)::NUMERIC * 0.75 THEN 'aging'
      ELSE 'healthy'
    END AS health_status,
    s.estimated_replacement_cost,
    CASE
      WHEN s.installation_date IS NULL OR COALESCE(s.lifespan_override, s.expected_lifespan_min) IS NULL THEN NULL
      ELSE GREATEST(
        0,
        COALESCE(s.lifespan_override, s.expected_lifespan_min)::NUMERIC
          - EXTRACT(EPOCH FROM (NOW() - s.installation_date::TIMESTAMPTZ)) / 31557600.0
      )
    END AS years_until_replacement_min,
    CASE
      WHEN s.installation_date IS NULL OR COALESCE(s.lifespan_override, s.expected_lifespan_max) IS NULL THEN NULL
      ELSE GREATEST(
        0,
        COALESCE(s.lifespan_override, s.expected_lifespan_max)::NUMERIC
          - EXTRACT(EPOCH FROM (NOW() - s.installation_date::TIMESTAMPTZ)) / 31557600.0
      )
    END AS years_until_replacement_max
  FROM systems s
  WHERE s.property_id = p_property_id
    AND s.deleted_at IS NULL
    AND s.status = 'active'
  ORDER BY
    CASE health_status
      WHEN 'end_of_life' THEN 0
      WHEN 'aging'       THEN 1
      WHEN 'healthy'     THEN 2
      ELSE 3
    END ASC,
    lifespan_percentage DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution to authenticated users.
GRANT EXECUTE ON FUNCTION get_system_lifespan_overview(UUID) TO authenticated;
