import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/i18n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Pre-load Be Vietnam Pro weights so font renders immediately on first frame
  await GoogleFonts.pendingFonts([
    GoogleFonts.beVietnamPro(),
    GoogleFonts.beVietnamPro(fontWeight: FontWeight.w500),
    GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
    GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
    GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800),
  ]);
  runApp(const ProviderScope(child: HireGenApp()));
}

class HireGenApp extends ConsumerWidget {
  const HireGenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final lang      = ref.watch(languageProvider);
    final router    = ref.read(appRouterProvider);

    return MaterialApp.router(
      title:                    'HireGen AI',
      debugShowCheckedModeBanner: false,
      theme:                    AppTheme.light,
      darkTheme:                AppTheme.dark,
      themeMode:                themeMode,
      routerConfig:             router,
      locale:           Locale(lang),
      supportedLocales: const [Locale('en'), Locale('vi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
