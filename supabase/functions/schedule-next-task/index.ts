import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function computeNextDueDate(currentDueDate: string, recurrence: string): string {
  // Parse as UTC midnight to avoid timezone drift
  const date = new Date(currentDueDate + "T00:00:00Z");

  switch (recurrence) {
    case "weekly":
      date.setUTCDate(date.getUTCDate() + 7);
      break;
    case "biweekly":
      date.setUTCDate(date.getUTCDate() + 14);
      break;
    case "monthly":
      date.setUTCMonth(date.getUTCMonth() + 1);
      break;
    case "quarterly":
      date.setUTCMonth(date.getUTCMonth() + 3);
      break;
    case "biannual":
      date.setUTCMonth(date.getUTCMonth() + 6);
      break;
    case "annual":
      date.setUTCFullYear(date.getUTCFullYear() + 1);
      break;
    default:
      break;
  }

  return date.toISOString().split("T")[0];
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
    const taskId: string | undefined = body?.task_id;
    if (!taskId) {
      return new Response(
        JSON.stringify({ error: "task_id is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 3: Fetch task and verify ownership
    const { data: task, error: taskError } = await supabase
      .from("maintenance_tasks")
      .select(
        "id, property_id, user_id, template_id, task_origin, name, description, instructions, category, linked_system_id, linked_appliance_id, due_date, recurrence, season, climate_adjusted, difficulty, diy_or_pro, priority, estimated_minutes, tools_needed, supplies_needed, reminder_days_before, notifications_enabled"
      )
      .eq("id", taskId)
      .eq("user_id", user.id)
      .is("deleted_at", null)
      .maybeSingle();

    if (taskError || !task) {
      return new Response(
        JSON.stringify({ error: "Task not found or access denied" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 4: Non-recurring tasks get no next occurrence
    if (!task.recurrence || task.recurrence === "none") {
      return new Response(
        JSON.stringify({ scheduled: false, reason: "non_recurring" }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 5: Compute next due date
    const nextDueDate = computeNextDueDate(task.due_date, task.recurrence);

    // Step 6: Insert next occurrence
    const { data: nextTask, error: insertError } = await supabase
      .from("maintenance_tasks")
      .insert({
        property_id: task.property_id,
        user_id: task.user_id,
        template_id: task.template_id,
        task_origin: task.task_origin,
        name: task.name,
        description: task.description,
        instructions: task.instructions,
        category: task.category,
        linked_system_id: task.linked_system_id,
        linked_appliance_id: task.linked_appliance_id,
        due_date: nextDueDate,
        recurrence: task.recurrence,
        season: task.season,
        climate_adjusted: task.climate_adjusted,
        status: "scheduled",
        difficulty: task.difficulty,
        diy_or_pro: task.diy_or_pro,
        priority: task.priority,
        estimated_minutes: task.estimated_minutes,
        tools_needed: task.tools_needed ?? [],
        supplies_needed: task.supplies_needed ?? [],
        reminder_days_before: task.reminder_days_before ?? 7,
        notifications_enabled: task.notifications_enabled ?? true,
        reminded_7day: false,
        reminded_1day: false,
      })
      .select("id, due_date")
      .single();

    if (insertError || !nextTask) {
      throw new Error(`Failed to schedule next task: ${insertError?.message}`);
    }

    console.log(`Scheduled next task for recurrence type: ${task.recurrence}`);

    return new Response(
      JSON.stringify({
        scheduled: true,
        next_task_id: nextTask.id,
        next_due_date: nextTask.due_date,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Schedule next task error:", (error as Error).message);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
