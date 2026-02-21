import 'package:get_it/get_it.dart';
import '../data/datasources/local_database.dart';
import '../domain/usecases/task_engine.dart';
import '../presentation/bloc/today_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 1. База данных (Singleton - один на всё приложение)
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  
  // 2. Движок (Singleton)
  sl.registerLazySingleton<TaskEngine>(() => TaskEngine(sl<AppDatabase>()));
  
  // 3. BLoC (Factory - создаем новый экземпляр каждый раз, когда открываем экран)
  sl.registerFactory<TodayBloc>(() => TodayBloc(sl<TaskEngine>()));
}