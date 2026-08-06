import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:queueflow_mobile/models/models.dart';
import 'package:queueflow_mobile/providers/auth_provider.dart';
import 'package:queueflow_mobile/screens/home_screen.dart';
import 'package:queueflow_mobile/services/api_service.dart';
import 'package:queueflow_mobile/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Ticket model parses API JSON', () {
    final ticket = Ticket.fromJson({
      'id': 1,
      'queue_id': 2,
      'number': 7,
      'display_code': 'G007',
      'customer_name': 'Ava',
      'customer_phone': '555',
      'status': 'waiting',
      'created_at': '2026-08-06T00:00:00',
      'called_at': null,
      'started_at': null,
      'completed_at': null,
      'notes': '',
      'position': 3,
      'estimated_wait_minutes': 16,
    });
    expect(ticket.displayCode, 'G007');
    expect(ticket.position, 3);
  });

  testWidgets('Home screen shows QueueFlow brand', (tester) async {
    final api = ApiService(baseUrl: 'http://127.0.0.1:8000');
    final auth = AuthProvider(api);
    auth.loading = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HomeScreen(),
        ),
      ),
    );

    expect(find.text('QueueFlow'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Try public queue'), findsOneWidget);
  });
}
