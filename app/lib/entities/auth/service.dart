// Entidade Auth - Service
// TODO: Regras de negócio de autenticação; persistência de tokens (secure storage/web storage).

import 'model.dart';

/// Contrato do serviço de autenticação
abstract class IAuthService {
	/// Efetua login, aciona o repositório e persiste tokens
	Future<AuthSession> login(LoginCredentials credentials);

	/// Usa refresh token para renovar o access token e atualizar a sessão
	Future<AuthSession> refresh();

	/// Faz logout limpando tokens e estado
	Future<void> logout();

	/// Obtém sessão atual (cache/memória)
	Future<AuthSession> session();
}
