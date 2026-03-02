import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/daily_task.dart';
import '../../domain/usecases/task_engine.dart';
import '../../domain/usecases/stats_engine.dart';

// --- СОСТОЯНИЯ ---
abstract class TodayState {}

class TodayLoading extends TodayState {}

class TodayLoaded extends TodayState {
  final List<DailyTask> tasks;
  final DateTime selectedDate;
  final int dailyPoints;
  final int currentStreak;

  TodayLoaded(
    this.tasks,
    this.selectedDate,
    this.dailyPoints,
    this.currentStreak,
  );
}

class TodayError extends TodayState {
  final String message;
  TodayError(this.message);
}

// --- СОБЫТИЯ ---
abstract class TodayEvent {}

class LoadTasks extends TodayEvent {}

class SelectDate extends TodayEvent {
  final DateTime date;
  SelectDate(this.date);
}

class ToggleTask extends TodayEvent {
  final String taskId;
  final bool isCompleted;
  ToggleTask(this.taskId, this.isCompleted);
}

class AddTask extends TodayEvent {
  final String title;
  final String startTime;
  final String endTime;
  final String type;
  final String frequency; // 'DAILY', 'WEEKLY', 'INTERVAL'
  final String? daysOfWeek; // "1,3,5" для WEEKLY
  final int interval; // N дней для INTERVAL

  AddTask(
    this.title,
    this.startTime,
    this.endTime,
    this.type, {
    this.frequency = 'DAILY',
    this.daysOfWeek,
    this.interval = 1,
  });
}

class DeleteTask extends TodayEvent {
  final String taskId;
  DeleteTask(this.taskId);
}

// --- BLOC ---
class TodayBloc extends Bloc<TodayEvent, TodayState> {
  final TaskEngine engine;
  final StatsEngine statsEngine;
  DateTime currentDate = DateTime.now();

  TodayBloc(this.engine, this.statsEngine) : super(TodayLoading()) {
    on<LoadTasks>((event, emit) async {
      emit(TodayLoading());
      final tasks = await engine.getTasksForDate(currentDate);
      final points = await statsEngine.getPointsForDate(currentDate);
      final streak = await statsEngine.calculateStreak();
      emit(TodayLoaded(tasks, currentDate, points, streak));
    });

    on<SelectDate>((event, emit) {
      currentDate = event.date;
      add(LoadTasks());
    });

    on<ToggleTask>((event, emit) async {
      await engine.toggleTaskCompletion(
        event.taskId,
        currentDate,
        event.isCompleted,
      );
      await statsEngine.recalculateDay(currentDate);
      add(LoadTasks());
    });

    on<AddTask>((event, emit) async {
      final hasCollision = await engine.hasTimeCollision(
        currentDate,
        event.startTime,
        event.endTime,
      );

      if (hasCollision) {
        emit(TodayError('Время ${event.startTime}-${event.endTime} занято!'));
        final tasks = await engine.getTasksForDate(currentDate);
        final points = await statsEngine.getPointsForDate(currentDate);
        final streak = await statsEngine.calculateStreak();
        emit(TodayLoaded(tasks, currentDate, points, streak));
      } else {
        await engine.createTask(
          title: event.title,
          type: event.type,
          points: event.type == 'RECURRING' ? 5 : 3,
          startTime: event.startTime,
          endTime: event.endTime,
          targetDate: currentDate,
          frequency: event.frequency,
          interval: event.interval,
          daysOfWeek: event.daysOfWeek,
        );
        await statsEngine.recalculateDay(currentDate);
        add(LoadTasks());
      }
    });

    on<DeleteTask>((event, emit) async {
      await engine.deleteTask(event.taskId);
      await statsEngine.recalculateDay(currentDate);
      add(LoadTasks());
    });
  }
}
