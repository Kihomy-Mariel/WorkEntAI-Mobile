class AppConfig {
  static String get baseUrl {
    return const String.fromEnvironment(
      'BASE_URL',
      defaultValue: 'http://localhost:8080/api',
    );
  }

  static String get wsUrl {
    return const String.fromEnvironment(
      'WS_URL',
      defaultValue: 'ws://localhost:8080/ws/websocket',
    );
  }

  static const int primaryColor = 0xFF2E75B6;
  static const int accentColor = 0xFF00C8E8;
  static const int bgColor = 0xFF0F1628;
  static const int cardColor = 0xFF1A2340;
  static const int successColor = 0xFF22C55E;
  static const int warningColor = 0xFFF59E0B;
  static const int dangerColor = 0xFFEF4444;
}
