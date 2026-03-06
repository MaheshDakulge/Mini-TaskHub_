import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard/task_model.dart';

/// Represents a single operation that was queued while offline.
class OfflineOperation {
  final String type; // 'add', 'toggle', 'delete'
  final Map<String, dynamic> data;

  OfflineOperation({required this.type, required this.data});

  Map<String, dynamic> toJson() => {'type': type, 'data': data};

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      type: json['type'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}

class LocalStorageService {
  // Singleton
  LocalStorageService._privateConstructor();
  static final LocalStorageService instance =
      LocalStorageService._privateConstructor();

  static const String _tasksKey = 'cached_tasks';
  static const String _queueKey = 'offline_queue';

  // ──────────────────────────────────────────
  // Tasks Cache
  // ──────────────────────────────────────────

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_tasksKey, jsonEncode(jsonList));
  }

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw == null) return [];
    try {
      final jsonList = jsonDecode(raw) as List;
      return jsonList
          .map((j) => Task.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ──────────────────────────────────────────
  // Offline Operations Queue
  // ──────────────────────────────────────────

  Future<void> saveQueue(List<OfflineOperation> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = queue.map((op) => op.toJson()).toList();
    await prefs.setString(_queueKey, jsonEncode(jsonList));
  }

  Future<List<OfflineOperation>> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null) return [];
    try {
      final jsonList = jsonDecode(raw) as List;
      return jsonList
          .map(
            (j) =>
                OfflineOperation.fromJson(Map<String, dynamic>.from(j as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }
}
