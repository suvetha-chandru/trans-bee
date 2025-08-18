import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trans_bee/screens/profile_setup_page.dart';
import 'package:trans_bee/screens/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _primeAuthStream();
  }

  Future<void> _primeAuthStream() async {
    // Ensures initial auth state is settled (useful after hot-restart)
    setState(() => _isLoading = true);
    await FirebaseAuth.instance.authStateChanges().first;
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value.trim()) ? null : 'Enter a valid email';
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return value.length >= 6 ? null : 'Password must be at least 6 characters';
  }

  Future<void> _navigateAfterLogin(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.serverAndCache));

    final profileComplete = (doc.data()?['profileComplete'] as bool?) ?? false;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => profileComplete ? const HomePage() : const ProfileSetupPage(),
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _navigateAfterLogin(cred.user!);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e, isLogin: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // seed user doc with profileComplete=false
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'email': _emailController.text.trim(),
        'profileComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
      );
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e, isLogin: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _emailValidator(email) != null) {
      _showSnack('Enter a valid email to reset password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnack('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e, isReset: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAuthError(FirebaseAuthException e, {bool isLogin = false, bool isReset = false}) {
    String msg;
    switch (e.code) {
      case 'invalid-email':
        msg = 'The email address is badly formatted.';
        break;
      case 'user-not-found':
        msg = isLogin ? 'No user found for that email.' : 'No user found.';
        break;
      case 'wrong-password':
        msg = 'Wrong password provided for that user.';
        break;
      case 'user-disabled':
        msg = 'This user account has been disabled.';
        break;
      case 'email-already-in-use':
        msg = 'An account already exists for that email.';
        break;
      case 'weak-password':
        msg = 'Password should be at least 6 characters.';
        break;
      case 'network-request-failed':
        msg = 'Network error. Check your internet connection.';
        break;
      case 'too-many-requests':
        msg = 'Too many attempts. Try again later or reset your password.';
        break;
      default:
        msg = e.message ?? 'Authentication error.';
    }
    if (isReset && e.code == 'missing-email') msg = 'Please enter your email.';
    _showSnack(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sign in to continue',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: _passwordValidator,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _signIn,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Sign in'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _isLoading ? null : _signUp,
                          child: const Text('Create an account'),
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
