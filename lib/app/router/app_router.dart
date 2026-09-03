import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/state_views.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/exploration/presentation/screens/explore_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/travel_books/presentation/screens/create_entry_screen.dart';
import '../../features/travel_books/presentation/screens/travel_books_screen.dart';
import 'app_shell.dart';
import 'route_paths.dart';

/// App-wide route tree. Auth guarding (redirecting `/app/*` to
/// [RoutePaths.login] when signed out, and `/login` etc. to
/// [RoutePaths.home] when already signed in) is added in the Authentication
/// phase once a real auth state stream exists to redirect on.
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RoutePaths.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: RoutePaths.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.explore,
              builder: (context, state) => const ExploreScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.create,
              builder: (context, state) => const CreateEntryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.travelBooks,
              builder: (context, state) => const TravelBooksScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: ErrorView(message: state.error?.message)),
);
