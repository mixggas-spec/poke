import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route_observer.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/home_models.dart';
import '../providers/home_provider.dart';
import 'widgets/account_bottom_sheet.dart';
import 'widgets/type_badge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshHomeData(ref);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    refreshHomeData(ref);
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: homeAsync.when(
          data: (data) => _HomeBody(data: data),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Could not load your Pokédex.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.onPrimary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => refreshHomeData(ref),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HomeTopBar(
          discoveredCount: data.discoveredCount,
          totalCount: data.totalCount,
          progress: data.discoveryProgress,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _LastDiscoveredPanel(pokemon: data.lastDiscovered),
          ),
        ),
        const SizedBox(height: 16),
        _CameraButton(onPressed: () => context.push('/camera')),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.discoveredCount,
    required this.totalCount,
    required this.progress,
  });

  final int discoveredCount;
  final int totalCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.push('/pokedex-index'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$discoveredCount / $totalCount discovered',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 5,
                        backgroundColor: AppColors.surface,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => showAccountBottomSheet(context),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.person,
                  color: AppColors.onPrimary,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastDiscoveredPanel extends StatelessWidget {
  const _LastDiscoveredPanel({required this.pokemon});

  final PokemonSummary? pokemon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: pokemon == null ? const _EmptyDiscoveryState() : _PokemonContent(pokemon: pokemon!),
    );
  }
}

class _EmptyDiscoveryState extends StatelessWidget {
  const _EmptyDiscoveryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.catching_pokemon,
              size: 96,
              color: AppColors.background.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Pokémon discovered yet.\nStart scanning!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokemonContent extends StatelessWidget {
  const _PokemonContent({required this.pokemon});

  final PokemonSummary pokemon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: pokemon.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: pokemon.imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.onPrimary,
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (_, _, _) => Icon(
                      Icons.image_not_supported_outlined,
                      size: 80,
                      color: AppColors.background.withValues(alpha: 0.5),
                    ),
                  )
                : Icon(
                    Icons.catching_pokemon,
                    size: 120,
                    color: AppColors.background.withValues(alpha: 0.4),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            '#${pokemon.pokedexNumber.toString().padLeft(3, '0')}',
            style: TextStyle(
              color: AppColors.onPrimary.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pokemon.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.onPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
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
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.45),
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 88,
          height: 88,
          child: Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 42,
          ),
        ),
      ),
    );
  }
}
