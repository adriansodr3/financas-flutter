// ── transactions_screen.dart ──────────────────────────────
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../widgets/category_picker.dart';
import 'tx_form_sheet.dart';
import 'tx_action_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  void load() { _load(); }
  int _year = DateTime.now().year, _month = DateTime.now().month;
  List<Transaction> _txs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    await DB.materializeFixed(_year, _month);
    final txs = await DB.getTransactions(_year, _month);
    if (mounted) setState(() { _txs = txs; _loading = false; });
  }

  void _prev() { setState(() { if (_month==1){_year--;_month=12;}else _month--; }); _load(); }
  void _next() { setState(() { if (_month==12){_year++;_month=1;}else _month++; }); _load(); }
  void _today(){ final n=DateTime.now(); setState((){_year=n.year;_month=n.month;}); _load(); }

  Future<void> _openForm(String type) async {
    final ok = await showModalBottomSheet<bool>(
        context: context, isScrollControlled: true,
        builder: (_) => TxFormSheet(type: type, year: _year, month: _month));
    if (ok == true) _load();
  }

  Future<void> _onTap(Transaction tx) async {
    final ok = await showModalBottomSheet<bool>(
        context: context, isScrollControlled: true,
        builder: (_) => TxActionSheet(tx: tx, year: _year, month: _month));
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: Column(children: [
      MonthNav(year: _year, month: _month, onPrev: _prev, onNext: _next, onToday: _today),
      Expanded(
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: kPurple))
          : _txs.isEmpty
            ? const EmptyState(icon: Icons.receipt_long_outlined, message: 'Nenhum lancamento neste mes')
            : RefreshIndicator(
                onRefresh: _load, color: kPurple,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: _txs.length,
                  itemBuilder: (_, i) => TxTile(tx: _txs[i], onTap: () => _onTap(_txs[i])),
                ),
              ),
      ),
    ]),
    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'fab_inc',
          backgroundColor: kGreen,
          onPressed: () => _openForm('income'),
          child: const Icon(Icons.arrow_upward, color: Colors.white),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'fab_exp',
          backgroundColor: kRed,
          onPressed: () => _openForm('expense'),
          child: const Icon(Icons.arrow_downward, color: Colors.white),
        ),
      ],
    ),
  );
}



class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});
  @override
  State<InstallmentsScreen> createState() => InstallmentsScreenState();
}

class InstallmentsScreenState extends State<InstallmentsScreen> {
  void load() { _load(); }
  List<Installment> _items = [];
  bool _loading = true;
  Installment? _undoInst;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await DB.getInstallments();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _settle(Installment inst) async {
    final pp = await DB.getInstallmentPaidPending(inst.id);
    final total = (pp['paid']! + pp['pending']!);
    final ok = await confirmSheet(
      context,
      title: 'Quitar "${inst.description}"',
      body: 'Sera lancada uma despesa de ${fmtCurrency(total)} hoje.\n\nPago: ${fmtCurrency(pp["paid"]!)}\nFalta: ${fmtCurrency(pp["pending"]!)}',
      confirmLabel: 'Quitar',
      confirmColor: kGreen,
    );
    if (ok != true) return;
    final settled = await DB.settleInstallment(inst);
    setState(() { _undoInst = inst; });
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('"${inst.description}" quitado — ${fmtCurrency(settled)}'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: _undo,
        ),
        duration: const Duration(seconds: 8),
      ));
    }
  }

  Future<void> _undo() async {
    if (_undoInst == null) return;
    // Recriar parcelamento (sem parcelas passadas - simplificado)
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Para desfazer, crie o parcelamento novamente com as parcelas restantes.')));
    setState(() => _undoInst = null);
  }

  Future<void> _editInstallment(Installment inst) async {
    final descCtrl = TextEditingController(text: inst.description);
    Category? selCat;

    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Editar Parcelamento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
            const SizedBox(height: 6),
            Text('${inst.totalParcelas}x de ${fmtCurrency(inst.installmentAmount)}',
                style: const TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 16),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descricao')),
            const SizedBox(height: 12),
            CategorySelector(
              type: 'expense',
              initial: null,
              onChanged: (c) => selCat = c,
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                if (descCtrl.text.trim().isEmpty) return;
                await DB.editInstallment(
                  instId: inst.id,
                  description: descCtrl.text.trim(),
                  categoryId: selCat?.id ?? inst.categoryId,
                );
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Salvar'),
            )),
          ]),
        ),
      ),
    );
  }


  Future<void> _addInstallment() async {
    List<Category> cats = await DB.getCategories(type: 'expense');
    Category? selCat = cats.isNotEmpty ? cats.first : null;
    final descCtrl  = TextEditingController();
    final totalCtrl = TextEditingController();
    final parcCtrl  = TextEditingController();
    final dateCtrl  = TextEditingController(text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,"0")}-01');

    final ok = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24,20,24,40),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Novo Parcelamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
            const SizedBox(height: 16),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descricao (ex: Notebook)')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: totalCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor total', prefixText: 'R\$ '))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: parcCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Parcelas'))),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              readOnly: true,
              onTap: () async {
                final initial = DateTime.tryParse(dateCtrl.text) ?? DateTime.now();
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: initial,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: kPurple, surface: kSurface)),
                    child: child!),
                );
                if (picked != null) {
                  dateCtrl.text = '\${picked.year}-\${picked.month.toString().padLeft(2,"0")}-01';
                }
              },
              decoration: const InputDecoration(
                labelText: 'Inicio',
                prefixIcon: Icon(Icons.calendar_today_outlined, color: kMuted),
                suffixIcon: Icon(Icons.edit_calendar_outlined, color: kMuted),
              ),
            ),
            const SizedBox(height: 12),
            CategorySelector(
              type: 'expense',
              
              onChanged: (c) { selCat = c; },
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                final total = double.tryParse(totalCtrl.text.replaceAll(',','.'));
                final n     = int.tryParse(parcCtrl.text);
                if (total==null || n==null || n<1 || descCtrl.text.trim().isEmpty) return;
                await DB.createInstallment(
                  description: descCtrl.text.trim(),
                  totalAmount: total, nParcelas: n,
                  startDate: dateCtrl.text.trim(),
                  categoryId: selCat?.id,
                );
                Navigator.pop(ctx, true);
              },
              child: const Text('Lancar'),
            )),
          ]),
        ),
      )),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(backgroundColor: kSurface, title: const Text('Parcelamentos', style: TextStyle(color: kText, fontSize: 16)), elevation: 0,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: kBorder))),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: kPurple))
      : _items.isEmpty
        ? const EmptyState(icon: Icons.credit_card_outlined, message: 'Nenhum parcelamento')
        : RefreshIndicator(
            onRefresh: _load, color: kPurple,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12,8,12,80),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final inst = _items[i];
                return FutureBuilder<Map<String,double>>(
                  future: DB.getInstallmentPaidPending(inst.id),
                  builder: (_, snap) {
                    final paid    = snap.data?['paid'] ?? 0;
                    final pending = snap.data?['pending'] ?? 0;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(inst.description,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kText))),
                            Text(inst.categoryName ?? '', style: const TextStyle(fontSize: 11, color: kMuted)),
                          ]),
                          const SizedBox(height: 4),
                          Text('${fmtCurrency(inst.totalAmount)} • ${inst.totalParcelas}x de ${fmtCurrency(inst.installmentAmount)}',
                              style: const TextStyle(fontSize: 12, color: kMuted)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: _miniCard('Pago', paid, kGreen)),
                            const SizedBox(width: 8),
                            Expanded(child: _miniCard('Falta', pending, kOrange)),
                          ]),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _editInstallment(inst),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Editar parcelamento'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kPurple),
                              foregroundColor: kPurple,
                              minimumSize: const Size(double.infinity, 36),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            Expanded(child: OutlinedButton(
                              onPressed: () => _settle(inst),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: kGreen), foregroundColor: kGreen),
                              child: const Text('Quitar'),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: OutlinedButton(
                              onPressed: () => _editInstallment(inst),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: kPurple), foregroundColor: kPurple),
                              child: const Text('Editar'),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: OutlinedButton(
                              onPressed: () async {
                                final ok = await confirmSheet(context,
                                    title: 'Cancelar "${inst.description}"',
                                    body: 'Remove TODAS as parcelas. Nao pode ser desfeito.',
                                    confirmLabel: 'Cancelar tudo');
                                if (ok == true) { await DB.cancelInstallment(inst.id); _load(); }
                              },
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: kRed), foregroundColor: kRed),
                              child: const Text('Cancelar'),
                            )),
                          ]),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: kPurple,
      onPressed: _addInstallment,
      child: const Icon(Icons.add),
    ),
  );

  Widget _miniCard(String label, double val, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: kMuted)),
      Text(fmtCurrency(val), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}
