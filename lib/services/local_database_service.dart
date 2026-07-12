import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Servicio de base de datos local SQLite para caché offline (CU-31 — Opción B).
///
/// Almacena políticas, trámites, tareas y KPIs para acceso sin conexión.
/// La sincronización ocurre cuando se restaura la conexión a internet.
///
/// Principio SRP: única responsabilidad de gestionar el esquema y acceso
/// a la base de datos local.
class LocalDatabaseService {
  static const String _dbName = 'workentai_offline.db';
  static const int _dbVersion = 1;

  static Database? _database;

  // Singleton
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _crearTablas,
    );
  }

  Future<void> _crearTablas(Database db, int version) async {
    // Políticas de negocio
    await db.execute('''
      CREATE TABLE politicas (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        estado TEXT,
        datos_json TEXT NOT NULL,
        actualizado_en INTEGER NOT NULL
      )
    ''');

    // Trámites del cliente
    await db.execute('''
      CREATE TABLE tramites (
        id TEXT PRIMARY KEY,
        numero_referencia TEXT,
        nombre_politica TEXT,
        estado TEXT,
        nombre_nodo_actual TEXT,
        descripcion TEXT,
        prioridad TEXT,
        datos_json TEXT NOT NULL,
        actualizado_en INTEGER NOT NULL
      )
    ''');

    // Tareas del funcionario
    await db.execute('''
      CREATE TABLE tareas (
        id TEXT PRIMARY KEY,
        titulo TEXT,
        estado TEXT,
        nombre_tramite TEXT,
        nombre_politica TEXT,
        prioridad TEXT,
        departamento TEXT,
        datos_json TEXT NOT NULL,
        actualizado_en INTEGER NOT NULL
      )
    ''');

    // KPIs globales (ADMIN)
    await db.execute('''
      CREATE TABLE kpis_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datos_json TEXT NOT NULL,
        guardado_en INTEGER NOT NULL
      )
    ''');

    // Cola de acciones pendientes de sincronizar cuando vuelva la conexión
    await db.execute('''
      CREATE TABLE acciones_pendientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        creado_en INTEGER NOT NULL,
        intentos INTEGER DEFAULT 0
      )
    ''');
  }

  // ── Políticas ─────────────────────────────────────────────────────────────

  Future<void> guardarPoliticas(List<Map<String, dynamic>> politicas) async {
    final db = await database;
    final batch = db.batch();
    for (final politica in politicas) {
      batch.insert(
        'politicas',
        {
          'id': politica['id'],
          'nombre': politica['nombre'] ?? '',
          'descripcion': politica['descripcion'] ?? '',
          'estado': politica['estado'] ?? '',
          'datos_json': jsonEncode(politica),
          'actualizado_en': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> obtenerPoliticas() async {
    final db = await database;
    final rows = await db.query('politicas', orderBy: 'nombre ASC');
    return rows.map((r) => jsonDecode(r['datos_json'] as String) as Map<String, dynamic>).toList();
  }

  // ── Trámites ──────────────────────────────────────────────────────────────

  Future<void> guardarTramites(List<Map<String, dynamic>> tramites) async {
    final db = await database;
    final batch = db.batch();
    for (final tramite in tramites) {
      batch.insert(
        'tramites',
        {
          'id': tramite['id'],
          'numero_referencia': tramite['numeroReferencia'] ?? '',
          'nombre_politica': tramite['nombrePolitica'] ?? '',
          'estado': tramite['estado'] ?? '',
          'nombre_nodo_actual': tramite['nombreNodoActual'] ?? '',
          'descripcion': tramite['descripcion'] ?? '',
          'prioridad': tramite['prioridad'] ?? 'MEDIA',
          'datos_json': jsonEncode(tramite),
          'actualizado_en': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> obtenerTramites() async {
    final db = await database;
    final rows = await db.query('tramites', orderBy: 'actualizado_en DESC');
    return rows.map((r) => jsonDecode(r['datos_json'] as String) as Map<String, dynamic>).toList();
  }

  // ── Tareas ────────────────────────────────────────────────────────────────

  Future<void> guardarTareas(List<Map<String, dynamic>> tareas) async {
    final db = await database;
    final batch = db.batch();
    for (final tarea in tareas) {
      batch.insert(
        'tareas',
        {
          'id': tarea['id'],
          'titulo': tarea['titulo'] ?? '',
          'estado': tarea['estado'] ?? '',
          'nombre_tramite': tarea['nombreTramite'] ?? '',
          'nombre_politica': tarea['nombrePolitica'] ?? '',
          'prioridad': tarea['prioridad'] ?? 'MEDIA',
          'departamento': tarea['departamento'] ?? '',
          'datos_json': jsonEncode(tarea),
          'actualizado_en': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> obtenerTareas() async {
    final db = await database;
    final rows = await db.query('tareas', orderBy: 'actualizado_en DESC');
    return rows.map((r) => jsonDecode(r['datos_json'] as String) as Map<String, dynamic>).toList();
  }

  // ── KPIs ──────────────────────────────────────────────────────────────────

  Future<void> guardarKpis(Map<String, dynamic> kpis) async {
    final db = await database;
    await db.insert(
      'kpis_cache',
      {
        'datos_json': jsonEncode(kpis),
        'guardado_en': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Mantener solo el registro más reciente
    await db.rawDelete(
      'DELETE FROM kpis_cache WHERE id NOT IN '
      '(SELECT id FROM kpis_cache ORDER BY guardado_en DESC LIMIT 1)',
    );
  }

  Future<Map<String, dynamic>?> obtenerKpis() async {
    final db = await database;
    final rows = await db.query('kpis_cache', orderBy: 'guardado_en DESC', limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['datos_json'] as String) as Map<String, dynamic>;
  }

  // ── Cola de acciones pendientes (offline sync) ────────────────────────────

  Future<void> guardarAccionPendiente(
      String tipo, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('acciones_pendientes', {
      'tipo': tipo,
      'payload_json': jsonEncode(payload),
      'creado_en': DateTime.now().millisecondsSinceEpoch,
      'intentos': 0,
    });
  }

  Future<List<Map<String, dynamic>>> obtenerAccionesPendientes() async {
    final db = await database;
    final rows = await db.query(
      'acciones_pendientes',
      orderBy: 'creado_en ASC',
      where: 'intentos < 5',
    );
    return rows.map((r) {
      final data = jsonDecode(r['payload_json'] as String) as Map<String, dynamic>;
      return {
        ...data,
        '_pendienteId': r['id'],
        '_tipo': r['tipo'],
      };
    }).toList();
  }

  Future<void> eliminarAccionPendiente(int id) async {
    final db = await database;
    await db.delete('acciones_pendientes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementarIntentosAccion(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE acciones_pendientes SET intentos = intentos + 1 WHERE id = ?',
      [id],
    );
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  Future<void> limpiarTodo() async {
    final db = await database;
    await db.delete('politicas');
    await db.delete('tramites');
    await db.delete('tareas');
    await db.delete('kpis_cache');
  }

  Future<void> cerrar() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
