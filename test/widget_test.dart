import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokedex/main.dart';

void main() {
  testWidgets('boots to splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PokedexApp()));
    await tester.pump();

    expect(find.text('Pokédex'), findsOneWidget);
  });
}
