import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trans_bee/model/profile_model.dart';
import 'package:trans_bee/providers/auth_provider.dart';
import 'package:trans_bee/providers/profile_provider.dart';
import 'package:trans_bee/screens/home_page.dart';
import 'package:trans_bee/screens/login_page.dart';
import 'package:trans_bee/screens/profile_setup_page.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final profileAsync = ref.watch(profileProvider);

    return authAsync.when(
      loading: () => _buildLoadingScreen(),
      error: (error, stack) => _buildErrorScreen(error),
      data: (user) {
        if (user == null) return const LoginPage();

        // Handle all possible profile states safely
        switch (profileAsync) {
          case AsyncData(value: final profile):
            return _handleProfileData(profile);
          case AsyncError(error: final error):
            return _buildErrorScreen(error);
          case _: // Covers AsyncLoading and any other states
            return _buildLoadingScreen();
        }
      },
    );
  }

  Widget _handleProfileData(Profile? profile) {
    final isProfileComplete = profile != null &&
        profile.name.isNotEmpty &&
        profile.mobile.isNotEmpty &&
        profile.address.isNotEmpty;

    return isProfileComplete ? const HomePage() : const ProfileSetupPage();
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScreen(Object error) {
    return Scaffold(
      body: Center(child: Text('Error: ${error.toString()}')),
    );
  }
}