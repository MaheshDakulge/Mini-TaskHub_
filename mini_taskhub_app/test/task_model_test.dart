import 'package:flutter_test/flutter_test.dart';
import 'package:mini_taskhub_app/dashboard/task_model.dart';

void main() {
  group('TaskModel Tests', () {
    final mockJson = {
      'id': '123e4567-e89b-12d3-a456-426614174000',
      'user_id': 'user-123',
      'title': 'Test Task',
      'description': 'This is a test task',
      'is_completed': false,
      'priority': 'high',
      'created_at': '2023-10-25T12:00:00Z',
    };

    test('Task.fromJson() correctly parses JSON', () {
      final task = Task.fromJson(mockJson);

      expect(task.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(task.userId, 'user-123');
      expect(task.title, 'Test Task');
      expect(task.description, 'This is a test task');
      expect(task.isCompleted, false);
      expect(task.priority, 'high');
      expect(task.createdAt, DateTime.parse('2023-10-25T12:00:00Z'));
    });

    test('Task.toJson() correctly serializes Task to JSON', () {
      final task = Task(
        id: '123',
        userId: 'user1',
        title: 'Serialize Test',
        description: null,
        isCompleted: true,
        priority: 'low',
        createdAt: DateTime.utc(2023, 10, 25, 12, 0, 0),
      );

      final json = task.toJson();

      expect(json['id'], '123');
      expect(json['title'], 'Serialize Test');
      expect(json['is_completed'], true);
      expect(json['priority'], 'low');
      expect(json['description'], null);
      expect(json['created_at'], '2023-10-25T12:00:00.000Z');
    });

    test('copyWith properly updates fields (e.g. is_completed toggle)', () {
      final task = Task(
        id: '1',
        userId: 'user1',
        title: 'Original',
        priority: 'medium',
        createdAt: DateTime.now(),
      );

      expect(task.isCompleted, false);

      final toggledTask = task.copyWith(isCompleted: !task.isCompleted);
      
      expect(toggledTask.isCompleted, true);
      expect(toggledTask.title, 'Original'); // Remains unchanged
    });
  });
}
