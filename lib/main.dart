import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/i18n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: HireGenApp()));
}

class HireGenApp extends ConsumerWidget {
  const HireGenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);
    final lang      = ref.watch(languageProvider);

    return MaterialApp.router(
      title:                    'HireGen AI',
      debugShowCheckedModeBanner: false,
      theme:                    AppTheme.light,
      darkTheme:                AppTheme.dark,
      themeMode:                themeMode,
      routerConfig:             router,
      locale:                   Locale(lang),
      supportedLocales:         const [Locale('en'), Locale('vi')],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
