import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workentai_mobile/services/auth_service.dart';

class MockClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;
  MockClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService', () {
    test('login éxito guarda token y usuario', () async {
      final mockClient = MockClient((request) async {
        final responseBody = jsonEncode({
          'id': 'user-123',
          'email': 'test@test.com',
          'nombre': 'Test User',
          'rol': 'CLIENTE',
          'token': 'fake-jwt-token'
        });
        return http.StreamedResponse(
          Stream.value(utf8.encode(responseBody)),
          200,
        );
      });

      final authService = AuthService(client: mockClient);
      final response = await authService.login('test@test.com', 'password123');

      expect(response.token, 'fake-jwt-token');
      expect(response.id, 'user-123');

      final token = await authService.getToken();
      expect(token, 'fake-jwt-token');

      final user = await authService.getUser();
      expect(user!['nombre'], 'Test User');
    });

    test('login falla lanza excepción', () async {
      final mockClient = MockClient((request) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'error': 'Credenciales incorrectas'}))),
          401,
        );
      });

      final authService = AuthService(client: mockClient);
      
      expect(
        () => authService.login('wrong@test.com', 'badpass'),
        throwsA(isA<Exception>()),
      );
    });

    test('logout limpia SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'wf_token': 'existing-token',
        'wf_user': '{"nombre": "test"}'
      });

      final authService = AuthService();
      await authService.logout();

      final token = await authService.getToken();
      expect(token, isNull);
    });

    test('isLoggedIn retorna true si hay token', () async {
      SharedPreferences.setMockInitialValues({'wf_token': 'valid-token'});
      final authService = AuthService();
      expect(await authService.isLoggedIn(), isTrue);
    });
  });
}
