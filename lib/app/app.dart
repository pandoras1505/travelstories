import 'package:flutter/material.dart';

import '../core/localization/generated/app_localizations.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class TravelStoriesApp extends StatelessWidget {
  const TravelStoriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TravelStories',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
