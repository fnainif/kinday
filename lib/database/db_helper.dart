import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/models/user_model_sql.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ppkd.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            title TEXT,
            description TEXT,
            energylvl INTEGER,
            prioritytask INTEGER,
            dueDate TEXT,
            dueTime TEXT,
            isCompleted INTEGER,
            subtasks TEXT,
            reminderMinutes INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE energy_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            energy INTEGER,
            timestamp TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS users');
          await db.execute('DROP TABLE IF EXISTS tasks');
          await db.execute('DROP TABLE IF EXISTS energy_logs');

          await db.execute('''
            CREATE TABLE users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT,
              email TEXT UNIQUE,
              password TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE tasks(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER,
              title TEXT,
              description TEXT,
              energylvl INTEGER,
              prioritytask INTEGER,
              dueDate TEXT,
              dueTime TEXT,
              isCompleted INTEGER,
              subtasks TEXT,
              reminderMinutes INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE energy_logs(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER,
              energy INTEGER,
              timestamp TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE tasks ADD COLUMN dueTime TEXT');
          } catch (e) {
            debugPrint("Error migrating database to v3: $e");
          }
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE tasks ADD COLUMN reminderMinutes INTEGER');
          } catch (e) {
            debugPrint("Error migrating database to v4: $e");
          }
        }
      },
    );
  }

  // --- User Operations ---

  // Fungsi Register
  Future<bool> registerUser(UserModelSql pengguna) async {
    final db = await database;
    try {
      final id = await db.insert('users', pengguna.toMap());
      return id > 0;
    } catch (e) {
      debugPrint("Error registering user: $e");
      return false;
    }
  }

  // Fungsi Login
  Future<UserModelSql?> loginUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return UserModelSql.fromMap(result.first);
    }
    return null;
  }

  // Get User by Email (to fetch generated id on register if needed)
  Future<UserModelSql?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return UserModelSql.fromMap(result.first);
    }
    return null;
  }

  Future<List<UserModelSql>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('users');
    return results.map((map) => UserModelSql.fromMap(map)).toList();
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> updateUser(UserModelSql pengguna) async {
    final db = await database;
    try {
      int count = await db.update(
        'users',
        pengguna.toMap(),
        where: 'id = ?',
        whereArgs: [pengguna.id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  // --- Task Operations ---

  Future<int> insertTask(TaskCard task, int userId) async {
    final db = await database;
    final map = {
      'userId': userId,
      'title': task.title,
      'description': task.description,
      'energylvl': task.energylvl,
      'prioritytask': task.prioritytask,
      'dueDate': task.dueDate?.toIso8601String(),
      'dueTime': task.dueTime,
      'isCompleted': task.isCompleted ? 1 : 0,
      'subtasks': jsonEncode(task.subtasks),
      'reminderMinutes': task.reminderMinutes,
    };
    final id = await db.insert('tasks', map);
    return id;
  }

  Future<List<TaskCard>> getTasksForUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return results.map((map) {
      final dueDateStr = map['dueDate'] as String?;
      final subtasksStr = map['subtasks'] as String?;
      List<Map<String, dynamic>> parsedSubtasks = [];
      if (subtasksStr != null && subtasksStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(subtasksStr);
          if (decoded is List) {
            parsedSubtasks = decoded
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        } catch (e) {
          debugPrint("Error parsing subtasks: $e");
        }
      }

      return TaskCard(
        id: map['id'] as int?,
        title: map['title'] as String,
        description: map['description'] as String?,
        energylvl: map['energylvl'] as int,
        prioritytask: map['prioritytask'] as int,
        dueDate: dueDateStr != null ? DateTime.parse(dueDateStr) : null,
        dueTime: map['dueTime'] as String?,
        isCompleted: (map['isCompleted'] as int) == 1,
        subtasks: parsedSubtasks,
        reminderMinutes: map['reminderMinutes'] as int?,
      );
    }).toList();
  }

  Future<bool> updateTask(TaskCard task) async {
    if (task.id == null) return false;
    final db = await database;
    final map = {
      'title': task.title,
      'description': task.description,
      'energylvl': task.energylvl,
      'prioritytask': task.prioritytask,
      'dueDate': task.dueDate?.toIso8601String(),
      'dueTime': task.dueTime,
      'isCompleted': task.isCompleted ? 1 : 0,
      'subtasks': jsonEncode(task.subtasks),
      'reminderMinutes': task.reminderMinutes,
    };

    int count = await db.update(
      'tasks',
      map,
      where: 'id = ?',
      whereArgs: [task.id],
    );
    return count > 0;
  }

  Future<bool> deleteTask(int id) async {
    final db = await database;
    int count = await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    return count > 0;
  }

  // --- Energy Log Operations ---

  Future<int> insertEnergyLog(int userId, int energy, String timestamp) async {
    final db = await database;
    final map = {'userId': userId, 'energy': energy, 'timestamp': timestamp};
    return await db.insert('energy_logs', map);
  }

  Future<List<Map<String, dynamic>>> getEnergyLogsForUser(int userId) async {
    final db = await database;
    return await db.query(
      'energy_logs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp ASC',
    );
  }

  Future<int?> getLatestEnergyForUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'energy_logs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first['energy'] as int?;
    }
    return null;
  }

  // --- Database Viewer Operations ---

  Future<List<Map<String, dynamic>>> getRawTableData(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  Future<int> deleteRawRow(String tableName, int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
