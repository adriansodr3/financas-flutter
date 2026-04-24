import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'tx_form_sheet.dart';
import 'tx_action_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _year  = DateTime.now().year;
  int _month = DateTime.now().month;

  bool _loading = true;
  List<Transaction> _txs = [];
  double _income = 0, _expense = 0, _fixed = 0, _pending = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await DB.materializeFixed(_year, _month);
      final txs    = await DB.getTransactions(_year, _month);
      final prev   = await DB.getBalanceBefore(_year, _month);
      final fixeds = await DB.getActiveFixed();
      final pend   = await DB.getPendingFromMonth(_year, _month);

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
          _txs     = txs;
          _income  = inc + (prev > 0 ? prev : 0);
          _expense = exp;
          _fixed   = fixedExp;
          _pending = pend;
          _loading = false;
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
      backgroundColor: kBg,
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