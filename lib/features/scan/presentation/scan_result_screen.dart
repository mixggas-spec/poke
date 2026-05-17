import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/presentation/widgets/type_badge.dart';
import '../../home/providers/home_provider.dart';
import '../data/scan_repository.dart';
import '../domain/scan_models.dart';
import '../providers/scan_provider.dart';

class ScanResultScreen extends ConsumerStatefulWidget {
  const ScanResultScreen({super.key});

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen> {
  bool _isConfirming = false;
  bool _showAlreadyDiscovered = false;
  String? _errorMessage;

  ScanSession? get _session => ref.watch(scanSessionProvider);

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No scan data available.',
                style: TextStyle(color: AppColors.onPrimary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/camera'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(session.result),
        ),
      ),
    );
  }

  Widget _buildContent(ScanResult result) {
    switch (result.status) {
      case ScanStatusType.identified:
        return _IdentifiedContent(
          result: result,
          isConfirming: _isConfirming,
          showAlreadyDiscovered: _showAlreadyDiscovered,
          errorMessage: _errorMessage,
          onConfirm: _confirmIdentification,
          onRetry: () => context.go('/camera'),
        );
      case ScanStatusType.notIdentified:
        return _MessageContent(
          title: 'Could not identify the Pokémon with confidence.',
          subtitle: 'Try taking a clearer photo.',
          onRetry: () => context.go('/camera'),
        );
      case ScanStatusType.noPokemonDetected:
        return _MessageContent(
          title: 'No Pokémon was detected in this image.',
          subtitle: 'Make sure the Pokémon is clearly visible.',
          onRetry: () => context.go('/camera'),
        );
      case ScanStatusType.error:
        return _MessageContent(
          title: 'Something went wrong. Please try again.',
          onRetry: () => context.go('/camera'),
        );
    }
  }

  Future<void> _confirmIdentification() async {
    final session = _session;
    if (session == null) {
      return;
    }

    final pokemon = session.result.pokemon;
    if (pokemon == null) {
      setState(() {
        _errorMessage =
            'This Pokémon is not in your catalog yet. Try scanning again.';
      });
      return;
    }

    setState(() {
      _isConfirming = true;
      _errorMessage = null;
      _showAlreadyDiscovered = false;
    });

    try {
      final outcome = await ref.read(scanRepositoryProvider).confirmDiscovery(
            pokemon,
          );

      if (!mounted) {
        return;
      }

      refreshHomeData(ref);

      if (outcome.type == DiscoveryOutcomeType.newDiscovery) {
        setNewDiscoveryPokemon(ref, outcome.pokemon);
        clearScanSession(ref);
        context.go('/new-discovery');
        return;
      }

      setState(() {
        _isConfirming = false;
        _showAlreadyDiscovered = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isConfirming = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }
}

class _IdentifiedContent extends StatelessWidget {
  const _IdentifiedContent({
    required this.result,
    required this.isConfirming,
    required this.showAlreadyDiscovered,
    required this.errorMessage,
    required this.onConfirm,
    required this.onRetry,
  });

  final ScanResult result;
  final bool isConfirming;
  final bool showAlreadyDiscovered;
  final String? errorMessage;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final pokemon = result.pokemon;
    final displayName = pokemon?.name ?? result.rawPokemonName ?? 'Pokémon';
    final number = pokemon?.pokedexNumber ?? result.rawPokedexNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Expanded(
                  child: pokemon?.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: pokemon!.imageUrl!,
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          Icons.catching_pokemon,
                          size: 120,
                          color: AppColors.background.withValues(alpha: 0.4),
                        ),
                ),
                if (number != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '#${number.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (pokemon != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (pokemon.type1 != null) TypeBadge(type: pokemon.type1!),
                      if (pokemon.type2 != null) TypeBadge(type: pokemon.type2!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Is this the Pokémon you scanned?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.primary),
          ),
        ],
        if (showAlreadyDiscovered) ...[
          const SizedBox(height: 16),
          const Text(
            "You've already discovered this Pokémon!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/pokedex-index'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Go to Pokédex'),
          ),
        ] else ...[
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isConfirming ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: isConfirming
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text("Yes, that's it!"),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: isConfirming ? null : onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onPrimary,
              side: const BorderSide(color: AppColors.secondary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('No, try again'),
          ),
        ],
      ],
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.title,
    this.subtitle,
    required this.onRetry,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.document_scanner_outlined,
          size: 72,
          color: AppColors.secondary.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ],
        const SizedBox(height: 32),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}
