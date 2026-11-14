import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:see_for_designs/models/design_item.dart';

class DatabaseService extends ChangeNotifier {
  static const _dbName = 'designs.db';
  static const _dbVersion = 1;
  static const _tableName = 'designs';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    // Use string concatenation to avoid external 'path' package
    final dbPath = '${documentsDirectory.path}/$_dbName';
    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        widthMm REAL NOT NULL,
        heightMm REAL NOT NULL,
        depthMm REAL NOT NULL,
        filePath TEXT NOT NULL,
        thumbnailPath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isTrashed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> init() async {
    await database;
  }

  Future<int> insertDesign(DesignItem item) async {
    final db = await database;
    final result = await db.insert(_tableName, item.toMap());
    notifyListeners();
    return result;
  }

  Future<List<DesignItem>> getAllDesigns({bool trashedOnly = false}) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'isTrashed = ?',
      whereArgs: [trashedOnly ? 1 : 0],
      orderBy: 'title ASC',
    );
    return maps.map((map) => DesignItem.fromMap(map)).toList();
  }

  Future<DesignItem?> getDesignById(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DesignItem.fromMap(maps.first);
  }

  Future<int> updateDesign(DesignItem item) async {
    final db = await database;
    final result = await db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    notifyListeners();
    return result;
  }

  Future<int> deleteDesignPermanently(String id) async {
    final db = await database;
    final result = await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
    return result;
  }
}
