import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/widgets.dart';


// ── reports_screen.dart ───────────────────────────────────

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _year = DateTime.now().year, _month = DateTime.now().month;
  String _showType = 'expense';
  List<Map<String, dynamic>> _summary = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await DB.getSummaryByCategory(_year, _month);
    if (mounted) setState(() { _summary = s; _loading = false; });
  }

  void _prev() { setState(() { if (_month==1){_year--;_month=12;}else _month--; }); _load(); }
  void _next() { setState(() { if (_month==12){_year++;_month=1;}else _month++; }); _load(); }

  List<Map<String, dynamic>> get _filtered =>
      _summary.where((s) => s['type'] == _showType).toList();

  double get _total => _filtered.fold(0.0, (s, r) => s + (r['total'] as double));

  @override
  Widget build(BuildContext context) {
    final color = _showType == 'expense' ? kRed : kGreen;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        MonthNav(year: _year, month: _month, onPrev: _prev, onNext: _next),
        // Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () { setState(() => _showType='expense'); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showType=='expense' ? kRed.withOpacity(0.15) : kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _showType=='expense' ? kRed : kBorder),
                ),
                child: Text('Despesas', textAlign: TextAlign.center,
                    style: TextStyle(color: _showType=='expense'?kRed:kMuted, fontWeight: FontWeight.w600)),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: () { setState(() => _showType='income'); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showType=='income' ? kGreen.withOpacity(0.15) : kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _showType=='income' ? kGreen : kBorder),
                ),
                child: Text('Entradas', textAlign: TextAlign.center,
                    style: TextStyle(color: _showType=='income'?kGreen:kMuted, fontWeight: FontWeight.w600)),
              ),
            )),
          ]),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: kPurple))
            : filtered.isEmpty
              ? const EmptyState(icon: Icons.bar_chart_outlined, message: 'Sem dados neste mes')
              : RefreshIndicator(
                  onRefresh: _load, color: kPurple,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      // Gráfico de pizza
                      if (filtered.length > 1)
                        Card(child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            Text('Total: ${fmtCurrency(_total)}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180,
                              child: PieChart(PieChartData(
                                sections: List.generate(filtered.length, (i) {
                                  final pct = filtered[i]['total'] / _total;
                                  final colors = [kPurple, kGreen, kRed, kOrange,
                                    Colors.teal, Colors.pink, Colors.amber, Colors.cyan];
                                  return PieChartSectionData(
                                    value: filtered[i]['total'] as double,
                                    title: '${(pct*100).toStringAsFixed(0)}%',
                                    color: colors[i % colors.length],
                                    radius: 60, titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
                                  );
                                }),
                                centerSpaceRadius: 40,
                              )),
                            ),
                          ]),
                        )),
                      const SizedBox(height: 8),
                      // Barras por categoria
                      ...filtered.map((s) {
                        final pct = _total > 0 ? s['total'] / _total : 0.0;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(s['name'] as String,
                                    style: const TextStyle(fontSize: 13, color: kText))),
                                Text('${(pct*100).toStringAsFixed(1)}%  •  ${fmtCurrency(s["total"] as double)}',
                                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct.toDouble(),
                                  backgroundColor: kBorder,
                                  valueColor: AlwaysStoppedAnimation(color),
                                  minHeight: 6,
                                ),
                              ),
                            ]),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),
      ]),
    );
  }
}


// ── categories_screen.dart ────────────────────────────────

const _kIcons = <String, IconData>{
  'home': Icons.home_outlined,
  'restaurant': Icons.restaurant_outlined,
  'directions_car': Icons.directions_car_outlined,
  'favorite': Icons.favorite_outline,
  'school': Icons.school_outlined,
  'celebration': Icons.celebration_outlined,
  'receipt_long': Icons.receipt_long_outlined,
  'work': Icons.work_outline,
  'computer': Icons.computer_outlined,
  'add_circle': Icons.add_circle_outline,
  'checkroom': Icons.checkroom_outlined,
  'attach_money': Icons.attach_money,
  'trending_up': Icons.trending_up,
  'fitness_center': Icons.fitness_center_outlined,
  'music_note': Icons.music_note_outlined,
  'local_cafe': Icons.local_cafe_outlined,
  'sports_bar': Icons.sports_bar_outlined,
  'local_pharmacy': Icons.local_pharmacy_outlined,
  'child_care': Icons.child_care_outlined,
  'flight': Icons.flight_outlined,
  'smartphone': Icons.smartphone_outlined,
  'pets': Icons.pets_outlined,
  'local_gas_station': Icons.local_gas_station_outlined,
  'local_hospital': Icons.local_hospital_outlined,
  'lightbulb': Icons.lightbulb_outline,
  'card_giftcard': Icons.card_giftcard_outlined,
  'fastfood': Icons.fastfood_outlined,
  'key': Icons.key_outlined,
  'sports_esports': Icons.sports_esports_outlined,
  'more_horiz': Icons.more_horiz,
};

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _cats = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cats = await DB.getCategories();
    if (mounted) setState(() { _cats = cats; _loading = false; });
  }

  Future<void> _add() async {
    String selType = 'expense';
    String selIcon = 'more_horiz';
    final nameCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24,20,24,40),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Nova Categoria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 12),
            // Tipo
            Row(children: ['expense','income'].map((t) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => setSt(()=>selType=t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selType==t ? (t=='expense'?kRed:kGreen).withOpacity(0.15) : kCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selType==t ? (t=='expense'?kRed:kGreen) : kBorder),
                  ),
                  child: Text(t=='expense'?'Despesa':'Entrada', textAlign: TextAlign.center,
                      style: TextStyle(color: selType==t?(t=='expense'?kRed:kGreen):kMuted, fontWeight: FontWeight.w600)),
                ),
              ),
            ))).toList()),
            const SizedBox(height: 16),
            const Text('Icone', style: TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 8),
            SizedBox(height: 200, child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _kIcons.length,
              itemBuilder: (_, i) {
                final key = _kIcons.keys.elementAt(i);
                final ico = _kIcons[key]!;
                final sel = selIcon == key;
                return GestureDetector(
                  onTap: () => setSt(()=>selIcon=key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: sel ? kPurple.withOpacity(0.15) : kCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? kPurple : kBorder),
                    ),
                    child: Icon(ico, color: sel ? kPurple : kMuted, size: 22),
                  ),
                );
              },
            )),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await DB.createCategory(nameCtrl.text.trim(), selType, selIcon);
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Salvar'),
            )),
          ]),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(backgroundColor: kSurface, title: const Text('Categorias', style: TextStyle(color: kText, fontSize: 16)), elevation: 0,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: kBorder))),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: kPurple))
      : _cats.isEmpty
        ? const EmptyState(icon: Icons.label_outline, message: 'Nenhuma categoria')
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12,8,12,80),
            itemCount: _cats.length,
            itemBuilder: (_, i) {
              final c = _cats[i];
              final isInc = c.type=='income';
              final color = isInc ? kGreen : kRed;
              final ico = _kIcons[c.icon] ?? Icons.more_horiz;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(ico, color: color, size: 20),
                  ),
                  title: Text(c.name, style: const TextStyle(fontSize: 14, color: kText)),
                  subtitle: Text(isInc ? 'Entrada' : 'Despesa', style: const TextStyle(fontSize: 12, color: kMuted)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: kMuted),
                    onPressed: () async {
                      final ok = await confirmSheet(context,
                          title: 'Excluir "${c.name}"',
                          body: 'Lancamentos existentes nao serao afetados.',
                          confirmLabel: 'Excluir');
                      if (ok == true) { await DB.deleteCategory(c.id); _load(); }
                    },
                  ),
                ),
              );
            },
          ),
    floatingActionButton: FloatingActionButton(backgroundColor: kPurple, onPressed: _add, child: const Icon(Icons.add)),
  );
}


// ── profile_screen.dart ───────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _sb = Supabase.instance.client;
  String get _email => _sb.auth.currentUser?.email ?? '—';

  Future<void> _logout() async {
    final ok = await confirmSheet(context,
        title: 'Sair da conta',
        body: 'Deseja fazer logout?\nSeus dados ficam salvos na nuvem.',
        confirmLabel: 'Sair');
    if (ok == true) await _sb.auth.signOut();
  }

  Future<void> _changePassword() async {
    final ctrl = TextEditingController();
    final ctrl2 = TextEditingController();
    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24,20,24,40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Alterar Senha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
            const SizedBox(height: 16),
            TextField(controller: ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'Nova senha')),
            const SizedBox(height: 12),
            TextField(controller: ctrl2, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar nova senha')),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                if (ctrl.text != ctrl2.text || ctrl.text.length < 6) return;
                await _sb.auth.updateUser(UserAttributes(password: ctrl.text));
                Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Senha alterada!')));
              },
              child: const Text('Salvar'),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(backgroundColor: kSurface, title: const Text('Perfil', style: TextStyle(color: kText, fontSize: 16)), elevation: 0,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: kBorder))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      // Avatar
      Center(child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: kPurple.withOpacity(0.15), shape: BoxShape.circle,
          border: Border.all(color: kPurple.withOpacity(0.4), width: 2)),
        child: const Icon(Icons.person_outline, color: kPurple, size: 40),
      )),
      const SizedBox(height: 12),
      Center(child: Text(_email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kText))),
      const SizedBox(height: 4),
      const Center(child: Text('Dados sincronizados na nuvem', style: TextStyle(fontSize: 12, color: kMuted))),
      const SizedBox(height: 32),

      // Ações
      Card(child: Column(children: [
        ListTile(
          leading: const Icon(Icons.lock_outline, color: kPurple),
          title: const Text('Alterar Senha', style: TextStyle(color: kText)),
          trailing: const Icon(Icons.chevron_right, color: kMuted),
          onTap: _changePassword,
        ),
        const Divider(height: 1, color: kBorder),
        ListTile(
          leading: const Icon(Icons.info_outline, color: kMuted),
          title: const Text('Versao', style: TextStyle(color: kText)),
          trailing: const Text('2.0.0', style: TextStyle(color: kMuted)),
        ),
      ])),
      const SizedBox(height: 16),

      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Sair da Conta'),
        style: ElevatedButton.styleFrom(backgroundColor: kRed),
      )),
    ]),
  );
}
