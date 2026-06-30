import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart' as p;
import '../models/rbac_models.dart';

class RbacLocalStorage {
  RbacLocalStorage._();
  static final RbacLocalStorage instance = RbacLocalStorage._();

  static const _storeName = 'rbac_cache';
  static const _key = 'applications';

  final _store = StoreRef<String, String>.main();
  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, '$_storeName.db');
    _db = await databaseFactoryIo.openDatabase(dbPath);
    if (kDebugMode) print('[RbacLocalStorage] Sembast opened');
  }

  Future<void> saveApplications(List<RbacApplication> apps) async {
    final db = _db;
    if (db == null) return;

    final jsonList = apps.map((a) => a.toJson()).toList();
    await _store.record(_key).put(db, jsonEncode(jsonList));
    if (kDebugMode) print('[RbacLocalStorage] Saved ${apps.length} apps to cache');
  }

  Future<List<RbacApplication>?> loadApplications() async {
    final db = _db;
    if (db == null) return null;

    final raw = await _store.record(_key).get(db);
    if (raw == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(raw);
      final apps = jsonList.map((j) => RbacApplication.fromJson(j)).toList();
      if (kDebugMode) print('[RbacLocalStorage] Loaded ${apps.length} apps from cache');
      return apps;
    } catch (e) {
      if (kDebugMode) print('[RbacLocalStorage] Error parsing cache: $e');
      return null;
    }
  }

  Future<void> clearAll() async {
    final db = _db;
    if (db == null) return;

    await _store.delete(db);
    if (kDebugMode) print('[RbacLocalStorage] Cache cleared');
  }
}
