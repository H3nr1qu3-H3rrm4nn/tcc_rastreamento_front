// TODO: Registrar dependências (services, repositories) aqui com get_it ou outro service locator.

// ignore_for_file: unused_import

import 'package:get_it/get_it.dart';

import '../../entities/auth/repository.dart';
import '../../entities/auth/service.dart';
import '../../entities/auth/controller.dart';

final GetIt di = GetIt.instance;

/// Chame este método no main() antes de rodar o app
Future<void> setupDependencies() async {
	// TODO: Registrar http client, storage, etc.
	// di.registerLazySingleton<HttpClient>(...);

	// Auth layer (contratos, sem implementação por enquanto)
	// di.registerLazySingleton<IAuthRepository>(() => AuthRepositoryImpl(...));
	// di.registerLazySingleton<IAuthService>(() => AuthServiceImpl(di()));
	// di.registerLazySingleton<IAuthController>(() => AuthControllerImpl(di()));
}
