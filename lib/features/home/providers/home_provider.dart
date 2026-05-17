import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_repository.dart';
import '../domain/home_models.dart';

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  return ref.read(homeRepositoryProvider).fetchHomeData();
});

final profileUsernameProvider = FutureProvider<String>((ref) async {
  return ref.read(homeRepositoryProvider).fetchUsername();
});

void refreshHomeData(WidgetRef ref) {
  ref.invalidate(homeDataProvider);
  ref.invalidate(profileUsernameProvider);
}
