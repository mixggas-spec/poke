import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/domain/home_models.dart';
import '../domain/scan_models.dart';

class ScanSessionNotifier extends Notifier<ScanSession?> {
  @override
  ScanSession? build() => null;

  void setSession(ScanSession? session) => state = session;
}

class NewDiscoveryPokemonNotifier extends Notifier<PokemonSummary?> {
  @override
  PokemonSummary? build() => null;

  void setPokemon(PokemonSummary? pokemon) => state = pokemon;
}

final scanSessionProvider =
    NotifierProvider<ScanSessionNotifier, ScanSession?>(
  ScanSessionNotifier.new,
);

final newDiscoveryPokemonProvider =
    NotifierProvider<NewDiscoveryPokemonNotifier, PokemonSummary?>(
  NewDiscoveryPokemonNotifier.new,
);

void setScanSession(WidgetRef ref, ScanSession session) {
  ref.read(scanSessionProvider.notifier).setSession(session);
}

void clearScanSession(WidgetRef ref) {
  ref.read(scanSessionProvider.notifier).setSession(null);
}

void setNewDiscoveryPokemon(WidgetRef ref, PokemonSummary pokemon) {
  ref.read(newDiscoveryPokemonProvider.notifier).setPokemon(pokemon);
}
