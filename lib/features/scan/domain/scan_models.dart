import '../../home/domain/home_models.dart';

enum ScanStatusType {
  identified,
  notIdentified,
  noPokemonDetected,
  error,
}

class ScanResult {
  const ScanResult({
    required this.status,
    this.confidence,
    this.pokemon,
    this.rawPokemonName,
    this.rawPokedexNumber,
  });

  final ScanStatusType status;
  final double? confidence;
  final PokemonSummary? pokemon;
  final String? rawPokemonName;
  final int? rawPokedexNumber;

  factory ScanResult.error() => const ScanResult(status: ScanStatusType.error);

  bool get isIdentified => status == ScanStatusType.identified;
}

enum DiscoveryOutcomeType { newDiscovery, alreadyDiscovered }

class DiscoveryOutcome {
  const DiscoveryOutcome({
    required this.type,
    required this.pokemon,
  });

  final DiscoveryOutcomeType type;
  final PokemonSummary pokemon;
}

class ScanSession {
  const ScanSession({
    required this.result,
    this.previewImageBytes,
  });

  final ScanResult result;
  final List<int>? previewImageBytes;
}
