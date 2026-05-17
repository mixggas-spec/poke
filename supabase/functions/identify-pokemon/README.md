# identify-pokemon

Supabase Edge Function that sends a base64 image to the Ollama chat API and returns a normalized Pokémon identification result for the Flutter app.

## Invoke (from Flutter, Prompt 7+)

```dart
await supabase.functions.invoke(
  'identify-pokemon',
  body: {'image': base64Image},
);
```

## Required secrets

Set in the Supabase project (**Project Settings → Edge Functions → Secrets**) before testing:

| Secret | Description |
|--------|-------------|
| `OLLAMA_MODEL_NAME` | Model id passed to `https://apichat.epvc.pt/api/chat`. Default in code: `qwen3.6:35b` (override via this secret). |
| `SUPABASE_URL` | Usually provided automatically in the Edge runtime. |
| `SUPABASE_SERVICE_ROLE_KEY` | Used to read `pokemon_catalog` (bypasses RLS for catalog lookup). |

Example CLI:

```bash
supabase secrets set OLLAMA_MODEL_NAME=qwen3.6:35b --project-ref ypuocuwalrkoxoffuitw
```

## Deploy

```bash
supabase functions deploy identify-pokemon
```

## Local serve

```bash
supabase functions serve identify-pokemon --env-file supabase/.env.local
```

Create `supabase/.env.local` with at least `OLLAMA_MODEL_NAME`.

## Request

`POST` JSON body:

```json
{ "image": "<BASE64_STRING>" }
```

## Success responses (HTTP 200)

**Identified** (`confidence >= 0.75` and non-empty `pokemon_name`):

```json
{
  "status": "identified",
  "pokedex_number": 25,
  "pokemon_name": "pikachu",
  "confidence": 0.97,
  "is_known_pokemon": true
}
```

**Not identified** (`confidence < 0.75`):

```json
{
  "status": "not_identified",
  "pokedex_number": null,
  "pokemon_name": null,
  "confidence": 0.22,
  "is_known_pokemon": false
}
```

**No Pokémon detected**:

```json
{
  "status": "no_pokemon_detected",
  "pokedex_number": null,
  "pokemon_name": null,
  "confidence": 0.05,
  "is_known_pokemon": false
}
```

## Errors

- **400** — missing/empty `image`
- **500** — timeout (30s), Ollama failure, parse error, or missing secrets  
  `{ "error": "Something went wrong. Please try again." }`

## Behavior

- 30-second timeout on the Ollama HTTP call
- Confidence threshold: **0.75** for `identified`
- Catalog lookup: `pokemon_catalog.name` **case-insensitive** (`ilike`); sets `is_known_pokemon` and `pokedex_number` from the catalog when matched
