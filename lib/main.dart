import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'core/injection.dart' as di;
import 'presentation/bloc/today_bloc.dart';
import 'data/datasources/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const DisciplineApp());
}

class DisciplineApp extends StatelessWidget {
  const DisciplineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discipline',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // BlocProvider внедряет BLoC в дерево виджетов и сразу вызывает событие LoadTasks
      home: BlocProvider(
        create: (context) => di.sl<TodayBloc>()..add(LoadTasks()),
        child: const TodayPage(),
      ),
    );
  }
}

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сегодня', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      // BlocBuilder автоматически перерисовывает ТОЛЬКО этот кусок при смене State
      body: BlocBuilder<TodayBloc, TodayState>(
        builder: (context, state) {
          if (state is TodayLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          } 
          
          if (state is TodayLoaded) {
            if (state.tasks.isEmpty) {
              return const Center(child: Text('Нет задач. Добавь первую!', style: TextStyle(color: Colors.grey)));
            }

            return ListView.builder(
              itemCount: state.tasks.length,
              itemBuilder: (context, index) {
                final task = state.tasks.elementAt(index);
                
                return CheckboxListTile(
                  title: Text(
                    task.title, 
                    style: TextStyle(
                      fontSize: 18,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? Colors.grey : Colors.white,
                    )
                  ),
                  subtitle: Text('Баллы: ${task.points} | Тип: ${task.type}'),
                  value: task.isCompleted,
                  activeColor: Colors.redAccent,
                  onChanged: (bool? value) {
                    if (value != null) {
                      // Отправляем СОБЫТИЕ в BLoC вместо прямого вызова БД
                      context.read<TodayBloc>().add(ToggleTask(task.id, value));
                    }
                  },
                );
              },
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () async {
          // Временная кнопка добавления (позже сделаем красивое окно)
          final db = di.sl<AppDatabase>();
          await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: const Uuid().v4(),
              title: 'Сделать коммит в GitHub',
              type: 'RECURRING',
              points: const drift.Value(5),
            ),
          );
          // Говорим BLoC'у: "Эй, данные изменились, загрузи их заново!"
          if (context.mounted) {
            context.read<TodayBloc>().add(LoadTasks());
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}