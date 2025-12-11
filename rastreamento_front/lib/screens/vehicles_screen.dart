import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../models/vehicle.dart';
import '../models/user_profile.dart';
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
  UserProfile? _currentUser;
  List<UserProfile> _users = [];
  final Set<int> _vehicleUserUpdateInProgress = <int>{};

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
      _currentUser = cachedProfile;
      final isAdmin = cachedProfile?.isAdmin == true;
      final userId = widget.userId ?? cachedProfile?.id;

      List<Vehicle> vehicles;
      List<UserProfile> users = _users;

      if (isAdmin) {
        vehicles = await _authService.fetchAllVehicles();
        users = await _authService.fetchAllUsers();
        users.sort((a, b) => a.id.compareTo(b.id));
      } else {
        if (userId == null) {
          setState(() {
            _errorMessage = 'Não foi possível identificar o usuário logado.';
            _isLoading = false;
          });
          return;
        }
        vehicles = await _authService.fetchVehicles(userId: userId);
      }

      if (!mounted) return;

      setState(() {
        _vehicles = vehicles;
        if (isAdmin) {
          _users = users;
        }
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
          if (_currentUser?.isAdmin == true) ...[
            ElevatedButton.icon(
              onPressed: _openCreateVehicleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Veículo'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
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
    final associatedUser = _findUserById(vehicle.userId);
    final associatedUserLabel = associatedUser != null
        ? '${associatedUser.id} - ${associatedUser.email}'
        : (vehicle.userId != null ? 'ID ${vehicle.userId}' : 'Nenhum usuário associado');
    final vehicleSpeed = '${vehicle.currentVelocity?.toStringAsFixed(1) ?? '0'} km/h';

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
                  Icons.speed,
                  'Velocidade',
                  vehicleSpeed,
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
          const SizedBox(height: 8),
          _buildInfoItem(
            Icons.person,
            'Usuário',
            associatedUserLabel,
          ),
          if (_currentUser?.isAdmin == true && _users.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildUserAssociationControl(vehicle),
          ],
          const SizedBox(height: 12),
          if (_currentUser?.isAdmin == true)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _openEditVehicleDialog(vehicle),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDeleteVehicle(vehicle),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
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

  UserProfile? _findUserById(int? id) {
    if (id == null) return null;
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleUserAssociationChange(
    Vehicle vehicle,
    int newUserId,
  ) async {
    if (_vehicleUserUpdateInProgress.contains(vehicle.id)) return;
    if (vehicle.userId == newUserId) return;

    setState(() {
      _vehicleUserUpdateInProgress.add(vehicle.id);
    });

    final updated = await _authService.updateVehicle(
      id: vehicle.id,
      name: vehicle.name ?? vehicle.type,
      plate: vehicle.plate,
      type: vehicle.type,
      userId: newUserId,
    );

    if (!mounted) {
      return;
    }

    if (updated == null) {
      setState(() {
        _vehicleUserUpdateInProgress.remove(vehicle.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar o usuário associado.')),
      );
      return;
    }

    setState(() {
      _vehicleUserUpdateInProgress.remove(vehicle.id);
      _vehicles = _vehicles
          .map((existing) => existing.id == vehicle.id ? updated : existing)
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário associado atualizado com sucesso.')),
    );
  }

  Widget _buildUserAssociationControl(Vehicle vehicle) {
    if (_users.isEmpty) {
      return const SizedBox.shrink();
    }

    final isUpdating = _vehicleUserUpdateInProgress.contains(vehicle.id);
    final hasCurrentUser =
      vehicle.userId != null && _users.any((user) => user.id == vehicle.userId);

    final items = _users
        .map(
          (user) => DropdownMenuItem<int>(
            value: user.id,
            child: Text('${user.id} - ${user.email}'),
          ),
        )
        .toList();

    if (!hasCurrentUser && vehicle.userId != null) {
      items.insert(
        0,
        DropdownMenuItem<int>(
          value: vehicle.userId,
          enabled: false,
          child: Text('ID ${vehicle.userId} (não encontrado)'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alterar usuário associado',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: vehicle.userId,
                items: items,
                onChanged: isUpdating
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        _handleUserAssociationChange(vehicle, value);
                      },
                decoration: const InputDecoration(
                  labelText: 'Usuário (ID)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                hint: const Text('Selecione o usuário'),
              ),
            ),
            if (isUpdating) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _openCreateVehicleDialog() async {
    AppLogger.info('Abrindo diálogo de criação de veículo');

    final cachedProfile = await _authService.getSavedUserProfile();
    _currentUser = cachedProfile;
    final isAdmin = _currentUser?.isAdmin == true;
    final defaultUserId = widget.userId ?? cachedProfile?.id;

    if (!isAdmin && defaultUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não identificado. Faça login novamente.')),
      );
      return;
    }

    final result = await showDialog<_VehicleFormResult>(
      context: context,
      builder: (context) => _VehicleFormDialog(
        initialName: 'Veículo',
        initialPlate: '',
        initialType: 'Veículo',
        showUserSelector: isAdmin,
        users: isAdmin ? _users : const [],
        initialUserId: isAdmin && _users.isNotEmpty ? _users.first.id : defaultUserId,
      ),
    );

    if (!mounted || result == null) return;

    final targetUserId = isAdmin ? result.userId : defaultUserId;

    if (targetUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um usuário para associar ao veículo.')),
      );
      return;
    }

    final created = await _authService.createVehicle(
      name: result.name,
      plate: result.plate,
      type: result.type,
      userId: targetUserId,
    );

    if (!mounted || created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível criar o veículo.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veículo criado com sucesso.')),
    );
    _loadVehicles();
  }

  Future<void> _openEditVehicleDialog(Vehicle vehicle) async {
    AppLogger.info('Abrindo diálogo de edição para veículo: ${vehicle.displayName}');

    final isAdmin = _currentUser?.isAdmin == true;

    final result = await showDialog<_VehicleFormResult>(
      context: context,
      builder: (context) => _VehicleFormDialog(
        initialName: vehicle.name ?? vehicle.type,
        initialPlate: vehicle.plate,
        initialType: vehicle.type,
        showUserSelector: isAdmin,
        users: isAdmin ? _users : const [],
        initialUserId: isAdmin ? vehicle.userId : null,
      ),
    );

    if (!mounted || result == null) return;

    final updated = await _authService.updateVehicle(
      id: vehicle.id,
      name: result.name,
      plate: result.plate,
      type: result.type,
      userId: isAdmin ? result.userId ?? vehicle.userId : vehicle.userId,
    );

    if (!mounted || updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar o veículo.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veículo atualizado com sucesso.')),
    );
    _loadVehicles();
  }

  Future<void> _confirmDeleteVehicle(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir veículo'),
          content: Text('Tem certeza que deseja excluir o veículo ${vehicle.displayName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final success = await _authService.deleteVehicle(vehicle.id);
    if (!mounted || !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o veículo.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veículo excluído com sucesso.')),
    );
    _loadVehicles();
  }
}

class _VehicleFormResult {
  final String name;
  final String plate;
  final String type;
  final int? userId;

  _VehicleFormResult({
    required this.name,
    required this.plate,
    required this.type,
    this.userId,
  });
}

class _VehicleFormDialog extends StatefulWidget {
  final String? initialName;
  final String? initialPlate;
  final String? initialType;
   final bool showUserSelector;
   final List<UserProfile> users;
   final int? initialUserId;

  const _VehicleFormDialog({
    this.initialName,
    this.initialPlate,
    this.initialType,
    required this.showUserSelector,
    required this.users,
    this.initialUserId,
  });

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _plateController;
  late TextEditingController _typeController;
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? 'Veículo');
    _plateController = TextEditingController(text: widget.initialPlate ?? '');
    _typeController = TextEditingController(text: widget.initialType ?? 'Veículo');
    _selectedUserId = widget.initialUserId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialPlate != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar veículo' : 'Novo veículo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome / Identificação'),
              ),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'Placa'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a placa';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              if (widget.showUserSelector && widget.users.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Usuário associado',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: _selectedUserId ?? widget.users.first.id,
                  items: widget.users
                      .map(
                        (u) => DropdownMenuItem<int>(
                          value: u.id,
                          child: Text('${u.id} - ${u.email}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedUserId = value),
                  decoration: const InputDecoration(
                    labelText: 'Selecione o usuário',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              _VehicleFormResult(
                name: _nameController.text.trim(),
                plate: _plateController.text.trim(),
                type: _typeController.text.trim().isEmpty
                    ? 'Veículo'
                    : _typeController.text.trim(),
                userId: widget.showUserSelector ? _selectedUserId : null,
              ),
            );
          },
          child: Text(isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}
