// Controller da View de Login
// TODO: Gerenciar estado do formulário e chamar AuthController.

import 'login_state.dart';

abstract class ILoginController {
	LoginState get state;

	void onEmailChanged(String value);
	void onPasswordChanged(String value);
	Future<void> submit();
}
