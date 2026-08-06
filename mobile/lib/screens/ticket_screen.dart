import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  Ticket? _ticket;
  QueueInfo? _queue;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiService>();
      final ticket = await api.getTicket(widget.ticketId);
      final queue = await api.getQueue(ticket.queueId);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _queue = queue;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    return Scaffold(
      appBar: AppBar(title: const Text('Your ticket')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ticket == null
                  ? (_error != null
                      ? Text(_error!, style: const TextStyle(color: Colors.red))
                      : const CircularProgressIndicator())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_queue?.organizationName ?? ''} · ${_queue?.name ?? ''}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ticket.displayCode,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: AppTheme.accentDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StatusBadge(ticket.status),
                        const SizedBox(height: 12),
                        Text(
                          ticket.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (ticket.status == 'waiting') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Position ${ticket.position} · Est. wait ${ticket.estimatedWaitMinutes} min',
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                        ],
                        if (ticket.status == 'called') ...[
                          const SizedBox(height: 12),
                          const Text(
                            'You have been called. Please proceed.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (ticket.status == 'serving') ...[
                          const SizedBox(height: 12),
                          const Text(
                            'You are being served now.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
