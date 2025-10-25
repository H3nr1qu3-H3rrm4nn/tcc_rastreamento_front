import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class AuthService {
  // Use o IP da sua máquina na rede local (descubra com ipconfig no Windows)
  final String baseUrl = 'https://semianimated-brendon-superimportant.ngrok-free.dev:8000';  // Substitua X pelo seu IP

  /// Realiza login e retorna o token JWT se bem-sucedido
  Future<String?> login(String email, String senha) async {
    final url = Uri.parse('$baseUrl/user/login');
    
    AppLogger.info('Tentando fazer login para: $email');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'senha': senha,  // Envie em texto plano via HTTPS
        }),
      );

      AppLogger.debug('Resposta do login - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final token = json['object']['access_token'];
        
        AppLogger.info('Login realizado com sucesso');
        return token;
      } else {
        AppLogger.warning(
          'Falha no login - Status: ${response.statusCode}, Body: ${response.body}'
        );
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao conectar com o backend', e, stackTrace);
      return null;
    }
  }

  /// Salva o token JWT no dispositivo
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      AppLogger.info('Token salvo com sucesso');
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao salvar token', e, stackTrace);
    }
  }

  /// Recupera o token JWT salvo
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token != null) {
        AppLogger.debug('Token recuperado do armazenamento');
      } else {
        AppLogger.warning('Nenhum token encontrado');
      }
      
      return token;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao recuperar token', e, stackTrace);
      return null;
    }
  }

  /// Remove o token JWT (logout)
  Future<void> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      AppLogger.info('Token removido - Logout realizado');
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao remover token', e, stackTrace);
    }
  }

  /// Faz uma requisição autenticada (GET)
  Future<http.Response?> authenticatedGet(String endpoint) async {
    final token = await getToken();
    
    if (token == null) {
      AppLogger.warning('Tentativa de requisição autenticada sem token');
      return null;
    }

    final url = Uri.parse('$baseUrl$endpoint');
    AppLogger.info('GET autenticado: $endpoint');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.debug('Resposta GET - Status: ${response.statusCode}');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Erro na requisição GET autenticada', e, stackTrace);
      return null;
    }
  }

  /// Faz uma requisição autenticada (POST)
  Future<http.Response?> authenticatedPost(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    
    if (token == null) {
      AppLogger.warning('Tentativa de requisição autenticada sem token');
      return null;
    }

    final url = Uri.parse('$baseUrl$endpoint');
    AppLogger.info('POST autenticado: $endpoint');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      AppLogger.debug('Resposta POST - Status: ${response.statusCode}');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Erro na requisição POST autenticada', e, stackTrace);
      return null;
    }
  }
}
