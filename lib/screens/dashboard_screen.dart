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

class _CategoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> catSummary;
  final double total;

  const _CategoryChart({required this.catSummary, required this.total});

  @override
  Widget build(BuildContext context) {
    if (catSummary.isEmpty || total <= 0) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < catSummary.length; i++) {
      final c = catSummary[i];
      final amt = (c['total'] as num?)?.toDouble() ?? 0.0;
      sections.add(PieChartSectionData(
        value: amt,
        color: _kChartColors[i % _kChartColors.length],
        radius: 28,
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
          const Text('GASTOS POR CATEGORIA',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: PieChart(PieChartData(
                  sections: sections,
                  centerSpaceRadius: 24,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    catSummary.length > 5 ? 5 : catSummary.length,
                    (i) {
                      final c = catSummary[i];
                      final amt = (c['total'] as num?)?.toDouble() ?? 0.0;
                      final pct = total > 0 ? (amt / total * 100) : 0.0;
                      final color = _kChartColors[i % _kChartColors.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Container(width: 8, height: 8,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(
                            c['category_name'] as String? ?? '—',
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          )),
                          Text('${pct.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11, color: kMuted)),
                        ]),
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