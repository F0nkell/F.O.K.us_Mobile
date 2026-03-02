import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_database.g.dart';

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()();
  IntColumn get points => integer().withDefault(const Constant(3))();
  TextColumn get startTime => text().nullable()();
  TextColumn get endTime => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class RecurringRules extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get frequency => text()();
  IntColumn get interval => integer().withDefault(const Constant(1))();
  TextColumn get daysOfWeek => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskInstances extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get date => text()();
  TextColumn get startTime => text().nullable()();
  TextColumn get endTime => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSkipped => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// НОВАЯ ТАБЛИЦА: Статистика за день
class DailyStats extends Table {
  TextColumn get date => text()(); // "2026-03-02" (Primary Key)
  IntColumn get totalPoints => integer().withDefault(const Constant(0))();
  BoolColumn get allRecurringCompleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {date};
}

// ДОБАВИЛИ DailyStats В СПИСОК ТАБЛИЦ
@DriftDatabase(tables: [Tasks, RecurringRules, TaskInstances, DailyStats])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    // ФОРСИРУЕМ НОВУЮ БАЗУ (v5)
    final file = File(p.join(dbFolder.path, 'discipline_v5.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
