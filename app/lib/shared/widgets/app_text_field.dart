import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
	final String label;
	final TextEditingController? controller;
	final ValueChanged<String>? onChanged;
	final TextInputType keyboardType;
	final bool obscureText;
	final String? errorText;

	const AppTextField({
		super.key,
		required this.label,
		this.controller,
		this.onChanged,
		this.keyboardType = TextInputType.text,
		this.obscureText = false,
		this.errorText,
	});

	@override
	Widget build(BuildContext context) {
		return TextField(
			controller: controller,
			onChanged: onChanged,
			keyboardType: keyboardType,
			obscureText: obscureText,
			decoration: InputDecoration(
				labelText: label,
				errorText: errorText,
				border: const OutlineInputBorder(),
			),
		);
	}
}
