import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'insights_screen.dart';

class QueueAdminScreen extends StatefulWidget {
  const QueueAdminScreen({super.key, required this.queueId});

  final int queueId;

  @override
  State<QueueAdminScreen> createState() => _QueueAdminScreenState();
}

class _QueueAdminScreenState extends State<QueueAdminScreen> {
  QueueInfo? _queue;
  List<Ticket> _tickets = [];
  bool _busy = false;
  String? _error;
  String? _message;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final api = context.read<ApiService>();
      final queue = await api.getQueue(widget.queueId);
      final tickets = await api.listTickets(
        widget.queueId,
        statusFilter: 'waiting,called,serving',
      );
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _tickets = tickets;
        if (!silent) _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) setState(() => _error = e.toString());
    }
  }

  Future<void> _callNext() async {
    setState(() {
      _busy = true;
      _message = null;
      _error = null;
    });
    try {
      final ticket = await context.read<ApiService>().callNext(widget.queueId);
      setState(() => _message = 'Called ${ticket.displayCode} — ${ticket.customerName}');
      await _load(silent: true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(int ticketId, String status) async {
    setState(() => _busy = true);
    try {
      await context.read<ApiService>().updateTicketStatus(ticketId, status);
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleOpen() async {
    if (_queue == null) return;
    setState(() => _busy = true);
    try {
      final updated = await context.read<ApiService>().updateQueue(
            widget.queueId,
            {'is_open': !_queue!.isOpen},
          );
      setState(() => _queue = updated);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _tickets.where((t) => t.status == 'waiting').toList();
    final active = _tickets
        .where((t) => t.status == 'called' || t.status == 'serving')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_queue?.name ?? 'Queue'),
        actions: [
          IconButton(
            tooltip: 'Insights',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InsightsScreen(queueId: widget.queueId),
              ),
            ),
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${_queue?.organizationName ?? ''} · Staff console',
              style: const TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_message!, style: const TextStyle(color: Color(0xFF047857))),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _callNext,
                    child: const Text('Call next'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _toggleOpen,
                  child: Text(_queue?.isOpen == true ? 'Close' : 'Open'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: StatCard(label: 'Waiting', value: '${waiting.length}')),
                const SizedBox(width: 8),
                Expanded(child: StatCard(label: 'Active', value: '${active.length}')),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Done',
                    value: '${_queue?.completedToday ?? 0}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Active', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            if (active.isEmpty)
              const Card(child: ListTile(title: Text('No tickets being served'))),
            ...active.map((t) {
              return Card(
                child: ListTile(
                  title: Text('${t.displayCode} · ${t.customerName}'),
                  subtitle: StatusBadge(t.status),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      if (t.status == 'called')
                        IconButton(
                          tooltip: 'Start',
                          onPressed: _busy ? null : () => _setStatus(t.id, 'serving'),
                          icon: const Icon(Icons.play_arrow),
                        ),
                      IconButton(
                        tooltip: 'Complete',
                        onPressed: _busy ? null : () => _setStatus(t.id, 'completed'),
                        icon: const Icon(Icons.check_circle_outline),
                      ),
                      IconButton(
                        tooltip: 'Skip',
                        onPressed: _busy ? null : () => _setStatus(t.id, 'skipped'),
                        icon: const Icon(Icons.skip_next),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text('Waiting line', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            if (waiting.isEmpty)
              const Card(child: ListTile(title: Text('Queue is empty'))),
            ...waiting.map((t) {
              return Card(
                child: ListTile(
                  title: Text('#${t.position} · ${t.displayCode}'),
                  subtitle: Text(t.customerName),
                  trailing: IconButton(
                    tooltip: 'Cancel',
                    onPressed: _busy ? null : () => _setStatus(t.id, 'cancelled'),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
