import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/models.dart';

class AuthService {
  static const _tokenKey = 'wf_token';
  static const _userKey = 'wf_user';

  Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final auth = AuthResponse.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, auth.token);
      await prefs.setString(_userKey, jsonEncode(data));
      return auth;
    }
    try {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Credenciales incorrectas');
    } catch (_) {
      throw Exception('Credenciales incorrectas');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
