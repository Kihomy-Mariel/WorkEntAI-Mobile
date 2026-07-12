import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workentai_mobile/services/app_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppProvider', () {
    test('estado inicial', () {
      final provider = AppProvider();
      expect(provider.user, isNull);
      expect(provider.politicas, isEmpty);
      expect(provider.tramites, isEmpty);
      expect(provider.tareas, isEmpty);
      expect(provider.notificaciones, isEmpty);
      expect(provider.loadingAuth, isFalse);
    });

    test('logout limpia el estado', () async {
      final provider = AppProvider();
      // Simulate login state
      SharedPreferences.setMockInitialValues({
        'wf_token': 'fake-token',
        'wf_user': '{"id":"1","nombre":"test"}'
      });
      
      await provider.checkSession();
      expect(provider.user, isNotNull);

      await provider.logout();

      expect(provider.user, isNull);
      expect(provider.politicas, isEmpty);
      expect(provider.tramites, isEmpty);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('wf_token'), isNull);
    });
  });
}
