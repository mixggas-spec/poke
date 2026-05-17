import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/placeholder/presentation/placeholder_screen.dart';
import '../../features/scan/presentation/camera_screen.dart';
import '../../features/scan/presentation/scan_result_screen.dart';
import '../providers/auth_state_provider.dart';
import 'app_route_observer.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authStateProvider).value ??
      AuthStatus.unauthenticated;

  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) {
    refreshNotifier.value++;
  });
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    observers: [appRouteObserver],
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.uri.path;
      final isSplashRoute = location == '/splash';
      final isAuthRoute = location == '/login' || location == '/register';
      final isPublicRoute = isSplashRoute || isAuthRoute;

      if (authStatus == AuthStatus.authenticated) {
        if (isAuthRoute || isSplashRoute) {
          return '/home';
        }
        return null;
      }

      if (!isPublicRoute) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/scan-result',
        builder: (context, state) => const ScanResultScreen(),
      ),
      GoRoute(
        path: '/new-discovery',
        builder: (context, state) =>
            const PlaceholderScreen(label: 'New Discovery'),
      ),
      GoRoute(
        path: '/pokedex-index',
        builder: (context, state) =>
            const PlaceholderScreen(label: 'Pokedex Index'),
      ),
      GoRoute(
        path: '/pokemon-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PlaceholderScreen(label: 'Pokemon Detail $id');
        },
      ),
    ],
    errorBuilder: (context, state) =>
        const PlaceholderScreen(label: 'Not Found'),
  );
});
