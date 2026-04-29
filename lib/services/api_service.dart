import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _headersBlob() async {
    final token = await _authService.getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String _errorMsg(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      return body['error'] ?? body['message'] ?? 'Error ${res.statusCode}';
    } catch (_) {
      return 'Error ${res.statusCode}';
    }
  }

  // ── Políticas ─────────────────────────────────────────────────
  Future<List<Politica>> getPoliticasActivas() async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/politicas/activas'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => Politica.fromJson(j)).toList();
    }
    throw Exception(_errorMsg(res));
  }

  // ── Trámites ──────────────────────────────────────────────────
  Future<List<Tramite>> getTramitesByCliente(String clienteId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/tramites/cliente/$clienteId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => Tramite.fromJson(j)).toList();
    }
    throw Exception(_errorMsg(res));
  }

  Future<Tramite> getTramiteById(String id) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/tramites/$id'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return Tramite.fromJson(jsonDecode(res.body));
    }
    throw Exception(_errorMsg(res));
  }

  Future<Tramite> solicitarTramite(
      String politicaId, String clienteId, String descripcion) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/tramites/iniciar?politicaId=$politicaId&clienteId=$clienteId&descripcion=${Uri.encodeComponent(descripcion)}');
    final res = await http.post(uri, headers: await _headers(), body: '{}');
    if (res.statusCode == 200) {
      return Tramite.fromJson(jsonDecode(res.body));
    }
    throw Exception(_errorMsg(res));
  }

  Future<Uint8List> descargarPdf(String tramiteId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/pdf/tramite/$tramiteId'),
      headers: await _headersBlob(),
    );
    if (res.statusCode == 200) {
      return res.bodyBytes;
    }
    throw Exception(_errorMsg(res));
  }

  // ── Notificaciones ────────────────────────────────────────────
  Future<List<Notificacion>> getNotificacionesNoLeidas(String usuarioId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/notificaciones/usuario/$usuarioId/no-leidas'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => Notificacion.fromJson(j)).toList();
    }
    throw Exception(_errorMsg(res));
  }

  Future<List<Notificacion>> getTodasNotificaciones(String usuarioId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/notificaciones/usuario/$usuarioId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => Notificacion.fromJson(j)).toList();
    }
    throw Exception(_errorMsg(res));
  }

  Future<void> marcarNotificacionLeida(String notifId) async {
    final res = await http.put(
      Uri.parse('${AppConfig.baseUrl}/notificaciones/$notifId/leer'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(_errorMsg(res));
  }

  Future<void> marcarTodasLeidas(String usuarioId) async {
    final res = await http.put(
      Uri.parse('${AppConfig.baseUrl}/notificaciones/usuario/$usuarioId/leer-todas'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(_errorMsg(res));
  }

  // ── Tareas (funcionario) ──────────────────────────────────────
  Future<List<Tarea>> getTareasByFuncionario(String funcionarioId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/tareas/funcionario/$funcionarioId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => Tarea.fromJson(j)).toList();
    }
    throw Exception(_errorMsg(res));
  }

  Future<List<Tarea>> getTareasByDepartamento(String departamento) async {
    final res = await http.get(
      Uri.parse(
          '${AppConfig.baseUrl}/tareas/departamento/${Uri.encodeComponent(departamento)}'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => Tarea.fromJson(j)).toList();
    }
    throw Exception(_errorMsg(res));
  }

  Future<void> completarTarea(
      String tareaId, Map<String, dynamic> datos) async {
    final res = await http.put(
      Uri.parse('${AppConfig.baseUrl}/tareas/$tareaId/completar'),
      headers: await _headers(),
      body: jsonEncode(datos),
    );
    if (res.statusCode != 200) throw Exception(_errorMsg(res));
  }

  Future<Tarea> actualizarEstadoTarea(String tareaId, String estado) async {
    final res = await http.put(
      Uri.parse('${AppConfig.baseUrl}/tareas/$tareaId/estado'),
      headers: await _headers(),
      body: jsonEncode({'estado': estado}),
    );
    if (res.statusCode == 200) return Tarea.fromJson(jsonDecode(res.body));
    throw Exception(_errorMsg(res));
  }

  // ── IA ────────────────────────────────────────────────────────
  Future<String> preguntarAsistente(String pregunta) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/ai/asistente'),
      headers: await _headers(),
      body: jsonEncode({'pregunta': pregunta}),
    );
    if (res.statusCode == 200) return res.body;
    throw Exception(_errorMsg(res));
  }

  // ── Usuario ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getUsuario(String id) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/usuarios/$id'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(_errorMsg(res));
  }

  Future<Map<String, dynamic>> updateUsuario(
      String id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('${AppConfig.baseUrl}/usuarios/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(_errorMsg(res));
  }
}
