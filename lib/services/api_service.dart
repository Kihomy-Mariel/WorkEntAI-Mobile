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


  // ── Agente IA (CU-22/23) ──────────────────────────────────────
  Future<Map<String, dynamic>> iniciarAgenteSesion() async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/agente/sesion'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception(_errorMsg(res));
  }

  Future<Map<String, dynamic>> enviarAgenteMensaje(String sessionId, String mensaje) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/agente/sesion/$sessionId/mensaje'),
      headers: await _headers(),
      body: jsonEncode({'mensaje': mensaje}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception(_errorMsg(res));
  }

  Future<Map<String, dynamic>> obtenerAgenteSesion(String sessionId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/agente/sesion/$sessionId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception(_errorMsg(res));
  }

  Future<void> cerrarAgenteSesion(String sessionId) async {
    final res = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/agente/sesion/$sessionId'),
      headers: await _headers(),
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(_errorMsg(res));
    }
  }

  // ── Gestión Documental (CU-24 al 27) ─────────────────────────
  Future<List<dynamic>> listarDocumentos(String tramiteId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/documentos/tramite/$tramiteId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception(_errorMsg(res));
  }

  Future<String> obtenerDocumentoUrl(String documentoId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/documentos/$documentoId/url'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['url'] ?? '';
    }
    throw Exception(_errorMsg(res));
  }

  Future<Map<String, dynamic>> subirDocumento({
    required String tramiteId,
    required String filePath,
    required String fileName,
    String? nodoId,
    String? descripcion,
  }) async {
    final token = await _authService.getToken();
    final uri = Uri.parse('${AppConfig.baseUrl}/documentos/tramite/$tramiteId');
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (nodoId != null && nodoId.isNotEmpty) {
      request.fields['nodoId'] = nodoId;
    }
    if (descripcion != null && descripcion.isNotEmpty) {
      request.fields['descripcion'] = descripcion;
    }

    request.files.add(await http.MultipartFile.fromPath('archivo', filePath, filename: fileName));

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception(_errorMsg(res));
  }

  // ── Motor Predictivo (CU-28/29) ──────────────────────────────
  Future<Map<String, dynamic>> predecirRutaOptima(String politicaId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/predictor/ruta/$politicaId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception(_errorMsg(res));
  }

  Future<Map<String, dynamic>> calcularRiesgoDemora(String tramiteId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/predictor/riesgo/$tramiteId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
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

