import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'tx_form_sheet.dart';
import 'tx_action_sheet.dart';

const _kChartColors = [
  Color(0xFF6366F1), // purple
  Color(0xFF22C55E), // green
  Color(0xFFEF4444), // red
  Color(0xFFF97316), // orange
  Color(0xFF14B8A6), // teal
  Color(0xFFEC4899), // pink
  Color(0xFFF59E0B), // amber
  Color(0xFF06B6D4), // cyan
];

class _CategoryChart extends StatefulWidget {
  final List<Map<String, dynamic>> catSummary;
  final List<Transaction> txs;
  final double total;

  const _CategoryChart({
    required this.catSummary,
    required this.txs,
    required this.total,
  });

  @override
  State<_CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<_CategoryChart> {
  int _touched = -1;

  void _onSectionTap(int index) {
    if (index < 0 || index >= widget.catSummary.length) return;
    final cat = widget.catSummary[index];
    final catName = cat['name'] as String? ?? 'Sem categoria';
    final color = _kChartColors[index % _kChartColors.length];
    final catTxs = widget.txs
        .where((t) => t.type == 'expense' && (t.categoryName ?? 'Sem categoria') == catName)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final total = (cat['total'] as num?)?.toDouble() ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        minChildSize: 0.3,
        builder: (_, ctrl) => Column(children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Row(children: [
              Container(width: 12, height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(catName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmtCurrency(total),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kRed)),
                Text('${catTxs.length} lançamento${catTxs.length == 1 ? "" : "s"}',
                  style: const TextStyle(fontSize: 11, color: kMuted)),
              ]),
            ]),
          ),
          Divider(height: 1, color: kBorder),
          // Lista
          Expanded(
            child: catTxs.isEmpty
              ? const Center(child: Text('Nenhum lançamento', style: TextStyle(color: kMuted)))
              : ListView.separated(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: catTxs.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: kBorder, indent: 16, endIndent: 16),
                  itemBuilder: (_, i) {
                    final t = catTxs[i];
                    return ListTile(
                      dense: true,
                      title: Text(t.description ?? '—', style: const TextStyle(fontSize: 13)),
                      subtitle: Text(fmtDate(t.date), style: const TextStyle(fontSize: 11, color: kMuted)),
                      trailing: Text(fmtCurrency(t.amount),
                        style: const TextStyle(fontSize: 13, color: kRed, fontWeight: FontWeight.w600)),
                    );
                  },
                ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.catSummary.isEmpty || widget.total <= 0) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < widget.catSummary.length; i++) {
      final c = widget.catSummary[i];
      final amt = (c['total'] as num?)?.toDouble() ?? 0.0;
      final isTouched = i == _touched;
      sections.add(PieChartSectionData(
        value: amt,
        color: _kChartColors[i % _kChartColors.length],
        radius: isTouched ? 36 : 28,
        title: '',
        showTitle: false,
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('GASTOS POR CATEGORIA',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.8)),
            const Spacer(),
            const Text('toque para detalhar',
                style: TextStyle(fontSize: 10, color: kMuted)),
            const SizedBox(width: 4),
            const Icon(Icons.touch_app_outlined, size: 13, color: kMuted),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 110,
                width: 110,
                child: PieChart(PieChartData(
                  sections: sections,
                  centerSpaceRadius: 24,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent) {
                        final idx = response?.touchedSection?.touchedSectionIndex ?? -1;
                        setState(() => _touched = idx);
                        if (idx >= 0) _onSectionTap(idx);
                      }
                    },
                  ),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    widget.catSummary.length > 5 ? 5 : widget.catSummary.length,
                    (i) {
                      final c = widget.catSummary[i];
                      final amt = (c['total'] as num?)?.toDouble() ?? 0.0;
                      final pct = widget.total > 0 ? (amt / widget.total * 100) : 0.0;
                      final color = _kChartColors[i % _kChartColors.length];
                      final isSelected = i == _touched;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _touched = i);
                          _onSectionTap(i);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(children: [
                            Container(width: 8, height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(
                              c['name'] as String? ?? '—',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )),
                            Text('${pct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? color : kMuted,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                )),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  void load() { _load(); }
  int _year  = DateTime.now().year;
  int _month = DateTime.now().month;

  bool _loading = true;
  List<Transaction> _txs = [];
  double _income = 0, _expense = 0, _fixed = 0, _pending = 0;
  List<Map<String, dynamic>> _catSummary = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await DB.materializeFixed(_year, _month);
      final results = await Future.wait([
        DB.getTransactions(_year, _month),
        DB.getBalanceBefore(_year, _month),
        DB.getActiveFixed(),
        DB.getPendingFromMonth(_year, _month),
        DB.getSummaryByCategory(_year, _month),
      ]);
      final txs    = results[0] as List<Transaction>;
      final prev   = results[1] as double;
      final fixeds = results[2] as List<FixedExpense>;
      final pend   = results[3] as double;
      final catSum = results[4] as List<Map<String, dynamic>>;

      double inc = 0, exp = 0;
      for (final t in txs) {
        if (t.type == 'income') inc += t.amount;
        else exp += t.amount;
      }
      final fixedExp = fixeds
          .where((f) => f.type == 'expense')
          .fold(0.0, (s, f) => s + f.amount);

      if (mounted) {
        setState(() {
          _txs        = txs;
          _income     = inc + (prev > 0 ? prev : 0);
          _expense    = exp;
          _fixed      = fixedExp;
          _pending    = pend;
          _catSummary = catSum;
          _loading    = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) { _year--; _month = 12; }
      else _month--;
    });
    _load();
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) { _year++; _month = 1; }
      else _month++;
    });
    _load();
  }

  void _today() {
    final now = DateTime.now();
    setState(() { _year = now.year; _month = now.month; });
    _load();
  }

  Future<void> _openTxForm(String type) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TxFormSheet(type: type, year: _year, month: _month),
    );
    if (ok == true) _load();
  }

  Future<void> _onTxTap(Transaction tx) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TxActionSheet(tx: tx, year: _year, month: _month),
    );
    if (ok == true) _load();
  }

  double get _saldo => _income - _expense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            body: Column(
          children: [
            MonthNav(
              year: _year, month: _month,
              onPrev: _prevMonth,
              onNext: _nextMonth,
              onToday: _today,
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPurple))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: kPurple,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(children: [
                            Expanded(child: SummaryCard(
                                label: 'ENTRADAS + SALDO ANT.', value: _income, color: kGreen)),
                            const SizedBox(width: 8),
                            Expanded(child: SummaryCard(
                                label: 'SAIDAS DO MES', value: _expense, color: kRed)),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: SummaryCard(
                                label: 'SALDO', value: _saldo,
                                color: _saldo >= 0 ? kGreen : kRed)),
                            const SizedBox(width: 8),
                            Expanded(child: SummaryCard(
                                label: 'FIXOS', value: _fixed, color: kRed)),
                            const SizedBox(width: 8),
                            Expanded(child: SummaryCard(
                                label: 'FALTA PAGAR', value: _pending, color: kOrange)),
                          ]),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openTxForm('income'),
                                icon: const Icon(Icons.arrow_upward, size: 16),
                                label: const Text('Entrada'),
                                style: ElevatedButton.styleFrom(backgroundColor: kGreen),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openTxForm('expense'),
                                icon: const Icon(Icons.arrow_downward, size: 16),
                                label: const Text('Despesa'),
                                style: ElevatedButton.styleFrom(backgroundColor: kRed),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          if (_catSummary.any((c) => c['type'] == 'expense'))
                            _CategoryChart(
                              catSummary: _catSummary
                                .where((c) => c['type'] == 'expense')
                                .toList(),
                              txs: _txs,
                              total: _expense,
                            ),
                          if (_catSummary.any((c) => c['type'] == 'expense'))
                            const SizedBox(height: 8),
                          const SectionHeader('Lancamentos'),
                          if (_txs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: EmptyState(
                                icon: Icons.receipt_long_outlined,
                                message: 'Nenhum lancamento neste mes.\nToque em Entrada ou Despesa para adicionar.',
                              ),
                            )
                          else
                            ...List.generate(_txs.length, (i) =>
                                TxTile(tx: _txs[i], onTap: () => _onTxTap(_txs[i]))),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
      ),
    );
  }
}