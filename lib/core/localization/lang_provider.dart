import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final langProvider = StateNotifierProvider<LangNotifier, String>((ref) {
  return LangNotifier();
});

class LangNotifier extends StateNotifier<String> {
  LangNotifier() : super('en') {
    _loadLang();
  }

  static const _key = 'app_lang';

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? 'en';
  }

  Future<void> setLang(String langCode) async {
    state = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, langCode);
  }
}
