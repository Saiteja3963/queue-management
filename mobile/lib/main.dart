import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QueueFlowApp());
}

class QueueFlowApp extends StatefulWidget {
  const QueueFlowApp({super.key});

  @override
  State<QueueFlowApp> createState() => _QueueFlowAppState();
}

class _QueueFlowAppState extends State<QueueFlowApp> {
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
        title: 'QueueFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}
