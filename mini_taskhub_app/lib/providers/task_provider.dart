import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../dashboard/task_model.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import '../services/local_storage_service.dart';
import '../auth/auth_service.dart';

enum TaskFilter { all, pending, completed, highPriority, today }

class TaskProvider extends ChangeNotifier {
  final _supabase = SupabaseService.instance;
  final _authService = AuthService();
  final _connectivity = ConnectivityService.instance;
  final _localStorage = LocalStorageService.instance;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  TaskFilter _currentFilter = TaskFilter.all;
  String _searchQuery = '';
  bool _isOnline = true;
  bool _isSyncing = false;
  bool _justCameOnline = false;

  StreamSubscription<bool>? _connectivitySubscription;

  // ──────────────────────────────────────────
  // Getters
  // ──────────────────────────────────────────

  List<Task> get allTasks => _tasks;

  List<Task> get tasks {
    List<Task> result = List.from(_tasks);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                (t.description?.toLowerCase().contains(q) ?? false) ||
                (t.category?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    // Apply filter
    switch (_currentFilter) {
      case TaskFilter.pending:
        result = result.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.completed:
        result = result.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.highPriority:
        result = result
            .where(
              (t) =>
                  (t.priority == 'urgent' || t.priority == 'high') &&
                  !t.isCompleted,
            )
            .toList();
        break;
      case TaskFilter.today:
        result = result.where((t) => t.isDueToday && !t.isCompleted).toList();
        break;
      case TaskFilter.all:
      default:
        break;
    }

    return result;
  }

  // Smart sort: urgent > high > medium > low, completed last
  List<Task> get sortedTasks {
    final list = List<Task>.from(tasks);
    const order = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      final pa = order[a.priority] ?? 2;
      final pb = order[b.priority] ?? 2;
      return pa.compareTo(pb);
    });
    return list;
  }

  List<Task> get urgentTasks =>
      _tasks.where((t) => t.priority == 'urgent' && !t.isCompleted).toList();

  List<Task> get todayTasks =>
      _tasks.where((t) => t.isDueToday && !t.isCompleted).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TaskFilter get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  bool get justCameOnline => _justCameOnline;
  bool get allDone => _tasks.isNotEmpty && _tasks.every((t) => t.isCompleted);

  // Statistics
  int get totalTasks => _tasks.length;
  int get pendingTasks => _tasks.where((t) => !t.isCompleted).length;
  int get completedTasks => _tasks.where((t) => t.isCompleted).length;
  double get completionRate =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

  // ──────────────────────────────────────────
  // Constructor & Connectivity
  // ──────────────────────────────────────────

  TaskProvider() {
    _isOnline = _connectivity.isOnline;
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _connectivitySubscription = _connectivity.onlineStatus.listen((
      online,
    ) async {
      final wasOffline = !_isOnline;
      _isOnline = online;
      notifyListeners();
      if (online && wasOffline) {
        _justCameOnline = true;
        notifyListeners();
        await syncOfflineQueue();
        await fetchTasks();
        Future.delayed(const Duration(seconds: 3), () {
          _justCameOnline = false;
          notifyListeners();
        });
      }
    });
  }

  void setFilter(TaskFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? m) {
    _errorMessage = m;
    notifyListeners();
  }

  // ──────────────────────────────────────────
  // Fetch
  // ──────────────────────────────────────────

  Future<void> fetchTasks() async {
    final user = _authService.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }

    if (!_isOnline) {
      _tasks = await _localStorage.loadTasks();
      notifyListeners();
      return;
    }

    _setLoading(true);
    _setError(null);
    try {
      final response = await _supabase.tasksTable
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      _tasks = (response as List).map((j) => Task.fromJson(j)).toList();
      await _localStorage.saveTasks(_tasks);
    } catch (e) {
      _tasks = await _localStorage.loadTasks();
      _setError('Showing cached data.');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────
  // Add Task
  // ──────────────────────────────────────────

  Future<void> addTask(
    String title,
    String? description,
    String priority, {
    String? category,
    DateTime? dueDate,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    if (!_isOnline) {
      final tempId = 'offline_${const Uuid().v4()}';
      final tempTask = Task(
        id: tempId,
        userId: user.id,
        title: title,
        description: description,
        priority: priority,
        category: category,
        dueDate: dueDate,
        createdAt: DateTime.now(),
      );
      _tasks.insert(0, tempTask);
      await _localStorage.saveTasks(_tasks);
      final queue = await _localStorage.loadQueue();
      queue.add(
        OfflineOperation(
          type: 'add',
          data: {
            'user_id': user.id,
            'title': title,
            'description': description,
            'priority': priority,
            'category': category,
            'due_date': dueDate?.toIso8601String(),
            'temp_id': tempId,
          },
        ),
      );
      await _localStorage.saveQueue(queue);
      notifyListeners();
      return;
    }

    _setLoading(true);
    _setError(null);
    try {
      final response = await _supabase.tasksTable
          .insert({
            'user_id': user.id,
            'title': title,
            'description': description,
            'priority': priority,
            'category': category,
            'due_date': dueDate?.toIso8601String(),
          })
          .select()
          .single();
      _tasks.insert(0, Task.fromJson(response));
      await _localStorage.saveTasks(_tasks);
    } catch (e) {
      _setError('Failed to add task: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────
  // Edit Task
  // ──────────────────────────────────────────

  Future<void> editTask(
    Task task, {
    required String title,
    String? description,
    required String priority,
    String? category,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final updated = task.copyWith(
      title: title,
      description: description,
      priority: priority,
      category: category,
      dueDate: dueDate,
      clearDueDate: clearDueDate,
    );
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    _tasks[index] = updated;
    notifyListeners();

    if (!_isOnline) {
      await _localStorage.saveTasks(_tasks);
      return;
    }

    try {
      await _supabase.tasksTable
          .update({
            'title': title,
            'description': description,
            'priority': priority,
            'category': category,
            'due_date': clearDueDate ? null : dueDate?.toIso8601String(),
          })
          .eq('id', task.id)
          .eq('user_id', user.id);
      await _localStorage.saveTasks(_tasks);
    } catch (e) {
      _tasks[index] = task;
      _setError('Failed to edit task: $e');
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────
  // Toggle
  // ──────────────────────────────────────────

  Future<void> toggleTask(Task task) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    _tasks[index] = updated;
    notifyListeners();

    if (!_isOnline) {
      await _localStorage.saveTasks(_tasks);
      final queue = await _localStorage.loadQueue();
      queue.add(
        OfflineOperation(
          type: 'toggle',
          data: {
            'task_id': task.id,
            'user_id': user.id,
            'is_completed': updated.isCompleted,
          },
        ),
      );
      await _localStorage.saveQueue(queue);
      return;
    }

    try {
      await _supabase.tasksTable
          .update({'is_completed': updated.isCompleted})
          .eq('id', task.id)
          .eq('user_id', user.id);
      await _localStorage.saveTasks(_tasks);
    } catch (e) {
      _tasks[index] = task;
      _setError('Failed to update task: $e');
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────
  // Delete
  // ──────────────────────────────────────────

  Future<void> deleteTask(String taskId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;
    final deleted = _tasks[taskIndex];
    _tasks.removeAt(taskIndex);
    notifyListeners();

    if (!_isOnline) {
      await _localStorage.saveTasks(_tasks);
      if (!taskId.startsWith('offline_')) {
        final queue = await _localStorage.loadQueue();
        queue.add(
          OfflineOperation(
            type: 'delete',
            data: {'task_id': taskId, 'user_id': user.id},
          ),
        );
        await _localStorage.saveQueue(queue);
      }
      return;
    }

    try {
      await _supabase.tasksTable
          .delete()
          .eq('id', taskId)
          .eq('user_id', user.id);
      await _localStorage.saveTasks(_tasks);
    } catch (e) {
      _tasks.insert(taskIndex, deleted);
      _setError('Failed to delete task: $e');
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────
  // Sync Offline Queue
  // ──────────────────────────────────────────

  Future<void> syncOfflineQueue() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final queue = await _localStorage.loadQueue();
    if (queue.isEmpty) return;

    _isSyncing = true;
    notifyListeners();
    final remaining = <OfflineOperation>[];

    for (final op in queue) {
      try {
        switch (op.type) {
          case 'add':
            final d = op.data;
            await _supabase.tasksTable.insert({
              'user_id': d['user_id'],
              'title': d['title'],
              'description': d['description'],
              'priority': d['priority'],
              'category': d['category'],
              'due_date': d['due_date'],
            });
            _tasks.removeWhere((t) => t.id == d['temp_id']);
            break;
          case 'toggle':
            final d = op.data;
            if (!(d['task_id'] as String).startsWith('offline_')) {
              await _supabase.tasksTable
                  .update({'is_completed': d['is_completed']})
                  .eq('id', d['task_id'] as String)
                  .eq('user_id', d['user_id'] as String);
            }
            break;
          case 'delete':
            final d = op.data;
            await _supabase.tasksTable
                .delete()
                .eq('id', d['task_id'] as String)
                .eq('user_id', d['user_id'] as String);
            break;
        }
      } catch (_) {
        remaining.add(op);
      }
    }

    await _localStorage.saveQueue(remaining);
    _isSyncing = false;
    notifyListeners();
  }

  void clearError() => _setError(null);

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
