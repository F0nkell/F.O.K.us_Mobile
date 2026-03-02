// Эта модель ничего не знает про базу данных. Она нужна только для UI.
class DailyTask {
  final String id;
  final String title;
  final String type;
  final int points;
  final bool isCompleted;
  final bool isSkipped;
  final String? startTime;
  final String? endTime;

  // Поля для отображения типа повторения в UI карточки
  final String frequency; // 'DAILY', 'WEEKLY', 'INTERVAL', 'ONCE'
  final String? daysOfWeek; // "1,3,5" (для WEEKLY)
  final int interval; // N (для INTERVAL)

  DailyTask({
    required this.id,
    required this.title,
    required this.type,
    required this.points,
    required this.isCompleted,
    required this.isSkipped,
    this.startTime,
    this.endTime,
    this.frequency = 'DAILY',
    this.daysOfWeek,
    this.interval = 1,
  });
}
