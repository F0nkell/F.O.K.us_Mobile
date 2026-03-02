import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../data/datasources/local_database.dart';
import '../entities/daily_task.dart';

class TaskEngine {
  final AppDatabase db;

  TaskEngine(this.db);

  // Метод создания новой задачи
  Future<void> createTask({
    required String title,
    required String type,
    required int points,
    String? startTime,
    String? endTime,
    DateTime? targetDate,
    String frequency = 'DAILY',
    int interval = 1,
    String? daysOfWeek,
  }) async {
    final newId = const Uuid().v4();

    // 1. Создаем шаблон задачи
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: newId,
            title: title,
            type: type,
            points: drift.Value(points),
            startTime: drift.Value(startTime),
            endTime: drift.Value(endTime),
          ),
        );

    // 2. Для ONE_TIME — привязываем к конкретному дню
    if (type == 'ONE_TIME' && targetDate != null) {
      final dateString = DateFormat('yyyy-MM-dd').format(targetDate);
      await db
          .into(db.taskInstances)
          .insert(
            TaskInstancesCompanion.insert(
              id: const Uuid().v4(),
              taskId: newId,
              date: dateString,
              isCompleted: const drift.Value(false),
            ),
          );
    }

    // 3. Для RECURRING — создаем правило повторения
    if (type == 'RECURRING') {
      await db
          .into(db.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              id: const Uuid().v4(),
              taskId: newId,
              frequency: frequency,
              interval: drift.Value(interval),
              daysOfWeek: drift.Value(daysOfWeek),
            ),
          );
    }
  }

  // Вспомогательный метод: перевод "HH:mm" в минуты от начала дня
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts.elementAt(0)) * 60 + int.parse(parts.elementAt(1));
  }

  // АЛГОРИТМ: Проверка пересечения времени
  Future<bool> hasTimeCollision(
    DateTime date,
    String newStart,
    String newEnd,
  ) async {
    final tasksForDay = await getTasksForDate(date);
    final newStartMin = _timeToMinutes(newStart);
    final newEndMin = _timeToMinutes(newEnd);

    for (final task in tasksForDay) {
      if (task.startTime != null && task.endTime != null) {
        final existingStartMin = _timeToMinutes(task.startTime!);
        final existingEndMin = _timeToMinutes(task.endTime!);
        if (newStartMin < existingEndMin && newEndMin > existingStartMin) {
          return true;
        }
      }
    }
    return false;
  }

  Future<List<DailyTask>> getTasksForDate(DateTime targetDate) async {
    final dateString = DateFormat('yyyy-MM-dd').format(targetDate);

    final allTasks = await (db.select(
      db.tasks,
    )..where((t) => t.isDeleted.equals(false))).get();

    final instances = await (db.select(
      db.taskInstances,
    )..where((i) => i.date.equals(dateString))).get();

    // Загружаем ВСЕ правила одним запросом (без N+1)
    final allRules = await db.select(db.recurringRules).get();

    final result = List<DailyTask>.empty(growable: true);

    // Нормализуем целевую дату
    final targetDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    for (final task in allTasks) {
      // Нормализуем дату создания
      final createdDay = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
      );

      // Не показываем задачу раньше даты её создания
      if (targetDay.isBefore(createdDay)) continue;

      final instance = instances.where((i) => i.taskId == task.id).firstOrNull;

      if (task.type == 'RECURRING') {
        // Ищем правило для этой задачи
        final rule = allRules.where((r) => r.taskId == task.id).firstOrNull;

        bool shouldShow = true; // Фолбэк: DAILY для старых задач без правила

        if (rule != null) {
          switch (rule.frequency) {
            case 'DAILY':
              shouldShow = true;
              break;

            case 'WEEKLY':
              if (rule.daysOfWeek != null && rule.daysOfWeek!.isNotEmpty) {
                final allowedDays = rule.daysOfWeek!
                    .split(',')
                    .map((d) => int.tryParse(d.trim()))
                    .whereType<int>()
                    .toList();
                shouldShow = allowedDays.contains(targetDate.weekday);
              }
              break;

            case 'INTERVAL':
              final daysDiff = targetDay.difference(createdDay).inDays;
              final ivl = rule.interval > 0 ? rule.interval : 1;
              shouldShow = daysDiff % ivl == 0;
              break;

            default:
              shouldShow = true;
          }
        }

        if (!shouldShow) continue;

        result.add(
          DailyTask(
            id: task.id,
            title: task.title,
            type: task.type,
            points: task.points,
            isCompleted: instance?.isCompleted ?? false,
            isSkipped: instance?.isSkipped ?? false,
            startTime: instance?.startTime ?? task.startTime,
            endTime: instance?.endTime ?? task.endTime,
            frequency: rule?.frequency ?? 'DAILY',
            daysOfWeek: rule?.daysOfWeek,
            interval: rule?.interval ?? 1,
          ),
        );
      } else if (task.type == 'ONE_TIME' && instance != null) {
        result.add(
          DailyTask(
            id: task.id,
            title: task.title,
            type: task.type,
            points: task.points,
            isCompleted: instance.isCompleted,
            isSkipped: instance.isSkipped,
            startTime: instance.startTime ?? task.startTime,
            endTime: instance.endTime ?? task.endTime,
            frequency: 'ONCE',
          ),
        );
      }
    }
    return result;
  }

  Future<void> toggleTaskCompletion(
    String taskId,
    DateTime date,
    bool isCompleted,
  ) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final query = db.select(db.taskInstances)
      ..where((i) => i.taskId.equals(taskId) & i.date.equals(dateString));
    final existing = await query.getSingleOrNull();

    if (existing != null) {
      await (db.update(db.taskInstances)
            ..where((i) => i.id.equals(existing.id)))
          .write(TaskInstancesCompanion(isCompleted: drift.Value(isCompleted)));
    } else {
      await db
          .into(db.taskInstances)
          .insert(
            TaskInstancesCompanion.insert(
              id: const Uuid().v4(),
              taskId: taskId,
              date: dateString,
              isCompleted: drift.Value(isCompleted),
            ),
          );
    }
  }

  Future<void> deleteTask(String taskId) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
      const TasksCompanion(isDeleted: drift.Value(true)),
    );
  }
}
