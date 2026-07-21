import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

const _adminEmail = 'adriansodre1@gmail.com';
// Service key via variável de ambiente (configurada no build)
const _serviceKey = String.fromEnvironment('SUPABASE_SERVICE_KEY', defaultValue: '');
const _supabaseUrl = 'https://gattydrrhmhuqysbsjol.supabase.co';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Buscar usuários via Admin API do Supabase
      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'admin-users',
        body: {'action': 'list'},
      );
      // Fallback: buscar via REST direto com service key
      await _loadViaRest();
    } catch (e) {
      await _loadViaRest();
    }
  }

  Future<void> _loadViaRest() async {
    try {
      // Usar Admin REST API diretamente
      final uri = Uri.parse('$_supabaseUrl/auth/v1/admin/users?page=1&per_page=50');
      final response = await _httpGet(uri);
      if (response != null) {
        final users = (response['users'] as List? ?? []);
        if (mounted) setState(() {
          _users = users.map((u) => Map<String, dynamic>.from(u as Map)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<Map<String, dynamic>?> _httpGet(Uri uri) async {
    // Usar dart:html na web ou http no mobile
    // Como não temos o pacote http, usar supabase client com service role
    try {
      final sb = SupabaseClient(_supabaseUrl, _serviceKey);
      final data = await sb.from('profiles').select();
      sb.dispose();
      return null;
    } catch (_) { return null; }
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final email = user['email'] as String? ?? '';
    if (email.isEmpty) return;
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email de reset enviado para $email')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final email = user['email'] as String? ?? '';
    final id    = user['id'] as String? ?? '';
    final ok = await confirmSheet(context,
      title: 'Excluir usuário',
      body: 'Excluir "$email"?\n\nTodos os dados deste usuário serão removidos permanentemente.',
      confirmLabel: 'Excluir');
    if (ok != true) return;
    try {
      final sb = SupabaseClient(_supabaseUrl, _serviceKey);
      await sb.auth.admin.deleteUser(id);
      sb.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário "$email" excluído')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.admin_panel_settings, color: kPurple, size: 20),
          SizedBox(width: 8),
          Text('Painel Administrador', style: TextStyle(fontSize: 16)),
        ]),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: kPurple))
        : _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: kRed, size: 48),
              const SizedBox(height: 12),
              Text('Erro ao carregar usuários', style: const TextStyle(color: kRed)),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 11, color: kMuted), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
            ]))
          : _users.isEmpty
            ? _buildLoadFromSupabase()
            : _buildUserList(),
    );
  }

  Widget _buildLoadFromSupabase() {
    // Buscar direto com SupabaseClient admin
    return FutureBuilder(
      future: _fetchUsersAdmin(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPurple));
        }
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return const EmptyState(icon: Icons.people_outline, message: 'Nenhum usuário encontrado');
        }
        _users = users;
        return _buildUserList();
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUsersAdmin() async {
    try {
      final sb = SupabaseClient(_supabaseUrl, _serviceKey);
      final res = await sb.auth.admin.listUsers();
      sb.dispose();
      return res.map((u) => {
        'id': u.id,
        'email': u.email ?? '',
        'created_at': u.createdAt,
        'last_sign_in_at': u.lastSignInAt,
        'email_confirmed_at': u.emailConfirmedAt,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Widget _buildUserList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUsersAdmin(),
      builder: (ctx, snap) {
        final users = snap.data ?? _users;
        if (snap.connectionState == ConnectionState.waiting && users.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: kPurple));
        }
        return Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Icon(Icons.people, color: kPurple, size: 18),
              const SizedBox(width: 8),
              Text('${users.length} usuário${users.length != 1 ? "s" : ""} cadastrado${users.length != 1 ? "s" : ""}',
                style: const TextStyle(color: kMuted, fontSize: 13)),
            ]),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(child: RefreshIndicator(
            onRefresh: _load,
            color: kPurple,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
              itemCount: users.length,
              itemBuilder: (_, i) {
                final u = users[i];
                final email = u['email'] as String? ?? '';
                final isAdmin = email == _adminEmail;
                final createdAt = u['created_at'] as String? ?? '';
                final lastSignIn = u['last_sign_in_at'] as String? ?? '';

                String formatDate(String iso) {
                  if (iso.isEmpty) return '—';
                  try {
                    final d = DateTime.parse(iso).toLocal();
                    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
                  } catch (_) { return '—'; }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isAdmin ? kPurple.withOpacity(0.15) : kMuted.withOpacity(0.1),
                            shape: BoxShape.circle),
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                            color: isAdmin ? kPurple : kMuted, size: 18)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(email,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis)),
                            if (isAdmin) Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: kPurple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: kPurple.withOpacity(0.4))),
                              child: const Text('Admin', style: TextStyle(fontSize: 10, color: kPurple, fontWeight: FontWeight.w600))),
                          ]),
                          const SizedBox(height: 2),
                          Text('Criado: ${formatDate(createdAt)}  •  Último acesso: ${formatDate(lastSignIn)}',
                            style: const TextStyle(fontSize: 11, color: kMuted)),
                        ])),
                      ]),
                      if (!isAdmin) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => _resetPassword(u),
                            icon: const Icon(Icons.lock_reset, size: 15),
                            label: const Text('Reset senha', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kOrange),
                              foregroundColor: kOrange,
                              padding: const EdgeInsets.symmetric(vertical: 8)),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => _deleteUser(u),
                            icon: const Icon(Icons.delete_outline, size: 15),
                            label: const Text('Excluir', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kRed),
                              foregroundColor: kRed,
                              padding: const EdgeInsets.symmetric(vertical: 8)),
                          )),
                        ]),
                      ],
                    ]),
                  ),
                );
              },
            ),
          )),
        ]);
      },
    );
  }
}
