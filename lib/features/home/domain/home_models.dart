class PokemonSummary {
  const PokemonSummary({
    required this.id,
    required this.pokedexNumber,
    required this.name,
    this.imageUrl,
    this.description,
    this.type1,
    this.type2,
  });

  final String id;
  final int pokedexNumber;
  final String name;
  final String? imageUrl;
  final String? description;
  final String? type1;
  final String? type2;
}

class HomeData {
  const HomeData({
    required this.discoveredCount,
    required this.totalCount,
    this.lastDiscovered,
  });

  final int discoveredCount;
  final int totalCount;
  final PokemonSummary? lastDiscovered;

  double get discoveryProgress =>
      totalCount > 0 ? discoveredCount / totalCount : 0;
}
