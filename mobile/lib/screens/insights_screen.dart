import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, required this.queueId});

  final int queueId;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  DashboardStats? _stats;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final stats = await context.read<ApiService>().insights(widget.queueId);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final maxHour = stats == null
        ? 1
        : stats.hourlyCompleted
            .map((e) => (e['count'] as num).toInt())
            .fold<int>(1, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text(stats?.queueName ?? 'Insights')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Live management dashboard',
              style: TextStyle(color: AppTheme.muted),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (stats != null) ...[
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.55,
                children: [
                  StatCard(label: 'Waiting', value: '${stats.currentlyWaiting}'),
                  StatCard(
                    label: 'Serving / called',
                    value: '${stats.currentlyServing + stats.currentlyCalled}',
                  ),
                  StatCard(label: 'Completed today', value: '${stats.completedToday}'),
                  StatCard(
                    label: 'Est. wait (new)',
                    value: '${stats.estimatedWaitForNew}m',
                  ),
                  StatCard(label: 'Avg wait', value: '${stats.avgWaitMinutes}m'),
                  StatCard(label: 'Avg service', value: '${stats.avgServiceMinutes}m'),
                  StatCard(
                    label: 'Throughput / hr',
                    value: '${stats.throughputPerHour}',
                  ),
                  StatCard(
                    label: 'Peak hour (UTC)',
                    value: stats.peakHour == null ? 'n/a' : '${stats.peakHour}:00',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Completions by hour',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
                  child: SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: stats.hourlyCompleted.map((h) {
                        final count = (h['count'] as num).toInt();
                        final height = 8 + (count / maxHour) * 100;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Tooltip(
                              message: '${h['hour']}:00 — $count',
                              child: Container(
                                height: height,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [AppTheme.accent, Color(0xFF14B8A6)],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Status breakdown',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...stats.statusBreakdown.entries.map(
                (e) => Card(
                  child: ListTile(
                    title: Text(e.key.replaceAll('_', ' ')),
                    trailing: Text(
                      '${e.value}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recent tickets',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...stats.recentTickets.map(
                (t) => Card(
                  child: ListTile(
                    title: Text('${t.displayCode} · ${t.customerName}'),
                    subtitle: Text(t.createdAt),
                    trailing: StatusBadge(t.status),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
