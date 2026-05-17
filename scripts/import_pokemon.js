import { ENV_FILE_PATH } from './env-loader.js';
import { createClient } from '@supabase/supabase-js';
import axios from 'axios';

const POKEAPI_BASE = 'https://pokeapi.co/api/v2';
const DELAY_MS = 100;

/** Node http adapter only — avoids axios fetch adapter ("fetch failed" on some Node/Windows setups). */
const httpClient = axios.create({
  adapter: 'http',
  timeout: 30_000,
  maxRedirects: 5,
  headers: {
    'User-Agent': 'pokedex-import-script/1.0',
    Accept: 'application/json',
  },
});

const VERSION_PRIORITY = [
  'red',
  'blue',
  'yellow',
  'gold',
  'silver',
  'crystal',
  'ruby',
  'sapphire',
  'emerald',
  'firered',
  'leafgreen',
  'diamond',
  'pearl',
  'platinum',
  'heartgold',
  'soulsilver',
  'black',
  'white',
];

const REGIONAL_FORM_PATTERN =
  /-(alola|galar|hisui|paldea)(-|$)/i;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function formatAxiosError(error, url) {
  if (!axios.isAxiosError(error)) {
    const message = error instanceof Error ? error.message : String(error);
    return new Error(`${message} for ${url}`);
  }

  if (error.response) {
    return new Error(`HTTP ${error.response.status} for ${url}`);
  }

  const code = error.code ? ` [${error.code}]` : '';
  return new Error(`${error.message}${code} for ${url}`);
}

async function getJson(url) {
  try {
    const { data } = await httpClient.get(url);
    return data;
  } catch (error) {
    throw formatAxiosError(error, url);
  }
}

/**
 * Fetch-compatible wrapper so @supabase/supabase-js also uses axios/http, not global fetch.
 */
function createHttpFetch() {
  return async (input, init = {}) => {
    const url = typeof input === 'string' ? input : input.url;
    const method = (init.method ?? 'GET').toUpperCase();

    const headers = {};
    if (init.headers) {
      const headerList = new Headers(init.headers);
      headerList.forEach((value, key) => {
        headers[key] = value;
      });
    }

    let data = init.body;
    if (
      typeof data === 'string' &&
      headers['Content-Type']?.includes('application/json')
    ) {
      try {
        data = JSON.parse(data);
      } catch {
        // keep raw string
      }
    }

    const response = await httpClient.request({
      url,
      method,
      data,
      headers,
      validateStatus: () => true,
    });

    const bodyText =
      response.data === undefined || response.data === null
        ? ''
        : typeof response.data === 'string'
          ? response.data
          : JSON.stringify(response.data);

    return {
      ok: response.status >= 200 && response.status < 300,
      status: response.status,
      statusText: response.statusText,
      headers: {
        get: (name) => {
          const key = name.toLowerCase();
          return (
            response.headers[key] ??
            response.headers[name] ??
            null
          );
        },
      },
      json: async () => {
        if (typeof response.data === 'object' && response.data !== null) {
          return response.data;
        }
        return JSON.parse(bodyText || '{}');
      },
      text: async () => bodyText,
    };
  };
}

function cleanDescription(text) {
  return text.replace(/[\f\n\r]+/g, ' ').replace(/\s+/g, ' ').trim();
}

function pickDescription(flavorTextEntries) {
  const english = flavorTextEntries.filter(
    (entry) => entry.language.name === 'en',
  );

  for (const versionName of VERSION_PRIORITY) {
    const match = english.find((entry) => entry.version.name === versionName);
    if (match?.flavor_text) {
      return cleanDescription(match.flavor_text);
    }
  }

  if (english[0]?.flavor_text) {
    return cleanDescription(english[0].flavor_text);
  }

  return null;
}

function isMainSpecies(species) {
  if (REGIONAL_FORM_PATTERN.test(species.name)) {
    return false;
  }

  return species.pokedex_numbers.some(
    (entry) => entry.pokedex.name === 'national',
  );
}

function getNationalPokedexNumber(species) {
  const national = species.pokedex_numbers.find(
    (entry) => entry.pokedex.name === 'national',
  );
  return national?.entry_number ?? null;
}

function getEnglishDisplayName(species) {
  const english = species.names?.find(
    (entry) => entry.language.name === 'en',
  );
  if (english?.name) {
    return english.name;
  }

  return species.name
    .split('-')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

async function listAllSpecies() {
  const results = [];
  let nextUrl = `${POKEAPI_BASE}/pokemon-species?limit=100`;

  while (nextUrl) {
    const page = await getJson(nextUrl);
    results.push(...page.results);
    nextUrl = page.next;
    if (nextUrl) {
      await sleep(DELAY_MS);
    }
  }

  return results;
}

async function importSpecies(supabase, speciesStub, failures) {
  await sleep(DELAY_MS);
  const species = await getJson(speciesStub.url);

  if (!isMainSpecies(species)) {
    return { status: 'skipped', reason: 'regional or non-national dex species' };
  }

  const pokedexNumber = getNationalPokedexNumber(species);
  if (pokedexNumber == null) {
    return { status: 'skipped', reason: 'missing national pokedex number' };
  }

  const defaultVariety =
    species.varieties.find((variety) => variety.is_default) ??
    species.varieties[0];

  if (!defaultVariety?.pokemon?.url) {
    failures.push({
      name: species.name,
      pokedexNumber,
      reason: 'no default pokemon variety',
    });
    return { status: 'failed' };
  }

  await sleep(DELAY_MS);
  const pokemon = await getJson(defaultVariety.pokemon.url);

  const types = pokemon.types
    .sort((a, b) => a.slot - b.slot)
    .map((entry) => entry.type.name);

  const imageUrl =
    pokemon.sprites?.other?.['official-artwork']?.front_default ?? null;

  const displayName = getEnglishDisplayName(species);

  console.log(`Importing #${pokedexNumber} ${displayName}...`);

  const { error } = await supabase.from('pokemon_catalog').upsert(
    {
      pokedex_number: pokedexNumber,
      name: displayName,
      description: pickDescription(species.flavor_text_entries),
      image_url: imageUrl,
      silhouette_url: null,
      type_1: types[0] ?? null,
      type_2: types[1] ?? null,
      pokemon_api_url: species.url,
    },
    { onConflict: 'pokedex_number' },
  );

  if (error) {
    failures.push({
      name: species.name,
      pokedexNumber,
      reason: error.message,
    });
    return { status: 'failed' };
  }

  return { status: 'imported' };
}

async function main() {
  const supabaseUrl = process.env.SUPABASE_URL?.trim();
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();

  console.log(`Loaded environment from: ${ENV_FILE_PATH}`);
  console.log(`SUPABASE_URL: ${supabaseUrl}`);
  console.log('Supabase client: using SUPABASE_SERVICE_ROLE_KEY only.\n');

  if (!supabaseUrl || !serviceRoleKey) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.');
    console.error(`Edit ${ENV_FILE_PATH} and set both variables.`);
    process.exit(1);
  }

  if (supabaseUrl.includes('your-project-ref')) {
    console.error(
      'SUPABASE_URL still contains the placeholder "your-project-ref".',
    );
    console.error(
      `Update ${ENV_FILE_PATH} with your real project URL (e.g. https://xxxx.supabase.co).`,
    );
    process.exit(1);
  }

  if (
    serviceRoleKey.includes('your-service-role') ||
    serviceRoleKey === process.env.SUPABASE_ANON_KEY?.trim()
  ) {
    console.error(
      'SUPABASE_SERVICE_ROLE_KEY must be the service_role secret from the Supabase dashboard, not the anon key.',
    );
    process.exit(1);
  }

  console.log('Testing PokeAPI connection (axios http adapter)...');
  await getJson(`${POKEAPI_BASE}/pokemon-species/1`);
  console.log('PokeAPI connection OK.\n');

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    global: { fetch: createHttpFetch() },
  });

  const speciesList = await listAllSpecies();
  console.log(`Loaded ${speciesList.length} species stubs from PokeAPI.\n`);

  speciesList.sort((a, b) => a.name.localeCompare(b.name));

  const failures = [];
  let imported = 0;
  let skipped = 0;

  for (const speciesStub of speciesList) {
    try {
      const result = await importSpecies(supabase, speciesStub, failures);
      if (result.status === 'imported') {
        imported += 1;
      } else if (result.status === 'skipped') {
        skipped += 1;
      }
    } catch (error) {
      failures.push({
        name: speciesStub.name,
        reason: error.message,
      });
      console.error(`Failed ${speciesStub.name}: ${error.message}`);
    }
  }

  console.log('');
  console.log(`Import finished. Imported: ${imported}, skipped: ${skipped}, failed: ${failures.length}`);

  if (failures.length > 0) {
    console.log('Failures:');
    for (const failure of failures) {
      console.log(`  - ${failure.name}: ${failure.reason}`);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
