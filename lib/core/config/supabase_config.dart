/// Supabase project credentials.
///
/// Set values via `--dart-define` (recommended for CI/local runs) or replace
/// [_defaultUrl] / [_defaultAnonKey] for local development.
/// See `.env.example` for the variable names.
class SupabaseConfig {
  const SupabaseConfig._();

  static const _defaultUrl = 'https://ypuocuwalrkoxoffuitw.supabase.co';
  static const _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwdW9jdXdhbHJrb3hvZmZ1aXR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1MDQwNDAsImV4cCI6MjA5NDA4MDA0MH0.TdnDJdyA27BAfie8QdltVoblaAWZsg1yjheuhUQAKAQ';

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultAnonKey,
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
