import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/presentation/widgets/type_badge.dart';
import '../../home/providers/home_provider.dart';
import '../../scan/providers/scan_provider.dart';

class NewDiscoveryScreen extends ConsumerWidget {
  const NewDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokemon = ref.watch(newDiscoveryPokemonProvider);

    if (pokemon == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No discovery data available.',
                style: TextStyle(color: AppColors.onPrimary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _continueHome(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _EnergyBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'NEW POKÉMON DISCOVERED!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      shadows: [
                        Shadow(
                          color: AppColors.accent.withValues(alpha: 0.9),
                          blurRadius: 18,
                        ),
                        Shadow(
                          color: AppColors.secondary.withValues(alpha: 0.6),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 450.ms)
                      .slideY(begin: -0.15, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 20),
                  Expanded(
                    child: pokemon.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: pokemon.imageUrl!,
                            fit: BoxFit.contain,
                          )
                            .animate()
                            .fadeIn(duration: 550.ms, delay: 200.ms)
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1, 1),
                              duration: 650.ms,
                              delay: 200.ms,
                              curve: Curves.easeOutBack,
                            )
                        : Icon(
                            Icons.catching_pokemon,
                            size: 160,
                            color: AppColors.onPrimary.withValues(alpha: 0.35),
                          )
                            .animate()
                            .fadeIn(duration: 550.ms, delay: 200.ms)
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1, 1),
                              duration: 650.ms,
                              delay: 200.ms,
                              curve: Curves.easeOutBack,
                            ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '#${pokemon.pokedexNumber.toString().padLeft(3, '0')}',
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (pokemon.type1 != null)
                        TypeBadge(type: pokemon.type1!),
                      if (pokemon.type2 != null) ...[
                        const SizedBox(width: 8),
                        TypeBadge(type: pokemon.type2!),
                      ],
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms)
                      .slideY(
                        begin: 0.35,
                        end: 0,
                        duration: 450.ms,
                        delay: 600.ms,
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: 12),
                  Text(
                    pokemon.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 750.ms)
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 450.ms,
                        delay: 750.ms,
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        pokemon.description?.trim().isNotEmpty == true
                            ? pokemon.description!.trim()
                            : 'A newly discovered Pokémon awaits more research.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.onPrimary.withValues(alpha: 0.85),
                          fontSize: 15,
                          height: 1.45,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 450.ms, delay: 900.ms),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _continueHome(context, ref),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 1100.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        delay: 1100.ms,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _continueHome(BuildContext context, WidgetRef ref) {
    ref.read(newDiscoveryPokemonProvider.notifier).setPokemon(null);
    clearScanSession(ref);
    refreshHomeData(ref);
    context.go('/home');
  }
}

class _EnergyBackground extends StatelessWidget {
  const _EnergyBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.1,
              colors: [
                AppColors.accent.withValues(alpha: 0.14),
                AppColors.secondary.withValues(alpha: 0.08),
                AppColors.background,
              ],
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fade(
              begin: 0.55,
              end: 1,
              duration: 2200.ms,
              curve: Curves.easeInOut,
            )
            .shimmer(
              duration: 2800.ms,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
      ),
    );
  }
}
