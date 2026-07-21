import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

const _adminEmail = 'adriansodre1@gmail.com';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _dbStats;
  bool _loading = true;
  String? _error;

  final _sb = Supabase.instance.client;

  @override
  void initState() { super.initState(); _load(); }

  Future<dynamic> _callAdmin(Map<String, dynamic> body) async {
    final res = await _sb.functions.invoke(
      'admin-users',
      body: body,
    );
    if (res.status != 200) {
      throw Exception(res.data?['error'] ?? 'Erro ${res.status}');
    }
    return res.data;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _callAdmin({'action': 'list'}),
        _callAdmin({'action': 'db-stats'}),
      ]);
      final data = results[0];
      final dbStats = results[1] as Map<String, dynamic>?;
      final users = (data['users'] as List? ?? [])
          .map((u) => Map<String, dynamic>.from(u as Map))
          .toList();
      // Ordenar: admin primeiro, depois por data de criação
      users.sort((a, b) {
        if (a['email'] == _adminEmail) return -1;
        if (b['email'] == _adminEmail) return 1;
        return (b['created_at'] as String).compareTo(a['created_at'] as String);
      });
      if (mounted) setState(() { _users = users; _dbStats = dbStats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final email = user['email'] as String? ?? '';
    final ok = await confirmSheet(context,
      title: 'Reset de senha',
      body: 'Enviar email de recuperação para "$email"?',
      confirmLabel: 'Enviar',
      confirmColor: kOrange);
    if (ok != true) return;
    try {
      await _callAdmin({'action': 'reset-password', 'email': email});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email enviado para $email')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: kRed));
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
      await _callAdmin({'action': 'delete', 'userId': id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário "$email" excluído')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: kRed));
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return '—'; }
  }

  String _fmtBytes(num bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildDbStats() {
    final total   = (_dbStats!['total_bytes'] as num? ?? 0);
    final limit   = (_dbStats!['limit_bytes'] as num? ?? 524288000);
    final pct     = (total / limit * 100).clamp(0, 100);
    final counts  = _dbStats!['counts'] as Map? ?? {};

    Color barColor = kGreen;
    if (pct > 70) barColor = kOrange;
    if (pct > 90) barColor = kRed;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.storage_outlined, color: kPurple, size: 18),
          const SizedBox(width: 8),
          const Text('Banco de Dados', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${pct.toStringAsFixed(1)}% usado',
              style: TextStyle(fontSize: 12, color: barColor, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 8)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_fmtBytes(total), style: TextStyle(fontSize: 12, color: barColor, fontWeight: FontWeight.w500)),
          Text('/ ${_fmtBytes(limit)} (Free tier)', style: const TextStyle(fontSize: 12, color: kMuted)),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 6, children: [
          for (final entry in counts.entries)
            _statChip(entry.key, entry.value as int),
        ]),
      ]),
    );
  }

  Widget _statChip(String table, int count) {
    const icons = {
      'transactions': Icons.receipt_long_outlined,
      'categories': Icons.label_outline,
      'fixed_expenses': Icons.push_pin_outlined,
      'installments': Icons.credit_card_outlined,
      'investments': Icons.savings_outlined,
      'fixed_skipped': Icons.skip_next_outlined,
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icons[table] ?? Icons.table_chart_outlined, size: 13, color: kMuted),
      const SizedBox(width: 4),
      Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(width: 2),
      Text(table.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, color: kMuted)),
    ]);
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
              const Text('Erro ao carregar usuários'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error!, style: const TextStyle(fontSize: 11, color: kMuted),
                    textAlign: TextAlign.center)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente')),
            ]))
          : Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.people, color: kPurple, size: 18),
                  const SizedBox(width: 8),
                  Text('${_users.length} usuário${_users.length != 1 ? "s" : ""} cadastrado${_users.length != 1 ? "s" : ""}',
                      style: const TextStyle(color: kMuted, fontSize: 13)),
                ]),
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              Expanded(child: RefreshIndicator(
                onRefresh: _load, color: kPurple,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    final email    = u['email'] as String? ?? '';
                    final isAdmin  = email == _adminEmail;
                    final created  = _formatDate(u['created_at'] as String?);
                    final lastSign = _formatDate(u['last_sign_in_at'] as String?);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: isAdmin ? kPurple.withOpacity(0.15) : kMuted.withOpacity(0.1),
                                shape: BoxShape.circle),
                              child: Icon(
                                isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                                color: isAdmin ? kPurple : kMuted, size: 20)),
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
                                  child: const Text('Admin',
                                      style: TextStyle(fontSize: 10, color: kPurple, fontWeight: FontWeight.w600))),
                              ]),
                              const SizedBox(height: 2),
                              Text('Criado: $created  •  Último acesso: $lastSign',
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
            ]),
    );
  }
}
