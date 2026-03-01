import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Season → default target month (1-indexed)
const SEASON_DEFAULT_MONTH: Record<string, number> = {
  spring: 4,
  summer: 7,
  fall: 10,
  winter: 12,
};

interface Template {
  id: string;
  name: string;
  description: string | null;
  instructions: string | null;
  category: string;
  season: string | null;
  recurrence: string;
  default_month: number | null;
  difficulty: string;
  diy_or_pro: string;
  priority: string;
  estimated_minutes: number | null;
  tools_needed: unknown[];
  supplies_needed: unknown[];
  climate_zones: number[] | null;
  system_category: string | null;
  appliance_type: string | null;
}

function computeDueDate(template: Template, today: Date): string {
  const currentYear = today.getUTCFullYear();
  const currentMonth = today.getUTCMonth() + 1; // 1-indexed

  // Monthly recurring with no season → due next month
  if (template.recurrence === "monthly" && !template.season) {
    const nextMonth = new Date(today);
    nextMonth.setUTCMonth(nextMonth.getUTCMonth() + 1);
    nextMonth.setUTCDate(1);
    return nextMonth.toISOString().split("T")[0];
  }

  // Determine target month
  const targetMonth =
    template.default_month ??
    (template.season ? SEASON_DEFAULT_MONTH[template.season] : currentMonth);

  // Roll to next year if the month has already passed this year
  const targetYear = targetMonth < currentMonth ? currentYear + 1 : currentYear;

  return `${targetYear}-${String(targetMonth).padStart(2, "0")}-01`;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Step 1: Verify JWT
    const authHeader = req.headers.get("Authorization");
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } }
    );

    const token = authHeader?.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    // Step 2: Parse and validate body
    const body = await req.json();
    const propertyId: string | undefined = body?.property_id;
    if (!propertyId) {
      return new Response(
        JSON.stringify({ error: "property_id is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 3: Fetch property — verify ownership and get climate_zone
    const { data: property, error: propError } = await supabase
      .from("properties")
      .select("id, user_id, climate_zone")
      .eq("id", propertyId)
      .eq("user_id", user.id)
      .is("deleted_at", null)
      .maybeSingle();

    if (propError || !property) {
      return new Response(
        JSON.stringify({ error: "Property not found or access denied" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const climateZone: number | null = body?.climate_zone ?? property.climate_zone;

    // Step 4: Idempotency — skip if template-generated tasks already exist
    const { count } = await supabase
      .from("maintenance_tasks")
      .select("id", { count: "exact", head: true })
      .eq("property_id", propertyId)
      .not("template_id", "is", null)
      .is("deleted_at", null);

    if ((count ?? 0) > 0) {
      console.log("Tasks already generated for property — skipping");
      return new Response(
        JSON.stringify({ tasks_created: 0, already_generated: true }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 5: Fetch all active templates
    const { data: templates, error: tmplError } = await supabase
      .from("maintenance_task_templates")
      .select(
        "id, name, description, instructions, category, season, recurrence, default_month, difficulty, diy_or_pro, priority, estimated_minutes, tools_needed, supplies_needed, climate_zones, system_category, appliance_type"
      )
      .eq("is_active", true);

    if (tmplError || !templates) {
      throw new Error("Failed to fetch templates");
    }

    // Step 6: Filter by climate zone (null = applies to all zones)
    const filtered: Template[] = climateZone
      ? templates.filter(
          (t: Template) =>
            t.climate_zones === null || t.climate_zones.includes(climateZone)
        )
      : templates;

    if (filtered.length === 0) {
      return new Response(
        JSON.stringify({ tasks_created: 0, already_generated: false }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 7: Build task rows
    const today = new Date();
    const taskRows = filtered.map((t: Template) => ({
      property_id: propertyId,
      user_id: user.id,
      template_id: t.id,
      task_origin: "system_generated",
      name: t.name,
      description: t.description,
      instructions: t.instructions,
      category: t.category,
      linked_system_id: null,
      linked_appliance_id: null,
      due_date: computeDueDate(t, today),
      recurrence: t.recurrence,
      season: t.season,
      climate_adjusted: climateZone !== null,
      status: "scheduled",
      difficulty: t.difficulty,
      diy_or_pro: t.diy_or_pro,
      priority: t.priority,
      estimated_minutes: t.estimated_minutes,
      tools_needed: t.tools_needed ?? [],
      supplies_needed: t.supplies_needed ?? [],
      reminder_days_before: 7,
      notifications_enabled: true,
    }));

    // Step 8: Bulk insert
    const { error: insertError } = await supabase
      .from("maintenance_tasks")
      .insert(taskRows);

    if (insertError) {
      throw new Error(`Insert failed: ${insertError.message}`);
    }

    // Count by category (no PII — just category labels and counts)
    const categories: Record<string, number> = {};
    for (const t of filtered) {
      categories[t.category] = (categories[t.category] ?? 0) + 1;
    }

    console.log(`Generated ${taskRows.length} tasks`);

    return new Response(
      JSON.stringify({ tasks_created: taskRows.length, categories }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Task generation error:", (error as Error).message);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
