import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Initializes Flutter bindings and Supabase when credentials are configured.
Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseConfig.isConfigured) {
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
}
