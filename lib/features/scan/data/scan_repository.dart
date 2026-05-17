import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client.dart';
import '../../home/domain/home_models.dart';
import '../domain/scan_models.dart';

class ScanRepository {
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

  Future<ScanResult> identifyPokemon(String base64Image) async {
    try {
      final response = await _client.functions.invoke(
        'identify-pokemon',
        body: {'image': base64Image},
      );

      if (response.status != 200) {
        return ScanResult.error();
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return ScanResult.error();
      }

      if (data.containsKey('error')) {
        return ScanResult.error();
      }

      return _parseScanResponse(data);
    } catch (_) {
      return ScanResult.error();
    }
  }

  Future<ScanResult> _parseScanResponse(Map<String, dynamic> data) async {
    final status = data['status'] as String?;
    final confidence = (data['confidence'] as num?)?.toDouble();
    final pokemonName = data['pokemon_name'] as String?;
    final pokedexNumber = data['pokedex_number'] as int?;

    switch (status) {
      case 'identified':
        final catalogPokemon = await _fetchCatalogPokemon(
          name: pokemonName,
          pokedexNumber: pokedexNumber,
        );
        return ScanResult(
          status: ScanStatusType.identified,
          confidence: confidence,
          pokemon: catalogPokemon,
          rawPokemonName: pokemonName,
          rawPokedexNumber: pokedexNumber,
        );
      case 'not_identified':
        return ScanResult(
          status: ScanStatusType.notIdentified,
          confidence: confidence,
        );
      case 'no_pokemon_detected':
        return ScanResult(
          status: ScanStatusType.noPokemonDetected,
          confidence: confidence,
        );
      default:
        return ScanResult.error();
    }
  }

  Future<PokemonSummary?> _fetchCatalogPokemon({
    String? name,
    int? pokedexNumber,
  }) async {
    if (pokedexNumber != null) {
      final byNumber = await _client
          .from('pokemon_catalog')
          .select(
            'id, pokedex_number, name, description, image_url, type_1, type_2',
          )
          .eq('pokedex_number', pokedexNumber)
          .maybeSingle();
      if (byNumber != null) {
        return _mapCatalogRow(byNumber);
      }
    }

    if (name != null && name.trim().isNotEmpty) {
      final byName = await _client
          .from('pokemon_catalog')
          .select(
            'id, pokedex_number, name, description, image_url, type_1, type_2',
          )
          .ilike('name', name.trim())
          .limit(1)
          .maybeSingle();
      if (byName != null) {
        return _mapCatalogRow(byName);
      }
    }

    return null;
  }

  PokemonSummary _mapCatalogRow(Map<String, dynamic> row) {
    return PokemonSummary(
      id: row['id'] as String,
      pokedexNumber: row['pokedex_number'] as int,
      name: row['name'] as String,
      imageUrl: row['image_url'] as String?,
      description: row['description'] as String?,
      type1: row['type_1'] as String?,
      type2: row['type_2'] as String?,
    );
  }

  Future<PokemonSummary?> fetchPokemonById(String pokemonId) async {
    final row = await _client
        .from('pokemon_catalog')
        .select(
          'id, pokedex_number, name, description, image_url, type_1, type_2',
        )
        .eq('id', pokemonId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return _mapCatalogRow(row);
  }

  Future<DiscoveryOutcome> confirmDiscovery(PokemonSummary pokemon) async {
    final userId = _userId;
    final pokemonId = pokemon.id;

    final existing = await _client
        .from('user_pokedex_entries')
        .select('id, is_discovered, times_scanned')
        .eq('user_id', userId)
        .eq('pokemon_id', pokemonId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('user_pokedex_entries').insert({
        'user_id': userId,
        'pokemon_id': pokemonId,
        'is_discovered': true,
        'discovered_at': DateTime.now().toUtc().toIso8601String(),
        'times_scanned': 1,
      });
      await _insertCapture(isNewDiscovery: true, pokemonId: pokemonId);
      return DiscoveryOutcome(
        type: DiscoveryOutcomeType.newDiscovery,
        pokemon: pokemon,
      );
    }

    final isDiscovered = existing['is_discovered'] as bool? ?? false;
    final timesScanned = existing['times_scanned'] as int? ?? 0;
    final entryId = existing['id'] as String;

    if (!isDiscovered) {
      await _client.from('user_pokedex_entries').update({
        'is_discovered': true,
        'discovered_at': DateTime.now().toUtc().toIso8601String(),
        'times_scanned': timesScanned + 1,
      }).eq('id', entryId);
      await _insertCapture(isNewDiscovery: true, pokemonId: pokemonId);
      return DiscoveryOutcome(
        type: DiscoveryOutcomeType.newDiscovery,
        pokemon: pokemon,
      );
    }

    await _client.from('user_pokedex_entries').update({
      'times_scanned': timesScanned + 1,
    }).eq('id', entryId);
    await _insertCapture(isNewDiscovery: false, pokemonId: pokemonId);

    return DiscoveryOutcome(
      type: DiscoveryOutcomeType.alreadyDiscovered,
      pokemon: pokemon,
    );
  }

  Future<void> _insertCapture({
    required bool isNewDiscovery,
    required String pokemonId,
  }) async {
    await _client.from('captures').insert({
      'user_id': _userId,
      'pokemon_id': pokemonId,
      'is_new_discovery': isNewDiscovery,
      'captured_image_url': null,
    });
  }

  static String toBase64(Uint8List bytes) => base64Encode(bytes);
}

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepository();
});
