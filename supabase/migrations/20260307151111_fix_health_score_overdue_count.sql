CREATE OR REPLACE FUNCTION get_home_health_score(p_property_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id         UUID := auth.uid();
  v_on_time_12mo    INT := 0;
  v_late_12mo       INT := 0;
  v_overdue_12mo    INT := 0;
  v_upcoming        INT := 0;
  v_total_relevant  INT;
  v_completed_pts   NUMERIC;
  v_base_ratio      NUMERIC;
  v_penalty         INT;
  v_score           INT;

  v_on_time_curr    INT := 0;
  v_late_curr       INT := 0;
  v_overdue_curr    INT := 0;
  v_total_curr      INT;
  v_score_curr      NUMERIC;

  v_on_time_prev    INT := 0;
  v_late_prev       INT := 0;
  v_overdue_prev    INT := 0;
  v_total_prev      INT;
  v_score_prev      NUMERIC;

  v_trend           TEXT;
  v_delta           NUMERIC;
BEGIN
  -- Security: verify property belongs to authenticated user.
  IF NOT EXISTS (
    SELECT 1 FROM properties
    WHERE id = p_property_id AND user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Property not found or access denied';
  END IF;

  -- On time: completed, completion date <= due date (12-month window)
  SELECT COUNT(DISTINCT t.id) INTO v_on_time_12mo
  FROM maintenance_tasks t
  JOIN task_completions c ON c.task_id = t.id
  WHERE t.property_id = p_property_id
    AND t.deleted_at IS NULL
    AND t.status = 'completed'
    AND t.due_date >= (CURRENT_DATE - INTERVAL '12 months')
    AND c.completed_date <= t.due_date;

  -- Late: completed, completion date > due date (12-month window)
  SELECT COUNT(DISTINCT t.id) INTO v_late_12mo
  FROM maintenance_tasks t
  JOIN task_completions c ON c.task_id = t.id
  WHERE t.property_id = p_property_id
    AND t.deleted_at IS NULL
    AND t.status = 'completed'
    AND t.due_date >= (CURRENT_DATE - INTERVAL '12 months')
    AND c.completed_date > t.due_date;

  -- Overdue: status = overdue OR (status in scheduled/due AND past due date).
  -- Matches the same logic the Flutter app uses to classify tasks as overdue.
  SELECT COUNT(*) INTO v_overdue_12mo
  FROM maintenance_tasks t
  WHERE t.property_id = p_property_id
    AND t.deleted_at IS NULL
    AND t.due_date >= (CURRENT_DATE - INTERVAL '12 months')
    AND t.due_date < CURRENT_DATE
    AND t.status NOT IN ('completed', 'skipped')
    AND t.id NOT IN (SELECT task_id FROM task_completions WHERE task_id = t.id);

  -- Upcoming: future-due scheduled/due tasks
  SELECT COUNT(*) INTO v_upcoming
  FROM maintenance_tasks t
  WHERE t.property_id = p_property_id
    AND t.deleted_at IS NULL
    AND t.status IN ('scheduled', 'due')
    AND t.due_date >= CURRENT_DATE;

  -- Compute 12-month score
  v_total_relevant := v_on_time_12mo + v_late_12mo + v_overdue_12mo;

  IF v_total_relevant = 0 THEN
    v_score := 100;
  ELSE
    v_completed_pts := (v_on_time_12mo::NUMERIC) + (v_late_12mo::NUMERIC * 0.5);
    v_base_ratio    := v_completed_pts / v_total_relevant;
    v_penalty       := v_overdue_12mo * 5;
    v_score         := GREATEST(0, ROUND((v_base_ratio * 100) - v_penalty)::INT);
  END IF;

  -- Current period (last 30 days)
  SELECT COUNT(DISTINCT t.id) INTO v_on_time_curr
  FROM maintenance_tasks t
  JOIN task_completions c ON c.task_id = t.id
  WHERE t.property_id = p_property_id
    AND t.deleted_at IS NULL
    AND t.status = 'completed'
    AND t.due_date >= (CURRENT_DATE - INTERVAL '30 days')
    AND t.due_date < CURRENT_DATE
    AND c.completed_date <= t.due_date;

  SELECT COUNT(DISTINCT t.id) INTO v_late_curr
  FROM maintenance_tasks t
  JOIN task_completions c ON c.task_id = t.id
  WHERE t.property_id = p_property_id
    AND t.deleted_at IS NULL
    AND t.status = 'completed'
    AND t.due_date >= (CURRENT_DATE - INTERVAL '30 days')
    AND t.due_date < CURRENT_DATE
    AND c.completed_date > t.due_date;

  SELECT COUNT(*) INTO v_overdue_curr
  FROM maintenance_tasks t
  WHERE t.property_id = p_property_id
    AND t.deleted_at IS NULL
    AND t.due_date >= (CURRENT_DATE - INTERVAL '30 days')
    AND t.due_date < CURRENT_DATE
    AND t.status NOT IN ('completed', 'skipped')
    AND t.id NOT IN (SELECT task_id FROM task_completions WHERE task_id = t.id);

  v_total_curr := v_on_time_curr + v_late_curr + v_overdue_curr;

  IF v_total_curr = 0 THEN
    v_score_curr := 100;
  ELSE
    v_score_curr := GREATEST(0::NUMERIC,
      (((v_on_time_curr::NUMERIC) + (v_late_curr::NUMERIC * 0.5)) / v_total_curr * 100)
      - (v_overdue_curr * 5)
    );
  END IF;

  -- Prior period (31-60 days ago)
  SELECT COUNT(DISTINCT t.id) INTO v_on_time_prev
  FROM maintenance_tasks t
  JOIN task_completions c ON c.task_id = t.id
  WHERE t.property_id = p_property_id
    AND t.deleted_at IS NULL
    AND t.status = 'completed'
    AND t.due_date >= (CURRENT_DATE - INTERVAL '60 days')
    AND t.due_date < (CURRENT_DATE - INTERVAL '30 days')
    AND c.completed_date <= t.due_date;

  SELECT COUNT(DISTINCT t.id) INTO v_late_prev
  FROM maintenance_tasks t
  JOIN task_completions c ON c.task_id = t.id
  WHERE t.property_id = p_property_id
    AND t.deleted_at IS NULL
    AND t.status = 'completed'
    AND t.due_date >= (CURRENT_DATE - INTERVAL '60 days')
    AND t.due_date < (CURRENT_DATE - INTERVAL '30 days')
    AND c.completed_date > t.due_date;

  SELECT COUNT(*) INTO v_overdue_prev
  FROM maintenance_tasks t
  WHERE t.property_id = p_property_id
    AND t.deleted_at IS NULL
    AND t.due_date >= (CURRENT_DATE - INTERVAL '60 days')
    AND t.due_date < (CURRENT_DATE - INTERVAL '30 days')
    AND t.status NOT IN ('completed', 'skipped')
    AND t.id NOT IN (SELECT task_id FROM task_completions WHERE task_id = t.id);

  v_total_prev := v_on_time_prev + v_late_prev + v_overdue_prev;

  IF v_total_prev = 0 THEN
    v_score_prev := 100;
  ELSE
    v_score_prev := GREATEST(0::NUMERIC,
      (((v_on_time_prev::NUMERIC) + (v_late_prev::NUMERIC * 0.5)) / v_total_prev * 100)
      - (v_overdue_prev * 5)
    );
  END IF;

  -- Trend
  v_delta := v_score_curr - v_score_prev;

  IF v_delta > 5 THEN
    v_trend := 'improving';
  ELSIF v_delta < -5 THEN
    v_trend := 'declining';
  ELSE
    v_trend := 'stable';
  END IF;

  RETURN json_build_object(
    'score',       v_score,
    'trend',       v_trend,
    'total_tasks', v_total_relevant,
    'completed',   v_on_time_12mo + v_late_12mo,
    'overdue',     v_overdue_12mo,
    'upcoming',    v_upcoming
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_home_health_score(UUID) TO authenticated;
