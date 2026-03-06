import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'transitions.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter() {
    final supabase = Supabase.instance.client;

    final router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: supabase.auth.currentSession != null
          ? '/dashboard'
          : '/login',

      redirect: (context, state) {
        final session = supabase.auth.currentSession;
        final isAuthRoute =
            state.uri.path == '/login' || state.uri.path == '/signup';

        if (session == null && !isAuthRoute) {
          if (state.uri.queryParameters.containsKey('code')) {
            return null;
          }
          return '/login';
        }

        if (session != null && isAuthRoute) {
          return '/dashboard';
        }

        return null;
      },

      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => fadeSlideTransition(
            context: context,
            state: state,
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          path: '/signup',
          pageBuilder: (context, state) => fadeSlideTransition(
            context: context,
            state: state,
            child: const SignupScreen(),
          ),
        ),
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => fadeSlideTransition(
            context: context,
            state: state,
            child: const DashboardScreen(),
          ),
        ),
      ],
    );

    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.passwordRecovery) {
        router.go('/dashboard');
      } else if (event == AuthChangeEvent.signedOut) {
        router.go('/login');
      }
    });

    return router;
  }
}
