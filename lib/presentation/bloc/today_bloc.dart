import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/daily_task.dart';
import '../../domain/usecases/task_engine.dart';

// --- СОСТОЯНИЯ (То, что видит UI) ---
abstract class TodayState {}

class TodayLoading extends TodayState {}

class TodayLoaded extends TodayState {
  final List<DailyTask> tasks;
  TodayLoaded(this.tasks);
}

// --- СОБЫТИЯ (То, что делает пользователь) ---
abstract class TodayEvent {}

class LoadTasks extends TodayEvent {}

class ToggleTask extends TodayEvent {
  final String taskId;
  final bool isCompleted;
  ToggleTask(this.taskId, this.isCompleted);
}

// --- САМ BLOC (Мозг экрана) ---
class TodayBloc extends Bloc<TodayEvent, TodayState> {
  final TaskEngine engine;

  TodayBloc(this.engine) : super(TodayLoading()) {
    
    // Обработка события: Загрузить задачи
    on<LoadTasks>((event, emit) async {
      emit(TodayLoading()); // Показываем крутилку
      final tasks = await engine.getTasksForDate(DateTime.now());
      emit(TodayLoaded(tasks)); // Отдаем готовый список в UI
    });

    // Обработка события: Нажатие на чекбокс
    on<ToggleTask>((event, emit) async {
      await engine.toggleTaskCompletion(event.taskId, DateTime.now(), event.isCompleted);
      add(LoadTasks()); // Перезагружаем список после изменения
    });
  }
}