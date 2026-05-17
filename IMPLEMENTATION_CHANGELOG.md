# Implementation Changelog

## Entry 2026-05-15 12:30

- Task: Flutter scaffold + routing + theme
- Summary: Created the Flutter project scaffold for `pokedex` in `/Users/240422/StudioProjects/Pokedex` using Flutter 3.41.9 / Dart 3.11.5. Set up a basic feature-folder structure with global routing, theme tokens, Supabase placeholder config, a stub auth provider, and placeholder screens only.
- Files changed:
  - `pubspec.yaml`
  - `pubspec.lock`
  - `lib/main.dart`
  - `lib/core/config/supabase_config.dart`
  - `lib/core/providers/auth_state_provider.dart`
  - `lib/core/router/app_router.dart`
  - `lib/core/theme/app_theme.dart`
  - `lib/features/placeholder/presentation/placeholder_screen.dart`
  - `test/widget_test.dart`
  - `IMPLEMENTATION_CHANGELOG.md`
- Packages added:
  - `supabase_flutter: ^2.12.4`
  - `camera: ^0.12.0+1`
  - `permission_handler: ^12.0.1`
  - `flutter_riverpod: ^3.3.1`
  - `riverpod_annotation: ^4.0.2`
  - `go_router: ^17.2.3`
  - `cached_network_image: ^3.4.1`
  - `image: ^4.8.0`
  - `flutter_svg: ^2.3.0`
  - `flutter_animate: ^4.5.2`
  - `shared_preferences: ^2.5.5`
  - `json_serializable: ^6.13.2`
  - `freezed: ^3.2.5`
  - `freezed_annotation: ^3.1.0`
  - `json_annotation: ^4.11.0`
  - `build_runner: ^2.15.0` as a dev dependency
- Packages removed: None.
- API / Edge Function changes: None.
- UI changes:
  - Added placeholder route `/splash` with centered text `Splash`.
  - Added placeholder route `/login` with centered text `Login`.
  - Added placeholder route `/register` with centered text `Register`.
  - Added placeholder route `/home` with centered text `Home`.
  - Added placeholder route `/camera` with centered text `Camera`.
  - Added placeholder route `/scan-result` with centered text `Scan Result`.
  - Added placeholder route `/new-discovery` with centered text `New Discovery`.
  - Added placeholder route `/pokedex-index` with centered text `Pokedex Index`.
  - Added placeholder route `/pokemon-detail/:id` with centered text including the selected id.
- Database changes: None.
- Testing performed:
  - Ran `/Users/240422/Downloads/flutter/bin/flutter pub get` successfully.
  - Ran `/Users/240422/Downloads/flutter/bin/flutter analyze` successfully with no issues.
  - Ran `/Users/240422/Downloads/flutter/bin/flutter test` successfully; widget test confirms the app boots to the Splash placeholder.
  - Ran `/Users/240422/Downloads/flutter/bin/flutter devices`; macOS and Chrome are available, no Android emulator/device is currently connected.
  - Did not run the app manually on a simulator/device in this session.
- Open issues:
  - `SUPABASE_URL` and `SUPABASE_ANON_KEY` remain empty placeholders in `lib/core/config/supabase_config.dart`.
  - `authStateProvider` is a stub returning unauthenticated.
  - Route guard currently leaves `/splash`, `/login`, and `/register` public; private routes redirect unauthenticated users to `/login`; authenticated routing is prepared for the next auth implementation.
  - No real screen UI, Supabase calls, database schema, or app logic has been implemented yet.
- Next recommended step: Execute Prompt 2 — Supabase setup + database schema.

## Entry 2026-05-16

- Task: Supabase setup + database schema + RLS
- Summary: Connected the Flutter app to Supabase via `Supabase.initialize` in bootstrap (skipped when credentials are empty). Added a single SQL migration creating four tables with RLS enabled on each. Updated `authStateProvider` to derive auth status from `supabase.auth.currentSession` when the client is initialized.
- Files changed:
  - `supabase/migrations/20260516120000_create_pokedex_schema.sql`
  - `lib/main.dart`
  - `lib/core/bootstrap/app_bootstrap.dart`
  - `lib/core/config/supabase_config.dart`
  - `lib/core/config/supabase_client.dart`
  - `lib/core/providers/auth_state_provider.dart`
  - `test/widget_test.dart`
  - `.env.example`
  - `.gitignore`
  - `IMPLEMENTATION_CHANGELOG.md`
- Packages added: None.
- Packages removed: None.
- API / Edge Function changes: None.
- UI changes: None.
- Database changes:
  - Created tables: `profiles`, `pokemon_catalog`, `user_pokedex_entries`, `captures`.
  - RLS enabled on all four tables.
  - `profiles`: SELECT/INSERT/UPDATE own row only (`auth.uid() = id`).
  - `pokemon_catalog`: SELECT for authenticated users only; no INSERT/UPDATE/DELETE policies for app users.
  - `user_pokedex_entries`: SELECT/INSERT/UPDATE own rows only (`auth.uid() = user_id`).
  - `captures`: SELECT/INSERT own rows only (`auth.uid() = user_id`); no UPDATE/DELETE policies.
  - Supporting indexes on `user_id`, `pokemon_id`, and `pokedex_number`.
- Testing performed:
  - Ran `flutter pub get` successfully.
  - Ran `flutter analyze` with no issues.
  - Ran `flutter test`; widget test boots to Splash placeholder after `bootstrapApp()`.
  - With empty credentials, Supabase init is skipped and `authStateProvider` returns unauthenticated (no crash on boot).
  - Migration SQL not applied in Supabase dashboard in this session (requires a Supabase project and manual apply via SQL Editor or `supabase db push`).
- Open issues:
  - `SUPABASE_URL` and `SUPABASE_ANON_KEY` must be set via `--dart-define` or by editing defaults in `lib/core/config/supabase_config.dart` before Supabase initializes on device.
  - `authStateProvider` reads `currentSession` only; reactive auth listening is deferred to Prompt 4.
  - `pokemon_catalog` is empty until Prompt 3 import script is run.
  - Apply migration in Supabase: run `supabase/migrations/20260516120000_create_pokedex_schema.sql` in the project SQL Editor or via Supabase CLI.
- Next recommended step: Execute Prompt 3 — PokeAPI catalog import script.

## Entry 2026-05-16 (Prompt 3)

- Task: PokeAPI catalog import script
- Summary: Added a Node.js script that paginates the PokeAPI `pokemon-species` list, keeps only main national-dex species (skips Alolan/Galarian/Hisuian/Paldean name suffixes), fetches each species and its default variety Pokémon for types and official artwork, selects English flavor text using the fixed game version priority, and upserts rows into `pokemon_catalog` on `pokedex_number`. Requests are spaced by 100ms to reduce PokeAPI rate-limit risk.
- Files changed:
  - `scripts/import_pokemon.js`
  - `scripts/package.json`
  - `scripts/.env.example`
  - `scripts/.gitignore`
  - `IMPLEMENTATION_CHANGELOG.md`
- Packages added (Node.js, in `scripts/`):
  - `@supabase/supabase-js: ^2.49.8`
  - `dotenv: ^16.5.0`
- Packages removed: None.
- API / Edge Function changes: None.
- UI changes: None.
- Database changes: None applied in this session. Running the script will populate `pokemon_catalog` with `pokedex_number`, `name`, `description`, `image_url`, `type_1`, `type_2`, `pokemon_api_url` (`silhouette_url` left null).
- Testing performed:
  - Ran `node --check import_pokemon.js` — no syntax errors.
  - `npm install` in `scripts/` was not run in this session (npm not available in the agent environment); run it locally before import.
  - Did not run the import script (per prompt); catalog remains empty until executed manually.
- How to run:
  1. `cd scripts`
  2. Copy `.env.example` to `.env` and set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and **`SUPABASE_SERVICE_ROLE_KEY`** (service role required to insert into `pokemon_catalog` because RLS allows only SELECT for authenticated app users).
  3. `npm run import-pokemon`
- Open issues:
  - Script has not been run yet; `pokemon_catalog` is still empty.
  - `OLLAMA_MODEL_NAME` is not part of this prompt (still unset until Prompt 6 Edge Function).
  - Import requires `SUPABASE_SERVICE_ROLE_KEY` in `scripts/.env`; anon key alone will fail on upsert due to RLS.
- Next recommended step: Run the import script, verify `pokemon_catalog` is populated, then execute Prompt 4 — Auth screens.

## Entry 2026-05-17 (Prompt 4)

- Task: Auth screens — Splash, Login, Register
- Summary: Implemented Splash, Login, and Register screens with the Pokedex visual identity. Auth state is exposed via a `StreamProvider` listening to `supabase.auth.onAuthStateChange`, with an initial emit from `currentSession`. `go_router` uses `refreshListenable` to reactively redirect authenticated users to `/home` and unauthenticated users away from protected routes.
- Files changed:
  - `lib/core/providers/auth_state_provider.dart`
  - `lib/core/router/app_router.dart`
  - `lib/core/widgets/pokedex_lens.dart`
  - `lib/features/auth/data/auth_repository.dart`
  - `lib/features/auth/presentation/splash_screen.dart`
  - `lib/features/auth/presentation/login_screen.dart`
  - `lib/features/auth/presentation/register_screen.dart`
  - `lib/features/auth/presentation/widgets/auth_scaffold.dart`
  - `lib/features/auth/presentation/widgets/auth_text_field.dart`
  - `test/widget_test.dart`
  - `IMPLEMENTATION_CHANGELOG.md`
- Packages added: None.
- Packages removed: None.
- API / Edge Function changes: None.
- UI changes:
  - **Splash** (`/splash`): Red background (#b83830), radial-gradient Pokedex lens, bold white “Pokédex” title, loading indicator while checking session, error state with “Something went wrong. Try again.” and retry button.
  - **Login** (`/login`): Dark background, centered panel with blue border (#3898b8), lens icon, email/password fields with cyan focus border, red primary button, link to register.
  - **Register** (`/register`): Same panel layout; username, email, password fields; sign-up button; link to login.
- Database changes: On register, after `auth.signUp`, inserts into `profiles` with `id` = auth user id and `username` from the form. Unique violation (`23505`) triggers sign-out and shows “This username is already taken.”
- Testing performed:
  - `flutter analyze` — no issues.
  - `flutter test` — boots to splash and finds “Pokédex”.
  - Manual tests (recommended):
    1. Register with username, email, password → redirected to Home placeholder.
    2. Sign out (future) / restart app with session → Splash then Home.
    3. Log in with valid credentials → Home.
    4. Wrong password → “Invalid email or password.”
    5. Duplicate username on register → “This username is already taken.”
    6. No session → Splash then Login.
- Open issues:
  - Splash checks `currentSession` only (no network refresh); expired tokens may require a new sign-in.
  - Email confirmation in Supabase (if enabled) may block immediate post-register redirect.
  - Home and other routes remain placeholders.
- Next recommended step: Execute Prompt 5 — Home screen.

## Entry 2026-05-17 (Prompt 5)

- Task: Home screen + Account Bottom Sheet
- Summary: Implemented the Home screen as the main Pokedex “face” with discovery progress, last-discovered Pokémon panel, and a prominent camera button. Data is loaded via Riverpod `FutureProvider`s backed by `HomeRepository` Supabase queries. Home data refreshes on first open, on retry, and when returning from another route (`RouteObserver.didPopNext`) so `/camera` and `/new-discovery` will trigger a reload once those flows exist.
- Files changed:
  - `lib/features/home/domain/home_models.dart`
  - `lib/features/home/data/home_repository.dart`
  - `lib/features/home/providers/home_provider.dart`
  - `lib/features/home/presentation/home_screen.dart`
  - `lib/features/home/presentation/widgets/account_bottom_sheet.dart`
  - `lib/features/home/presentation/widgets/type_badge.dart`
  - `lib/core/router/app_router.dart`
  - `lib/core/router/app_route_observer.dart`
  - `IMPLEMENTATION_CHANGELOG.md`
- Packages added: None.
- Packages removed: None.
- API / Edge Function changes: None.
- UI changes:
  - **Top bar:** Tappable “X / Y discovered” counter with cyan progress bar (opens `/pokedex-index`); circular profile button opens account sheet.
  - **Center panel:** Blue/cyan gradient panel with official artwork (`cached_network_image`), name, padded dex number, and type badges; empty state with silhouette-style icon and “No Pokémon discovered yet. Start scanning!”
  - **Camera button:** Large red circular button with white camera icon at bottom center (navigates to `/camera` placeholder).
  - **Account bottom sheet:** Username from `profiles`, red “Sign out” button (Supabase `signOut`, router redirects to login).
- Database changes: None (reads only). Queries:
  - Total: `pokemon_catalog` count.
  - Discovered: `user_pokedex_entries` where `user_id` = current user and `is_discovered = true` (count).
  - Last discovered: same table filtered/ordered by `discovered_at` DESC, limit 1, with embedded `pokemon_catalog` select.
  - Username: `profiles.username` for current user id.
- Testing performed:
  - `flutter analyze` — no issues.
  - `flutter test` — splash widget test still passes.
  - Manual tests (recommended): 0 discovered → empty state and `0 / N` counter; tap profile → sheet with username and sign out; sign out → login; tap camera → camera placeholder; tap counter → pokedex-index placeholder; return from pushed routes → home data reloads.
- Open issues:
  - Discovery refresh after a real scan is wired via `RouteObserver` but not end-to-end testable until Prompt 7 (camera) writes `user_pokedex_entries`.
  - `/pokedex-index` and `/camera` remain placeholders.
- Next recommended step: Execute Prompt 6 — Supabase Edge Function.

## Entry 2026-05-17 (Prompt 6)

- Task: Supabase Edge Function — identify-pokemon
- Summary: Added the `identify-pokemon` Edge Function (Deno). It validates a base64 `image` from the request body, calls the Ollama chat API with a 30-second timeout, parses the model’s JSON reply, applies the confidence rules, looks up the Pokémon name in `pokemon_catalog` (case-insensitive), and returns one of the three normalized scan statuses.
- Files changed:
  - `supabase/functions/identify-pokemon/index.ts`
  - `supabase/functions/identify-pokemon/README.md`
  - `IMPLEMENTATION_CHANGELOG.md`
- Packages added (Deno / ESM imports in Edge Function):
  - `@supabase/supabase-js@2.49.8` (via `esm.sh`)
- Packages removed: None.
- API / Edge Function changes:
  - **Function:** `identify-pokemon`
  - **Input:** `POST` JSON `{ "image": "<BASE64_STRING>" }`
  - **Ollama:** `POST https://apichat.epvc.pt/api/chat` with `model` = `OLLAMA_MODEL_NAME`, `stream: false`, `format: "json"`, user message + `images: [base64]`
  - **Timeout:** 30 seconds (abort → HTTP 500)
  - **Confidence:** `>= 0.75` and non-empty `pokemon_name` → `identified`; `< 0.75` → `not_identified`; no Pokémon / empty name / model `no_pokemon_detected` → `no_pokemon_detected`
  - **Responses (200):** `identified`, `not_identified`, `no_pokemon_detected` shapes as specified in Prompt 6
  - **Error (500):** `{ "error": "Something went wrong. Please try again." }`
  - **Client error (400):** missing/empty image
  - **Secrets:** `OLLAMA_MODEL_NAME` must be set manually in Supabase (documented in `supabase/functions/identify-pokemon/README.md`)
- UI changes: None (Flutter does not call this function yet).
- Database changes: None (reads `pokemon_catalog` via service-role client inside the function).
- Testing performed:
  - Function structure and TypeScript/Deno syntax reviewed; not deployed or invoked with a live image in this session.
  - `OLLAMA_MODEL_NAME` not set in Supabase secrets during this session (placeholder — must be configured before real tests).
- Open issues:
  - Deploy with `supabase functions deploy identify-pokemon` and set `OLLAMA_MODEL_NAME` before Prompt 7.
  - Confirm the Ollama endpoint and model name against `https://apichat.epvc.pt/api/chat` in your environment.
  - End-to-end scan flow remains unimplemented in Flutter until Prompt 7.
- Next recommended step: Confirm `OLLAMA_MODEL_NAME`, set it as a Supabase secret, then execute Prompt 7 — Camera screen + scan flow.

## Entry 2026-05-17 — OLLAMA_MODEL_NAME configuration

- Task: Configure Ollama model for `identify-pokemon` Edge Function
- Summary: Set the Ollama model to `qwen3.6:35b` in the Edge Function code (default constant, overridable by `OLLAMA_MODEL_NAME` secret). Added `supabase/.env.example` for local serve. Remote Supabase secret must be applied via Dashboard or CLI (see below).
- Files changed:
  - `supabase/functions/identify-pokemon/index.ts`
  - `supabase/functions/identify-pokemon/README.md`
  - `supabase/.env.example`
  - `IMPLEMENTATION_CHANGELOG.md`
- Packages added: None.
- Packages removed: None.
- API / Edge Function changes:
  - **Model:** `qwen3.6:35b` (constant `OLLAMA_MODEL_NAME` in `index.ts`; env secret overrides when set).
  - **Supabase secret:** `OLLAMA_MODEL_NAME=qwen3.6:35b` for project `ypuocuwalrkoxoffuitw`.
- UI changes: None.
- Database changes: None.
- Testing performed:
  - Code updated; Supabase CLI was not available in the agent environment to run `supabase secrets set` remotely.
- Set secret manually:
  - **Dashboard:** Project → Edge Functions → Secrets → add `OLLAMA_MODEL_NAME` = `qwen3.6:35b`
  - **CLI:** `supabase secrets set OLLAMA_MODEL_NAME=qwen3.6:35b --project-ref ypuocuwalrkoxoffuitw`
  - **Local serve:** copy `supabase/.env.example` to `supabase/.env.local`
- Open issues:
  - Redeploy the function after setting the secret: `supabase functions deploy identify-pokemon`
- Next recommended step: Execute Prompt 7 — Camera screen + scan flow.

## Entry 2026-05-17 (Prompt 7)

- Task: Camera screen + scan flow + Scan Result screen
- Summary: Implemented the full scan pipeline: camera preview and capture with permission handling, JPEG compression (max 1024px, 85% quality, ≤1MB), base64 upload to the `identify-pokemon` Edge Function, analyzing overlay with scan-line animation, and a Scan Result screen covering all four states plus the discovery confirmation flow (new vs already discovered).
- Files changed:
  - `lib/features/scan/domain/scan_models.dart`
  - `lib/features/scan/data/image_compressor.dart`
  - `lib/features/scan/data/scan_repository.dart`
  - `lib/features/scan/providers/scan_provider.dart`
  - `lib/features/scan/presentation/camera_screen.dart`
  - `lib/features/scan/presentation/scan_result_screen.dart`
  - `lib/features/scan/presentation/widgets/scan_analyzing_overlay.dart`
  - `lib/core/router/app_router.dart`
  - `android/app/src/main/AndroidManifest.xml`
  - `ios/Runner/Info.plist`
  - `IMPLEMENTATION_CHANGELOG.md`
- Packages added: None.
- Packages removed: None.
- API / Edge Function changes:
  - Flutter calls `supabase.functions.invoke('identify-pokemon', body: { 'image': base64String })`.
  - HTTP 200 → parse `status` (`identified` | `not_identified` | `no_pokemon_detected`); non-200 or `{ error }` → error state.
  - For `identified`, enriches result from `pokemon_catalog` by `pokedex_number` or case-insensitive `name`.
- UI changes:
  - **Camera:** Full-screen preview, back button, red circular capture button, permission denied / permanently denied UI with Try Again and Open Settings.
  - **Analyzing overlay:** Captured image with animated cyan scan line and “Analyzing image...”.
  - **Scan Result:** Identified (artwork, name, number, types, Yes/No); not identified; no Pokémon detected; technical error — each with Try Again where specified; already-discovered inline message + Go to Pokédex.
- Database changes (on confirm “Yes, that's it!”):
  - **New discovery:** insert or update `user_pokedex_entries` (`is_discovered=true`, `discovered_at=now`, `times_scanned` incremented); insert `captures` with `is_new_discovery=true`.
  - **Already discovered:** increment `times_scanned`; insert `captures` with `is_new_discovery=false`.
  - New discovery navigates to `/new-discovery` (placeholder) with Pokémon data in `newDiscoveryPokemonProvider`.
- Testing performed:
  - `flutter analyze` — no issues.
  - `flutter test` — passes.
  - Manual/device tests recommended for all scan states, permissions, and discovery writes.
- Open issues:
  - `/new-discovery` screen is still a placeholder (Prompt 8).
  - Edge Function must be deployed with `OLLAMA_MODEL_NAME` for live identification.
  - Camera not testable in unit/widget tests; permission edge cases need device verification.
- Next recommended step: Execute Prompt 8 — New Discovery screen.

## Entry 2026-05-17 (Prompt 8)

- Task: New Discovery screen
- Summary: Implemented a celebratory `/new-discovery` screen that reads Pokémon data from `newDiscoveryPokemonProvider` (set after a new scan confirmation). Uses `flutter_animate` for staged reveal animations and refreshes Home when the user taps Continue.
- Files changed:
  - `lib/features/discovery/presentation/new_discovery_screen.dart`
  - `lib/features/home/domain/home_models.dart`
  - `lib/features/scan/data/scan_repository.dart`
  - `lib/features/scan/presentation/scan_result_screen.dart`
  - `lib/core/router/app_router.dart`
  - `IMPLEMENTATION_CHANGELOG.md`
- Packages added: None.
- Packages removed: None.
- API / Edge Function changes: None.
- UI changes:
  - Dark background (#202628) with pulsing radial cyan/blue energy background (fade loop + shimmer).
  - Header “NEW POKÉMON DISCOVERED!” with cyan glow shadow (fade + slide down, 450ms).
  - Large official artwork: fade + scale 0.5→1.0 with easeOutBack (550–650ms, 200ms delay).
  - Row: dex number left, type badges right (fade + slide up, 600ms delay).
  - Name: bold centered (fade + slide up, 750ms delay).
  - Description: scrollable body text (fade in, 900ms delay).
  - Red Continue button (#b83830) (fade + slide up, 1100ms delay).
- Database changes: None (display only). `fetchPokemonById` loads `description` from `pokemon_catalog` before navigation.
- Testing performed:
  - `flutter analyze` — no issues after `use_build_context_synchronously` fix.
  - `flutter test` — passes.
  - Manual tests recommended: confirm new discovery after scan → correct name, number, artwork, description; verify animation sequence; Continue → Home counter/panel updated.
- Open issues: None noted in code review.
- Next recommended step: Execute Prompt 9 — Pokédex Index screen + Pokémon Detail.
