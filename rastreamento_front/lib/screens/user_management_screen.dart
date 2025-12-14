import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../models/user_profile.dart';
import '../utils/app_logger.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AuthService _authService = AuthService();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<UserProfile> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await _authService.fetchAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e, stack) {
      AppLogger.error('Erro ao carregar usuários', e, stack);
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar a lista de usuários.';
        _loading = false;
      });
    }
  }

  void _showUserDialog({UserProfile? user}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    bool isAdmin = user?.isAdmin ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool localSubmitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> handleSubmit() async {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                _submitting = true;
              });
              setStateDialog(() {
                localSubmitting = true;
              });

              try {
                UserProfile? saved;
                if (user == null) {
                  saved = await _authService.createUser(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    name: nameController.text.trim().isEmpty
                        ? null
                        : nameController.text.trim(),
                    isAdmin: isAdmin,
                  );
                } else {
                  saved = await _authService.updateUser(
                    id: user.id,
                    email: emailController.text.trim(),
                    password: passwordController.text.isEmpty
                        ? null
                        : passwordController.text,
                    name: nameController.text.trim().isEmpty
                        ? null
                        : nameController.text.trim(),
                    isAdmin: isAdmin,
                  );
                }

                if (!mounted) return;
                if (saved != null) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(user == null
                          ? 'Usuário criado com sucesso.'
                          : 'Usuário atualizado com sucesso.'),
                    ),
                  );
                  await _loadUsers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Não foi possível salvar o usuário.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _submitting = false;
                  });
                }
                if (Navigator.of(dialogContext).mounted) {
                  setStateDialog(() {
                    localSubmitting = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: Text(user == null ? 'Novo usuário' : 'Editar usuário'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          hintText: 'Nome completo (opcional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'usuario@empresa.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe um e-mail';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'E-mail inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: user == null ? 'Senha' : 'Senha (opcional)',
                          hintText: user == null
                              ? 'Defina uma senha temporária'
                              : 'Deixe em branco para manter',
                        ),
                        validator: (value) {
                          if (user != null) return null;
                          if (value == null || value.isEmpty) {
                            return 'Defina uma senha para o novo usuário';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter ao menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Administrador'),
                        value: isAdmin,
                        onChanged: (value) {
                          setStateDialog(() {
                            isAdmin = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: localSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: localSubmitting ? null : handleSubmit,
                  icon: localSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(user == null ? 'Criar' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndDelete(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir usuário'),
        content: Text('Deseja excluir ${user.displayName}? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _submitting = true;
    });

    try {
      final success = await _authService.deleteUser(user.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário ${user.displayName} excluído.')),
        );
        await _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível excluir o usuário.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _buildContent() {
    if (_loading) {
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
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nenhum usuário encontrado.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _submitting ? null : () => _showUserDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Criar usuário'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?'),
            ),
            title: Text(user.displayName),
            subtitle: Text(user.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(color: Colors.indigo),
                    ),
                  ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: _submitting ? null : () => _showUserDialog(user: user),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Excluir',
                  onPressed: _submitting ? null : () => _confirmAndDelete(user),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                ),
              ],
            ),
          );
        },
      ),
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
              const Icon(Icons.people_alt_outlined, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                'Gerenciamento de Usuários',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _submitting ? null : () => _showUserDialog(),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Novo usuário'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Crie, edite ou remova contas. Apenas administradores podem acessar esta seção.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 520,
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
