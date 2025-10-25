import 'package:flutter/material.dart';
import '../widgets/app_bar_custom.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/vehicle_list_item.dart';
import '../utils/app_logger.dart';
import 'vehicles_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({
    super.key,
    required this.userName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _vehiclesData = [
    {
      'name': 'Caminhão A',
      'location': 'São Paulo, SP',
      'status': 'Online',
      'speed': 65,
    },
    {
      'name': 'Van B',
      'location': 'Rio de Janeiro, RJ',
      'status': 'Offline',
      'speed': 0,
    },
    {
      'name': 'Carro C',
      'location': 'Belo Horizonte, MG',
      'status': 'Online',
      'speed': 80,
    },
    {
      'name': 'Moto D',
      'location': 'Brasília, DF',
      'status': 'Online',
      'speed': 60,
    },
  ];

  void _onMenuItemSelected(int index) {
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
        return const VehiclesScreen();
      case 2:
        return const HistoryScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final onlineVehicles = _vehiclesData.where((v) => v['status'] == 'Online').length;
    final totalVehicles = _vehiclesData.length;

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
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Mapa interativo será carregado aqui',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Integração com Google Maps via OpenStreetMap',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
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
                          itemCount: _vehiclesData.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final vehicle = _vehiclesData[index];
                            return VehicleListItem(
                              name: vehicle['name'],
                              location: vehicle['location'],
                              status: vehicle['status'],
                              speed: vehicle['speed'],
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
      ),
      body: _buildCurrentScreen(),
    );
  }
}
