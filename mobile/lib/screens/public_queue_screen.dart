import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'ticket_screen.dart';

class PublicQueueScreen extends StatefulWidget {
  const PublicQueueScreen({
    super.key,
    required this.orgSlug,
    required this.queueSlug,
  });

  final String orgSlug;
  final String queueSlug;

  @override
  State<PublicQueueScreen> createState() => _PublicQueueScreenState();
}

class _PublicQueueScreenState extends State<PublicQueueScreen> {
  QueueInfo? _queue;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final queue = await context.read<ApiService>().getPublicQueue(
            widget.orgSlug,
            widget.queueSlug,
          );
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ticket = await context.read<ApiService>().joinQueue(
            orgSlug: widget.orgSlug,
            queueSlug: widget.queueSlug,
            customerName: _name.text.trim(),
            customerPhone: _phone.text.trim(),
          );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TicketScreen(ticketId: ticket.id)),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue;
    return Scaffold(
      appBar: AppBar(title: Text(queue?.name ?? 'Join queue')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            queue?.organizationName ?? 'Queue',
            style: const TextStyle(
              color: AppTheme.accentDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            queue?.description ?? 'Take a number and track your place in line.',
            style: const TextStyle(color: AppTheme.muted, fontSize: 15),
          ),
          const SizedBox(height: 16),
          if (queue != null)
            Row(
              children: [
                Expanded(child: StatCard(label: 'Waiting', value: '${queue.waitingCount}')),
                const SizedBox(width: 8),
                Expanded(child: StatCard(label: 'Serving', value: '${queue.servingCount}')),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Est. wait',
                    value: '${queue.estimatedWaitMinutes}m',
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (queue != null) StatusBadge(queue.isOpen ? 'Open' : 'Closed'),
          const SizedBox(height: 20),
          const Text(
            'Get your number',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Your name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)'),
            keyboardType: TextInputType.phone,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_busy || queue?.isOpen != true) ? null : _join,
            child: Text(_busy ? 'Joining…' : 'Join queue'),
          ),
        ],
      ),
    );
  }
}
