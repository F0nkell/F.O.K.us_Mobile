import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/usecases/stats_engine.dart';
import '../../core/injection.dart' as di;

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _statsEngine = di.sl<StatsEngine>();

  int _streak = 0;
  int _totalPoints = 0;
  List<DailyStat> _recentDays = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final streak = await _statsEngine.calculateStreak();
    final total = await _statsEngine.getTotalPoints();
    final days = await _statsEngine.getRecentDaysStats(14);
    setState(() {
      _streak = streak;
      _totalPoints = total;
      _recentDays = days;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Профиль',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Шапка: Streak + Уровень ---
                  _buildHeroCard(context),
                  const SizedBox(height: 20),

                  // --- Общие баллы ---
                  _buildTotalPointsCard(context),
                  const SizedBox(height: 20),

                  // --- История 14 дней ---
                  const Text(
                    'История (14 дней)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryList(context),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final level = _totalPoints ~/ 100 + 1;
    final nextLevel = level * 100;
    final progressInLevel = _totalPoints % 100;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Стрик
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_streak',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'дней подряд',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Уровень
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Уровень $level',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$progressInLevel / $nextLevel б.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressInLevel / 100,
                backgroundColor: Colors.white12,
                color: Colors.redAccent,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalPointsCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Всего баллов',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  '$_totalPoints',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    final dateFormat = DateFormat('E, d MMM', 'ru_RU');
    return Column(
      children: _recentDays.asMap().entries.map((entry) {
        final stat = entry.value;
        final isToday = entry.key == 0;
        final label = isToday ? 'Сегодня' : dateFormat.format(stat.date);

        Color statusColor;
        IconData statusIcon;
        if (!stat.hasData) {
          statusColor = Colors.grey.shade700;
          statusIcon = Icons.remove;
        } else if (stat.allCompleted) {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else {
          statusColor = Colors.orangeAccent;
          statusIcon = Icons.circle_outlined;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (stat.points > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${stat.points}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const Text('—', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
