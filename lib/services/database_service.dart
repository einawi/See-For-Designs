import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:see_for_designs/models/design_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _databaseName = 'designs.db';
  static const String _tableName = 'designs';
  static const int _databaseVersion = 1;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path =
        '${documentsDirectory.path}${Platform.pathSeparator}$_databaseName';
    return openDatabase(
      path,
      version: _databaseVersion,
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
        fileName TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        isTrashed INTEGER NOT NULL DEFAULT 0,
        thumbnailPath TEXT
      )
    ''');
  }

  Future<int> insertDesign(DesignModel design) async {
    final Database db = await database;
    return db.insert(
      _tableName,
      design.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateDesign(DesignModel design) async {
    final Database db = await database;
    return db.update(
      _tableName,
      design.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[design.id],
    );
  }

  Future<int> deleteDesign(String id) async {
    final Database db = await database;
    return db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<DesignModel>> getAllDesigns() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return List<DesignModel>.generate(
      maps.length,
      (int i) => DesignModel.fromMap(maps[i]),
    );
  }

  Future<DesignModel?> getDesignById(String id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DesignModel.fromMap(maps.first);
  }

  Future<List<DesignModel>> getDesignsByTitle(String title) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'title = ? COLLATE NOCASE',
      whereArgs: <Object?>[title],
    );
    return List<DesignModel>.generate(
      maps.length,
      (int i) => DesignModel.fromMap(maps[i]),
    );
  }

  Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
