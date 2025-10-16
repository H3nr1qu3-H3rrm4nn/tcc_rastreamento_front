String? validateEmail(String value) {
	if (value.isEmpty) return 'Informe o email';
	final emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
	if (!emailReg.hasMatch(value)) return 'Email inválido';
	return null;
}

String? validatePassword(String value) {
	if (value.isEmpty) return 'Informe a senha';
	if (value.length < 6) return 'Senha muito curta';
	return null;
}
