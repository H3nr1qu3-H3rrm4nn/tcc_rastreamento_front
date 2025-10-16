// Entidade Auth - Repository
// TODO: Implementar chamando endpoints FastAPI (/auth/login, /auth/refresh) via shared/network.

import 'model.dart';

/// Contrato do repositório de autenticação
abstract class IAuthRepository {
	/// Chama POST /auth/login com email/senha
	Future<AuthTokens> login(LoginCredentials credentials);

	/// Chama POST /auth/refresh com refresh_token
	Future<AuthTokens> refresh(String refreshToken);
}
