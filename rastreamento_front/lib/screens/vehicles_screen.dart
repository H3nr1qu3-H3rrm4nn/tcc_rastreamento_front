import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final List<Map<String, dynamic>> _vehicles = [
    {
      'id': 1,
      'name': 'Caminhão A',
      'placa': 'ABC-1234',
      'tipo': 'Caminhão',
      'status': 'Online',
      'localizacao': 'São Paulo, SP',
      'motorista': 'João Silva',
    },
    {
      'id': 2,
      'name': 'Van B',
      'placa': 'XYZ-5678',
      'tipo': 'Van',
      'status': 'Offline',
      'localizacao': 'Rio de Janeiro, RJ',
      'motorista': 'Maria Santos',
    },
    {
      'id': 3,
      'name': 'Carro C',
      'placa': 'DEF-9012',
      'tipo': 'Carro',
      'status': 'Online',
      'localizacao': 'Belo Horizonte, MG',
      'motorista': 'Pedro Oliveira',
    },
  ];

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

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final isOnline = vehicle['status'] == 'Online';
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
                      vehicle['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Placa: ${vehicle['placa']}',
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  vehicle['status'],
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
                child: _buildInfoItem(Icons.local_shipping, 'Tipo', vehicle['tipo']),
              ),
              Expanded(
                child: _buildInfoItem(Icons.location_on, 'Local', vehicle['localizacao']),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoItem(Icons.person, 'Motorista', vehicle['motorista']),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  AppLogger.info('Visualizar detalhes do veículo: ${vehicle['name']}');
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Detalhes'),
              ),
              TextButton.icon(
                onPressed: () {
                  AppLogger.info('Editar veículo: ${vehicle['name']}');
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
