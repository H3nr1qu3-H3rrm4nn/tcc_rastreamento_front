// Estado da View de Login
// Contratos mínimos sem implementação.

enum LoginStatus { idle, loading, success, error }

class LoginState {
	final String email;
	final String password;
	final LoginStatus status;
	final String? message;

	const LoginState({
		this.email = '',
		this.password = '',
		this.status = LoginStatus.idle,
		this.message,
	});
}
