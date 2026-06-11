class AppTranslations {
  static const Map<String, Map<String, String>> strings = {
    'en': {
      'language': 'Language',
      'english': 'English',
      'indonesian': 'Indonesian',
      'alerts': 'Alerts',
      'dashboard': 'Dashboard',
      'profile': 'Profile',
      'rooms': 'Rooms',
    },
    'id': {
      'language': 'Bahasa',
      'english': 'Inggris',
      'indonesian': 'Indonesia',
      'alerts': 'Peringatan',
      'dashboard': 'Dasbor',
      'profile': 'Profil',
      'rooms': 'Ruangan',
    }
  };

  static String tr(String key, String langCode) {
    return strings[langCode]?[key] ?? key;
  }
}
