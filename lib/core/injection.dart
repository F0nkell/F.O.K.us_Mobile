import 'package:get_it/get_it.dart';
import '../data/datasources/local_database.dart';
import '../domain/usecases/task_engine.dart';
import '../domain/usecases/stats_engine.dart';
import '../presentation/bloc/today_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 1. База данных (Singleton)
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // 2. Движок задач (Singleton)
  sl.registerLazySingleton<TaskEngine>(() => TaskEngine(sl<AppDatabase>()));

  // 3. Движок статистики (Singleton)
  sl.registerLazySingleton<StatsEngine>(
    () => StatsEngine(sl<AppDatabase>(), sl<TaskEngine>()),
  );

  // 4. BLoC (Factory)
  sl.registerFactory<TodayBloc>(
    () => TodayBloc(sl<TaskEngine>(), sl<StatsEngine>()),
  );
}
