import 'package:flutter/material.dart';

import '../../../shared/utils/validators.dart' as v;
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'login_state.dart';

/// LoginView responsiva (somente UI). Sem integração ainda.
class LoginView extends StatefulWidget {
	const LoginView({super.key});

	@override
	State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
	final _emailCtrl = TextEditingController();
	final _pwdCtrl = TextEditingController();
	LoginState _state = const LoginState();

	String? _emailError;
	String? _pwdError;

	@override
	void dispose() {
		_emailCtrl.dispose();
		_pwdCtrl.dispose();
		super.dispose();
	}

	void _onEmailChanged(String value) {
		setState(() {
			_state = LoginState(
				email: value,
				password: _state.password,
				status: _state.status,
				message: _state.message,
			);
			_emailError = v.validateEmail(value);
		});
	}

	void _onPasswordChanged(String value) {
		setState(() {
			_state = LoginState(
				email: _state.email,
				password: value,
				status: _state.status,
				message: _state.message,
			);
			_pwdError = v.validatePassword(value);
		});
	}

	Future<void> _submit() async {
		// Validação básica
		final emailErr = v.validateEmail(_state.email);
		final pwdErr = v.validatePassword(_state.password);
		if (emailErr != null || pwdErr != null) {
			setState(() {
				_emailError = emailErr;
				_pwdError = pwdErr;
				_state = LoginState(
					email: _state.email,
					password: _state.password,
					status: LoginStatus.error,
					message: 'Preencha os campos corretamente',
				);
			});
			return;
		}

		setState(() {
			_state = LoginState(
				email: _state.email,
				password: _state.password,
				status: LoginStatus.loading,
			);
		});

		// Simulação local: aguarda 1s e marca sucesso (sem backend)
		await Future<void>.delayed(const Duration(seconds: 1));

		if (!mounted) return;
		setState(() {
			_state = LoginState(
				email: _state.email,
				password: _state.password,
				status: LoginStatus.success,
			);
		});

		// TODO: em breve vamos integrar com IAuthController e navegar para home
		// context.go(AppRoutes.home);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: LayoutBuilder(
				builder: (context, constraints) {
					final isWide = constraints.maxWidth >= 600;
					final content = _LoginCard(
						emailController: _emailCtrl,
						passwordController: _pwdCtrl,
						emailError: _emailError,
						passwordError: _pwdError,
						status: _state.status,
						onEmailChanged: _onEmailChanged,
						onPasswordChanged: _onPasswordChanged,
						onSubmit: _submit,
					);

					if (isWide) {
						return Center(
							child: ConstrainedBox(
								constraints: const BoxConstraints(maxWidth: 420),
								child: content,
							),
						);
					}
					return SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: content));
				},
			),
		);
	}
}

class _LoginCard extends StatelessWidget {
	final TextEditingController emailController;
	final TextEditingController passwordController;
	final String? emailError;
	final String? passwordError;
	final LoginStatus status;
	final ValueChanged<String> onEmailChanged;
	final ValueChanged<String> onPasswordChanged;
	final Future<void> Function() onSubmit;

	const _LoginCard({
		required this.emailController,
		required this.passwordController,
		required this.emailError,
		required this.passwordError,
		required this.status,
		required this.onEmailChanged,
		required this.onPasswordChanged,
		required this.onSubmit,
	});

	@override
	Widget build(BuildContext context) {
		final loading = status == LoginStatus.loading;
		final hasError = status == LoginStatus.error;

		return Card(
			elevation: 2,
			clipBehavior: Clip.antiAlias,
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Text(
							'Entrar',
							style: Theme.of(context).textTheme.headlineSmall,
							textAlign: TextAlign.center,
						),
						const SizedBox(height: 16),
						AppTextField(
							label: 'Email',
							controller: emailController,
							keyboardType: TextInputType.emailAddress,
							onChanged: onEmailChanged,
							errorText: emailError,
						),
						const SizedBox(height: 12),
						AppTextField(
							label: 'Senha',
							controller: passwordController,
							obscureText: true,
							onChanged: onPasswordChanged,
							errorText: passwordError,
						),
						const SizedBox(height: 16),
						AppButton(
							label: 'Entrar',
							loading: loading,
							onPressed: loading ? null : onSubmit,
						),
						if (hasError) ...[
							const SizedBox(height: 12),
							Text(
								'Verifique seus dados',
								style: TextStyle(color: Theme.of(context).colorScheme.error),
								textAlign: TextAlign.center,
							),
						],
					],
				),
			),
		);
	}
}
