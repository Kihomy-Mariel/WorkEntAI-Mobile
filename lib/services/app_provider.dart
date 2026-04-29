import 'package:flutter/material.dart';
import '../models/models.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'notification_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  // ── State ─────────────────────────────────────────────────────
  Map<String, dynamic>? _user;
  List<Politica> _politicas = [];
  List<Tramite> _tramites = [];
  List<Tarea> _tareas = [];
  List<Notificacion> _notificaciones = [];

  bool _loadingAuth = false;
  bool _loadingData = false;
  bool _loadingAction = false;

  String _authError = '';
  String _dataError = '';
  String _actionError = '';
  String _actionSuccess = '';

  // ── Getters ───────────────────────────────────────────────────
  Map<String, dynamic>? get user => _user;
  String get userId => _user?['id'] ?? '';
  String get userNombre => _user?['nombre'] ?? '';
  String get userEmail => _user?['email'] ?? '';
  String get userRol => _user?['rol'] ?? '';
  String get userDepartamento => _user?['departamento'] ?? '';

  List<Politica> get politicas => _politicas;
  List<Tramite> get tramites => _tramites;
  List<Tramite> get tramitesActivos =>
      _tramites.where((t) => t.estado != 'COMPLETADO' && t.estado != 'RECHAZADO').toList();
  List<Tramite> get tramitesCompletados =>
      _tramites.where((t) => t.estado == 'COMPLETADO').toList();

  List<Tarea> get tareas => _tareas;
  List<Tarea> get tareasPendientes =>
      _tareas.where((t) => t.estado == 'PENDIENTE').toList();
  List<Tarea> get tareasEnProceso =>
      _tareas.where((t) => t.estado == 'EN_PROCESO').toList();
  List<Tarea> get tareasCompletadas =>
      _tareas.where((t) => t.estado == 'COMPLETADO').toList();

  List<Notificacion> get notificaciones => _notificaciones;
  int get unreadCount => _notificaciones.where((n) => !n.leida).length;

  bool get loadingAuth => _loadingAuth;
  bool get loadingData => _loadingData;
  bool get loadingAction => _loadingAction;

  String get authError => _authError;
  String get dataError => _dataError;
  String get actionError => _actionError;
  String get actionSuccess => _actionSuccess;

  // ── Auth ──────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _loadingAuth = true;
    _authError = '';
    notifyListeners();
    try {
      final auth = await _authService.login(email, password);
      _user = await _authService.getUser();
      _loadingAuth = false;
      notifyListeners();

      // Registrar token FCM para notificaciones push
      NotificationService.registrarToken(auth.id, auth.token);

      return true;
    } catch (e) {
      _authError = _cleanError(e.toString());
      _loadingAuth = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkSession() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      _user = await _authService.getUser();
      notifyListeners();
    }
    return loggedIn;
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _politicas = [];
    _tramites = [];
    _tareas = [];
    _notificaciones = [];
    _authError = '';
    _dataError = '';
    notifyListeners();
  }

  // ── Data loading ──────────────────────────────────────────────
  Future<void> cargarDatos() async {
    if (_user == null) {
      _user = await _authService.getUser();
      if (_user == null) return;
    }
    _loadingData = true;
    _dataError = '';
    notifyListeners();

    try {
      final rol = userRol;
      final id = userId;

      if (rol == 'CLIENTE') {
        final results = await Future.wait([
          _apiService.getPoliticasActivas(),
          _apiService.getTramitesByCliente(id),
          _apiService.getNotificacionesNoLeidas(id),
        ]);
        _politicas = results[0] as List<Politica>;
        _tramites = results[1] as List<Tramite>;
        _notificaciones = results[2] as List<Notificacion>;
      } else if (rol == 'FUNCIONARIO' || rol == 'ADMIN') {
        final dept = userDepartamento;
        final results = await Future.wait([
          dept.isNotEmpty
              ? _apiService.getTareasByDepartamento(dept)
              : _apiService.getTareasByFuncionario(id),
          _apiService.getNotificacionesNoLeidas(id),
        ]);
        _tareas = results[0] as List<Tarea>;
        _notificaciones = results[1] as List<Notificacion>;
      }
    } catch (e) {
      _dataError = _cleanError(e.toString());
    }

    _loadingData = false;
    notifyListeners();
  }

  Future<void> cargarNotificaciones() async {
    if (userId.isEmpty) return;
    try {
      _notificaciones = await _apiService.getNotificacionesNoLeidas(userId);
      notifyListeners();
    } catch (_) {}
  }

  // ── Cliente actions ───────────────────────────────────────────
  Future<Tramite?> solicitarTramite(
      String politicaId, String descripcion) async {
    _loadingAction = true;
    _actionError = '';
    _actionSuccess = '';
    notifyListeners();
    try {
      final tramite =
          await _apiService.solicitarTramite(politicaId, userId, descripcion);
      _tramites.insert(0, tramite);
      _actionSuccess = 'Trámite solicitado correctamente';
      _loadingAction = false;
      notifyListeners();
      return tramite;
    } catch (e) {
      _actionError = _cleanError(e.toString());
      _loadingAction = false;
      notifyListeners();
      return null;
    }
  }

  Future<Tramite?> refreshTramite(String tramiteId) async {
    try {
      final updated = await _apiService.getTramiteById(tramiteId);
      final idx = _tramites.indexWhere((t) => t.id == tramiteId);
      if (idx >= 0) {
        _tramites[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (_) {
      return null;
    }
  }

  // ── Notificaciones ────────────────────────────────────────────
  Future<void> marcarLeida(String notifId) async {
    try {
      await _apiService.marcarNotificacionLeida(notifId);
      final idx = _notificaciones.indexWhere((n) => n.id == notifId);
      if (idx >= 0) {
        _notificaciones.removeAt(idx);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> marcarTodasLeidas() async {
    if (userId.isEmpty) return;
    try {
      await _apiService.marcarTodasLeidas(userId);
      _notificaciones = [];
      notifyListeners();
    } catch (_) {}
  }

  // ── Funcionario actions ───────────────────────────────────────
  Future<bool> completarTarea(
      String tareaId, Map<String, dynamic> datos) async {
    _loadingAction = true;
    _actionError = '';
    notifyListeners();
    try {
      await _apiService.completarTarea(tareaId, datos);
      _actionSuccess = 'Tarea completada. El trámite avanzó automáticamente.';
      await cargarDatos();
      _loadingAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = _cleanError(e.toString());
      _loadingAction = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cambiarEstadoTarea(String tareaId, String estado) async {
    try {
      final updated = await _apiService.actualizarEstadoTarea(tareaId, estado);
      final idx = _tareas.indexWhere((t) => t.id == tareaId);
      if (idx >= 0) {
        _tareas[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _actionError = _cleanError(e.toString());
      notifyListeners();
      return false;
    }
  }

  // ── Perfil ────────────────────────────────────────────────────
  Future<bool> updatePerfil(String nombre, String departamento) async {
    if (userId.isEmpty) return false;
    _loadingAction = true;
    _actionError = '';
    notifyListeners();
    try {
      final updated = await _apiService.updateUsuario(userId, {
        'nombre': nombre,
        'departamento': departamento,
      });
      _user = {...?_user, ...updated};
      await _authService.updateUser(_user!);
      _actionSuccess = 'Perfil actualizado correctamente';
      _loadingAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = _cleanError(e.toString());
      _loadingAction = false;
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────
  void clearErrors() {
    _authError = '';
    _dataError = '';
    _actionError = '';
    _actionSuccess = '';
    notifyListeners();
  }

  String _cleanError(String raw) {
    return raw.replaceAll('Exception: ', '').replaceAll('Exception:', '');
  }
}
