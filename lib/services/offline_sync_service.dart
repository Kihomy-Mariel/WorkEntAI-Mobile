import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'local_database_service.dart';


/// Servicio de sincronización offline (CU-31 — Opción B).
///
/// Responsabilidades:
///  1. Detectar conectividad de red
///  2. Sincronizar caché local desde el backend cuando hay conexión
///  3. Ejecutar acciones pendientes que se guardaron sin conexión
///
/// Principio SRP: solo gestiona la sincronización, no la presentación.
/// Principio DIP: depende de LocalDatabaseService (interfaz de datos locales).
class OfflineSyncService {
  final LocalDatabaseService _db;
  final String _baseUrl;

  OfflineSyncService({
    required LocalDatabaseService db,
    required String baseUrl,
  })  : _db = db,
        _baseUrl = baseUrl;

  // ── Estado de conectividad ────────────────────────────────────────────────

  /// Verifica si hay conexión activa al backend.
  /// No usamos connectivity_plus para evitar dependencia adicional;
  /// simplemente intentamos un HEAD al endpoint de health.
  Future<bool> hayConexion() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/actuator/health'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200 || resp.statusCode == 401 || resp.statusCode == 403 || resp.statusCode == 404;
    } catch (_) {
      return false;
    }
  }

  // ── Sincronización completa ───────────────────────────────────────────────

  /// Sincroniza todos los datos del backend al caché local.
  /// Debe llamarse al iniciar la app o al recuperar conexión.
  ///
  /// @param token JWT del usuario para autenticar las peticiones
  /// @param rol   Rol del usuario (determina qué datos sincronizar)
  Future<SyncResult> sincronizarTodo(String token, String rol) async {
    if (!await hayConexion()) {
      debugPrint('📴 Sin conexión — se usará caché local');
      return const SyncResult(exitoso: false, mensaje: 'Sin conexión a internet');

    }

    debugPrint('🔄 Iniciando sincronización offline...');
    int sincronizados = 0;
    final errores = <String>[];

    // Siempre sincronizar políticas activas (todos los roles)
    try {
      await _sincronizarPoliticas(token);
      sincronizados++;
    } catch (e) {
      errores.add('Políticas: $e');
    }

    // Según el rol
    if (rol == 'CLIENTE' || rol == 'ADMIN') {
      try {
        await _sincronizarTramites(token);
        sincronizados++;
      } catch (e) {
        errores.add('Trámites: $e');
      }
    }

    if (rol == 'FUNCIONARIO' || rol == 'ADMIN') {
      try {
        await _sincronizarTareas(token);
        sincronizados++;
      } catch (e) {
        errores.add('Tareas: $e');
      }
    }

    if (rol == 'ADMIN') {
      try {
        await _sincronizarKpis(token);
        sincronizados++;
      } catch (e) {
        errores.add('KPIs: $e');
      }
    }

    // Ejecutar acciones pendientes
    try {
      final accionesEjecutadas = await _ejecutarAccionesPendientes(token);
      debugPrint('✅ $accionesEjecutadas acción(es) pendiente(s) ejecutadas');
    } catch (e) {
      errores.add('Acciones pendientes: $e');
    }

    await _guardarFechaUltimaSinc();

    debugPrint('✅ Sincronización completa: $sincronizados módulo(s)');
    return SyncResult(
      exitoso: errores.isEmpty,
      sincronizados: sincronizados,
      errores: errores,
      mensaje: errores.isEmpty
          ? 'Sincronización completa'
          : 'Sincronización parcial (${errores.length} error(es))',
    );
  }

  // ── Sincronización por módulo ─────────────────────────────────────────────

  Future<void> _sincronizarPoliticas(String token) async {
    final resp = await _get('/politicas', token);
    if (resp != null) {
      final List<dynamic> lista = jsonDecode(resp);
      await _db.guardarPoliticas(lista.cast<Map<String, dynamic>>());
      debugPrint('   📋 ${lista.length} política(s) sincronizada(s)');
    }
  }

  Future<void> _sincronizarTramites(String token) async {
    final resp = await _get('/tramites/mis-tramites', token);
    if (resp != null) {
      final List<dynamic> lista = jsonDecode(resp);
      await _db.guardarTramites(lista.cast<Map<String, dynamic>>());
      debugPrint('   📁 ${lista.length} trámite(s) sincronizado(s)');
    }
  }

  Future<void> _sincronizarTareas(String token) async {
    final resp = await _get('/tareas/mis-tareas', token);
    if (resp != null) {
      final List<dynamic> lista = jsonDecode(resp);
      await _db.guardarTareas(lista.cast<Map<String, dynamic>>());
      debugPrint('   ✅ ${lista.length} tarea(s) sincronizada(s)');
    }
  }

  Future<void> _sincronizarKpis(String token) async {
    final resp = await _get('/analytics/kpis', token);
    if (resp != null) {
      final Map<String, dynamic> kpis = jsonDecode(resp);
      await _db.guardarKpis(kpis);
      debugPrint('   📊 KPIs sincronizados');
    }
  }

  // ── Ejecución de acciones pendientes ─────────────────────────────────────

  Future<int> _ejecutarAccionesPendientes(String token) async {
    final pendientes = await _db.obtenerAccionesPendientes();
    int ejecutados = 0;

    for (final accion in pendientes) {
      final int pendienteId = accion['_pendienteId'] as int;
      final String tipo = accion['_tipo'] as String;

      try {
        bool exito = false;

        switch (tipo) {
          case 'COMPLETAR_TAREA':
            exito = await _completarTarea(token, accion);
            break;
          case 'CREAR_TRAMITE':
            exito = await _crearTramite(token, accion);
            break;
          default:
            debugPrint('⚠️ Tipo de acción desconocido: $tipo');
            await _db.incrementarIntentosAccion(pendienteId);
            continue;
        }

        if (exito) {
          await _db.eliminarAccionPendiente(pendienteId);
          ejecutados++;
        } else {
          await _db.incrementarIntentosAccion(pendienteId);
        }
      } catch (e) {
        debugPrint('⚠️ Error ejecutando acción pendiente $tipo: $e');
        await _db.incrementarIntentosAccion(pendienteId);
      }
    }

    return ejecutados;
  }

  Future<bool> _completarTarea(String token, Map<String, dynamic> payload) async {
    final tareaId = payload['tareaId'];
    final body = jsonEncode({
      'observacion': payload['observacion'] ?? '',
      'datosFormulario': payload['datosFormulario'] ?? {},
    });

    final resp = await http.put(
      Uri.parse('$_baseUrl/tareas/$tareaId/completar'),
      headers: _headers(token),
      body: body,
    );
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  Future<bool> _crearTramite(String token, Map<String, dynamic> payload) async {
    final body = jsonEncode(payload);
    final resp = await http.post(
      Uri.parse('$_baseUrl/tramites'),
      headers: _headers(token),
      body: body,
    );
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  // ── Fecha de última sincronización ────────────────────────────────────────

  Future<void> _guardarFechaUltimaSinc() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultima_sync', DateTime.now().toIso8601String());
  }

  Future<DateTime?> obtenerFechaUltimaSinc() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('ultima_sync');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ── HTTP Helper ───────────────────────────────────────────────────────────

  Future<String?> _get(String endpoint, String token) async {
    try {
      final resp = await http
          .get(
            Uri.parse('$_baseUrl$endpoint'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) return resp.body;
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
}

/// Resultado de una operación de sincronización
class SyncResult {
  final bool exitoso;
  final int sincronizados;
  final List<String> errores;
  final String mensaje;

  const SyncResult({
    required this.exitoso,
    this.sincronizados = 0,
    this.errores = const [],
    this.mensaje = '',
  });
}
