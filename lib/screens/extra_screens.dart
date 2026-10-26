import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'admin_screen.dart';
import '../main.dart' show themeNotifier, setTheme;
import '../utils/fullscreen.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/widgets.dart';


// ── reports_screen.dart ───────────────────────────────────

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  void load() { _loadAll(); }

  late TabController _tab;

  // modo mês
  int _year = DateTime.now().year, _month = DateTime.now().month;

  // modo período
  bool _isPeriod = false;
  int _startYear = DateTime.now().year, _startMonth = 1;
  int _endYear   = DateTime.now().year, _endMonth   = DateTime.now().month;

  bool _loading = true;

  // dados
  double _income = 0, _expense = 0, _fixedExp = 0, _varExp = 0, _instExp = 0;
  double _balanceBefore = 0, _investTotal = 0;
  List<Map<String, dynamic>> _catSummary = [];
  List<Map<String, dynamic>> _evolution = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _prev() {
    setState(() { if (_month==1){_year--;_month=12;}else _month--; });
    _loadAll();
  }
  void _next() {
    setState(() { if (_month==12){_year++;_month=1;}else _month++; });
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    late Map<String, double> stats;
    late List<Map<String, dynamic>> catSum;
    late List<Map<String, dynamic>> evol;

    if (_isPeriod) {
      final results = await Future.wait([
        DB.getStatsForPeriod(_startYear, _startMonth, _endYear, _endMonth),
        DB.getSummaryByCategoryForPeriod(_startYear, _startMonth, _endYear, _endMonth),
        DB.getBalanceBefore(_startYear, _startMonth),
        DB.getEvolutionForPeriod(_startYear, _startMonth, _endYear, _endMonth),
        DB.getInvestments(),
      ]);
      stats  = results[0] as Map<String, double>;
      catSum = results[1] as List<Map<String, dynamic>>;
      _balanceBefore = results[2] as double;
      evol   = results[3] as List<Map<String, dynamic>>;
      final invs = results[4] as List<Map<String, dynamic>>;
      double ap=0, rs=0, rd=0;
      for (final i in invs) {
        final amt = (i['amount'] as num).toDouble();
        if (i['type']=='aporte') ap+=amt;
        else if (i['type']=='resgate') rs+=amt;
        else if (i['type']=='rendimento') rd+=amt;
      }
      _investTotal = ap - rs + rd;
    } else {
      final results = await Future.wait([
        DB.getMonthStats(_year, _month),
        DB.getSummaryByCategory(_year, _month),
        DB.getBalanceBefore(_year, _month),
        DB.getEvolution(_year, _month),
        DB.getInvestments(),
      ]);
      stats  = results[0] as Map<String, double>;
      catSum = results[1] as List<Map<String, dynamic>>;
      _balanceBefore = results[2] as double;
      evol   = results[3] as List<Map<String, dynamic>>;
      final invs = results[4] as List<Map<String, dynamic>>;
      double ap=0, rs=0, rd=0;
      for (final i in invs) {
        final amt = (i['amount'] as num).toDouble();
        if (i['type']=='aporte') ap+=amt;
        else if (i['type']=='resgate') rs+=amt;
        else if (i['type']=='rendimento') rd+=amt;
      }
      _investTotal = ap - rs + rd;
    }

    _income   = stats['income']!;
    _expense  = stats['expense']!;
    _fixedExp = stats['fixedExp']!;
    _instExp  = stats['instExp']!;
    _varExp   = stats['varExp']!;
    _catSummary = catSum;
    _evolution  = evol;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showPeriodPicker() async {
    int sy = _startYear, sm = _startMonth, ey = _endYear, em = _endMonth;
    final months = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        Widget _picker(String label, int y, int m,
            void Function(int, int) onChange) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: kMuted, letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(children: [
                // Mês
                IconButton(
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  icon: const Icon(Icons.chevron_left, size: 20, color: kMuted),
                  onPressed: () {
                    int nm = m - 1, ny = y;
                    if (nm <= 0) { nm = 12; ny--; }
                    setSt(() {}); onChange(ny, nm);
                  },
                ),
                Expanded(
                  child: Text('${months[m-1]}/$y',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  icon: const Icon(Icons.chevron_right, size: 20, color: kMuted),
                  onPressed: () {
                    int nm = m + 1, ny = y;
                    if (nm > 12) { nm = 1; ny++; }
                    setSt(() {}); onChange(ny, nm);
                  },
                ),
              ]),
            ),
          ]);
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Selecionar período', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _picker('DE', sy, sm, (ny, nm) => setSt(() { sy = ny; sm = nm; })),
            const SizedBox(height: 14),
            _picker('ATÉ', ey, em, (ny, nm) => setSt(() { ey = ny; em = nm; })),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPurple, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  // garante que De <= Até
                  if (sy > ey || (sy == ey && sm > em)) {
                    final tmp = sy; sy = ey; ey = tmp;
                    final tmpm = sm; sm = em; em = tmpm;
                  }
                  setState(() {
                    _startYear = sy; _startMonth = sm;
                    _endYear   = ey; _endMonth   = em;
                    _isPeriod = true;
                  });
                  Navigator.pop(ctx);
                  _loadAll();
                },
                child: const Text('Aplicar'),
              ),
            ),
          ]),
        );
      }),
    );
  }

  String get _periodLabel {
    final months = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return '${months[_startMonth-1]}/$_startYear – ${months[_endMonth-1]}/$_endYear';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Relatórios', style: TextStyle(fontSize: 16)),
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(97),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Divider(height: 1, color: kBorder),
          // ── Filtro de modo ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(children: [
              _ModeChip(label: 'Mês', active: !_isPeriod, onTap: () {
                if (_isPeriod) setState(() => _isPeriod = false);
                _loadAll();
              }),
              const SizedBox(width: 8),
              _ModeChip(label: 'Período', active: _isPeriod, onTap: _showPeriodPicker),
              if (_isPeriod) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _showPeriodPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kPurple.withOpacity(0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Expanded(child: Text(_periodLabel,
                          style: const TextStyle(fontSize: 12, color: kPurple, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis)),
                        const Icon(Icons.edit_outlined, size: 13, color: kPurple),
                      ]),
                    ),
                  ),
                ),
              ],
            ]),
          ),
          TabBar(
            controller: _tab,
            indicatorColor: kPurple,
            labelColor: kPurple,
            unselectedLabelColor: kMuted,
            tabs: const [
              Tab(text: 'Resumo'),
              Tab(text: 'Categorias'),
              Tab(text: 'Evolução'),
            ],
          ),
        ]),
      ),
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: kPurple))
      : TabBarView(
          controller: _tab,
          children: [
            _ResumoTab(
              year: _year, month: _month,
              onPrev: _isPeriod ? null : _prev,
              onNext: _isPeriod ? null : _next,
              isPeriod: _isPeriod,
              income: _income, expense: _expense,
              fixedExp: _fixedExp, varExp: _varExp, instExp: _instExp,
              balanceBefore: _balanceBefore, investTotal: _investTotal,
              catSummary: _catSummary,
            ),
            _CategoriasTab(
              year: _year, month: _month,
              onPrev: _isPeriod ? null : _prev,
              onNext: _isPeriod ? null : _next,
              isPeriod: _isPeriod,
              catSummary: _catSummary,
              income: _income, expense: _expense,
            ),
            _EvolucaoTab(evolution: _evolution, isPeriod: _isPeriod),
          ],
        ),
  );
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: active ? kPurple : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? kPurple : kBorder),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: active ? Colors.white : kMuted)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Aba Resumo — KPIs + composição das despesas + gargalos
// ─────────────────────────────────────────────────────────────
class _ResumoTab extends StatelessWidget {
  final int year, month;
  final VoidCallback? onPrev, onNext;
  final bool isPeriod;
  final double income, expense, fixedExp, varExp, instExp;
  final double balanceBefore, investTotal;
  final List<Map<String, dynamic>> catSummary;

  const _ResumoTab({
    required this.year, required this.month,
    required this.onPrev, required this.onNext,
    required this.isPeriod,
    required this.income, required this.expense,
    required this.fixedExp, required this.varExp, required this.instExp,
    required this.balanceBefore, required this.investTotal,
    required this.catSummary,
  });

  double get _saldoMes => income - expense;
  double get _saldoAcum => balanceBefore + _saldoMes;
  double get _taxaPoupanca => income > 0 ? (_saldoMes / income * 100) : 0;
  double get _comprometido => income > 0 ? ((fixedExp + instExp) / income * 100) : 0;

  @override
  Widget build(BuildContext context) {
    final positivo = _saldoMes >= 0;
    final topExp = catSummary.where((c) => c['type']=='expense').take(3).toList();

    return RefreshIndicator(
      onRefresh: () async {},
      color: kPurple,
      child: ListView(padding: const EdgeInsets.all(14), children: [
        if (!isPeriod)
          MonthNav(year: year, month: month, onPrev: onPrev!, onNext: onNext!),
        if (!isPeriod) const SizedBox(height: 12),

        // ── Alerta se saldo negativo ──
        if (_saldoMes < 0)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kRed.withOpacity(0.5)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: kRed, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Despesas superaram a receita em ${fmtCurrency(expense - income)}${isPeriod ? " no período." : " neste mês."}',
                style: const TextStyle(color: kRed, fontSize: 12),
              )),
            ]),
          ),

        // ── KPI Cards — linha 1 ──
        Row(children: [
          _KpiCard('Receita', income, kGreen, icon: Icons.arrow_downward_rounded),
          const SizedBox(width: 8),
          _KpiCard('Despesas', expense, kRed, icon: Icons.arrow_upward_rounded),
          const SizedBox(width: 8),
          _KpiCard('Saldo do Mês', _saldoMes, positivo ? kGreen : kRed,
              icon: positivo ? Icons.trending_up : Icons.trending_down),
        ]),
        const SizedBox(height: 8),

        // ── KPI Cards — linha 2 ──
        Row(children: [
          _KpiCard('Saldo Acumulado', _saldoAcum, _saldoAcum >= 0 ? kPurple : kRed,
              icon: Icons.account_balance_wallet_outlined),
          const SizedBox(width: 8),
          _KpiCard('Patrimônio', investTotal, const Color(0xFF0EA5E9),
              icon: Icons.savings_outlined),
          const SizedBox(width: 8),
          _KpiCard('Poupança', null, _taxaPoupanca >= 20 ? kGreen : _taxaPoupanca >= 5 ? kOrange : kRed,
              icon: Icons.percent,
              pct: _taxaPoupanca),
        ]),
        const SizedBox(height: 14),

        // ── Taxa de comprometimento ──
        _SecTitle('Comprometimento da Renda'),
        const SizedBox(height: 8),
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(
                'Fixas + Parcelas comprometem ${_comprometido.toStringAsFixed(1)}% da receita',
                style: const TextStyle(fontSize: 12, color: kMuted),
              )),
              Text(
                fmtCurrency(fixedExp + instExp),
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: _comprometido > 70 ? kRed : _comprometido > 50 ? kOrange : kGreen,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_comprometido / 100).clamp(0.0, 1.0),
                backgroundColor: kBorder,
                valueColor: AlwaysStoppedAnimation(
                  _comprometido > 70 ? kRed : _comprometido > 50 ? kOrange : kGreen),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            if (income > 0) ...[
              _MiniBar('Fixas', fixedExp, income, kRed.withOpacity(0.8)),
              const SizedBox(height: 4),
              _MiniBar('Parcelas', instExp, income, kOrange.withOpacity(0.8)),
              const SizedBox(height: 4),
              _MiniBar('Variáveis', varExp, income, kPurple.withOpacity(0.8)),
            ],
          ]),
        )),
        const SizedBox(height: 14),

        // ── Composição das despesas ──
        if (expense > 0) ...[
          _SecTitle('Composição das Despesas'),
          const SizedBox(height: 8),
          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              _ComposicaoRow('Despesas Fixas', fixedExp, expense, kRed),
              const SizedBox(height: 8),
              _ComposicaoRow('Parcelas', instExp, expense, kOrange),
              const SizedBox(height: 8),
              _ComposicaoRow('Variáveis', varExp, expense, kPurple),
            ]),
          )),
          const SizedBox(height: 14),
        ],

        // ── Maiores gargalos (top 3 categorias de despesa) ──
        if (topExp.isNotEmpty) ...[
          _SecTitle('Maiores Gargalos'),
          const SizedBox(height: 8),
          ...topExp.asMap().entries.map((e) {
            final rank = e.key + 1;
            final cat = e.value;
            final pctRenda = income > 0 ? (cat['total'] as double) / income * 100 : 0.0;
            final pctDesp = expense > 0 ? (cat['total'] as double) / expense * 100 : 0.0;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: [kRed, kOrange, kPurple][e.key].withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('#$rank',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: [kRed, kOrange, kPurple][e.key]),
                  )),
                ),
                title: Text(cat['name'] as String,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${pctDesp.toStringAsFixed(1)}% das despesas'
                  '${income > 0 ? " · ${pctRenda.toStringAsFixed(1)}% da renda" : ""}',
                  style: const TextStyle(fontSize: 11, color: kMuted),
                ),
                trailing: Text(fmtCurrency(cat['total'] as double),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kRed)),
              ),
            );
          }),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Aba Categorias
// ─────────────────────────────────────────────────────────────
class _CategoriasTab extends StatefulWidget {
  final int year, month;
  final VoidCallback? onPrev, onNext;
  final bool isPeriod;
  final List<Map<String, dynamic>> catSummary;
  final double income, expense;

  const _CategoriasTab({
    required this.year, required this.month,
    required this.onPrev, required this.onNext,
    required this.isPeriod,
    required this.catSummary, required this.income, required this.expense,
  });

  @override
  State<_CategoriasTab> createState() => _CategoriasTabState();
}

class _CategoriasTabState extends State<_CategoriasTab> {
  String _showType = 'expense';

  List<Map<String, dynamic>> get _filtered =>
      widget.catSummary.where((s) => s['type'] == _showType).toList();

  double get _total => _showType == 'expense' ? widget.expense : widget.income;

  @override
  Widget build(BuildContext context) {
    final color = _showType == 'expense' ? kRed : kGreen;
    final filtered = _filtered;
    const colors = [kPurple, kGreen, kRed, kOrange,
      Colors.teal, Colors.pink, Colors.amber, Colors.cyan];

    return Column(children: [
      if (!widget.isPeriod)
        MonthNav(year: widget.year, month: widget.month,
            onPrev: widget.onPrev!, onNext: widget.onNext!),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _showType='expense'),
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
            onTap: () => setState(() => _showType='income'),
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
        child: filtered.isEmpty
          ? const EmptyState(icon: Icons.bar_chart_outlined, message: 'Sem dados neste mês')
          : ListView(padding: const EdgeInsets.fromLTRB(12,0,12,12), children: [
              // Pie chart
              if (filtered.length > 1)
                Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Text('Total: ${fmtCurrency(_total)}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
                      child: PieChart(PieChartData(
                        sections: List.generate(filtered.length, (i) {
                          final pct = _total > 0 ? filtered[i]['total'] / _total : 0.0;
                          return PieChartSectionData(
                            value: filtered[i]['total'] as double,
                            title: '${(pct*100).toStringAsFixed(0)}%',
                            color: colors[i % colors.length],
                            radius: 56,
                            titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                          );
                        }),
                        centerSpaceRadius: 38,
                      )),
                    ),
                  ]),
                )),
              const SizedBox(height: 8),
              // Barras por categoria
              ...filtered.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final pct = _total > 0 ? (s['total'] as double) / _total : 0.0;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(child: Text(s['name'] as String,
                            style: const TextStyle(fontSize: 13))),
                        Text(
                          '${(pct*100).toStringAsFixed(1)}%  •  ${fmtCurrency(s["total"] as double)}',
                          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: kBorder,
                          valueColor: AlwaysStoppedAnimation(colors[i % colors.length]),
                          minHeight: 5,
                        ),
                      ),
                    ]),
                  ),
                );
              }),
            ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Aba Evolução — últimos 6 meses
// ─────────────────────────────────────────────────────────────
class _EvolucaoTab extends StatelessWidget {
  final List<Map<String, dynamic>> evolution;
  final bool isPeriod;
  const _EvolucaoTab({required this.evolution, this.isPeriod = false});

  static const _monthNames = ['Jan','Fev','Mar','Abr','Mai','Jun',
                               'Jul','Ago','Set','Out','Nov','Dez'];

  @override
  Widget build(BuildContext context) {
    if (evolution.isEmpty) {
      return const EmptyState(icon: Icons.timeline, message: 'Sem dados de evolução');
    }

    // Calcular máximo para escala do gráfico
    double maxVal = 0;
    for (final m in evolution) {
      final inc = (m['income'] as double);
      final exp = (m['expense'] as double);
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    if (maxVal == 0) maxVal = 1;

    return ListView(padding: const EdgeInsets.all(14), children: [
      // ── Gráfico de barras ──
      _SecTitle('Receita vs Despesa — Últimos 6 Meses'),
      const SizedBox(height: 8),
      Card(child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(children: [
          SizedBox(
            height: 180,
            child: BarChart(BarChartData(
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gi, rod, ri) {
                    final m = evolution[group.x];
                    final label = ri == 0 ? 'Receita' : 'Despesa';
                    final color = ri == 0 ? kGreen : kRed;
                    return BarTooltipItem(
                      '$label\n${fmtCurrency(rod.toY)}',
                      TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, reservedSize: 22,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= evolution.length) return const SizedBox();
                      final mn = (evolution[i]['month'] as int) - 1;
                      return Text(_monthNames[mn], style: const TextStyle(fontSize: 10, color: kMuted));
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: kBorder, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              maxY: maxVal * 1.15,
              barGroups: List.generate(evolution.length, (i) {
                final m = evolution[i];
                return BarChartGroupData(
                  x: i,
                  barsSpace: 3,
                  barRods: [
                    BarChartRodData(
                      toY: (m['income'] as double),
                      color: kGreen.withOpacity(0.85),
                      width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    BarChartRodData(
                      toY: (m['expense'] as double),
                      color: kRed.withOpacity(0.85),
                      width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ],
                );
              }),
            )),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _LegendDot(kGreen, 'Receita'),
            const SizedBox(width: 16),
            _LegendDot(kRed, 'Despesas'),
          ]),
        ]),
      )),
      const SizedBox(height: 14),

      // ── Saldo mensal ──
      _SecTitle('Saldo Líquido por Mês'),
      const SizedBox(height: 8),
      Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          ...evolution.map((m) {
            final saldo = (m['income'] as double) - (m['expense'] as double);
            final mn = (m['month'] as int) - 1;
            final positivo = saldo >= 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(width: 34,
                  child: Text('${_monthNames[mn]}/${(m['year'] as int) % 100}',
                    style: const TextStyle(fontSize: 11, color: kMuted))),
                const SizedBox(width: 8),
                Expanded(child: Stack(children: [
                  Container(height: 18, decoration: BoxDecoration(
                    color: kBorder.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  )),
                  if (positivo && (m['income'] as double) > 0)
                    FractionallySizedBox(
                      widthFactor: (saldo / maxVal).clamp(0.0, 1.0),
                      child: Container(height: 18, decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      )),
                    ),
                  if (!positivo && (m['expense'] as double) > 0)
                    FractionallySizedBox(
                      widthFactor: (-saldo / maxVal).clamp(0.0, 1.0),
                      child: Container(height: 18, decoration: BoxDecoration(
                        color: kRed.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      )),
                    ),
                ])),
                const SizedBox(width: 8),
                Text(fmtCurrency(saldo),
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: positivo ? kGreen : kRed,
                  )),
              ]),
            );
          }),
        ]),
      )),
      const SizedBox(height: 14),

      // ── Tabela resumo ──
      _SecTitle('Tabela Detalhada'),
      const SizedBox(height: 8),
      Card(child: Padding(
        padding: const EdgeInsets.all(2),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(46),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
            3: FlexColumnWidth(),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(8)),
              children: const [
                _TCell('Mês', bold: true),
                _TCell('Receita', bold: true),
                _TCell('Despesa', bold: true),
                _TCell('Saldo', bold: true),
              ],
            ),
            ...evolution.map((m) {
              final saldo = (m['income'] as double) - (m['expense'] as double);
              final mn = (m['month'] as int) - 1;
              return TableRow(children: [
                _TCell('${_monthNames[mn]}'),
                _TCell(fmtCurrency(m['income'] as double), color: kGreen),
                _TCell(fmtCurrency(m['expense'] as double), color: kRed),
                _TCell(fmtCurrency(saldo), color: saldo >= 0 ? kGreen : kRed),
              ]);
            }),
          ],
        ),
      )),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets auxiliares de relatório
// ─────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  final IconData icon;
  final double? pct;

  const _KpiCard(this.label, this.value, this.color,
      {required this.icon, this.pct});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(child: Text(label,
              style: const TextStyle(fontSize: 10, color: kMuted),
              overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              pct != null
                ? '${pct!.toStringAsFixed(1)}%'
                : fmtCurrency(value!),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ]),
      ),
    ),
  );
}

class _SecTitle extends StatelessWidget {
  final String text;
  const _SecTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted,
        letterSpacing: 0.5));
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value, total;
  final Color color;
  const _MiniBar(this.label, this.value, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    return Row(children: [
      SizedBox(width: 70,
        child: Text(label, style: const TextStyle(fontSize: 11, color: kMuted))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: pct.clamp(0.0, 1.0),
          backgroundColor: kBorder,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
        ),
      )),
      const SizedBox(width: 8),
      Text('${(pct*100).toStringAsFixed(0)}%',
        style: const TextStyle(fontSize: 11, color: kMuted)),
    ]);
  }
}

class _ComposicaoRow extends StatelessWidget {
  final String label;
  final double value, total;
  final Color color;
  const _ComposicaoRow(this.label, this.value, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    return Row(children: [
      Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
      Text('${(pct*100).toStringAsFixed(1)}%',
        style: const TextStyle(fontSize: 11, color: kMuted)),
      const SizedBox(width: 8),
      Text(fmtCurrency(value),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: kMuted)),
  ]);
}

class _TCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool bold;
  const _TCell(this.text, {this.color, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    child: Text(text,
      style: TextStyle(
        fontSize: 11,
        color: color ?? kText,
        fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );
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
  State<CategoriesScreen> createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen> {
  void load() { _load(); }
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
            const Text('Nova Categoria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
        appBar: AppBar(title: const Text('Categorias', style: TextStyle(fontSize: 16)), elevation: 0,
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
                  title: Text(c.name, style: const TextStyle(fontSize: 14)),
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

const _adminEmail = 'adriansodre1@gmail.com';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  void refresh() { if (mounted) setState(() {}); }
  final _sb = Supabase.instance.client;
  String get _email => _sb.auth.currentUser?.email ?? '—';
  String? _avatarUrl;
  bool _uploadingAvatar = false;
  bool _isFullscreen = false;
  late final _fsSub = onFullscreenChange.listen((v) {
    if (mounted) setState(() => _isFullscreen = v);
  });

  @override
  void initState() {
    super.initState();
    _isFullscreen = isFullscreen;
    _fsSub; // inicia o listener
    _loadAvatar();
  }

  @override
  void dispose() {
    _fsSub.cancel();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    final url = await DB.getAvatarUrl();
    if (mounted) setState(() => _avatarUrl = url);
  }

  Future<void> _changeAvatar() async {
    final hasPhoto = _avatarUrl != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: kMuted.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Foto de Perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          const Divider(),
          if (hasPhoto) ListTile(
            leading: const Icon(Icons.visibility_outlined, color: kPurple),
            title: const Text('Ver foto atual'),
            onTap: () => Navigator.pop(ctx, 'view'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: kPurple),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: kPurple),
            title: const Text('Tirar foto com câmera'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          if (hasPhoto) ListTile(
            leading: const Icon(Icons.delete_outline, color: kRed),
            title: const Text('Remover foto', style: TextStyle(color: kRed)),
            onTap: () => Navigator.pop(ctx, 'remove'),
          ),
          const SizedBox(height: 8),
        ]),
      )),
    );

    if (choice == 'view' && _avatarUrl != null) {
      if (mounted) showDialog(
        context: context,
        useRootNavigator: true,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(_avatarUrl!, fit: BoxFit.contain))));
      return;
    }

    if (choice == 'remove') {
      setState(() => _avatarUrl = null);
      return;
    }

    ImageSource? source;
    if (choice == 'gallery') source = ImageSource.gallery;
    if (choice == 'camera')  source = ImageSource.camera;
    if (source == null) return;

    try {
      final picker = ImagePicker();
      final file   = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (file == null) return;
      setState(() => _uploadingAvatar = true);
      final bytes = await file.readAsBytes();
      final url   = await DB.uploadAvatar(bytes, 'image/jpeg');
      if (mounted) setState(() { _avatarUrl = url; _uploadingAvatar = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: kRed));
      }
    }
  }

  Future<void> _logout() async {
    final ok = await confirmSheet(context,
        title: 'Sair da conta',
        body: 'Deseja fazer logout?\nSeus dados ficam salvos na nuvem.',
        confirmLabel: 'Sair');
    if (ok == true) await _sb.auth.signOut();
  }

  void _showThemePicker(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => ValueListenableBuilder<String>(
        valueListenable: themeNotifier,
        builder: (_, currentId, __) {
          final darkThemes  = kThemes.where((t) => t.isDark).toList();
          final lightThemes = kThemes.where((t) => !t.isDark).toList();

          Widget themeRow(AppThemeConfig t) {
            final selected = t.id == currentId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () { setTheme(t.id); Navigator.pop(ctx); },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: t.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? t.accent : t.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Mini preview: surface + accent dot
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: t.border),
                        ),
                        child: Center(
                          child: Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(
                              color: t.accent, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.label,
                              style: TextStyle(
                                color: t.text, fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(t.isDark ? 'Escuro' : 'Claro',
                              style: TextStyle(color: t.muted, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle, color: t.accent, size: 22)
                      else
                        Icon(Icons.radio_button_unchecked, color: t.muted, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            builder: (_, scrollCtrl) => Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: kBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Escolher Tema',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 0, 0, 8),
                        child: Text('ESCUROS',
                          style: TextStyle(fontSize: 11, color: kMuted,
                              letterSpacing: 1.1, fontWeight: FontWeight.w600)),
                      ),
                      ...darkThemes.map(themeRow),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 8, 0, 8),
                        child: Text('CLAROS',
                          style: TextStyle(fontSize: 11, color: kMuted,
                              letterSpacing: 1.1, fontWeight: FontWeight.w600)),
                      ),
                      ...lightThemes.map(themeRow),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
            const Text('Alterar Senha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
        appBar: AppBar(title: const Text('Perfil', style: TextStyle(fontSize: 16)), elevation: 0,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: kBorder))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      // Avatar
      Center(child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _changeAvatar,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(alignment: Alignment.bottomRight, children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: kPurple.withOpacity(0.15), shape: BoxShape.circle,
                  border: Border.all(color: kPurple.withOpacity(0.4), width: 2)),
                child: _uploadingAvatar
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: kPurple, strokeWidth: 2))
                  : ClipOval(child: _avatarUrl != null
                      ? Image.network(_avatarUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person_outline, color: kPurple, size: 44))
                      : const Icon(Icons.person_outline, color: kPurple, size: 44)),
              ),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: kPurple, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14)),
            ]),
          ),
        ),
      )),
      const SizedBox(height: 12),
      Center(child: Text(_email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      const SizedBox(height: 4),
      const Center(child: Text('Dados sincronizados na nuvem', style: TextStyle(fontSize: 12, color: kMuted))),
      const SizedBox(height: 32),

      // Ações
      Card(child: Column(children: [
        ListTile(
          leading: const Icon(Icons.lock_outline, color: kPurple),
          title: const Text('Alterar Senha', style: TextStyle()),
          trailing: const Icon(Icons.chevron_right, color: kMuted),
          onTap: _changePassword,
        ),
        const Divider(height: 1, color: kBorder),
        ValueListenableBuilder<String>(
          valueListenable: themeNotifier,
          builder: (_, themeId, __) {
            final cfg = themeById(themeId);
            return ListTile(
              leading: const Icon(Icons.palette_outlined, color: kMuted),
              title: Text('Tema: ${cfg.label}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: cfg.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: kBorder, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: kMuted),
                ],
              ),
              onTap: () => _showThemePicker(context),
            );
          },
        ),
        const Divider(height: 1, color: kBorder),
        ListTile(
          leading: Icon(
            _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: kMuted,
          ),
          title: Text(_isFullscreen ? 'Sair da tela cheia' : 'Tela cheia'),
          trailing: const Icon(Icons.chevron_right, color: kMuted),
          onTap: () { toggleFullscreen(); setState(() => _isFullscreen = !_isFullscreen); },
        ),
        const Divider(height: 1, color: kBorder),
        ListTile(
          leading: const Icon(Icons.info_outline, color: kMuted),
          title: const Text('Versao', style: TextStyle()),
          trailing: const Text('2.0.0', style: TextStyle(color: kMuted)),
        ),
      ])),
      const SizedBox(height: 16),

      // Painel Admin (só aparece para o email administrador)
      if (_email == _adminEmail) ...[
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminScreen())),
          icon: const Icon(Icons.admin_panel_settings),
          label: const Text('Painel Administrador'),
          style: ElevatedButton.styleFrom(backgroundColor: kPurple),
        )),
        const SizedBox(height: 8),
      ],
      // Reset de dados
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: _resetData,
        icon: const Icon(Icons.delete_sweep_outlined, color: kRed),
        label: const Text('Resetar Todos os Dados', style: TextStyle(color: kRed)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kRed),
          foregroundColor: kRed,
        ),
      )),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Sair da Conta'),
        style: ElevatedButton.styleFrom(backgroundColor: kRed),
      )),
    ]),
  );

  Future<void> _resetData() async {
    // Primeira confirmação
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Resetar todos os dados?',
            style: TextStyle(color: kText, fontSize: 17)),
        content: const Text(
          'Isso vai apagar permanentemente todas as suas transações, '
          'despesas fixas, investimentos e categorias personalizadas.\n\n'
          'Esta ação não pode ser desfeita.',
          style: TextStyle(color: kMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: kMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );

    if (first != true || !mounted) return;

    // Segunda confirmação — digitar "RESETAR"
    final confirmCtrl = TextEditingController();
    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: kSurface,
          title: const Text('Confirme o reset',
              style: TextStyle(color: kText, fontSize: 17)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
              'Digite RESETAR abaixo para confirmar:',
              style: TextStyle(color: kMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'RESETAR',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setStateDialog(() {}),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: kMuted)),
            ),
            ElevatedButton(
              onPressed: confirmCtrl.text.trim() == 'RESETAR'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: kRed),
              child: const Text('Resetar tudo'),
            ),
          ],
        ),
      ),
    );

    confirmCtrl.dispose();
    if (second != true || !mounted) return;

    // Executar reset
    setState(() => _uploadingAvatar = true); // reutiliza flag de loading
    try {
      await DB.resetAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos os dados foram resetados.'),
            backgroundColor: kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao resetar: $e'),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }
}
