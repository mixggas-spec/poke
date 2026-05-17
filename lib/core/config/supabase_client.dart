import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Returns the Supabase client when initialized; null if credentials are missing.
SupabaseClient? get supabaseClient {
  if (!SupabaseConfig.isConfigured) {
    return null;
  }

  return Supabase.instance.client;
}
