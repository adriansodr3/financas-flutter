import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

const _adminEmail = 'adriansodre1@gmail.com';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(
            icon: Icons.people_outline,
            color: kPurple,
            title: 'Usuários',
            subtitle: 'Ver todos os usuários, resetar senhas e excluir contas',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.storage_outlined,
            color: kGreen,
            title: 'Banco de Dados',
            subtitle: 'Uso do espaço, registros por tabela e capacidade restante',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminDbScreen())),
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.pending_actions_outlined,
            color: kRed,
            title: 'Aprovações Pendentes',
            subtitle: 'Usuários aguardando liberação de acesso ao sistema',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminPendingScreen())),
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.bar_chart_outlined,
            color: kOrange,
            title: 'Estatísticas Gerais',
            subtitle: 'Total de transações, categorias e movimentações no sistema',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminStatsScreen())),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon, required this.color,
    required this.title, required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: kMuted)),
            ])),
            Icon(Icons.chevron_right, color: kMuted),
          ]),
        ),
      ),
    );
  }
}

// ── Tela de Usuários ──────────────────────────────────────

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  final _sb = Supabase.instance.client;

  @override
  void initState() { super.initState(); _load(); }

  Future<dynamic> _call(Map<String, dynamic> body) async {
    final res = await _sb.functions.invoke('admin-users', body: body);
    if (res.status != 200) throw Exception(res.data?['error'] ?? 'Erro ${res.status}');
    return res.data;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _call({'action': 'list'});
      final users = (data['users'] as List? ?? [])
          .map((u) => Map<String, dynamic>.from(u as Map))
          .toList();
      users.sort((a, b) {
        if (a['email'] == _adminEmail) return -1;
        if (b['email'] == _adminEmail) return 1;
        return (b['created_at'] as String).compareTo(a['created_at'] as String);
      });
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _inviteUser() async {
    final emailCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.mail_outline, color: kPurple, size: 22),
          SizedBox(width: 8),
          Text('Convidar usuário'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'O usuário receberá um e-mail com um link para criar a conta no aplicativo.',
            style: TextStyle(fontSize: 13, color: kMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'E-mail do convidado',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: kMuted))),
          ElevatedButton.icon(
            icon: const Icon(Icons.send_outlined, size: 16),
            label: const Text('Enviar convite'),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty || !email.contains('@')) return;
              Navigator.pop(ctx);
              try {
                final result = await _call({'action': 'invite', 'email': email});
                if (result is Map && result['error'] != null) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: ${result["error"]}'), backgroundColor: kRed));
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Convite enviado para $email'), backgroundColor: kGreen));
                  _load();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e'), backgroundColor: kRed));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(Map<String, dynamic> u) async {
    final email = u['email'] as String? ?? '';
    final ok = await confirmSheet(context,
      title: 'Reset de senha',
      body: 'Enviar email de recuperação para "$email"?',
      confirmLabel: 'Enviar', confirmColor: kOrange);
    if (ok != true) return;
    try {
      await _call({'action': 'reset-password', 'email': email});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email enviado para $email')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: kRed));
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> u) async {
    final email = u['email'] as String? ?? '';
    final ok = await confirmSheet(context,
      title: 'Excluir usuário',
      body: 'Excluir "$email"?\nTodos os dados serão removidos permanentemente.',
      confirmLabel: 'Excluir');
    if (ok != true) return;
    try {
      await _call({'action': 'delete', 'userId': u['id']});
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

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return '—'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuários (${_users.length})', style: const TextStyle(fontSize: 16)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Convidar usuário',
            onPressed: _inviteUser,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: kPurple))
        : _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: kRed, size: 48),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: kMuted, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _load,
                icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
            ]))
          : RefreshIndicator(
              onRefresh: _load, color: kPurple,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final email   = u['email'] as String? ?? '';
                  final isAdmin = email == _adminEmail;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 38, height: 38,
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
                            Text('Criado: ${_fmt(u['created_at'])}  •  Último acesso: ${_fmt(u['last_sign_in_at'])}',
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
            ),
    );
  }
}

// ── Tela de Banco de Dados ────────────────────────────────

class AdminDbScreen extends StatefulWidget {
  const AdminDbScreen({super.key});
  @override
  State<AdminDbScreen> createState() => _AdminDbScreenState();
}

class _AdminDbScreenState extends State<AdminDbScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;
  final _sb = Supabase.instance.client;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _sb.functions.invoke('admin-users', body: {'action': 'db-stats'});
      if (mounted) setState(() { _stats = Map<String, dynamic>.from(res.data as Map); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _fmtBytes(num b) {
    if (b < 1024) return '${b.toStringAsFixed(0)} B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banco de Dados', style: TextStyle(fontSize: 16)),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: kGreen))
        : _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: kRed, size: 48),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _load,
                icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
            ]))
          : RefreshIndicator(
              onRefresh: _load, color: kGreen,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                // Card principal de uso
                Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.storage_outlined, color: kGreen, size: 20),
                    SizedBox(width: 8),
                    Text('Uso do Banco', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 16),
                  () {
                    final total = (_stats!['total_bytes'] as num? ?? 0);
                    final limit = (_stats!['limit_bytes'] as num? ?? 524288000);
                    final pct   = (total / limit * 100).clamp(0.0, 100.0);
                    Color c = kGreen;
                    if (pct > 70) c = kOrange;
                    if (pct > 90) c = kRed;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(_fmtBytes(total), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c)),
                        Text('de ${_fmtBytes(limit)}', style: const TextStyle(fontSize: 14, color: kMuted)),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: Theme.of(context).dividerColor,
                          valueColor: AlwaysStoppedAnimation(c),
                          minHeight: 12)),
                      const SizedBox(height: 6),
                      Text('${pct.toStringAsFixed(1)}% utilizado  •  ${_fmtBytes(limit - total)} livre',
                        style: TextStyle(fontSize: 12, color: c)),
                    ]);
                  }(),
                ]))),
                const SizedBox(height: 12),
                // Registros por tabela
                Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Registros por Tabela', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...() {
                    final counts = _stats!['counts'] as Map? ?? {};
                    const labels = {
                      'transactions': ('Transações', Icons.receipt_long_outlined, kPurple),
                      'categories': ('Categorias', Icons.label_outline, kOrange),
                      'fixed_expenses': ('Fixos', Icons.push_pin_outlined, kRed),
                      'installments': ('Parcelamentos', Icons.credit_card_outlined, kGreen),
                      'investments': ('Investimentos', Icons.savings_outlined, Color(0xFF0EA5E9)),
                      'fixed_skipped': ('Fixos pulados', Icons.skip_next_outlined, kMuted),
                    };
                    return counts.entries.map((e) {
                      final info = labels[e.key];
                      final label = info?.$1 ?? e.key;
                      final icon  = info?.$2 ?? Icons.table_chart_outlined;
                      final color = info?.$3 ?? kMuted;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Icon(icon, size: 18, color: color),
                          const SizedBox(width: 10),
                          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
                          Text('${e.value}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                          const SizedBox(width: 4),
                          const Text('registros', style: TextStyle(fontSize: 11, color: kMuted)),
                        ]),
                      );
                    }).toList();
                  }(),
                ]))),
                const SizedBox(height: 12),
                Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                  const Icon(Icons.info_outline, color: kMuted, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Plano Free Supabase: 500 MB de banco de dados',
                    style: TextStyle(fontSize: 12, color: kMuted))),
                ]))),
              ]),
            ),
    );
  }
}

// ── Tela de Estatísticas ──────────────────────────────────

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});
  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  final _sb = Supabase.instance.client;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _sb.functions.invoke('admin-users', body: {'action': 'list'}),
        _sb.functions.invoke('admin-users', body: {'action': 'db-stats'}),
      ]);
      final users  = (results[0].data?['users'] as List? ?? []);
      final stats  = results[1].data as Map? ?? {};
      final counts = stats['counts'] as Map? ?? {};
      if (mounted) setState(() {
        _data = {
          'total_users': users.length,
          'total_transactions': counts['transactions'] ?? 0,
          'total_categories': counts['categories'] ?? 0,
          'total_fixed': counts['fixed_expenses'] ?? 0,
          'total_installments': counts['installments'] ?? 0,
          'total_investments': counts['investments'] ?? 0,
        };
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas Gerais', style: TextStyle(fontSize: 16)),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: kOrange))
        : RefreshIndicator(
            onRefresh: _load, color: kOrange,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              _statCard('Usuários cadastrados', '${_data!['total_users']}',
                Icons.people_outline, kPurple),
              const SizedBox(height: 10),
              _statCard('Total de transações', '${_data!['total_transactions']}',
                Icons.receipt_long_outlined, kGreen),
              const SizedBox(height: 10),
              _statCard('Categorias criadas', '${_data!['total_categories']}',
                Icons.label_outline, kOrange),
              const SizedBox(height: 10),
              _statCard('Gastos fixos ativos', '${_data!['total_fixed']}',
                Icons.push_pin_outlined, kRed),
              const SizedBox(height: 10),
              _statCard('Parcelamentos', '${_data!['total_installments']}',
                Icons.credit_card_outlined, kPurple),
              const SizedBox(height: 10),
              _statCard('Investimentos registrados', '${_data!['total_investments']}',
                Icons.savings_outlined, const Color(0xFF0EA5E9)),
            ]),
          ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: kMuted))),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
      ]),
    ));
  }
}

// ── Tela de Aprovações Pendentes ──────────────────────────

class AdminPendingScreen extends StatefulWidget {
  const AdminPendingScreen({super.key});
  @override
  State<AdminPendingScreen> createState() => _AdminPendingScreenState();
}

class _AdminPendingScreenState extends State<AdminPendingScreen> {
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  final _sb = Supabase.instance.client;

  @override
  void initState() { super.initState(); _load(); }

  Future<dynamic> _call(Map<String, dynamic> body) async {
    final res = await _sb.functions.invoke('admin-users', body: body);
    if (res.status != 200) throw Exception(res.data?['error'] ?? 'Erro');
    return res.data;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _call({'action': 'pending-users'});
      if (mounted) setState(() {
        _pending = List<Map<String, dynamic>>.from(data['users'] as List? ?? []);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> u) async {
    final email = u['email'] as String? ?? '';
    final ok = await confirmSheet(context,
      title: 'Aprovar acesso',
      body: 'Liberar acesso de "$email"?',
      confirmLabel: 'Aprovar',
      confirmColor: kGreen);
    if (ok != true) return;
    try {
      await _call({'action': 'approve', 'userId': u['id']});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$email" aprovado!'), backgroundColor: kGreen));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: kRed));
    }
  }

  Future<void> _reject(Map<String, dynamic> u) async {
    final email = u['email'] as String? ?? '';
    final ok = await confirmSheet(context,
      title: 'Rejeitar cadastro',
      body: "Rejeitar e remover o usuario \"$email\"?\nEle nao podera mais acessar o sistema.",
      confirmLabel: 'Rejeitar');
    if (ok != true) return;
    try {
      await _call({'action': 'reject', 'userId': u['id']});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário rejeitado e removido')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: kRed));
    }
  }

  String _fmt(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2,"0")}/${d.month.toString().padLeft(2,"0")}/${d.year} ${d.hour.toString().padLeft(2,"0")}:${d.minute.toString().padLeft(2,"0")}';
    } catch (_) { return '—'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pendentes (${_pending.length})', style: const TextStyle(fontSize: 16)),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: kRed))
        : _pending.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.check_circle_outline, color: kGreen, size: 56),
              SizedBox(height: 12),
              Text('Nenhum cadastro pendente', style: TextStyle(color: kMuted, fontSize: 14)),
            ]))
          : RefreshIndicator(
              onRefresh: _load, color: kRed,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
                itemCount: _pending.length,
                itemBuilder: (_, i) {
                  final u = _pending[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 38, height: 38,
                            decoration: BoxDecoration(color: kOrange.withOpacity(0.12), shape: BoxShape.circle),
                            child: const Icon(Icons.person_outline, color: kOrange, size: 20)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(u['email'] as String? ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Cadastrado em: ${_fmt(u["created_at"])}', style: const TextStyle(fontSize: 11, color: kMuted)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: kOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: kOrange.withOpacity(0.4))),
                            child: const Text('Pendente', style: TextStyle(fontSize: 10, color: kOrange, fontWeight: FontWeight.w600))),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: ElevatedButton.icon(
                            onPressed: () => _approve(u),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Aprovar'),
                            style: ElevatedButton.styleFrom(backgroundColor: kGreen, padding: const EdgeInsets.symmetric(vertical: 10)),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => _reject(u),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Rejeitar'),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: kRed), foregroundColor: kRed, padding: const EdgeInsets.symmetric(vertical: 10)),
                          )),
                        ]),
                      ]),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
