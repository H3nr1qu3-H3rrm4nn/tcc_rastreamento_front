import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://localhost:8000';  // altere para a URL do seu backend

  Future<String?> login(String email, String senha) async {
    final url = Uri.parse('$baseUrl/user/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // Ajuste caso seu backend retorne o token em outra chave
      return json['object']['access_token']; 
    } else {
      // Login falhou
      return null;
    }
  }
}
