import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'package:trans_bee/providers/auth_provider.dart';
import 'package:trans_bee/screens/home_page.dart';
import 'package:trans_bee/screens/login_page.dart';
import 'package:trans_bee/screens/profile_setup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // (Optional) Firestore settings; persistence is on by default for mobile.
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: authState.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(child: Text('Error: $error')),
        ),
        data: (user) {
          if (user == null) {
            // No user signed in -> Login
            return const LoginPage();
          }

          // User signed in -> check profileComplete
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(const GetOptions(source: Source.serverAndCache)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              final data = snapshot.data?.data();
              final profileComplete = (data?['profileComplete'] as bool?) ?? false;

              return profileComplete ? const HomePage() : const ProfileSetupPage();
            },
          );
        },
      ),
    );
  }
}
