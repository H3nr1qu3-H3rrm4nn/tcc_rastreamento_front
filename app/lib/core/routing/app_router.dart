// TODO: Definir rotas nomeadas e navegação (GoRouter ou Navigator 2.0) aqui.

// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../entities/auth/views/login_view.dart';

/// Rotas nomeadas base
abstract class AppRoutes {
	static const login = '/login';
	static const home = '/';
}

/// Instância do roteador (a ser inicializada no main)
GoRouter createRouter() {
	// TODO: Adicionar rotas e guards (ex.: require auth)
	return GoRouter(
		initialLocation: AppRoutes.login,
		routes: <RouteBase>[
				GoRoute(
					path: AppRoutes.login,
					builder: (_, __) => const LoginView(),
				),
			GoRoute(
				path: AppRoutes.home,
				builder: (_, __) => const _HomePlaceholder(),
			),
		],
	);
}

class _HomePlaceholder extends StatelessWidget {
	const _HomePlaceholder({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Home (placeholder)')),
			body: const Center(child: Text('TODO: Home para Android/Web')),
		);
	}
}
