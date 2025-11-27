import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedVehicle = 'Caminhão A';
  final List<String> _vehicles = [
    'Caminhão A',
    'Van B',
    'Carro C',
    'Moto D',
  ];

  final List<Map<String, dynamic>> _historyData = [
    {
      'timestamp': '2025-10-25 14:30:00',
      'localizacao': 'São Paulo, SP',
      'latitude': -23.5505,
      'longitude': -46.6333,
      'velocidade': 65,
      'status': 'Em movimento',
    },
    {
      'timestamp': '2025-10-25 14:15:00',
      'localizacao': 'Guarulhos, SP',
      'latitude': -23.4566,
      'longitude': -46.4936,
      'velocidade': 80,
      'status': 'Em movimento',
    },
    {
      'timestamp': '2025-10-25 14:00:00',
      'localizacao': 'Arujá, SP',
      'latitude': -23.3439,
      'longitude': -46.3569,
      'velocidade': 90,
      'status': 'Em movimento',
    },
    {
      'timestamp': '2025-10-25 13:30:00',
      'localizacao': 'Campinas, SP',
      'latitude': -22.9068,
      'longitude': -47.0626,
      'velocidade': 0,
      'status': 'Parado',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: DropdownButton<String>(
              value: _selectedVehicle,
              isExpanded: true,
              underline: const SizedBox(),
              items: _vehicles.map((vehicle) {
                return DropdownMenuItem<String>(
                  value: vehicle,
                  child: Text(vehicle),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedVehicle = newValue;
                  });
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _historyData.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final record = _historyData[index];
              return _buildHistoryCard(record, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record, int index) {
    final statusColor = record['status'] == 'Em movimento' ? Colors.green : Colors.orange;

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
                      color: Colors.indigo.withOpacity(0.1),
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
                        record['timestamp'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Lat: ${record['latitude'].toStringAsFixed(4)}, Long: ${record['longitude'].toStringAsFixed(4)}',
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record['status'],
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
                  record['localizacao'],
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
                '${record['velocidade']} km/h',
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
