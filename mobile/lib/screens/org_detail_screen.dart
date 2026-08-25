import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'public_queue_screen.dart';
import 'queue_admin_screen.dart';
import 'insights_screen.dart';

class OrgDetailScreen extends StatefulWidget {
  const OrgDetailScreen({super.key, required this.orgId});

  final int orgId;

  @override
  State<OrgDetailScreen> createState() => _OrgDetailScreenState();
}

class _OrgDetailScreenState extends State<OrgDetailScreen> {
  Organization? _org;
  List<QueueInfo> _queues = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final org = await api.getOrg(widget.orgId);
      final queues = await api.listQueues(widget.orgId);
      if (!mounted) return;
      setState(() {
        _org = org;
        _queues = queues;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createQueue() async {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final prefixCtrl = TextEditingController(text: 'A');
    final avgCtrl = TextEditingController(text: '5');
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New queue'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Queue name'),
                onChanged: (v) {
                  slugCtrl.text = v
                      .toLowerCase()
                      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                      .replaceAll(RegExp(r'^-|-$'), '');
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: slugCtrl,
                decoration: const InputDecoration(labelText: 'Slug'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: prefixCtrl,
                decoration: const InputDecoration(labelText: 'Ticket prefix'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: avgCtrl,
                decoration: const InputDecoration(labelText: 'Avg service minutes'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ApiService>().createQueue(
            orgId: widget.orgId,
            name: nameCtrl.text.trim(),
            slug: slugCtrl.text.trim(),
            description: descCtrl.text.trim(),
            ticketPrefix: prefixCtrl.text.trim().isEmpty ? 'A' : prefixCtrl.text.trim(),
            avgServiceMinutes: int.tryParse(avgCtrl.text) ?? 5,
          );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_org?.name ?? 'Organization')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createQueue,
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New queue'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_org != null) ...[
                    Text(_org!.description, style: const TextStyle(color: AppTheme.muted)),
                    const SizedBox(height: 8),
                    Text('/${_org!.slug}', style: const TextStyle(color: AppTheme.muted)),
                    const SizedBox(height: 16),
                  ],
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  if (_queues.isEmpty)
                    const Card(
                      child: ListTile(title: Text('No queues yet')),
                    ),
                  ..._queues.map((q) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    q.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                StatusBadge(q.isOpen ? 'Open' : 'Closed'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Waiting ${q.waitingCount} · Serving ${q.servingCount} · Done ${q.completedToday}',
                              style: const TextStyle(color: AppTheme.muted),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QueueAdminScreen(queueId: q.id),
                                    ),
                                  ),
                                  child: const Text('Manage'),
                                ),
                                OutlinedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InsightsScreen(queueId: q.id),
                                    ),
                                  ),
                                  child: const Text('Insights'),
                                ),
                                OutlinedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PublicQueueScreen(
                                        orgSlug: _org!.slug,
                                        queueSlug: q.slug,
                                      ),
                                    ),
                                  ),
                                  child: const Text('User view'),
                                ),
                              ],
                            ),
                          ],
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
