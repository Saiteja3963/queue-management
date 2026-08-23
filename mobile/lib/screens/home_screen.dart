import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'public_queue_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD9F2EF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Multi-business queue platform',
                style: TextStyle(
                  color: AppTheme.accentDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'QueueFlow',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppTheme.accentDark,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage queues for any business from your phone. Staff run the console; customers join and track their ticket.',
              style: TextStyle(color: AppTheme.muted, fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 24),
            if (auth.user != null) ...[
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                ),
                child: const Text('Open dashboard'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Sign in'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text('Create account'),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PublicQueueScreen(
                    orgSlug: 'city-care',
                    queueSlug: 'general-practice',
                  ),
                ),
              ),
              child: const Text('Try public queue'),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Demo login',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'admin@demo.com / password123',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _FeatureCard(
              title: 'Admin & staff',
              body: 'Call next, serve, complete, and close queues from the console.',
            ),
            _FeatureCard(
              title: 'Customer join',
              body: 'Take a number without an account and watch live position updates.',
            ),
            _FeatureCard(
              title: 'Queue insights',
              body: 'Waiting counts, average wait, throughput, and peak hour.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(body),
        ),
      ),
    );
  }
}
