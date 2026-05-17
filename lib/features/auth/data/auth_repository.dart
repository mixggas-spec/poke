import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client.dart';

class UsernameTakenException implements Exception {
  const UsernameTakenException();
}

class AuthRepository {
  SupabaseClient get _client {
    final client = supabaseClient;
    if (client == null) {
      throw const AuthException('Supabase is not configured.');
    }
    return client;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Registration failed. Please try again.');
    }

    try {
      await _client.from('profiles').insert({
        'id': user.id,
        'username': username.trim(),
      });
    } on PostgrestException catch (error) {
      await _client.auth.signOut();
      if (error.code == '23505') {
        throw const UsernameTakenException();
      }
      rethrow;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
