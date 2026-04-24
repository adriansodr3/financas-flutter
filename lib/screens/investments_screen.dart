import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

const kInvestColor = Color(0xFF0EA5E9); // azul sky

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});
  @override
  State<InvestmentsScreen> createState() => InvestmentsScreenState();
}

class InvestmentsScreenState extends State<InvestmentsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => _loading = true);
    final items = await DB.getInvestments();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  double get _totalAportes  => _items.where((i) => i['type']=='aporte').fold(0.0, (s,i) => s+(i['amount'] as num).toDouble());
  double get _totalResgates => _items.where((i) => i['type']=='resgate').fold(0.0, (s,i) => s+(i['amount'] as num).toDouble());
  double get _totalRendimentos => _items.where((i) => i['type']=='rendimento').fold(0.0, (s,i) => s+(i['amount'] as num).toDouble());
  double get _patrimonio => _totalAportes - _totalResgates + _totalRendimentos;

  Color _typeColor(String t) {
    switch(t) {
      case 'aporte': return kInvestColor;
      case 'resgate': return kRed;
      case 'rendimento': return kGreen;
      default: return kMuted;
    }
  }
  String _typeLabel(String t) {
    switch(t) {
      case 'aporte': return 'Aporte';
      case 'resgate': return 'Resgate';
      case 'rendimento': return 'Rendimento';
      default: return t;
    }
  }

  Future<void> _add() async {
    String selType = 'aporte';
    final nameCtrl = TextEditingController();
    final amtCtrl  = TextEditingController();
    final notesCtrl = TextEditingController();
    String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24,20,24,40), child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Registrar Movimentacao', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
          const SizedBox(height: 4),
          const Text('O aporte reduz seu saldo e aumenta o patrimônio.\nO resgate faz o inverso.', style: TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 16),
          // Tipo
          Row(children: ['aporte','resgate','rendimento'].map((t) => Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => setSt(() => selType = t),
              child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selType==t ? _typeColor(t).withOpacity(0.15) : kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selType==t ? _typeColor(t) : kBorder)),
                child: Text(_typeLabel(t), textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: selType==t ? _typeColor(t) : kMuted, fontWeight: FontWeight.w600)),
              ),
            ),
          ))).toList()),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome (ex: Tesouro Selic, CDB Nubank)')),
          const SizedBox(height: 12),
          TextField(controller: amtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ ')),
          const SizedBox(height: 12),
          // Data
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(context: ctx,
                initialDate: DateTime.tryParse(dateStr) ?? DateTime.now(),
                firstDate: DateTime(2020), lastDate: DateTime(2035),
                builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: kInvestColor, surface: kSurface)), child: child!));
              if (picked != null) setSt(() => dateStr = DateFormat('yyyy-MM-dd').format(picked));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, color: kMuted, size: 18),
                const SizedBox(width: 10),
                Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr)), style: const TextStyle(color: kText)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Observacoes (opcional)')),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kInvestColor),
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text.replaceAll(',','.'));
              if (amt == null || nameCtrl.text.trim().isEmpty) return;
              await DB.createInvestment(name: nameCtrl.text.trim(), amount: amt, type: selType, date: dateStr, notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim());
              Navigator.pop(ctx); load();
            },
            child: const Text('Registrar'),
          )),
        ]),
      ))));
  }

  @override
  Widget build(BuildContext context) {
    final fmt = (double v) => NumberFormat.currency(locale:'pt_BR', symbol:'R\$').format(v);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kSurface, elevation: 0, title: const Text('Investimentos', style: TextStyle(color: kText, fontSize: 16)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: kBorder))),
      body: _loading ? const Center(child: CircularProgressIndicator(color: kInvestColor)) : Column(children: [
        // Cards de resumo
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Row(children: [
            Expanded(child: _summaryTile('Patrimônio', _patrimonio, kInvestColor)),
            const SizedBox(width: 8),
            Expanded(child: _summaryTile('Aportes', _totalAportes, kInvestColor)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _summaryTile('Resgates', _totalResgates, kRed)),
            const SizedBox(width: 8),
            Expanded(child: _summaryTile('Rendimentos', _totalRendimentos, kGreen)),
          ]),
        ])),
        const Divider(height: 1, color: kBorder),
        Expanded(child: _items.isEmpty
          ? const EmptyState(icon: Icons.savings_outlined, message: 'Nenhum investimento registrado.\nAportes reduzem seu saldo corrente.')
          : RefreshIndicator(onRefresh: load, color: kInvestColor, child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12,8,12,80),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final inv = _items[i];
                final t = inv['type'] as String;
                final color = _typeColor(t);
                return Card(margin: const EdgeInsets.symmetric(vertical: 3), child: ListTile(
                  leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(t=='aporte' ? Icons.arrow_downward : t=='resgate' ? Icons.arrow_upward : Icons.trending_up, color: color, size: 18)),
                  title: Text(inv['name'] as String, style: const TextStyle(fontSize: 14, color: kText)),
                  subtitle: Text('${_typeLabel(t)}  •  ${inv['date']}${inv['notes'] != null ? '  •  ${inv['notes']}' : ''}', style: const TextStyle(fontSize: 11, color: kMuted)),
                  trailing: Text(fmt((inv['amount'] as num).toDouble()), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                ));
              },
          )),
        ),
      ]),
      floatingActionButton: FloatingActionButton(backgroundColor: kInvestColor, onPressed: _add, child: const Icon(Icons.add)),
    );
  }

  Widget _summaryTile(String label, double val, Color color) => Card(child: Padding(
    padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: kMuted, letterSpacing: 0.8)),
      const SizedBox(height: 4),
      Text(NumberFormat.currency(locale:'pt_BR', symbol:'R\$').format(val),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
    ])));
}
