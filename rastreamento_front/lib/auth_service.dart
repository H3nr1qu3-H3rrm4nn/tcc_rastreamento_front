import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/location_point.dart';
import 'models/user_profile.dart';
import 'models/vehicle.dart';
import 'utils/app_logger.dart';

class AuthService {
  AuthService({String? overrideBaseUrl}) : baseUrl = overrideBaseUrl ?? _envBaseUrl;

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://urbantrack-back.onrender.com',
  );

  final String baseUrl;

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

  Future<http.Response?> authenticatedPut(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();

    if (token == null) {
      AppLogger.warning('Tentativa de PUT autenticado sem token');
      return null;
    }

    final url = Uri.parse('$baseUrl$endpoint');
    AppLogger.info('PUT autenticado: $endpoint');

    try {
      final response = await http.put(
        url,
        headers: _defaultHeaders(authenticated: true, token: token),
        body: jsonEncode(body),
      );

      AppLogger.debug('Resposta PUT - Status: ${response.statusCode}');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Erro na requisição PUT autenticada', e, stackTrace);
      return null;
    }
  }

  Future<http.Response?> authenticatedDelete(String endpoint) async {
    final token = await getToken();

    if (token == null) {
      AppLogger.warning('Tentativa de DELETE autenticado sem token');
      return null;
    }

    final url = Uri.parse('$baseUrl$endpoint');
    AppLogger.info('DELETE autenticado: $endpoint');

    try {
      final response = await http.delete(
        url,
        headers: _defaultHeaders(authenticated: true, token: token),
      );

      AppLogger.debug('Resposta DELETE - Status: ${response.statusCode}');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Erro na requisição DELETE autenticada', e, stackTrace);
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

  Future<List<Vehicle>> fetchAllVehicles() async {
    final response = await authenticatedPost('/vehicle/all', {});
    if (response == null) return [];

    if (response.statusCode != 200) {
      AppLogger.warning('Falha ao listar todos os veículos: ${response.statusCode}');
      return [];
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Backend indicou falha ao listar todos os veículos: ${body['message']}');
      return [];
    }

    final data = _dataFromBody(body);
    final list = data is List ? data : const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(Vehicle.fromJson)
        .toList();
  }

  Future<Vehicle?> createVehicle({
    required String name,
    required String plate,
    required String type,
    required int userId,
    bool? isOnline,
    String? lastLocation,
  }) async {
    final response = await authenticatedPost('/vehicle/save', {
      'name': name,
      'plate': plate,
      'type': type,
      'user_id': userId,
      if (isOnline != null) 'is_online': isOnline,
      if (lastLocation != null) 'last_location': lastLocation,
    });

    if (response == null || response.statusCode != 200) {
      AppLogger.warning('Falha ao criar veículo: ${response?.statusCode}');
      return null;
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Falha lógica ao criar veículo: ${body['message']}');
      return null;
    }

    final data = _dataFromBody(body);
    if (data is Map<String, dynamic>) {
      return Vehicle.fromJson(data);
    }
    return null;
  }

  Future<Vehicle?> updateVehicle({
    required int id,
    String? name,
    String? plate,
    String? type,
    int? userId,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (plate != null) body['plate'] = plate;
    if (type != null) body['type'] = type;
    if (userId != null) body['user_id'] = userId;

    if (body.isEmpty) {
      AppLogger.warning('Nenhum campo fornecido para atualizar o veículo $id');
      return null;
    }

    final response = await authenticatedPut('/vehicle/update_by_id/$id', body);

    if (response == null || response.statusCode != 200) {
      AppLogger.warning('Falha ao atualizar veículo: ${response?.statusCode}');
      return null;
    }

    final responseBody = _extractBody(response.body);
    if (!_isSuccess(responseBody)) {
      AppLogger.warning('Falha lógica ao atualizar veículo: ${responseBody['message']}');
      return null;
    }

    final data = _dataFromBody(responseBody);
    if (data is Map<String, dynamic>) {
      return Vehicle.fromJson(data);
    }
    return null;
  }

  Future<bool> deleteVehicle(int id) async {
    final response = await authenticatedDelete('/vehicle/delete_by_id/$id');
    if (response == null) return false;

    if (response.statusCode != 200) {
      AppLogger.warning('Falha ao excluir veículo: ${response.statusCode}');
      return false;
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Falha lógica ao excluir veículo: ${body['message']}');
      return false;
    }

    return true;
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

  Future<List<UserProfile>> fetchAllUsers() async {
    final response = await authenticatedPost('/user/all', {});
    if (response == null || response.statusCode != 200) {
      AppLogger.warning('Não foi possível carregar a lista de usuários');
      return [];
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Falha ao obter lista de usuários: ${body['message']}');
      return [];
    }

    final data = _dataFromBody(body);
    final list = data is List ? data : const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(UserProfile.fromJson)
        .toList();
  }

  Future<UserProfile?> createUser({
    required String email,
    required String password,
    String? name,
    bool isAdmin = false,
    String? imageSrc,
  }) async {
    final response = await authenticatedPost('/user/save', {
      'email': email,
      'password': password,
      if (name != null) 'name': name,
      'is_admin': isAdmin,
      if (imageSrc != null) 'image_src': imageSrc,
    });

    if (response == null || response.statusCode != 200) {
      AppLogger.warning('Falha ao criar usuário: ${response?.statusCode}');
      return null;
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Falha lógica ao criar usuário: ${body['message']}');
      return null;
    }

    final data = _dataFromBody(body);
    if (data is Map<String, dynamic>) {
      return UserProfile.fromJson(data);
    }

    AppLogger.warning('Resposta inesperada ao criar usuário: ${response.body}');
    return null;
  }

  Future<UserProfile?> updateUser({
    required int id,
    String? email,
    String? password,
    String? name,
    bool? isAdmin,
    String? imageSrc,
  }) async {
    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (name != null) body['name'] = name;
    if (isAdmin != null) body['is_admin'] = isAdmin;
    if (imageSrc != null) body['image_src'] = imageSrc;

    if (body.isEmpty) {
      AppLogger.warning('Nenhum campo fornecido para atualizar o usuário $id');
      return null;
    }

    final response = await authenticatedPut('/user/update_by_id/$id', body);

    if (response == null || response.statusCode != 200) {
      AppLogger.warning('Falha ao atualizar usuário: ${response?.statusCode}');
      return null;
    }

    final responseBody = _extractBody(response.body);
    if (!_isSuccess(responseBody)) {
      AppLogger.warning('Falha lógica ao atualizar usuário: ${responseBody['message']}');
      return null;
    }

    final data = _dataFromBody(responseBody);
    if (data is Map<String, dynamic>) {
      return UserProfile.fromJson(data);
    }

    AppLogger.warning('Resposta inesperada ao atualizar usuário: ${response.body}');
    return null;
  }

  Future<bool> deleteUser(int id) async {
    final response = await authenticatedDelete('/user/delete_by_id/$id');
    if (response == null) {
      return false;
    }

    if (response.statusCode != 200) {
      AppLogger.warning('Falha ao excluir usuário: ${response.statusCode}');
      return false;
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Falha lógica ao excluir usuário: ${body['message']}');
      return false;
    }

    return true;
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

  /// Fetch locations for [vehicleId] between [start] and [end]. Timestamps are
  /// sent no timezone, matching how values are persisted na base (GMT-03).
  Future<List<LocationPoint>> fetchVehicleLocationsInRange(
    int vehicleId,
    DateTime start,
    DateTime end,
  ) async {
    String formatIso(DateTime dt) {
      // Ajusta manualmente para GMT-03, já que o backend interpreta dessa forma.
      final offset = const Duration(hours: 3);
      final adjusted = dt.subtract(offset);
      final withoutMs = DateTime(
        adjusted.year,
        adjusted.month,
        adjusted.day,
        adjusted.hour,
        adjusted.minute,
        adjusted.second,
      );
      final iso = withoutMs.toIso8601String();
      final tIndex = iso.indexOf('T');
      if (tIndex == -1) return iso;
      final timePart = iso.substring(tIndex + 1);
      final dotIndex = timePart.indexOf('.');
      final zIndex = timePart.indexOf('Z');
      final endIndex = dotIndex != -1
          ? tIndex + 1 + dotIndex
          : (zIndex != -1 ? tIndex + 1 + zIndex : iso.length);
      return iso.substring(0, endIndex);
    }

    final startStr = Uri.encodeComponent(formatIso(start));
    final endStr = Uri.encodeComponent(formatIso(end));
    final response = await authenticatedGet(
      '/location/list_by_vehicle_and_range/$vehicleId/$startStr/$endStr',
    );
    if (response == null || response.statusCode != 200) {
      return [];
    }

    final body = _extractBody(response.body);
    if (!_isSuccess(body)) {
      AppLogger.warning('Falha ao obter histórico por período: ${body['message']}');
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

