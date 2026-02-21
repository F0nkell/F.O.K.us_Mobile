import 'package:intl/intl.dart';
// ИСПРАВЛЕНИЕ 1 и 2: Подключаем Drift для оператора & и drift.Value
import 'package:drift/drift.dart' as drift;
// ИСПРАВЛЕНИЕ 3: Подключаем генератор уникальных ID
import 'package:uuid/uuid.dart';

import '../../data/datasources/local_database.dart';
import '../entities/daily_task.dart';

class TaskEngine {
  final AppDatabase db;

  TaskEngine(this.db);

  // Главный алгоритм: Получить задачи на конкретную дату
  Future<List<DailyTask>> getTasksForDate(DateTime targetDate) async {
    final dateString = DateFormat('yyyy-MM-dd').format(targetDate);

    final allTasks = await (db.select(db.tasks)..where((t) => t.isDeleted.equals(false))).get();
    final instances = await (db.select(db.taskInstances)..where((i) => i.date.equals(dateString))).get();

    final result = List<DailyTask>.empty(growable: true);

    for (final task in allTasks) {
      final instance = instances.where((i) => i.taskId == task.id).firstOrNull;

      if (task.type == 'RECURRING') {
        result.add(DailyTask(
          id: task.id,
          title: task.title,
          type: task.type,
          points: task.points,
          isCompleted: instance?.isCompleted ?? false,
          isSkipped: instance?.isSkipped ?? false,
        ));
      } else if (task.type == 'ONE_TIME') {
        if (instance != null) {
          result.add(DailyTask(
            id: task.id,
            title: task.title,
            type: task.type,
            points: task.points,
            isCompleted: instance.isCompleted,
            isSkipped: instance.isSkipped,
          ));
        }
      }
    }

    return result;
  }

  // Метод материализации: Отмечаем задачу выполненной в конкретный день
  Future<void> toggleTaskCompletion(String taskId, DateTime date, bool isCompleted) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    
    // Теперь оператор & работает, потому что мы импортировали drift!
    final query = db.select(db.taskInstances)..where((i) => i.taskId.equals(taskId) & i.date.equals(dateString));
    final existing = await query.getSingleOrNull();
    
    if (existing != null) {
      final updateQuery = db.update(db.taskInstances)..where((i) => i.id.equals(existing.id));
      await updateQuery.write(
        TaskInstancesCompanion(isCompleted: drift.Value(isCompleted)),
      );
    } else {
      // Теперь Uuid() работает, потому что мы его импортировали!
      final newInstanceId = const Uuid().v4();
      await db.into(db.taskInstances).insert(
        TaskInstancesCompanion.insert(
          id: newInstanceId,
          taskId: taskId,
          date: dateString,
          isCompleted: drift.Value(isCompleted),
        ),
      );
    }
  }
}