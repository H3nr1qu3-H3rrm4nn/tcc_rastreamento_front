import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../auth_service.dart';
import '../config/app_config.dart';
import '../models/location_point.dart';
import '../models/vehicle.dart';
import '../utils/app_logger.dart';
import '../widgets/app_bar_custom.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/vehicle_list_item.dart';
import 'history_screen.dart';
import 'user_management_screen.dart';
import 'vehicles_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final int? userId;
  final bool isAdmin;

  const DashboardScreen({
    super.key,
    required this.userName,
    this.userId,
    required this.isAdmin,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<Vehicle> _vehicles = [];
  Map<String, dynamic> _stats = {};
  int? _resolvedUserId;
  Set<Marker> _vehicleMarkers = {};
  Map<int, LocationPoint> _vehicleLocations = {};
  CameraPosition? _initialCameraPosition;
  GoogleMapController? _mapController;
  Timer? _positionRefreshTimer;
  bool _loadingPositions = false;
  bool _isAdmin = false;

  static const CameraPosition _defaultCameraPosition = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _positionRefreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final cachedProfile = await _authService.getSavedUserProfile();
      final userId = widget.userId ?? cachedProfile?.id;
      _isAdmin = cachedProfile?.isAdmin ?? widget.isAdmin;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Não foi possível identificar o usuário logado.';
          _isLoading = false;
        });
        return;
      }

      final vehicles = await _authService.fetchVehicles(userId: userId);
      final stats = await _authService.fetchVehicleStats();

      if (!mounted) return;

      setState(() {
        _resolvedUserId = userId;
        _vehicles = vehicles;
        _stats = stats;
        _isAdmin = cachedProfile?.isAdmin ?? widget.isAdmin;
        _isLoading = false;
      });

      await _loadVehicleMarkers(vehicles);
      _schedulePositionRefresh();
    } catch (e, stack) {
      AppLogger.error('Erro ao carregar dashboard', e, stack);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível carregar os dados da frota.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVehicleMarkers(List<Vehicle> vehicles, {bool showLoading = true}) async {
    if (!mounted) return;
    if (vehicles.isEmpty) {
      setState(() {
        _vehicleMarkers = {};
        _vehicleLocations = {};
        if (showLoading) _loadingPositions = false;
      });
      return;
    }

    if (showLoading) {
      setState(() {
        _loadingPositions = true;
      });
    }

    try {
      final locationEntries = await Future.wait<MapEntry<Vehicle, LocationPoint?>>(
        vehicles.map((vehicle) async {
          final location = await _authService.fetchLastVehicleLocation(vehicle.id);
          return MapEntry(vehicle, location);
        }),
      );

      final markers = <Marker>{};
      final latestLocations = <int, LocationPoint>{};
      LatLng? firstPosition;

      for (final entry in locationEntries) {
        final vehicle = entry.key;
        final location = entry.value;
        if (location == null) continue;

        final position = LatLng(location.latitude, location.longitude);
        firstPosition ??= position;
        latestLocations[vehicle.id] = location;

        final marker = Marker(
          markerId: MarkerId('vehicle_${vehicle.id}'),
          position: position,
          infoWindow: InfoWindow(
            title: vehicle.displayName,
            snippet: 'Velocidade: ${location.velocity?.toStringAsFixed(1) ?? '0'} km/h',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            vehicle.isOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
          ),
        );

        markers.add(marker);
      }

      if (!mounted) return;

      setState(() {
        _vehicleMarkers = markers;
        _vehicleLocations = latestLocations;
        if (_initialCameraPosition == null && firstPosition != null) {
          _initialCameraPosition = CameraPosition(target: firstPosition, zoom: 13);
        }
        if (showLoading) {
          _loadingPositions = false;
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMarkersToMap());
    } catch (e, stack) {
      AppLogger.error('Erro ao carregar posições dos veículos', e, stack);
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _loadingPositions = false;
        });
      }
    }
  }

  void _schedulePositionRefresh() {
    _positionRefreshTimer?.cancel();
    _positionRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshVehiclePositions();
    });
  }

  Future<void> _refreshVehiclePositions() async {
    if (_resolvedUserId == null) return;

    try {
      final vehiclesFuture = _authService.fetchVehicles(userId: _resolvedUserId!);
      final statsFuture = _authService.fetchVehicleStats();

      final vehicles = await vehiclesFuture;
      final stats = await statsFuture;
      if (!mounted) return;

      setState(() {
        _vehicles = vehicles;
        if (stats.isNotEmpty) {
          _stats = stats;
        }
      });

      await _loadVehicleMarkers(vehicles, showLoading: false);
    } catch (e, stack) {
      AppLogger.error('Erro ao atualizar veículos', e, stack);
    }
  }

  void _fitMarkersToMap() {
    if (_mapController == null || _vehicleMarkers.isEmpty) return;

    if (_vehicleMarkers.length == 1) {
      final marker = _vehicleMarkers.first;
      _mapController!
          .animateCamera(CameraUpdate.newLatLngZoom(marker.position, 14));
      return;
    }

    final latitudes = _vehicleMarkers.map((marker) => marker.position.latitude);
    final longitudes = _vehicleMarkers.map((marker) => marker.position.longitude);

    final south = latitudes.reduce(math.min);
    final north = latitudes.reduce(math.max);
    final west = longitudes.reduce(math.min);
    final east = longitudes.reduce(math.max);

    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    try {
      _mapController!
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    } catch (e) {
      AppLogger.debug('Não foi possível ajustar o mapa: $e');
    }
  }

  Widget _buildRealtimeMap() {
    if (!isGoogleMapsEnabled) {
      return _buildMapUnavailableMessage();
    }

    final cameraPosition = _initialCameraPosition ?? _defaultCameraPosition;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: cameraPosition,
          markers: _vehicleMarkers,
          zoomControlsEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
            _fitMarkersToMap();
          },
        ),
        if (_loadingPositions)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black12,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (_vehicleMarkers.isEmpty && !_loadingPositions)
          Positioned.fill(
            child: Center(
              child: Text(
                'Sem veículos com posição disponível no momento.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapUnavailableMessage() {
    if (!kIsWeb) {
      return const Center(child: Text('Mapa indisponível no momento.'));
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Google Maps não configurado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Informe GOOGLE_MAPS_API_KEY via --dart-define ou arquivo .env para habilitar o mapa na versão web.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _onMenuItemSelected(int index) {
    if (index == 3 && !_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aba disponível apenas para administradores.')),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    AppLogger.info('Menu item selected: $index');
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return VehiclesScreen(userId: _resolvedUserId);
      case 2:
        return HistoryScreen(userId: _resolvedUserId);
      case 3:
        return const UserManagementScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final totalVehicles = (_stats['total'] is num)
        ? (_stats['total'] as num).toInt()
        : _vehicles.length;
    final onlineVehicles = (_stats['online'] is num)
        ? (_stats['online'] as num).toInt()
        : _vehicles.where((v) => v.isOnline).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título e descrição
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Visão geral da frota de veículos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Cards de estatísticas
          Row(
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'Total de Veículos',
                  value: totalVehicles.toString(),
                  icon: Icons.directions_car,
                  color: Colors.blue,
                  subtitle: 'Cadastrados',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DashboardCard(
                  title: 'Online',
                  value: onlineVehicles.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                  subtitle: '100% da frota',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mapa e lista de veículos
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mapa (ocupará 60% da largura)
              Expanded(
                flex: 6,
                child: Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map, color: Colors.indigo),
                            const SizedBox(width: 8),
                            const Text(
                              'Mapa em Tempo Real',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          child: _buildRealtimeMap(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Lista de veículos ativos (ocupará 40% da largura)
              Expanded(
                flex: 4,
                child: Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Veículos Ativos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _vehicles.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final vehicle = _vehicles[index];
                            final latestPoint = _vehicleLocations[vehicle.id];
                            final locationLabel = latestPoint != null
                                ? '${latestPoint.latitude.toStringAsFixed(5)}, '
                                    '${latestPoint.longitude.toStringAsFixed(5)}'
                                : (vehicle.lastLocation ?? 'Localização indisponível');
                            final speed = (latestPoint?.velocity ?? vehicle.currentVelocity ?? 0)
                                .round();
                            return VehicleListItem(
                              name: vehicle.displayName,
                              location: locationLabel,
                              status: vehicle.isOnline ? 'Online' : 'Offline',
                              speed: speed,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        userName: widget.userName,
        selectedIndex: _selectedIndex,
        onMenuItemSelected: _onMenuItemSelected,
        isAdmin: _isAdmin,
      ),
      body: _buildCurrentScreen(),
    );
  }
}
