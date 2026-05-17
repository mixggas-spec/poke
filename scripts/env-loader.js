import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
export const ENV_FILE_PATH = path.resolve(scriptsDir, '.env');

if (!fs.existsSync(ENV_FILE_PATH)) {
  throw new Error(
    `Missing .env at ${ENV_FILE_PATH}\n` +
      'Copy scripts/.env.example to scripts/.env and add your Supabase credentials.',
  );
}

const result = dotenv.config({
  path: ENV_FILE_PATH,
  override: true,
});

if (result.error) {
  throw new Error(`Failed to load ${ENV_FILE_PATH}: ${result.error.message}`);
}

if (!process.env.SUPABASE_URL) {
  throw new Error(
    `SUPABASE_URL is not set after loading ${ENV_FILE_PATH}`,
  );
}
