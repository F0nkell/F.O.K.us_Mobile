import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/today_bloc.dart';

class AddTaskBottomSheet extends StatefulWidget {
  const AddTaskBottomSheet({super.key});

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _intervalController = TextEditingController(text: '2');

  String _selectedType = 'ONE_TIME';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Настройки повторения
  String _frequency = 'DAILY';
  final Set<int> _selectedDays = {}; // 1=Пн … 7=Вс

  static const _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.redAccent,
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E1E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Введите название задачи');
      return;
    }
    if (_startTime == null || _endTime == null) {
      _showError('Выберите время начала и конца');
      return;
    }
    if (_toMinutes(_startTime!) >= _toMinutes(_endTime!)) {
      _showError('Начало должно быть раньше конца');
      return;
    }
    if (_selectedType == 'RECURRING' &&
        _frequency == 'WEEKLY' &&
        _selectedDays.isEmpty) {
      _showError('Выберите хотя бы один день недели');
      return;
    }

    final interval = int.tryParse(_intervalController.text.trim()) ?? 2;
    String? daysOfWeek;
    if (_frequency == 'WEEKLY') {
      final sorted = _selectedDays.toList()..sort();
      daysOfWeek = sorted.join(',');
    }

    context.read<TodayBloc>().add(
      AddTask(
        title,
        _formatTime(_startTime!),
        _formatTime(_endTime!),
        _selectedType,
        frequency: _selectedType == 'RECURRING' ? _frequency : 'DAILY',
        daysOfWeek: daysOfWeek,
        interval: interval,
      ),
    );
    Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Новая задача',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // --- Название ---
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Тип задачи ---
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ONE_TIME', label: Text('Разовая (3 б.)')),
                ButtonSegment(
                  value: 'RECURRING',
                  label: Text('Постоянная (5 б.)'),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (s) =>
                  setState(() => _selectedType = s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.redAccent.withOpacity(0.2);
                  }
                  return Colors.transparent;
                }),
              ),
            ),
            const SizedBox(height: 16),

            // --- Настройки повторения (только для RECURRING) ---
            if (_selectedType == 'RECURRING') ...[
              const Text(
                'Повторение',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'DAILY', label: Text('Ежедневно')),
                  ButtonSegment(value: 'WEEKLY', label: Text('По дням')),
                  ButtonSegment(value: 'INTERVAL', label: Text('Интервал')),
                ],
                selected: {_frequency},
                onSelectionChanged: (s) => setState(() => _frequency = s.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.blueAccent.withOpacity(0.2);
                    }
                    return Colors.transparent;
                  }),
                ),
              ),
              const SizedBox(height: 12),

              // Дни недели
              if (_frequency == 'WEEKLY') ...[
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    final day = i + 1; // 1=Пн…7=Вс
                    final selected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(_dayLabels[i]),
                      selected: selected,
                      selectedColor: Colors.redAccent.withOpacity(0.3),
                      checkmarkColor: Colors.redAccent,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],

              // Интервал
              if (_frequency == 'INTERVAL') ...[
                TextField(
                  controller: _intervalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Раз в N дней',
                    prefixIcon: const Icon(Icons.repeat),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],

            // --- Время ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.access_time, color: Colors.white),
                    label: Text(
                      _startTime == null ? 'Начало' : _formatTime(_startTime!),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(
                      Icons.access_time_filled,
                      color: Colors.white,
                    ),
                    label: Text(
                      _endTime == null ? 'Конец' : _formatTime(_endTime!),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Кнопка сохранения ---
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'СОХРАНИТЬ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
