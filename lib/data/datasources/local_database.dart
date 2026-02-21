import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Генерируемый файл (пока его нет, будет ошибка, это нормально)
part 'local_database.g.dart';

// 1. Таблица Шаблонов Задач
class Tasks extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // 'ONE_TIME', 'RECURRING'
  IntColumn get points => integer().withDefault(const Constant(3))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

// 2. Таблица Правил Повторения
class RecurringRules extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get frequency => text()(); // 'DAILY', 'WEEKLY'
  IntColumn get interval => integer().withDefault(const Constant(1))();
  TextColumn get daysOfWeek => text().nullable()(); // "1,3,5"
  
  @override
  Set<Column> get primaryKey => {id};
}

// 3. Таблица Выполненных Задач (Инстансы)
class TaskInstances extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get date => text()(); // "2023-10-27" (Строгая привязка к дню)
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSkipped => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

// --- САМА БАЗА ДАННЫХ ---
@DriftDatabase(tables: [Tasks, RecurringRules, TaskInstances])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// Функция открытия файла БД (работает и на Windows, и на Android)
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'discipline.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}