import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth_service.dart';
import '../models/vehicle.dart';
import '../utils/app_logger.dart';

enum _TrackingStatus {
  idle,
  connecting,
  streaming,
  reconnecting,
  error,
}

class TrackingScreen extends StatefulWidget {
  final String userName;
  final int? userId;

  const TrackingScreen({
    super.key,
    required this.userName,
    this.userId,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isTracking = false;
  String _vehicleName = 'Carregando veículo...';
  int? _vehicleId;

  String _statusMessage = 'Envio de localização desativado.';
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _loadingVehicles = false;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription? _socketSubscription;
  WebSocketChannel? _channel;
  _TrackingStatus _trackingStatus = _TrackingStatus.idle;
  Timer? _reconnectTimer;
  bool _userRequestedStop = false;
  String? _authToken;

  final AuthService _authService = AuthService();
  late final Uri _socketUri;

  @override
  void initState() {
    super.initState();
    _socketUri = Uri.parse('${_authService.websocketBaseUrl}/location/websocket');
    _loadVehicles();
  }

  Future<void> _ensurePositionStream() async {
    if (_positionSubscription != null) {
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _sendLocation(position);
      },
      onError: (error) {
        AppLogger.error('Erro no stream de localização', error);
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Erro ao obter localização: $error';
          _trackingStatus = _TrackingStatus.error;
        });
      },
    );
  }

  Future<void> _initializeSocket({required bool isReconnect}) async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final token = _authToken ?? await _authService.getToken();
    if (token == null) {
      await _stopTracking(
        statusMessage: 'Token não encontrado. Faça login novamente.',
      );
      return;
    }
    _authToken = token;

    try {
      await _socketSubscription?.cancel();
    } catch (_) {}
    _socketSubscription = null;

    if (_channel != null) {
      try {
        await _channel?.sink.close();
      } catch (_) {}
    }
    _channel = null;

    if (!mounted || _userRequestedStop) {
      return;
    }

    setState(() {
      _trackingStatus =
          isReconnect ? _TrackingStatus.reconnecting : _TrackingStatus.connecting;
      _statusMessage = isReconnect
          ? 'Tentando reconectar...'
          : 'Estabelecendo conexão e preparando o envio...';
    });

    try {
      final channel = IOWebSocketChannel.connect(
        _socketUri,
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      _channel = channel;

      _socketSubscription = channel.stream.listen(
        _handleSocketEvent,
        onDone: () {
          AppLogger.warning('WebSocket encerrado pelo servidor');
          _handleConnectionLoss('Conexão encerrada pelo servidor.');
        },
        onError: (error, stack) {
          AppLogger.error('Erro no canal WebSocket', error, stack);
          _handleConnectionLoss('Erro na conexão: $error');
        },
        cancelOnError: true,
      );

      channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));

      if (!mounted || _userRequestedStop) {
        return;
      }

      setState(() {
        _trackingStatus = _TrackingStatus.streaming;
        _statusMessage = 'Enviando localização para a plataforma web...';
      });

      if (isReconnect) {
        AppLogger.info('Reconexão estabelecida para veículo $_vehicleId');
      } else {
        AppLogger.info('Rastreamento iniciado para veículo $_vehicleId');
      }
    } catch (e, stack) {
      AppLogger.error('Erro ao abrir WebSocket', e, stack);
      _handleConnectionLoss('Erro ao conectar: $e');
    }
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _loadingVehicles = true;
      _vehicleName = 'Carregando veículos...';
      _statusMessage = 'Localizando veículos vinculados.';
      _vehicles = [];
      _selectedVehicle = null;
      _vehicleId = null;
    });

    try {
      final cachedProfile = await _authService.getSavedUserProfile();
      final userId = widget.userId ?? cachedProfile?.id;

      if (userId == null) {
        setState(() {
          _vehicleName = 'Usuário sem identificação';
          _statusMessage = 'Não foi possível identificar o usuário.';
          _loadingVehicles = false;
        });
        return;
      }

      final vehicles = await _authService.fetchVehicles(userId: userId);
      if (!mounted) return;
      if (vehicles.isEmpty) {
        setState(() {
          _vehicleName = 'Nenhum veículo';
          _vehicleId = null;
          _statusMessage = 'Nenhum veículo vinculado foi encontrado.';
          _vehicles = [];
          _selectedVehicle = null;
          _loadingVehicles = false;
        });
        return;
      }

      final primaryVehicle = vehicles.first;
      setState(() {
        _vehicles = vehicles;
        _selectedVehicle = primaryVehicle;
        _vehicleName = primaryVehicle.displayName;
        _vehicleId = primaryVehicle.id;
        _statusMessage = 'Pronto para iniciar o rastreamento.';
        _loadingVehicles = false;
      });
    } catch (e, stack) {
      AppLogger.error('Erro ao carregar veículo', e, stack);
      setState(() {
        _vehicleName = 'Erro ao carregar veículo';
        _statusMessage = 'Erro ao buscar veículo vinculado.';
        _loadingVehicles = false;
      });
    }
  }

  void _handleVehicleSelection(int? vehicleId) {
    if (vehicleId == null) return;
    Vehicle? selected;
    for (final vehicle in _vehicles) {
      if (vehicle.id == vehicleId) {
        selected = vehicle;
        break;
      }
    }
    if (selected == null) return;

    final vehicle = selected;

    setState(() {
      _selectedVehicle = vehicle;
      _vehicleId = vehicle.id;
      _vehicleName = vehicle.displayName;
      if (!_isTracking) {
        _statusMessage = 'Pronto para iniciar o rastreamento.';
      }
    });
  }

  Future<bool> _checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = 'Ative o serviço de localização do dispositivo.';
      });
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        _statusMessage = 'Permissão de localização negada.';
      });
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage =
            'Permissão de localização permanentemente negada. Vá nas configurações do sistema para permitir.';
      });
      return false;
    }

    return true;
  }

  Future<void> _startTracking() async {
    if (_isTracking) {
      return;
    }

    if (_vehicleId == null) {
      setState(() {
        _statusMessage = 'Nenhum veículo vinculado ao rastreador.';
        _trackingStatus = _TrackingStatus.error;
      });
      return;
    }

    setState(() {
      _isTracking = true;
      _userRequestedStop = false;
      _trackingStatus = _TrackingStatus.connecting;
      _statusMessage = 'Verificando permissões de localização.';
    });

    final hasPermission = await _checkAndRequestLocationPermission();
    if (!hasPermission) {
      if (!mounted) return;
      setState(() {
        _isTracking = false;
        _trackingStatus = _TrackingStatus.idle;
        _statusMessage = 'Permissão necessária para iniciar o rastreamento.';
      });
      return;
    }

    try {
      final token = await _authService.getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _isTracking = false;
          _trackingStatus = _TrackingStatus.idle;
          _statusMessage = 'Token não encontrado. Faça login novamente.';
        });
        return;
      }

      _authToken = token;
      await _ensurePositionStream();
      if (!mounted) return;

      setState(() {
        _trackingStatus = _TrackingStatus.connecting;
        _statusMessage = 'Estabelecendo conexão e preparando o envio...';
      });

      await _initializeSocket(isReconnect: false);
    } catch (e, stack) {
      AppLogger.error('Erro ao iniciar rastreamento', e, stack);
      if (!mounted) return;
      setState(() {
        _trackingStatus = _TrackingStatus.error;
        _statusMessage = 'Erro ao iniciar rastreamento: $e';
        _isTracking = false;
        _userRequestedStop = true;
      });
    }
  }

  Future<void> _sendLocation(Position position) async {
    if (_channel == null) return;
    if (_vehicleId == null) return;

    final payload = {
      'vehicle_id': _vehicleId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'velocity': position.speed * 3.6, // m/s -> km/h
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      _channel!.sink.add(jsonEncode(payload));
      AppLogger.debug('Localização enviada: $payload');
    } catch (e, stack) {
      AppLogger.error('Erro ao enviar localização via WebSocket', e, stack);
    }
  }

  void _handleSocketEvent(dynamic event) {
    final payload = _parseSocketPayload(event);
    if (payload == null) {
      return;
    }

    if (payload['message'] == 'connection_closed') {
      AppLogger.warning('Servidor solicitou o encerramento da conexão');
      _handleConnectionLoss('Conexão encerrada pelo servidor.');
      return;
    }

    final success = payload['success'];
    if (success == false && payload['error'] != null) {
      final reason = payload['error'].toString();
      AppLogger.warning('Servidor retornou erro: $reason');
      final fatalAuthIssue = reason.toLowerCase().contains('token');
      if (fatalAuthIssue) {
        unawaited(_stopTracking(statusMessage: 'Erro do servidor: $reason'));
        return;
      }
      _handleConnectionLoss('Erro do servidor: $reason.');
    }
  }

  Map<String, dynamic>? _parseSocketPayload(dynamic event) {
    try {
      if (event is Map<String, dynamic>) {
        return event;
      }
      if (event is String) {
        final decoded = jsonDecode(event);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      if (event is List<int>) {
        final decoded = jsonDecode(utf8.decode(event));
        if (decoded is Map<String, dynamic>) return decoded;
      }
      final decoded = jsonDecode(event.toString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      AppLogger.debug('Evento de socket ignorado: $event');
      return null;
    }
  }

  void _handleConnectionLoss(String message) {
    unawaited(_socketSubscription?.cancel());
    _socketSubscription = null;

    if (_channel != null) {
      try {
        _channel?.sink.close();
      } catch (_) {}
    }
    _channel = null;

    if (!_isTracking || _userRequestedStop) {
      return;
    }

    if (!mounted) {
      _scheduleReconnect();
      return;
    }

    setState(() {
      _trackingStatus = _TrackingStatus.reconnecting;
      _statusMessage = '$message Tentando reconectar...';
    });

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (!_isTracking || _userRequestedStop) {
      return;
    }

    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isTracking || _userRequestedStop || !mounted) {
        return;
      }
      unawaited(_initializeSocket(isReconnect: true));
    });
  }

  Future<void> _stopTracking({String? statusMessage}) async {
    _userRequestedStop = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      await _positionSubscription?.cancel();
    } catch (_) {}
    _positionSubscription = null;

    try {
      await _socketSubscription?.cancel();
    } catch (_) {}
    _socketSubscription = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    _authToken = null;

    if (!mounted) return;
    setState(() {
      _isTracking = false;
      _trackingStatus = _TrackingStatus.idle;
      _statusMessage = statusMessage ?? 'Envio de localização desativado.';
    });

    AppLogger.info('Rastreamento parado.');
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _stopTracking();
    } else {
      await _startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = switch (_trackingStatus) {
      _TrackingStatus.streaming => Colors.red,
      _TrackingStatus.connecting => Colors.orange,
      _TrackingStatus.reconnecting => Colors.orange,
      _TrackingStatus.error => _isTracking ? Colors.orange : Colors.redAccent,
      _ => Colors.green,
    };

    final buttonText = switch (_trackingStatus) {
      _TrackingStatus.streaming => 'Parar envio da localização',
      _TrackingStatus.connecting => 'Conectando... (toque para parar)',
      _TrackingStatus.reconnecting => 'Tentando reconectar... (toque para parar)',
      _TrackingStatus.error => _isTracking ? 'Parar rastreamento' : 'Tentar novamente',
      _ => 'Começar rastreamento',
    };

    final statusColor = switch (_trackingStatus) {
      _TrackingStatus.streaming => Colors.green,
      _TrackingStatus.connecting => Colors.blueGrey,
      _TrackingStatus.reconnecting => Colors.orange,
      _TrackingStatus.error => Colors.redAccent,
      _ => Colors.blueGrey,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreamento'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Olá, ${widget.userName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _toggleTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Veículo vinculado:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingVehicles)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                )
              else if (_vehicles.isEmpty)
                Text(
                  _vehicleName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  value: _selectedVehicle?.id,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: _vehicles
                      .map(
                        (vehicle) => DropdownMenuItem<int>(
                          value: vehicle.id,
                          child: Text(vehicle.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: _loadingVehicles ? null : _handleVehicleSelection,
                ),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 16),
              if (_trackingStatus == _TrackingStatus.streaming)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Acompanhe os dados em tempo real pelo painel web.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
