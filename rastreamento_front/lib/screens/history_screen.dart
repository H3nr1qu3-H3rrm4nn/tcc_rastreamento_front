import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../auth_service.dart';
import '../models/location_point.dart';
import '../models/vehicle.dart';
import '../utils/app_logger.dart';

class HistoryScreen extends StatefulWidget {
  final int? userId;

  const HistoryScreen({super.key, this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AuthService _authService = AuthService();
  List<Vehicle> _vehicles = [];
  int? _selectedVehicleId;
  bool _loadingVehicles = true;
  bool _loadingHistory = false;
  String? _errorMessage;
  List<LocationPoint> _history = [];

  GoogleMapController? _mapController;
  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 12,
  );
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  DateTime? _startDateTime;
  DateTime? _endDateTime;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _loadVehicles();
    }
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _loadingVehicles = true;
      _errorMessage = null;
    });

    try {
      final cachedProfile = await _authService.getSavedUserProfile();
      final userId = widget.userId ?? cachedProfile?.id;

      if (userId == null) {
        setState(() {
          _errorMessage = 'Não foi possível identificar o usuário logado.';
          _loadingVehicles = false;
        });
        return;
      }

      final vehicles = await _authService.fetchVehicles(userId: userId);

      if (!mounted) return;

      setState(() {
        _vehicles = vehicles;
        _selectedVehicleId = vehicles.isNotEmpty ? vehicles.first.id : null;
        _loadingVehicles = false;
      });

      if (_selectedVehicleId != null) {
        _loadHistory(_selectedVehicleId!);
      }
    } catch (e, stack) {
      AppLogger.error('Erro ao carregar veículos para histórico', e, stack);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível carregar os veículos.';
        _loadingVehicles = false;
      });
    }
  }

  Future<void> _loadHistory(int vehicleId) async {
    setState(() {
      _loadingHistory = true;
      _errorMessage = null;
    });

    try {
        final start = _startDateTime;
        final end = _endDateTime;

        // If both start and end are set, call the backend range endpoint.
        final history = (start != null && end != null)
          ? await _authService.fetchVehicleLocationsInRange(vehicleId, start, end)
          : await _authService.fetchVehicleLocations(vehicleId);

        final filtered = history;

      if (!mounted) return;
      setState(() {
        _history = filtered;
        _loadingHistory = false;
      });

      _updateMapFromHistory();
    } catch (e, stack) {
      AppLogger.error('Erro ao carregar histórico', e, stack);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível carregar o histórico.';
        _loadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Histórico de Rastreamento',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Visualize o trajeto dos veículos em um período',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildMap(),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 320,
                  child: _buildSidebar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultCamera,
            polylines: _polylines,
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_history.isNotEmpty) {
                unawaited(Future.microtask(_fitMapToHistory));
              }
            },
          ),
          if (_loadingHistory)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black12,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_history.isEmpty && !_loadingHistory)
            Positioned.fill(
              child: Center(
                child: Text(
                  'Nenhum trajeto para o período selecionado.',
                  style: TextStyle(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Veículo',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          if (_loadingVehicles)
            const Center(child: CircularProgressIndicator())
          else if (_vehicles.isEmpty)
            const Text('Nenhum veículo disponível.')
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: DropdownButton<int>(
                value: _selectedVehicleId,
                isExpanded: true,
                underline: const SizedBox(),
                items: _vehicles.map((vehicle) {
                  return DropdownMenuItem<int>(
                    value: vehicle.id,
                    child: Text(vehicle.displayName),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedVehicleId = newValue;
                    });
                  }
                },
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Período',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildDateTimeField(
            label: 'Início',
            value: _startDateTime,
            onChanged: (dt) => setState(() => _startDateTime = dt),
          ),
          const SizedBox(height: 8),
          _buildDateTimeField(
            label: 'Fim',
            value: _endDateTime,
            onChanged: (dt) => setState(() => _endDateTime = dt),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _onApplyFilters,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Visualizar trajeto'),
            ),
          ),
          const SizedBox(height: 8),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    final text = value == null
        ? 'Selecionar $label'
        : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
            '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final initialDate = value ?? now;
        final date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 1),
        );
        if (!mounted || date == null) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initialDate),
        );
        if (!mounted || time == null) return;

        final result = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onChanged(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onApplyFilters() {
    if (_selectedVehicleId == null) {
      setState(() {
        _errorMessage = 'Selecione um veículo.';
      });
      return;
    }
    if (_startDateTime == null || _endDateTime == null) {
      setState(() {
        _errorMessage = 'Informe o período de início e fim.';
      });
      return;
    }
    if (_endDateTime!.isBefore(_startDateTime!)) {
      setState(() {
        _errorMessage = 'Data de fim não pode ser anterior ao início.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    _loadHistory(_selectedVehicleId!);
  }

  void _updateMapFromHistory() {
    if (_history.isEmpty) {
      setState(() {
        _polylines = {};
        _markers = {};
      });
      return;
    }

    final orderedHistory = List<LocationPoint>.from(_history)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final orderedPoints = orderedHistory
        .map((h) => LatLng(h.latitude, h.longitude))
        .toList(growable: false);

    final gapThreshold = const Duration(minutes: 5);
    final segmentPolylines = <Polyline>{};
    var currentSegment = <LatLng>[];
    DateTime? previousTimestamp;
    var segmentIndex = 0;

    for (final item in orderedHistory) {
      final currentPoint = LatLng(item.latitude, item.longitude);
      if (previousTimestamp != null &&
          item.timestamp.difference(previousTimestamp).abs() > gapThreshold) {
        if (currentSegment.length >= 2) {
          segmentPolylines.add(
            Polyline(
              polylineId: PolylineId('segment_${segmentIndex++}'),
              points: List<LatLng>.from(currentSegment),
              color: Colors.indigo,
              width: 4,
            ),
          );
        }
        currentSegment = <LatLng>[];
      }

      currentSegment.add(currentPoint);
      previousTimestamp = item.timestamp;
    }

    if (currentSegment.length >= 2) {
      segmentPolylines.add(
        Polyline(
          polylineId: PolylineId('segment_${segmentIndex++}'),
          points: List<LatLng>.from(currentSegment),
          color: Colors.indigo,
          width: 4,
        ),
      );
    }

    final start = orderedPoints.first;
    final end = orderedPoints.last;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('start'),
        position: start,
        infoWindow: const InfoWindow(title: 'Início'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: end,
        infoWindow: const InfoWindow(title: 'Fim'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    setState(() {
      _polylines = segmentPolylines;
      _markers = markers;
    });

    _fitMapToHistory();
  }

  void _fitMapToHistory() {
    if (_mapController == null || _history.isEmpty) return;

    final orderedPoints = List<LocationPoint>.from(_history)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final points = orderedPoints
        .map((h) => LatLng(h.latitude, h.longitude))
        .toList();
    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;

    for (final p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    unawaited(
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      ),
    );
  }
}
