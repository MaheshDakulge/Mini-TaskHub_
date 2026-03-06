import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleAuth();
  }

  Future<void> _handleAuth() async {
    final supabase = Supabase.instance.client;

    // Supabase handles the session exchange from the initial URL automatically.
    // However, it is an asynchronous process. We must wait for the auth state.
    
    // First, check if we already have a session natively
    final session = supabase.auth.currentSession;
    if (session != null) {
      if (mounted) context.go('/dashboard');
      return;
    }

    // Otherwise, listen for Auth state changes (e.g. from Google OAuth callback)
    supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.passwordRecovery) {
        context.go('/dashboard');
      } else if (event == AuthChangeEvent.initialSession) {
        // If initialSession is triggered and session is still null, we are truly not logged in
        if (data.session == null) {
          context.go('/login');
        }
      } else if (event == AuthChangeEvent.signedOut) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}