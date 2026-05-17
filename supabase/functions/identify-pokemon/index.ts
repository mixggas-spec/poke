import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const OLLAMA_CHAT_URL = "https://apichat.epvc.pt/api/chat";
const OLLAMA_MODEL_NAME = "qwen3.6:35b";
const OLLAMA_TIMEOUT_MS = 30_000;
const CONFIDENCE_THRESHOLD = 0.75;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type ScanStatus = "identified" | "not_identified" | "no_pokemon_detected";

interface ScanResponse {
  status: ScanStatus;
  pokedex_number: number | null;
  pokemon_name: string | null;
  confidence: number;
  is_known_pokemon: boolean;
}

interface ModelPayload {
  status?: string;
  pokedex_number?: number | null;
  pokemon_name?: string | null;
  confidence?: number;
  is_known_pokemon?: boolean;
}

interface CatalogRow {
  pokedex_number: number;
  name: string;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function errorResponse(): Response {
  return jsonResponse(
    { error: "Something went wrong. Please try again." },
    500,
  );
}

function parseModelContent(content: string): ModelPayload {
  const trimmed = content.trim();
  try {
    return JSON.parse(trimmed) as ModelPayload;
  } catch {
    const match = trimmed.match(/\{[\s\S]*\}/);
    if (!match) {
      throw new Error("Model response is not valid JSON.");
    }
    return JSON.parse(match[0]) as ModelPayload;
  }
}

function buildScanResponse(
  model: ModelPayload,
  catalogRow: CatalogRow | null,
): ScanResponse {
  const confidence = typeof model.confidence === "number"
    ? Math.max(0, Math.min(1, model.confidence))
    : 0;

  const rawName = typeof model.pokemon_name === "string"
    ? model.pokemon_name.trim()
    : "";

  const modelStatus = typeof model.status === "string"
    ? model.status.toLowerCase()
    : "";

  if (
    modelStatus === "no_pokemon_detected" ||
    rawName.length === 0
  ) {
    return {
      status: "no_pokemon_detected",
      pokedex_number: null,
      pokemon_name: null,
      confidence,
      is_known_pokemon: false,
    };
  }

  if (confidence < CONFIDENCE_THRESHOLD) {
    return {
      status: "not_identified",
      pokedex_number: null,
      pokemon_name: null,
      confidence,
      is_known_pokemon: false,
    };
  }

  const normalizedName = rawName.toLowerCase();

  return {
    status: "identified",
    pokedex_number: catalogRow?.pokedex_number ??
      (typeof model.pokedex_number === "number"
        ? model.pokedex_number
        : null),
    pokemon_name: normalizedName,
    confidence,
    is_known_pokemon: catalogRow != null,
  };
}

async function lookupCatalogPokemon(
  supabase: ReturnType<typeof createClient>,
  pokemonName: string,
): Promise<CatalogRow | null> {
  const { data, error } = await supabase
    .from("pokemon_catalog")
    .select("pokedex_number, name")
    .ilike("name", pokemonName)
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error("Catalog lookup failed:", error.message);
    return null;
  }

  return data as CatalogRow | null;
}

async function callOllama(
  modelName: string,
  base64Image: string,
): Promise<ModelPayload> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), OLLAMA_TIMEOUT_MS);

  try {
    const response = await fetch(OLLAMA_CHAT_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      signal: controller.signal,
      body: JSON.stringify({
        model: modelName,
        stream: false,
        format: "json",
        messages: [
          {
            role: "user",
            content:
              "Analyze the image. Identify only one Pokemon. If you cannot identify it with confidence, return that it was not possible to identify it. Reply only in JSON with status, pokedex_number, pokemon_name, confidence, and is_known_pokemon. Choose only Pokemon that exist in our catalog.",
            images: [base64Image],
          },
        ],
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      console.error("Ollama HTTP error:", response.status, body);
      throw new Error(`Ollama request failed with status ${response.status}`);
    }

    const payload = await response.json();
    const content = payload?.message?.content;

    if (typeof content !== "string" || content.trim().length === 0) {
      throw new Error("Ollama response did not include message content.");
    }

    return parseModelContent(content);
  } catch (error) {
    if (error instanceof Error && error.name === "AbortError") {
      throw new Error("Ollama request timed out after 30 seconds.");
    }
    throw error;
  } finally {
    clearTimeout(timeoutId);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  try {
    const modelName = (Deno.env.get("OLLAMA_MODEL_NAME") ?? OLLAMA_MODEL_NAME)
      .trim();

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error("Supabase environment variables are missing.");
      return errorResponse();
    }

    const body = await req.json();
    const image = body?.image;

    if (typeof image !== "string" || image.trim().length === 0) {
      return jsonResponse({ error: "Image is required." }, 400);
    }

    const base64Image = image.trim();

    const modelResult = await callOllama(modelName, base64Image);

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const candidateName = typeof modelResult.pokemon_name === "string"
      ? modelResult.pokemon_name.trim()
      : "";

    const catalogRow = candidateName.length > 0
      ? await lookupCatalogPokemon(supabase, candidateName)
      : null;

    const result = buildScanResponse(modelResult, catalogRow);
    return jsonResponse(result);
  } catch (error) {
    console.error(
      "identify-pokemon error:",
      error instanceof Error ? error.message : error,
    );
    return errorResponse();
  }
});
