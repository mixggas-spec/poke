import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client.dart';
import '../domain/home_models.dart';

class HomeRepository {
  SupabaseClient get _client {
    final client = supabaseClient;
    if (client == null) {
      throw const AuthException('Supabase is not configured.');
    }
    return client;
  }

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthException('Not signed in.');
    }
    return id;
  }

  Future<HomeData> fetchHomeData() async {
    final userId = _userId;

    final totalResponse = await _client
        .from('pokemon_catalog')
        .select('id')
        .count(CountOption.exact);

    final discoveredResponse = await _client
        .from('user_pokedex_entries')
        .select('id')
        .eq('user_id', userId)
        .eq('is_discovered', true)
        .count(CountOption.exact);

    final lastRow = await _client
        .from('user_pokedex_entries')
        .select('''
          pokemon_catalog (
            id,
            pokedex_number,
            name,
            image_url,
            type_1,
            type_2
          )
        ''')
        .eq('user_id', userId)
        .eq('is_discovered', true)
        .order('discovered_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return HomeData(
      discoveredCount: discoveredResponse.count,
      totalCount: totalResponse.count,
      lastDiscovered: _parseLastDiscovered(lastRow),
    );
  }

  Future<String> fetchUsername() async {
    final row = await _client
        .from('profiles')
        .select('username')
        .eq('id', _userId)
        .single();

    return row['username'] as String;
  }

  PokemonSummary? _parseLastDiscovered(Map<String, dynamic>? row) {
    if (row == null) {
      return null;
    }

    final catalog = row['pokemon_catalog'];
    if (catalog is! Map<String, dynamic>) {
      return null;
    }

    return PokemonSummary(
      id: catalog['id'] as String,
      pokedexNumber: catalog['pokedex_number'] as int,
      name: catalog['name'] as String,
      imageUrl: catalog['image_url'] as String?,
      type1: catalog['type_1'] as String?,
      type2: catalog['type_2'] as String?,
    );
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository();
});
