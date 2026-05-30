import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface TaskRequest {
  name: string;
  brand?: string | null;
  modelNumber?: string | null;
  category: string;
  formType: "system" | "appliance";
}

interface SuggestedTask {
  name: string;
  description: string;
  category: string;
  recurrence: "none" | "monthly" | "quarterly" | "biannual" | "annual";
  priority: "low" | "medium" | "high" | "critical";
  diyOrPro: "diy" | "professional";
  estimatedMinutes: number;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Auth ────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } }
    );
    const token = authHeader?.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    const body: TaskRequest = await req.json();

    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicKey) {
      return new Response(
        JSON.stringify({ error: "ANTHROPIC_API_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const itemDesc = [body.brand, body.name, body.modelNumber]
      .filter(Boolean)
      .join(" ");

    const claudeRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: `Generate up to 5 realistic maintenance tasks for a home ${body.formType}: "${itemDesc}" (category: ${body.category}).

Return ONLY a valid JSON array — no explanation, no markdown. Each task:
{
  "name": "short task name (max 50 chars)",
  "description": "one sentence explaining what to do and why",
  "category": "${body.category}",
  "recurrence": "one of: monthly, quarterly, biannual, annual, none",
  "priority": "one of: low, medium, high, critical",
  "diyOrPro": "one of: diy, professional",
  "estimatedMinutes": integer (realistic time to complete)
}

Rules:
- Max 5 tasks, only include genuinely useful recurring maintenance
- Use "professional" only when truly unsafe for DIY (refrigerant, electrical panels)
- Recurrence should match real maintenance schedules (e.g. fridge coils = biannual)
- estimatedMinutes should be realistic (cleaning coils = 30, filter change = 15)
- Do not invent tasks that don't apply to this specific ${body.formType} type`,
          },
        ],
      }),
    });

    if (!claudeRes.ok) {
      console.error("Claude error:", await claudeRes.text());
      return new Response(
        JSON.stringify({ error: "Task generation failed" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const claudeData = await claudeRes.json();
    const rawText: string = claudeData.content?.[0]?.text ?? "[]";
    const cleaned = rawText.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
    const tasks: SuggestedTask[] = JSON.parse(cleaned);

    // Cap at 5 just in case Claude returns more.
    return new Response(JSON.stringify(tasks.slice(0, 5)), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("generate-item-tasks error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
