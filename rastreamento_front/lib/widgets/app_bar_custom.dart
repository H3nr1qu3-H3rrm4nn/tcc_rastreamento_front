import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../utils/app_logger.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final int selectedIndex;
  final Function(int) onMenuItemSelected;
  final bool isAdmin;
  static final AuthService _authService = AuthService();

  const CustomAppBar({
    super.key,
    required this.userName,
    required this.selectedIndex,
    required this.onMenuItemSelected,
    required this.isAdmin,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  void _handleLogout(BuildContext context) {
    AppLogger.info('Usuário $userName realizou logout');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar saída'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await _authService.removeToken();
              navigator.pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Logo e nome do app
              const Icon(
                Icons.location_on,
                color: Colors.indigo,
                size: 32,
              ),
              const SizedBox(width: 8),
              const Text(
                'Rastreamento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 32),

              // Menu de navegação
              _buildMenuItem('Dashboard', 0),
              _buildMenuItem('Veículos', 1),
              _buildMenuItem('Histórico', 2),
              if (isAdmin) _buildMenuItem('Usuários', 3),

              const Spacer(),

              // Informações do usuário e logout
              Row(
                children: [
                  Text(
                    'Bem-vindo, $userName',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sair',
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, int index) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: () => onMenuItemSelected(index),
        style: TextButton.styleFrom(
          foregroundColor: isSelected ? Colors.indigo : Colors.grey[700],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
