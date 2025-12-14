import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../auth_service.dart';
import '../models/location_point.dart';
import '../models/vehicle.dart';
import '../utils/app_logger.dart';

class LocationAuditScreen extends StatefulWidget {
  const LocationAuditScreen({super.key});

  @override
  State<LocationAuditScreen> createState() => _LocationAuditScreenState();
}

class _LocationAuditScreenState extends State<LocationAuditScreen> {
  final AuthService _authService = AuthService();
  List<Vehicle> _vehicles = [];
  Map<int, Vehicle> _vehicleById = {};
  List<LocationPoint> _locations = [];

  bool _loadingVehicles = true;
  bool _loadingLocations = false;
  String? _error;
  int? _selectedVehicleId;
  DateTime _start = DateTime.now().subtract(const Duration(hours: 6));
  DateTime _end = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _loadingVehicles = true;
      _error = null;
    });

    try {
      final vehicles = await _authService.fetchAllVehicles();
      if (!mounted) return;
      vehicles.sort((a, b) => a.displayName.compareTo(b.displayName));
      setState(() {
        _vehicles = vehicles;
        _vehicleById = {for (final v in vehicles) v.id: v};
        _selectedVehicleId = vehicles.isNotEmpty ? vehicles.first.id : null;
        _loadingVehicles = false;
      });

      if (vehicles.isNotEmpty) {
        await _fetchLocations();
      }
    } catch (e, stack) {
      AppLogger.error('Erro ao carregar veículos para auditoria', e, stack);
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar a lista de veículos.';
        _loadingVehicles = false;
      });
    }
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null) return DateTime(date.year, date.month, date.day);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _fetchLocations() async {
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um veículo para filtrar.')),
      );
      return;
    }

    if (_start.isAfter(_end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data inicial não pode ser maior que a final.')),
      );
      return;
    }

    setState(() {
      _loadingLocations = true;
      _error = null;
      _locations = [];
    });

    try {
      final data = await _authService.fetchVehicleLocationsInRange(
        _selectedVehicleId!,
        _start,
        _end,
      );
      if (!mounted) return;
      setState(() {
        _locations = data;
        _loadingLocations = false;
      });
    } catch (e, stack) {
      AppLogger.error('Erro ao buscar auditoria de localizações', e, stack);
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar as localizações.';
        _loadingLocations = false;
      });
    }
  }

  Widget _buildFilters() {
    return Wrap(
      runSpacing: 12,
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<int>(
            value: _selectedVehicleId,
            items: _vehicles
                .map(
                  (v) => DropdownMenuItem<int>(
                    value: v.id,
                    child: Text(v.displayName),
                  ),
                )
                .toList(),
            onChanged: _loadingVehicles ? null : (value) => setState(() => _selectedVehicleId = value),
            decoration: const InputDecoration(
              labelText: 'Veículo',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _DateField(
          label: 'Início',
          value: _start,
          onTap: () async {
            final picked = await _pickDateTime(_start);
            if (picked != null && mounted) {
              setState(() => _start = picked);
            }
          },
        ),
        _DateField(
          label: 'Fim',
          value: _end,
          onTap: () async {
            final picked = await _pickDateTime(_end);
            if (picked != null && mounted) {
              setState(() => _end = picked);
            }
          },
        ),
        ElevatedButton.icon(
          onPressed: _loadingVehicles || _loadingLocations ? null : _fetchLocations,
          icon: const Icon(Icons.search),
          label: const Text('Buscar'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_loadingVehicles || _loadingLocations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchLocations,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_selectedVehicleId == null) {
      return const Center(child: Text('Selecione um veículo para iniciar a busca.'));
    }

    if (_locations.isEmpty) {
      return const Center(child: Text('Nenhum registro encontrado para o intervalo informado.'));
    }

    return ListView.separated(
      itemCount: _locations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final loc = _locations[index];
        final vehicle = _vehicleById[loc.vehicleId];
        final title = vehicle?.displayName ?? 'Veículo ${loc.vehicleId}';
        final speed = loc.velocity != null ? '${loc.velocity!.toStringAsFixed(1)} km/h' : 'N/A';
        final formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(loc.localTimestamp);
        return ListTile(
          leading: const Icon(Icons.place_outlined, color: Colors.indigo),
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Horário: $formattedTime'),
              Text('Coordenadas: ${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}'),
              Text('Velocidade: $speed'),
              if (loc.status != null && loc.status!.isNotEmpty) Text('Status: ${loc.status}'),
              if (loc.localizacao != null && loc.localizacao!.isNotEmpty)
                Text('Localização: ${loc.localizacao}'),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${loc.latitude.toStringAsFixed(2)}'),
              Text('${loc.longitude.toStringAsFixed(2)}'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_outlined, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                'Auditoria de Localizações',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Filtre posições gravadas por veículo e intervalo de tempo. Disponível apenas para administradores.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(height: 520, child: _buildResults()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = value.toLocal().toString().split('.').first;
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}
