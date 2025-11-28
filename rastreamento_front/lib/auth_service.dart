import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/location_point.dart';
import 'models/user_profile.dart';
import 'models/vehicle.dart';
import 'utils/app_logger.dart';

class AuthService {
  final String baseUrl = 'https://semianimated-brendon-superimportant.ngrok-free.dev';

  Map<String, String> _defaultHeaders({bool authenticated = false, String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    if (authenticated) {
      headers['Authorization'] = 'Bearer ${token ?? ''}';
    }

    return headers;
  }

  String get websocketBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    }
    if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'ws://');
    }
    return baseUrl;
  }

  Map<String, dynamic> _extractBody(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      AppLogger.warning('Body não pôde ser convertido em JSON: $rawBody');
    }
    return {};
  }

  Map<String, dynamic> _extractObject(Map<String, dynamic> body) {
    final object = _dataFromBody(body);
    if (object is Map<String, dynamic>) {
      return object;
    }
    return body;
  }

  bool _isSuccess(Map<String, dynamic> body) {
    final success = body['success'];
    if (success is bool) return success;
    if (success is String) {
      return success.toLowerCase() == 'true';
    }
    return false;
  }

  dynamic _dataFromBody(Map<String, dynamic> body) {
    dynamic data = body.containsKey('object') ? body['object'] : body['data'];
    if (data is String) {
      final trimmed = data.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          data = jsonDecode(trimmed);
        } catch (_) {
          // keep raw string if not parseable
        }
      }
    }
    return data ?? body;
  }

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/user/login');

    AppLogger.info('Tentando fazer login para: $email');

    try {
      final response = await http.post(
        url,
        headers: _defaultHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      AppLogger.debug('Resposta do login - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = _extractBody(response.body);
        if (!_isSuccess(body)) {
          AppLogger.warning('Login retornou falha lógica: ${body['message']}');
          return null;
        }

        final data = _dataFromBody(body);
        String? token;
        if (data is Map<String, dynamic>) {
          token = (data['access_token'] ?? data['token'] ?? data['jwt']) as String?;
        } else if (data is String) {
          token = data;
        }

        if (token != null && token.isNotEmpty) {
          AppLogger.info('Login realizado com sucesso');
          return token;
        }

        AppLogger.warning('Token não encontrado na resposta: ${response.body}');
        return null;
      }

      AppLogger.warning('Falha no login - Status: ${response.statusCode}, Body: ${response.body}');
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao conectar com o backend', e, stackTrace);
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      AppLogger.info('Token salvo com sucesso');
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao salvar token', e, stackTrace);
    }
  }

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

  Future<void> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('user_profile');
      AppLogger.info('Sessão removida - Logout realizado');
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao remover sessão', e, stackTrace);
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', jsonEncode(profile.toJson()));
      AppLogger.debug('Perfil salvo em cache');
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao salvar perfil', e, stackTrace);
    }
  }

  Future<UserProfile?> getSavedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_profile');
      if (raw == null) return null;
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao recuperar perfil salvo', e, stackTrace);
      return null;
    }
  }

  Future<http.Response?> authenticatedGet(String endpoint) async {
    final token = await getToken();

    if (token == null) {
      AppLogger.warning('Tentativa de GET autenticado sem token');
      return null;
    }

    final url = Uri.parse('$baseUrl$endpoint');
    AppLogger.info('GET autenticado: $endpoint');

    try {
      final response = await http.get(
        url,
        headers: _defaultHeaders(authenticated: true, token: token),
      );

      AppLogger.debug('Resposta GET - Status: ${response.statusCode}');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Erro na requisição GET autenticada', e, stackTrace);
      return null;
    }
  }

  Future<http.Response?> authenticatedPost(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();

    if (token == null) {
      AppLogger.warning('Tentativa de POST autenticado sem token');
      return null;
    }

    final url = Uri.parse('$baseUrl$endpoint');
    AppLogger.info('POST autenticado: $endpoint');

    try {
      final response = await http.post(
        url,
        headers: _defaultHeaders(authenticated: true, token: token),
        body: jsonEncode(body),
      );

      AppLogger.debug('Resposta POST - Status: ${response.statusCode}');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Erro na requisição POST autenticada', e, stackTrace);
      return null;
    }
  }

  Future<UserProfile?> fetchCurrentUser() async {
    final response = await authenticatedGet('/user/find_user_by_token');
    if (response == null) return null;

    if (response.statusCode == 200) {
      final body = _extractBody(response.body);
      if (!_isSuccess(body)) {
        AppLogger.warning('Backend indicou falha ao obter usuário: ${body['message']}');
        return null;
      }
      final profile = UserProfile.fromJson(_extractObject(body));
      await saveUserProfile(profile);
      return profile;
    }

    AppLogger.warning('Falha ao obter o usuário atual: ${response.statusCode}');
    return null;
  }

  Future<List<Vehicle>> fetchVehicles({required int userId}) async {
    final response = await authenticatedGet('/vehicle/list_by_user_id?user_id=$userId');
    if (response == null) return [];

    if (response.statusCode != 200) {
      AppLogger.warning('Falha ao listar veículos por usuário: ${response.statusCode}');
      return [];
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Backend indicou falha ao listar veículos: ${body['message']}');
      return [];
    }

    final data = _dataFromBody(body);
    final list = data is List ? data : const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(Vehicle.fromJson)
        .toList();
  }

  Future<List<Vehicle>> fetchOnlineVehicles() async {
    final response = await authenticatedGet('/vehicle/list_online');
    if (response == null) return [];

    if (response.statusCode != 200) {
      AppLogger.warning('Falha ao listar veículos online: ${response.statusCode}');
      return [];
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Backend indicou falha ao listar veículos online: ${body['message']}');
      return [];
    }

    final data = _dataFromBody(body);
    final list = data is List ? data : const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(Vehicle.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> fetchVehicleStats() async {
    final response = await authenticatedGet('/vehicle/stats');
    if (response == null || response.statusCode != 200) {
      AppLogger.warning('Não foi possível carregar estatísticas da frota');
      return {};
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Falha ao obter estatísticas: ${body['message']}');
      return {};
    }
    return _extractObject(body);
  }

  Future<List<LocationPoint>> fetchVehicleLocations(int vehicleId) async {
    final response = await authenticatedGet('/location/list_by_vehicle_id/$vehicleId');
    if (response == null || response.statusCode != 200) {
      return [];
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Falha ao obter histórico de localização: ${body['message']}');
      return [];
    }

    final data = _dataFromBody(body);
    final list = data is List ? data : const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(LocationPoint.fromJson)
        .toList();
  }

  Future<LocationPoint?> fetchLastVehicleLocation(int vehicleId) async {
    final response = await authenticatedGet('/location/last_by_vehicle_id/$vehicleId');
    if (response == null || response.statusCode != 200) {
      return null;
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Falha ao obter última localização: ${body['message']}');
      return null;
    }

    return LocationPoint.fromJson(_extractObject(body));
  }
}
