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

      // Alerts screen filter chips
      'filter_all': 'All',
      'filter_warning': 'Warning',
      'filter_critical': 'Critical',

      // Alert tile labels
      'severity_critical': 'CRITICAL',
      'severity_high': 'HIGH',
      'severity_warning': 'WARNING',
      'severity_medium': 'MEDIUM',
      'severity_low': 'LOW',
      'severity_info': 'INFO',
      'badge_new': 'NEW',
      'swipe_acknowledge': 'ACKNOWLEDGE',

      // Search
      'search_alerts': 'Search alerts...',
      'no_alerts_found': 'No alerts found',
      'try_different': 'Try a different search term.',

      // Empty states
      'no_alerts': 'No active alerts',
      'all_nominal': 'All systems nominal',
      'no_alerts_sub': 'No alerts',
      'subscribe_rooms': 'Subscribe to rooms to receive alerts.',

      // Detail sheet
      'location': 'Location',
      'device_id': 'Device ID',
      'timestamp': 'Timestamp',
      'status': 'Status',
      'status_acknowledged': 'Acknowledged',
      'status_active': 'Active — Needs Attention',
      'badge_safe': 'SAFE',
      'btn_acknowledge': 'ACKNOWLEDGE & MARK SAFE',
      'btn_acknowledging': 'ACKNOWLEDGING...',
      'btn_view_room': 'VIEW ROOM',
      'sensor_data': 'Sensor Data',
      'fusion_score': 'Fusion Score',
      'alert_type': 'Alert Type',
      'image_capture': 'Detection Capture',

      // Timestamps
      'just_now': 'just now',
    },
    'id': {
      'language': 'Bahasa',
      'english': 'Inggris',
      'indonesian': 'Indonesia',
      'alerts': 'Peringatan',
      'dashboard': 'Dasbor',
      'profile': 'Profil',
      'rooms': 'Ruangan',

      // Alerts screen filter chips
      'filter_all': 'Semua',
      'filter_warning': 'Waspada',
      'filter_critical': 'Kritis',

      // Alert tile labels
      'severity_critical': 'KRITIS',
      'severity_high': 'TINGGI',
      'severity_warning': 'WASPADA',
      'severity_medium': 'MENENGAH',
      'severity_low': 'RENDAH',
      'severity_info': 'INFO',
      'badge_new': 'BARU',
      'swipe_acknowledge': 'AKUI',

      // Search
      'search_alerts': 'Cari peringatan...',
      'no_alerts_found': 'Tidak ada peringatan ditemukan',
      'try_different': 'Coba kata kunci yang berbeda.',

      // Empty states
      'no_alerts': 'Tidak ada peringatan aktif',
      'all_nominal': 'Semua sistem normal',
      'no_alerts_sub': 'Tidak ada peringatan',
      'subscribe_rooms': 'Langganan ruangan untuk menerima peringatan.',

      // Detail sheet
      'location': 'Lokasi',
      'device_id': 'ID Perangkat',
      'timestamp': 'Waktu',
      'status': 'Status',
      'status_acknowledged': 'Telah Dikonfirmasi',
      'status_active': 'Aktif — Perlu Perhatian',
      'badge_safe': 'AMAN',
      'btn_acknowledge': 'KONFIRMASI & TANDAI AMAN',
      'btn_acknowledging': 'MENGKONFIRMASI...',
      'btn_view_room': 'LIHAT RUANGAN',
      'sensor_data': 'Data Sensor',
      'fusion_score': 'Skor Fusi',
      'alert_type': 'Tipe Peringatan',
      'image_capture': 'Tangkapan Deteksi',

      // Timestamps
      'just_now': 'baru saja',
    },
  };

  static String tr(String key, String langCode) {
    return strings[langCode]?[key] ?? strings['en']?[key] ?? key;
  }

  /// Translate a severity string (e.g. 'critical') → localized label
  static String severity(String? sev, String langCode) {
    final key = 'severity_${sev?.toLowerCase() ?? 'info'}';
    return tr(key, langCode);
  }
}
