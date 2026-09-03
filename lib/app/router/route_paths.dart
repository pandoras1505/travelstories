/// Central registry of route paths. Screens and redirects reference these
/// constants rather than hardcoding strings, so the route tree stays the
/// single source of truth described in the navigation architecture.
class RoutePaths {
  RoutePaths._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String app = '/app';
  static const String home = '/app/home';
  static const String explore = '/app/explore';
  static const String create = '/app/create';
  static const String travelBooks = '/app/travel-books';
  static const String profile = '/app/profile';
  static const String editProfile = '/app/profile/edit';
}
