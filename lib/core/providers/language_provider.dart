import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLangKey = 'hiregena-lang';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = p.getString(_kLangKey) ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLangKey, lang);
  }

  void toggle() => setLanguage(state == 'en' ? 'vi' : 'en');
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, String>((_) => LanguageNotifier());
