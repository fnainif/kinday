import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kinday/database/db_helper.dart';

class FirebaseBackupService {
  static final FirebaseBackupService _instance = FirebaseBackupService._internal();
  factory FirebaseBackupService() => _instance;
  FirebaseBackupService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DBHelper _dbHelper = DBHelper();

  static const String _lastBackupKey = 'last_backup_time';

  // Helper to get current Firebase UID
  String? get _currentUserUid => _auth.currentUser?.uid;

  /// Backs up tasks, energy logs, and focus sessions to Firestore in a single document.
  Future<bool> backupData(int localUserId, {bool silent = false}) async {
    final uid = _currentUserUid;
    if (uid == null) {
      if (!silent) debugPrint("Backup failed: User not logged into Firebase.");
      return false;
    }

    try {
      if (!silent) debugPrint("Starting backup for user $localUserId to Firebase UID $uid...");

      // 1. Fetch raw data from SQLite
      final tasks = await _dbHelper.getRawTasksForUser(localUserId);
      final energyLogs = await _dbHelper.getEnergyLogsForUser(localUserId);
      final focusSessions = await _dbHelper.getFocusSessionsForUser(localUserId);

      if (!silent) {
        debugPrint("SQLite Data Found for Backup: "
            "Tasks: ${tasks.length}, "
            "Energy Logs: ${energyLogs.length}, "
            "Focus Sessions: ${focusSessions.length}");
      }

      // 2. Prepare backup structure
      final backupData = {
        'backup_timestamp': FieldValue.serverTimestamp(),
        'tasks': tasks,
        'energy_logs': energyLogs,
        'focus_sessions': focusSessions,
      };

      // 3. Save to Firestore (overwriting the 'latest' backup document)
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('backups')
          .doc('latest')
          .set(backupData);

      // 4. Update last backup timestamp in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());

      if (!silent) debugPrint("Backup successful!");
      return true;
    } catch (e) {
      debugPrint("Error backing up data: $e");
      return false;
    }
  }

  /// Restores data from Firestore, merging it into SQLite without duplicates.
  Future<bool> restoreData(int localUserId) async {
    final uid = _currentUserUid;
    if (uid == null) {
      debugPrint("Restore failed: User not logged into Firebase.");
      return false;
    }

    try {
      debugPrint("Starting restore for user $localUserId from Firebase UID $uid...");

      // 1. Fetch backup document from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('backups')
          .doc('latest')
          .get();

      if (!doc.exists || doc.data() == null) {
        debugPrint("Restore failed: No backup found in Firestore.");
        return false;
      }

      final data = doc.data()!;
      final db = await _dbHelper.database;

      // 2. Restore Tasks
      final List<dynamic> backupTasks = data['tasks'] as List<dynamic>? ?? [];
      debugPrint("Found ${backupTasks.length} tasks in backup. Restoring...");
      for (var taskData in backupTasks) {
        final Map<String, dynamic> task = Map<String, dynamic>.from(taskData as Map);
        final title = task['title'] as String? ?? '';
        final createdAt = task['createdAt'] as String? ?? '';

        // Check if task already exists locally
        final exists = await _dbHelper.taskExists(localUserId, title, createdAt);
        debugPrint("Task '$title' (createdAt: '$createdAt'): exists locally = $exists");
        if (!exists) {
          // Remove local autoincrement ID to let SQLite generate a new one
          task.remove('id');
          // Ensure correct local user ID mapping
          task['userId'] = localUserId;
          final newId = await db.insert('tasks', task);
          debugPrint("Inserted task '$title' with new ID $newId");
        } else {
          debugPrint("Skipped task '$title' (already exists)");
        }
      }

      // 3. Restore Energy Logs
      final List<dynamic> backupLogs = data['energy_logs'] as List<dynamic>? ?? [];
      debugPrint("Found ${backupLogs.length} energy logs in backup. Restoring...");
      for (var logData in backupLogs) {
        final Map<String, dynamic> log = Map<String, dynamic>.from(logData as Map);
        final timestamp = log['timestamp'] as String? ?? '';

        // Check if log already exists locally
        final exists = await _dbHelper.energyLogExists(localUserId, timestamp);
        debugPrint("Energy Log at '$timestamp': exists locally = $exists");
        if (!exists) {
          log.remove('id');
          log['userId'] = localUserId;
          final newId = await db.insert('energy_logs', log);
          debugPrint("Inserted energy log with new ID $newId");
        } else {
          debugPrint("Skipped energy log at '$timestamp'");
        }
      }

      // 4. Restore Focus Sessions
      final List<dynamic> backupSessions = data['focus_sessions'] as List<dynamic>? ?? [];
      debugPrint("Found ${backupSessions.length} focus sessions in backup. Restoring...");
      for (var sessionData in backupSessions) {
        final Map<String, dynamic> session = Map<String, dynamic>.from(sessionData as Map);
        final timestamp = session['timestamp'] as String? ?? '';

        // Check if session already exists locally
        final exists = await _dbHelper.focusSessionExists(localUserId, timestamp);
        debugPrint("Focus Session at '$timestamp': exists locally = $exists");
        if (!exists) {
          session.remove('id');
          session['userId'] = localUserId;
          final newId = await db.insert('focus_sessions', session);
          debugPrint("Inserted focus session with new ID $newId");
        } else {
          debugPrint("Skipped focus session at '$timestamp'");
        }
      }

      debugPrint("Restore successful!");
      return true;
    } catch (e) {
      debugPrint("Error restoring data: $e");
      return false;
    }
  }

  /// Checks if more than 7 days have passed since the last backup and triggers a silent backup if so.
  Future<void> checkAndRunAutoBackup(int localUserId) async {
    final uid = _currentUserUid;
    if (uid == null) return; // User not logged in, skip auto-backup

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupStr = prefs.getString(_lastBackupKey);

      if (lastBackupStr == null) {
        // First time backup, run it
        await backupData(localUserId, silent: true);
      } else {
        final lastBackupTime = DateTime.parse(lastBackupStr);
        final difference = DateTime.now().difference(lastBackupTime).inDays;

        if (difference >= 7) {
          debugPrint("Auto-backup trigger: $difference days since last backup. Running backup...");
          await backupData(localUserId, silent: true);
        }
      }
    } catch (e) {
      debugPrint("Error checking or running auto backup: $e");
    }
  }
}
