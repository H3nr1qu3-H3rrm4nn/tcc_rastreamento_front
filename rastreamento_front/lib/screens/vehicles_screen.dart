import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../models/vehicle.dart';
import '../utils/app_logger.dart';

class VehiclesScreen extends StatefulWidget {
  final int? userId;

  const VehiclesScreen({super.key, this.userId});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final AuthService _authService = AuthService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void didUpdateWidget(covariant VehiclesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _loadVehicles();
    }
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cachedProfile = await _authService.getSavedUserProfile();
      final userId = widget.userId ?? cachedProfile?.id;

      if (userId == null) {
        setState(() {
          _errorMessage = 'Não foi possível identificar o usuário logado.';
          _isLoading = false;
        });
        return;
      }

      final vehicles = await _authService.fetchVehicles(userId: userId);

      if (!mounted) return;

      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e, stack) {
      AppLogger.error('Erro ao carregar veículos', e, stack);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível carregar os veículos.';
        _isLoading = false;
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
            'Gerenciar Veículos',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Visualize e gerencie todos os veículos cadastrados',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              AppLogger.info('Botão adicionar veículo clicado');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Adicionar veículo - Em desenvolvimento')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Veículo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
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
                  onPressed: _loadVehicles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            )
          else if (_vehicles.isEmpty)
            const Text('Nenhum veículo encontrado para este usuário.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vehicles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return _buildVehicleCard(vehicle);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final isOnline = vehicle.isOnline;
    final statusColor = isOnline ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Placa: ${vehicle.plate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(Icons.local_shipping, 'Tipo', vehicle.type),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.location_on,
                  'Local',
                  vehicle.lastLocation ?? 'Sem registro',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            Icons.place,
            'Último local',
            vehicle.lastLocation ?? 'Sem registro',
          ),
          const SizedBox(height: 4),
          _buildInfoItem(
            Icons.speed,
            'Velocidade',
            '${vehicle.currentVelocity?.toStringAsFixed(1) ?? '0'} km/h',
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  AppLogger.info('Visualizar detalhes do veículo: ${vehicle.displayName}');
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Detalhes'),
              ),
              TextButton.icon(
                onPressed: () {
                  AppLogger.info('Editar veículo: ${vehicle.displayName}');
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
