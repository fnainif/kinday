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
      version: 6,
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
            startDate TEXT,
            dueDate TEXT,
            dueTime TEXT,
            isCompleted INTEGER,
            subtasks TEXT,
            reminderMinutes INTEGER,
            repeatType TEXT,
            selectedWeekDays TEXT,
            finishDate TEXT,
            createdAt TEXT,
            lastOccurrenceDate TEXT
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
        await db.execute('''
          CREATE TABLE focus_sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            durationMinutes INTEGER,
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
        if (oldVersion < 5) {
          try {
            await db.execute('ALTER TABLE tasks ADD COLUMN repeatType TEXT');
            await db.execute('ALTER TABLE tasks ADD COLUMN selectedWeekDays TEXT');
            await db.execute('ALTER TABLE tasks ADD COLUMN finishDate TEXT');
            await db.execute('ALTER TABLE tasks ADD COLUMN createdAt TEXT');
            await db.execute('ALTER TABLE tasks ADD COLUMN lastOccurrenceDate TEXT');
            
            await db.execute('''
              CREATE TABLE IF NOT EXISTS focus_sessions(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                userId INTEGER,
                durationMinutes INTEGER,
                timestamp TEXT
              )
            ''');
          } catch (e) {
            debugPrint("Error migrating database to v5: $e");
          }
        }
        if (oldVersion < 6) {
          try {
            await db.execute('ALTER TABLE tasks ADD COLUMN startDate TEXT');
          } catch (e) {
            debugPrint("Error migrating database to v6: $e");
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

  // Get User by ID
  Future<UserModelSql?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return UserModelSql.fromMap(result.first);
    }
    return null;
  }

  // Check if email is already registered by another user
  Future<bool> isEmailRegistered(String email, {int? excludeUserId}) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: excludeUserId != null ? 'email = ? AND id != ?' : 'email = ?',
      whereArgs: excludeUserId != null ? [email, excludeUserId] : [email],
    );
    return result.isNotEmpty;
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
      'startDate': task.startDate?.toIso8601String(),
      'dueDate': task.dueDate?.toIso8601String(),
      'dueTime': task.dueTime,
      'isCompleted': task.isCompleted ? 1 : 0,
      'subtasks': jsonEncode(task.subtasks),
      'reminderMinutes': task.reminderMinutes,
      'repeatType': task.repeatType.name,
      'selectedWeekDays': jsonEncode(task.selectedWeekDays),
      'finishDate': task.finishDate?.toIso8601String(),
      'createdAt': task.createdAt.toIso8601String(),
      'lastOccurrenceDate': task.lastOccurrenceDate?.toIso8601String(),
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
      final startDateStr = map['startDate'] as String?;
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

      final repeatTypeStr = map['repeatType'] as String?;
      final repeatType = RepeatType.values.firstWhere(
        (e) => e.name == repeatTypeStr,
        orElse: () => RepeatType.none,
      );

      final weekDaysStr = map['selectedWeekDays'] as String?;
      List<int> parsedWeekDays = [];
      if (weekDaysStr != null && weekDaysStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(weekDaysStr);
          if (decoded is List) {
            parsedWeekDays = decoded.cast<int>();
          }
        } catch (e) {
          debugPrint("Error parsing selectedWeekDays: $e");
        }
      }

      final finishDateStr = map['finishDate'] as String?;
      final finishDate = finishDateStr != null ? DateTime.parse(finishDateStr) : null;

      final createdAtStr = map['createdAt'] as String?;
      final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();

      final lastOccurStr = map['lastOccurrenceDate'] as String?;
      final lastOccur = lastOccurStr != null ? DateTime.parse(lastOccurStr) : null;

      final startDate = startDateStr != null
          ? DateTime.parse(startDateStr)
          : (dueDateStr != null ? DateTime.parse(dueDateStr) : createdAt);

      return TaskCard(
        id: map['id'] as int?,
        title: map['title'] as String,
        description: map['description'] as String?,
        energylvl: map['energylvl'] as int,
        prioritytask: map['prioritytask'] as int,
        startDate: startDate,
        dueDate: dueDateStr != null ? DateTime.parse(dueDateStr) : null,
        dueTime: map['dueTime'] as String?,
        isCompleted: (map['isCompleted'] as int) == 1,
        subtasks: parsedSubtasks,
        reminderMinutes: map['reminderMinutes'] as int?,
        repeatType: repeatType,
        selectedWeekDays: parsedWeekDays,
        finishDate: finishDate,
        createdAt: createdAt,
        lastOccurrenceDate: lastOccur,
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
      'startDate': task.startDate?.toIso8601String(),
      'dueDate': task.dueDate?.toIso8601String(),
      'dueTime': task.dueTime,
      'isCompleted': task.isCompleted ? 1 : 0,
      'subtasks': jsonEncode(task.subtasks),
      'reminderMinutes': task.reminderMinutes,
      'repeatType': task.repeatType.name,
      'selectedWeekDays': jsonEncode(task.selectedWeekDays),
      'finishDate': task.finishDate?.toIso8601String(),
      'createdAt': task.createdAt.toIso8601String(),
      'lastOccurrenceDate': task.lastOccurrenceDate?.toIso8601String(),
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

  // --- Focus Session Operations ---

  Future<int> insertFocusSession(int userId, int durationMinutes) async {
    final db = await database;
    final map = {
      'userId': userId,
      'durationMinutes': durationMinutes,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return await db.insert('focus_sessions', map);
  }

  Future<int> getTotalFocusMinutesForUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'focus_sessions',
      columns: ['durationMinutes'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    int total = 0;
    for (var row in results) {
      total += (row['durationMinutes'] as int? ?? 0);
    }
    return total;
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

  // --- Backup and Restore helper operations ---

  Future<bool> taskExists(int userId, String title, String createdAt) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'tasks',
      where: 'userId = ? AND title = ? AND createdAt = ?',
      whereArgs: [userId, title, createdAt],
    );
    return results.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getRawTasksForUser(int userId) async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> energyLogExists(int userId, String timestamp) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'energy_logs',
      where: 'userId = ? AND timestamp = ?',
      whereArgs: [userId, timestamp],
    );
    return results.isNotEmpty;
  }

  Future<bool> focusSessionExists(int userId, String timestamp) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'focus_sessions',
      where: 'userId = ? AND timestamp = ?',
      whereArgs: [userId, timestamp],
    );
    return results.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getFocusSessionsForUser(int userId) async {
    final db = await database;
    return await db.query(
      'focus_sessions',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<int> insertFocusSessionWithTimestamp(int userId, int durationMinutes, String timestamp) async {
    final db = await database;
    final map = {
      'userId': userId,
      'durationMinutes': durationMinutes,
      'timestamp': timestamp,
    };
    return await db.insert('focus_sessions', map);
  }
}
