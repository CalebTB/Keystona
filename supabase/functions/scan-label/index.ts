import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ScanRequest {
  imageBase64: string;
  mimeType: "image/jpeg" | "image/png" | "image/heic" | "image/webp";
  formType?: "system" | "appliance"; // determines which category list to use
}

interface LabelScanResult {
  brand: string | null;
  modelNumber: string | null;
  serialNumber: string | null;
  name: string | null;
  manufactureDate: string | null; // "YYYY-MM" or "YYYY"
  estimatedYear: number | null;
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

    // ── Parse request ────────────────────────────────────────────────────────
    const body: ScanRequest = await req.json();
    if (!body.imageBase64 || !body.mimeType) {
      return new Response(
        JSON.stringify({ error: "imageBase64 and mimeType are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Call Claude Vision ───────────────────────────────────────────────────
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicKey) {
      return new Response(
        JSON.stringify({ error: "ANTHROPIC_API_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const claudeRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-opus-4-8",
        max_tokens: 768,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: body.mimeType,
                  data: body.imageBase64,
                },
              },
              {
                type: "text",
                text: body.formType === "appliance"
  ? `You are reading a home appliance label. Extract what you can see AND use your knowledge of the brand/model to estimate lifespan and replacement cost. Return ONLY a valid JSON object — no explanation, no markdown, just the JSON.

{
  "brand": "manufacturer or brand name",
  "modelNumber": "model number (look for MOD, MODEL, M/N)",
  "serialNumber": "serial number (look for SER, SERIAL, S/N)",
  "name": "product type (e.g. 'Refrigerator', 'Washing Machine', 'Dishwasher')",
  "manufactureDate": "YYYY-MM or YYYY from label (look for MFG DATE, DATE, DOM), or null",
  "estimatedYear": manufacture year as integer or null,
  "category": "one of exactly: kitchen, laundry, climate, cleaning, outdoor, bathroom, other",
  "estimatedLifespanYears": typical lifespan in years as integer (e.g. fridge=13, washer=11, dishwasher=10, dryer=13),
  "estimatedReplacementCostUsd": rough mid-range replacement cost in USD as integer (e.g. fridge=1200, washer=800, dishwasher=700),
  "notes": "key specs from the label: capacity, voltage, amperage, Energy Star rating, refrigerant type, etc. — one concise sentence, or null if nothing notable"
}

Categories: kitchen=fridge/freezer/dishwasher/oven/microwave; laundry=washer/dryer; climate=AC/heater/air purifier; cleaning=vacuum; outdoor=mower/generator; bathroom=personal care appliances.
Be precise copying model and serial numbers.`
  : `You are reading a home system label. Extract what you can see AND use your knowledge of the brand/model to estimate lifespan and replacement cost. Return ONLY a valid JSON object — no explanation, no markdown, just the JSON.

{
  "brand": "manufacturer or brand name",
  "modelNumber": "model number (look for MOD, MODEL, M/N)",
  "serialNumber": "serial number (look for SER, SERIAL, S/N)",
  "name": "product type (e.g. 'Central Air Conditioner', 'Water Heater', 'Electrical Panel')",
  "manufactureDate": "YYYY-MM or YYYY from label (look for MFG DATE, DATE, DOM), or null",
  "estimatedYear": manufacture year as integer or null,
  "category": "one of exactly: hvac, plumbing, electrical, roofing, foundation, siding, windows_doors, insulation, garage, other",
  "estimatedLifespanYears": typical lifespan in years as integer (e.g. AC=15, furnace=20, water_heater=12, panel=35, roof=25),
  "estimatedReplacementCostUsd": rough mid-range replacement cost in USD as integer (e.g. AC=5000, water_heater=1200, panel=3000),
  "notes": "key specs from the label: BTU/tonnage, SEER rating, voltage, amperage, fuel type, tank capacity, etc. — one concise sentence, or null if nothing notable"
}

Categories: hvac=heating/cooling/ventilation; plumbing=water heaters/pumps; electrical=panels/generators; roofing=roof/gutters; garage=doors/openers.
Be precise copying model and serial numbers.`,
              },
            ],
          },
        ],
      }),
    });

    if (!claudeRes.ok) {
      const err = await claudeRes.text();
      console.error("Claude API error:", err);
      return new Response(
        JSON.stringify({ error: "Vision API error" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const claudeData = await claudeRes.json();
    const rawText: string = claudeData.content?.[0]?.text ?? "{}";

    // Strip any accidental markdown fences
    const cleaned = rawText.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
    const result: LabelScanResult = JSON.parse(cleaned);

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("scan-label error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
