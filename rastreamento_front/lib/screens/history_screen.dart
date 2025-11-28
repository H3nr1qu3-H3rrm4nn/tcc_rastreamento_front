import 'package:flutter/material.dart';
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
      final history = await _authService.fetchVehicleLocations(vehicleId);
      if (!mounted) return;
      setState(() {
        _history = history;
        _loadingHistory = false;
      });
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
    return SingleChildScrollView(
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
            'Visualize o histórico de localização dos veículos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Selecione um veículo:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingVehicles)
            const Center(child: CircularProgressIndicator())
          else if (_vehicles.isEmpty)
            const Text('Nenhum veículo disponível para exibir o histórico.')
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
                    _loadHistory(newValue);
                    AppLogger.info('Veículo selecionado para histórico: $newValue');
                  }
                },
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Últimas localizações:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Column(
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_selectedVehicleId != null) {
                      _loadHistory(_selectedVehicleId!);
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            )
          else if (_history.isEmpty)
            const Text('Nenhum registro encontrado para o período selecionado.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = _history[index];
                return _buildHistoryCard(record, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(LocationPoint record, int index) {
    final isMoving = (record.velocity ?? 0) > 0;
    final statusColor = isMoving ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.formattedTimestamp,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Lat: ${record.latitude.toStringAsFixed(4)}, Long: ${record.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record.status ?? (isMoving ? 'Em movimento' : 'Parado'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  record.localizacao ?? 'Localização não informada',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.speed, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${record.velocity?.toStringAsFixed(1) ?? '0'} km/h',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
