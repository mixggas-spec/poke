import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/home_provider.dart';

class AccountBottomSheet extends ConsumerWidget {
  const AccountBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameAsync = ref.watch(profileUsernameProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          usernameAsync.when(
            data: (username) => Text(
              username,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ),
            error: (_, _) => const Text(
              'Could not load username.',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _signOut(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final client = supabaseClient;
    if (client != null) {
      await client.auth.signOut();
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

void showAccountBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const AccountBottomSheet(),
  );
}
