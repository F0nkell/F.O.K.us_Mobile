// Эта модель ничего не знает про базу данных. Она нужна только для UI.
class DailyTask {
  final String id; // ID самого шаблона задачи
  final String title;
  final String type; // ONE_TIME или RECURRING
  final int points;
  final bool isCompleted;
  final bool isSkipped;

  DailyTask({
    required this.id,
    required this.title,
    required this.type,
    required this.points,
    required this.isCompleted,
    required this.isSkipped,
  });
}