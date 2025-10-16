import 'package:flutter/material.dart';

import 'core/di/di.dart';
import 'core/routing/app_router.dart';

// Entrypoint mínimo: conecta DI e Router
// Próximos passos: adicionar rotas (login) e views reais.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TCC Rastreamento',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: createRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
