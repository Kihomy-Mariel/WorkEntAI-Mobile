import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SyncRequest {
  final int? id;
  final String url;
  final String method;
  final String body;
  final int timestamp;

  SyncRequest({
    this.id,
    required this.url,
    required this.method,
    required this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'method': method,
      'body': body,
      'timestamp': timestamp,
    };
  }

  factory SyncRequest.fromMap(Map<String, dynamic> map) {
    return SyncRequest(
      id: map['id'],
      url: map['url'],
      method: map['method'],
      body: map['body'],
      timestamp: map['timestamp'],
    );
  }
}

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Database? _database;
  bool _isOnline = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool get isOnline => _isOnline;

  Future<void> init() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'workentai_sync.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE sync_queue(id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT, method TEXT, body TEXT, timestamp INTEGER)',
        );
      },
      version: 1,
    );

    // Initial check
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);

    // Listen for changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool wasOffline = !_isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    
    notifyListeners();

    if (wasOffline && _isOnline) {
      _syncPendingRequests();
    }
  }

  Future<void> queueRequest(String url, String method, Map<String, dynamic> body) async {
    final db = _database;
    if (db == null) return;

    final req = SyncRequest(
      url: url,
      method: method,
      body: jsonEncode(body),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await db.insert(
      'sync_queue',
      req.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _syncPendingRequests() async {
    final db = _database;
    if (db == null || !_isOnline) return;

    final List<Map<String, dynamic>> maps = await db.query('sync_queue', orderBy: 'timestamp ASC');
    
    for (var map in maps) {
      final req = SyncRequest.fromMap(map);
      try {
        if (req.method == 'POST') {
          await http.post(
            Uri.parse(req.url),
            headers: {'Content-Type': 'application/json'},
            body: req.body,
          );
        } else if (req.method == 'PUT') {
          await http.put(
            Uri.parse(req.url),
            headers: {'Content-Type': 'application/json'},
            body: req.body,
          );
        }
        
        // Remove from queue after success
        await db.delete(
          'sync_queue',
          where: 'id = ?',
          whereArgs: [req.id],
        );
      } catch (e) {
        print('Error syncing request ${req.id}: $e');
        // Will retry next time network connects
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
