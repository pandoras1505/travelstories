import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/state_views.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/experiences/presentation/screens/create_experience_screen.dart';
import '../../features/experiences/presentation/screens/edit_experience_screen.dart';
import '../../features/exploration/presentation/screens/explore_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/travel_books/presentation/screens/create_travel_book_screen.dart';
import '../../features/travel_books/presentation/screens/edit_travel_book_screen.dart';
import '../../features/travel_books/presentation/screens/travel_book_detail_screen.dart';
import '../../features/travel_books/presentation/screens/travel_books_screen.dart';
import 'app_shell.dart';
import 'go_router_refresh_stream.dart';
import 'route_paths.dart';

const _authRoutes = {
  RoutePaths.login,
  RoutePaths.register,
  RoutePaths.forgotPassword,
};

/// The app-wide route tree, built once by `ref.read(authRepositoryProvider)`
/// so it goes through the same DI seam as the rest of the app (tests can
/// override [authRepositoryProvider] with a fake). `redirect` keeps `/app/*`
/// for signed-in users only and bounces a signed-in user away from the auth
/// screens; it re-runs whenever [GoRouterRefreshStream] notifies it of an
/// auth state change. The splash route is left alone — [SplashScreen]
/// decides its own destination once, after its brand-moment delay.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.read(authRepositoryProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges()),
    redirect: (context, state) {
      final isSplash = state.matchedLocation == RoutePaths.splash;
      if (isSplash) return null;

      final isSignedIn = authRepository.currentUser != null;
      final isAuthRoute = _authRoutes.contains(state.matchedLocation);

      if (!isSignedIn && !isAuthRoute) return RoutePaths.login;
      if (isSignedIn && isAuthRoute) return RoutePaths.home;
      return null;
    },
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
                builder: (context, state) => const CreateTravelBookScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.travelBooks,
                builder: (context, state) => const TravelBooksScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => TravelBookDetailScreen(
                      travelBookId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => EditTravelBookScreen(
                          travelBookId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'experiences/new',
                        builder: (context, state) => CreateExperienceScreen(
                          travelBookId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'experiences/:experienceId/edit',
                        builder: (context, state) => EditExperienceScreen(
                          travelBookId: state.pathParameters['id']!,
                          experienceId: state.pathParameters['experienceId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: ErrorView(message: state.error?.message)),
  );
});
