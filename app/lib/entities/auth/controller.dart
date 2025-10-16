// Entidade Auth - Controller
// TODO: Lidar com ações de login/logout/refresh para a UI.

import 'model.dart';

/// Contrato do controller de autenticação
abstract class IAuthController {
	/// Estado atual da sessão
	Future<AuthSession> getSession();

	/// Login com email e senha (retorna sessão)
	Future<AuthSession> login(String email, String password);

	/// Logout (limpa sessão)
	Future<void> logout();

	/// Força refresh do token
	Future<AuthSession> refresh();
}
