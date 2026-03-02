import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/datasources/local_database.dart';
import 'task_engine.dart';

class StatsEngine {
  final AppDatabase db;
  final TaskEngine taskEngine;

  StatsEngine(this.db, this.taskEngine);

  // Пересчет статистики за конкретный день
  Future<void> recalculateDay(DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    // 1. Получаем все задачи на этот день через наш TaskEngine
    final tasks = await taskEngine.getTasksForDate(date);

    int points = 0;
    bool allRecurringDone = true;
    bool hasRecurring = false;

    // 2. Считаем баллы и проверяем постоянные задачи
    for (final task in tasks) {
      if (task.isCompleted) {
        points += task.points;
      }

      if (task.type == 'RECURRING') {
        hasRecurring = true;
        if (!task.isCompleted) {
          allRecurringDone = false; // Нашли невыполненную постоянную задачу
        }
      }
    }

    // Если постоянных задач нет, считаем, что условие Streak не выполнено
    if (!hasRecurring) {
      allRecurringDone = false;
    }

    // 3. Сохраняем результат в таблицу DailyStats (INSERT OR REPLACE)
    await db
        .into(db.dailyStats)
        .insertOnConflictUpdate(
          DailyStatsCompanion.insert(
            date: dateString,
            totalPoints: drift.Value(points),
            allRecurringCompleted: drift.Value(allRecurringDone),
          ),
        );
  }

  // Получить баллы за день
  Future<int> getPointsForDate(DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final query = db.select(db.dailyStats)
      ..where((s) => s.date.equals(dateString));
    final stat = await query.getSingleOrNull();
    return stat?.totalPoints ?? 0;
  }

  // АЛГОРИТМ: Расчет Streak (Серии дней подряд)
  Future<int> calculateStreak() async {
    int streak = 0;
    DateTime checkDate = DateTime.now(); // Начинаем с сегодня

    while (true) {
      final dateString = DateFormat('yyyy-MM-dd').format(checkDate);
      final query = db.select(db.dailyStats)
        ..where((s) => s.date.equals(dateString));
      final stat = await query.getSingleOrNull();

      if (stat != null && stat.allRecurringCompleted) {
        streak++; // День успешен, плюсуем серию
        checkDate = checkDate.subtract(
          const Duration(days: 1),
        ); // Идем во вчерашний день
      } else {
        // Если сегодня еще не выполнено, но вчера было выполнено - серия не прерывается
        if (streak == 0 && isSameDay(checkDate, DateTime.now())) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break; // Нашли пропуск, серия прервалась
      }
    }
    return streak;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Суммарные баллы за всё время
  Future<int> getTotalPoints() async {
    final all = await db.select(db.dailyStats).get();
    return all.fold<int>(0, (sum, s) => sum + s.totalPoints);
  }

  // Последние N дней со статистикой
  Future<List<DailyStat>> getRecentDaysStats(int days) async {
    final result = <DailyStat>[];
    final today = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final query = db.select(db.dailyStats)
        ..where((s) => s.date.equals(dateString));
      final stat = await query.getSingleOrNull();
      result.add(
        DailyStat(
          date: date,
          points: stat?.totalPoints ?? 0,
          allCompleted: stat?.allRecurringCompleted ?? false,
          hasData: stat != null,
        ),
      );
    }
    return result;
  }
}

// Вспомогательная модель для экрана статистики
class DailyStat {
  final DateTime date;
  final int points;
  final bool allCompleted;
  final bool hasData;

  DailyStat({
    required this.date,
    required this.points,
    required this.allCompleted,
    required this.hasData,
  });
}
