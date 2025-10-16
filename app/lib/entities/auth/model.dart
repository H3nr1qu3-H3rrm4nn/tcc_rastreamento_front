// Entidade Auth - Model
// Contratos mínimos sem implementação.

/// Credenciais de login (entrada do usuário)
class LoginCredentials {
	final String email;
	final String password;

	const LoginCredentials({required this.email, required this.password});
}

/// Resposta de autenticação do backend (tokens etc.)
class AuthTokens {
	final String accessToken;
	final String? refreshToken;

	const AuthTokens({required this.accessToken, this.refreshToken});
}

/// Estado simples de autenticação em memória
class AuthSession {
	final bool isAuthenticated;
	final AuthTokens? tokens;

	const AuthSession({required this.isAuthenticated, this.tokens});
}
