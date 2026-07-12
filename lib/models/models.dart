import 'package:flutter/material.dart';

// ── CampoFormulario ───────────────────────────────────────────
class CampoFormulario {
  final String nombre;
  final String tipo; // text, textarea, number, boolean, select, file, grid, fecha, hora, checkbox, radio
  final String etiqueta;
  final bool requerido;
  final List<String> opciones;

  CampoFormulario({
    required this.nombre,
    required this.tipo,
    required this.etiqueta,
    required this.requerido,
    this.opciones = const [],
  });

  factory CampoFormulario.fromJson(Map<String, dynamic> j) => CampoFormulario(
        nombre: j['nombre'] ?? '',
        tipo: j['tipo'] ?? 'text',
        etiqueta: j['etiqueta'] ?? j['nombre'] ?? '',
        requerido: j['requerido'] == true,
        opciones: (j['opciones'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

// ── Auth ──────────────────────────────────────────────────────
class AuthResponse {
  final String token;
  final String id;
  final String email;
  final String nombre;
  final String rol;
  final String departamento;
  final List<String> departamentos;

  AuthResponse({
    required this.token,
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.departamento,
    this.departamentos = const [],
  });

  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
        token: j['token'] ?? '',
        id: j['id'] ?? '',
        email: j['email'] ?? '',
        nombre: j['nombre'] ?? '',
        rol: j['rol'] ?? '',
        departamento: j['departamento'] ?? '',
        departamentos: (j['departamentos'] as List?)
            ?.map((e) => e.toString())
            .toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'id': id,
        'email': email,
        'nombre': nombre,
        'rol': rol,
        'departamento': departamento,
        'departamentos': departamentos,
      };
}

// ── Politica ──────────────────────────────────────────────────
class Politica {
  final String id;
  final String nombre;
  final String descripcion;
  final String? categoria;
  final String? organizacion;
  final int? tiempoEstimadoDias;
  final String estado;
  final int? tramitesActivos;
  final int? tramitesCompletados;
  final String fechaCreacion;

  Politica({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.categoria,
    this.organizacion,
    this.tiempoEstimadoDias,
    required this.estado,
    this.tramitesActivos,
    this.tramitesCompletados,
    required this.fechaCreacion,
  });

  factory Politica.fromJson(Map<String, dynamic> j) => Politica(
        id: j['id'] ?? '',
        nombre: j['nombre'] ?? '',
        descripcion: j['descripcion'] ?? '',
        categoria: j['categoria'],
        organizacion: j['organizacion'],
        tiempoEstimadoDias: j['tiempoEstimadoDias'],
        estado: j['estado'] ?? 'BORRADOR',
        tramitesActivos: j['tramitesActivos'],
        tramitesCompletados: j['tramitesCompletados'],
        fechaCreacion: j['fechaCreacion'] ?? '',
      );
}

// ── Tramite ───────────────────────────────────────────────────
class Tramite {
  final String id;
  final String politicaId;
  final String? nombrePolitica;
  final String clienteId;
  final String? nombreCliente;
  final String nodoActualId;
  final String? nombreNodoActual;
  final String? departamentoActual;
  final String estado;
  final String? descripcion;
  final String? numeroReferencia;
  final String? prioridad;
  final List<HistorialTramite> historial;
  final Map<String, dynamic>? datosFormulario;
  final String fechaInicio;
  final String? fechaFin;
  final String? fechaUltimaActualizacion;
  final int? duracionMinutos;

  Tramite({
    required this.id,
    required this.politicaId,
    this.nombrePolitica,
    required this.clienteId,
    this.nombreCliente,
    required this.nodoActualId,
    this.nombreNodoActual,
    this.departamentoActual,
    required this.estado,
    this.descripcion,
    this.numeroReferencia,
    this.prioridad,
    required this.historial,
    this.datosFormulario,
    required this.fechaInicio,
    this.fechaFin,
    this.fechaUltimaActualizacion,
    this.duracionMinutos,
  });

  factory Tramite.fromJson(Map<String, dynamic> j) => Tramite(
        id: j['id'] ?? '',
        politicaId: j['politicaId'] ?? '',
        nombrePolitica: j['nombrePolitica'],
        clienteId: j['clienteId'] ?? '',
        nombreCliente: j['nombreCliente'],
        nodoActualId: j['nodoActualId'] ?? '',
        nombreNodoActual: j['nombreNodoActual'],
        departamentoActual: j['departamentoActual'],
        estado: j['estado'] ?? 'NUEVO',
        descripcion: j['descripcion'],
        numeroReferencia: j['numeroReferencia'],
        prioridad: j['prioridad'],
        historial: (j['historial'] as List? ?? [])
            .map((h) => HistorialTramite.fromJson(h))
            .toList(),
        datosFormulario: j['datosFormulario'] != null
            ? Map<String, dynamic>.from(j['datosFormulario'])
            : null,
        fechaInicio: j['fechaInicio'] ?? '',
        fechaFin: j['fechaFin'],
        fechaUltimaActualizacion: j['fechaUltimaActualizacion'],
        duracionMinutos: j['duracionMinutos'],
      );

  Color get estadoColor {
    switch (estado) {
      case 'NUEVO':
        return const Color(0xFF3B82F6);
      case 'EN_PROCESO':
        return const Color(0xFFF59E0B);
      case 'COMPLETADO':
        return const Color(0xFF22C55E);
      case 'RECHAZADO':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get estadoLabel {
    switch (estado) {
      case 'NUEVO':
        return 'Nuevo';
      case 'EN_PROCESO':
        return 'En Proceso';
      case 'COMPLETADO':
        return 'Completado';
      case 'RECHAZADO':
        return 'Rechazado';
      default:
        return estado;
    }
  }

  String get estadoEmoji {
    switch (estado) {
      case 'NUEVO':
        return '🔵';
      case 'EN_PROCESO':
        return '🟡';
      case 'COMPLETADO':
        return '🟢';
      case 'RECHAZADO':
        return '🔴';
      default:
        return '⚪';
    }
  }

  String get refDisplay =>
      numeroReferencia ?? id.substring(0, 8).toUpperCase();

  String get fechaInicioFormatted => _formatDate(fechaInicio);
  String? get fechaFinFormatted =>
      fechaFin != null ? _formatDate(fechaFin!) : null;

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  String get duracionFormatted {
    if (duracionMinutos == null) return '—';
    final h = duracionMinutos! ~/ 60;
    final m = duracionMinutos! % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}

// ── HistorialTramite ──────────────────────────────────────────
class HistorialTramite {
  final String nodoId;
  final String nombreNodo;
  final String? departamento;
  final String? funcionarioId;
  final String? nombreFuncionario;
  final String accion;
  final String? observacion;
  final String? resultadoDecision;
  final int? duracionMinutos;
  final String fecha;

  HistorialTramite({
    required this.nodoId,
    required this.nombreNodo,
    this.departamento,
    this.funcionarioId,
    this.nombreFuncionario,
    required this.accion,
    this.observacion,
    this.resultadoDecision,
    this.duracionMinutos,
    required this.fecha,
  });

  factory HistorialTramite.fromJson(Map<String, dynamic> j) => HistorialTramite(
        nodoId: j['nodoId'] ?? '',
        nombreNodo: j['nombreNodo'] ?? '',
        departamento: j['departamento'],
        funcionarioId: j['funcionarioId'],
        nombreFuncionario: j['nombreFuncionario'],
        accion: j['accion'] ?? '',
        observacion: j['observacion'],
        resultadoDecision: j['resultadoDecision'],
        duracionMinutos: j['duracionMinutos'],
        fecha: j['fecha'] ?? '',
      );

  String get fechaFormatted {
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha.length >= 16 ? fecha.substring(0, 16) : fecha;
    }
  }
}

// ── Notificacion ──────────────────────────────────────────────
class Notificacion {
  final String id;
  final String usuarioId;
  final String mensaje;
  final String tipo;
  final String? referenciaId;
  final String? tipoReferencia;
  final bool leida;
  final String fechaCreacion;

  Notificacion({
    required this.id,
    required this.usuarioId,
    required this.mensaje,
    required this.tipo,
    this.referenciaId,
    this.tipoReferencia,
    required this.leida,
    required this.fechaCreacion,
  });

  factory Notificacion.fromJson(Map<String, dynamic> j) => Notificacion(
        id: j['id'] ?? '',
        usuarioId: j['usuarioId'] ?? '',
        mensaje: j['mensaje'] ?? '',
        tipo: j['tipo'] ?? '',
        referenciaId: j['referenciaId'],
        tipoReferencia: j['tipoReferencia'],
        leida: j['leida'] ?? false,
        fechaCreacion: j['fechaCreacion'] ?? '',
      );

  String get tipoEmoji {
    switch (tipo) {
      case 'NUEVA_TAREA':
        return '📋';
      case 'TRAMITE_COMPLETADO':
        return '✅';
      case 'TRAMITE_RECHAZADO':
        return '❌';
      case 'TRAMITE_AVANZADO':
        return '➡️';
      case 'CUELLO_BOTELLA':
        return '⚠️';
      default:
        return '🔔';
    }
  }

  String get fechaFormatted {
    try {
      final dt = DateTime.parse(fechaCreacion);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return fechaCreacion.length >= 10 ? fechaCreacion.substring(0, 10) : fechaCreacion;
    }
  }
}

// ── Tarea (para funcionarios) ─────────────────────────────────
class Tarea {
  final String id;
  final String tramiteId;
  final String politicaId;
  final String nodoId;
  final String? nombreNodo;
  final String? departamento;
  final String funcionarioId;
  final String? nombreFuncionario;
  final String? numeroReferenciaTramite;
  final String? nombrePolitica;
  final String? instrucciones;
  final List<CampoFormulario> camposFormulario;
  final String estado;
  final Map<String, dynamic> formularioDatos;
  final String? observacion;
  final String? prioridad;
  final String fechaAsignacion;
  final String? fechaCompletado;
  final int? duracionMinutos;

  Tarea({
    required this.id,
    required this.tramiteId,
    required this.politicaId,
    required this.nodoId,
    this.nombreNodo,
    this.departamento,
    required this.funcionarioId,
    this.nombreFuncionario,
    this.numeroReferenciaTramite,
    this.nombrePolitica,
    this.instrucciones,
    this.camposFormulario = const [],
    required this.estado,
    required this.formularioDatos,
    this.observacion,
    this.prioridad,
    required this.fechaAsignacion,
    this.fechaCompletado,
    this.duracionMinutos,
  });

  factory Tarea.fromJson(Map<String, dynamic> j) => Tarea(
        id: j['id'] ?? '',
        tramiteId: j['tramiteId'] ?? '',
        politicaId: j['politicaId'] ?? '',
        nodoId: j['nodoId'] ?? '',
        nombreNodo: j['nombreNodo'],
        departamento: j['departamento'],
        funcionarioId: j['funcionarioId'] ?? '',
        nombreFuncionario: j['nombreFuncionario'],
        numeroReferenciaTramite: j['numeroReferenciaTramite'],
        nombrePolitica: j['nombrePolitica'],
        instrucciones: j['instrucciones'],
        camposFormulario: (j['camposFormulario'] as List? ?? [])
            .map((c) => CampoFormulario.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
        estado: j['estado'] ?? 'PENDIENTE',
        formularioDatos: j['formularioDatos'] != null
            ? Map<String, dynamic>.from(j['formularioDatos'])
            : {},
        observacion: j['observacion'],
        prioridad: j['prioridad'],
        fechaAsignacion: j['fechaAsignacion'] ?? '',
        fechaCompletado: j['fechaCompletado'],
        duracionMinutos: j['duracionMinutos'],
      );

  Color get estadoColor {
    switch (estado) {
      case 'PENDIENTE':
        return const Color(0xFFEF4444);
      case 'EN_PROCESO':
        return const Color(0xFFF59E0B);
      case 'COMPLETADO':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get estadoLabel {
    switch (estado) {
      case 'PENDIENTE':
        return '🔴 Pendiente';
      case 'EN_PROCESO':
        return '🟡 En Proceso';
      case 'COMPLETADO':
        return '🟢 Completado';
      default:
        return estado;
    }
  }
}
