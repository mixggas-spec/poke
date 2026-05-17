import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_client.dart';

enum AuthStatus { authenticated, unauthenticated }

final authStateProvider = StreamProvider<AuthStatus>((ref) {
  final client = supabaseClient;
  if (client == null) {
    return Stream.value(AuthStatus.unauthenticated);
  }

  return _authStatusStream(client);
});

Stream<AuthStatus> _authStatusStream(SupabaseClient client) {
  late final StreamController<AuthStatus> controller;

  controller = StreamController<AuthStatus>(
    onListen: () {
      controller.add(_statusFromSession(client.auth.currentSession));

      final subscription = client.auth.onAuthStateChange.listen(
        (data) => controller.add(_statusFromSession(data.session)),
        onError: controller.addError,
      );

      controller.onCancel = () => subscription.cancel();
    },
  );

  return controller.stream;
}

AuthStatus _statusFromSession(Session? session) {
  return session != null
      ? AuthStatus.authenticated
      : AuthStatus.unauthenticated;
}
