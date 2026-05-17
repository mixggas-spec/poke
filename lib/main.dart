import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  await bootstrapApp();
  runApp(const ProviderScope(child: PokedexApp()));
}

class PokedexApp extends ConsumerWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Pokedex',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
