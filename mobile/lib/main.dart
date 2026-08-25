import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QMeApp());
}

class QMeApp extends StatefulWidget {
  const QMeApp({super.key});

  @override
  State<QMeApp> createState() => _QMeAppState();
}

class _QMeAppState extends State<QMeApp> {
  late final ApiService _api;
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _auth = AuthProvider(_api);
    _auth.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _api),
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
      ],
      child: MaterialApp(
        title: "Q'Me",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.loading) {
              return Scaffold(
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                    ),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              );
            }
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}

/// Back-compat alias for existing tests/imports.
typedef QueueFlowApp = QMeApp;
