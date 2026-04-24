import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../widgets/category_picker.dart';

class FixedScreen extends StatefulWidget {
  const FixedScreen({super.key});
  @override
  State<FixedScreen> createState() => FixedScreenState();
}

class FixedScreenState extends State<FixedScreen> {
  List<FixedExpense> _all = [];
  String? _filterCat; // null = todos
  bool _loading = true;
  int _year = DateTime.now().year, _month = DateTime.now().month;

  List<FixedExpense> get _filtered =>
      _filterCat == null ? _all : _all.where((f) => f.categoryName == _filterCat).toList();

  List<String> get _catOptions =>
      _all.map((f) => f.categoryName ?? '—').toSet().toList()..sort();

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => _loading = true);
    final items = await DB.getActiveFixed();
    if (mounted) setState(() { _all = items; _loading = false; });
  }

  Future<void> _deactivateForward(FixedExpense f) async {
    final ok = await confirmSheet(context,
      title: 'Desativar "${f.description}"',
      body: 'Remove este fixo do mês atual em diante.\nMeses anteriores permanecem intactos.',
      confirmLabel: 'Desativar');
    if (ok == true) {
      await DB.deactivateFixedForward(fixedId: f.id, fromYear: _year, fromMonth: _month);
      load();
    }
  }

  Future<void> _editFixed(FixedExpense f) async {
    final descCtrl = TextEditingController(text: f.description);
    final amtCtrl  = TextEditingController(text: f.amount.toStringAsFixed(2));
    Category? selCat;

    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24,20,24,40), child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Editar Fixo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
          const SizedBox(height: 4),
          const Text('Novos valores aplicam do mês atual em diante.', style: TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 16),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descricao')),
          const SizedBox(height: 12),
          TextField(controller: amtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Novo valor', prefixText: 'R\$ ')),
          const SizedBox(height: 16),
          CategorySelector(type: f.type, onChanged: (c) => selCat = c),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text.replaceAll(',','.'));
              if (amt == null || descCtrl.text.trim().isEmpty) return;
              await DB.editFixedForward(
                fixedId: f.id,
                amount: amt,
                description: descCtrl.text.trim(),
                categoryId: selCat?.id ?? f.categoryId,
                fromYear: _year, fromMonth: _month);
              Navigator.pop(ctx); load();
            },
            child: const Text('Salvar'),
          )),
        ])))));
  }

  Future<void> _addFixed() async {
    String selType = 'expense';
    Category? selCat;
    final descCtrl = TextEditingController();
    final amtCtrl  = TextEditingController();
    String dateStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-01';

    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24,20,24,40), child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Novo Fixo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
          const SizedBox(height: 16),
          // Tipo
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () async { final c = await DB.getCategories(type:'expense'); setSt((){selType='expense'; selCat=null;}); },
              child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: selType=='expense'?kRed.withOpacity(0.15):kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: selType=='expense'?kRed:kBorder)),
                child: Text('Despesa', textAlign: TextAlign.center, style: TextStyle(color: selType=='expense'?kRed:kMuted, fontWeight: FontWeight.w600))))),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: () async { setSt((){selType='income'; selCat=null;}); },
              child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: selType=='income'?kGreen.withOpacity(0.15):kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: selType=='income'?kGreen:kBorder)),
                child: Text('Entrada', textAlign: TextAlign.center, style: TextStyle(color: selType=='income'?kGreen:kMuted, fontWeight: FontWeight.w600))))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descricao (ex: Aluguel)')),
          const SizedBox(height: 12),
          TextField(controller: amtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor mensal', prefixText: 'R\$ ')),
          const SizedBox(height: 12),
          // Data início
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(context: ctx,
                initialDate: DateTime.tryParse(dateStr) ?? DateTime.now(),
                firstDate: DateTime(2020), lastDate: DateTime(2035),
                builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: kPurple, surface: kSurface)), child: child!));
              if (picked != null) setSt(() => dateStr = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-01');
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, color: kMuted, size: 18), const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Valido a partir de', style: TextStyle(fontSize: 11, color: kMuted)),
                  Text(DateFormat('MM/yyyy').format(DateTime.parse(dateStr)), style: const TextStyle(color: kText)),
                ]),
              ])),
          ),
          const SizedBox(height: 16),
          CategorySelector(type: selType, onChanged: (c) => selCat = c),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text.replaceAll(',','.'));
              if (amt == null || descCtrl.text.trim().isEmpty) return;
              await DB.createFixed(type: selType, amount: amt, description: descCtrl.text.trim(), categoryId: selCat?.id, validFrom: dateStr);
              Navigator.pop(ctx); load();
            },
            child: const Text('Salvar'),
          )),
        ])))));
  }

  @override
  Widget build(BuildContext context) {
    final cats = _catOptions;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kSurface, elevation: 0,
        title: const Text('Gastos e Receitas Fixos', style: TextStyle(color: kText, fontSize: 16)),
        actions: [
          // Filtro por categoria
          if (cats.isNotEmpty) PopupMenuButton<String?>(
            icon: Icon(Icons.filter_list, color: _filterCat != null ? kPurple : kMuted),
            color: kSurface,
            onSelected: (v) => setState(() => _filterCat = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: null, child: Text('Todos', style: TextStyle(color: _filterCat==null?kPurple:kText))),
              ...cats.map((c) => PopupMenuItem(value: c, child: Text(c, style: TextStyle(color: _filterCat==c?kPurple:kText)))),
            ],
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: kBorder)),
      ),
      body: Column(children: [
        if (_filterCat != null)
          Container(color: kPurple.withOpacity(0.1), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              const Icon(Icons.filter_alt, color: kPurple, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text('Filtro: $_filterCat', style: const TextStyle(color: kPurple, fontSize: 12))),
              GestureDetector(onTap: () => setState(() => _filterCat = null),
                  child: const Icon(Icons.close, color: kPurple, size: 16)),
            ])),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: kPurple))
          : _filtered.isEmpty
            ? const EmptyState(icon: Icons.push_pin_outlined, message: 'Nenhum fixo cadastrado')
            : RefreshIndicator(onRefresh: load, color: kPurple, child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12,8,12,80),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final f = _filtered[i];
                  final isInc = f.type=='income';
                  final color = isInc ? kGreen : kRed;
                  return Card(margin: const EdgeInsets.symmetric(vertical: 3), child: ListTile(
                    leading: Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(isInc ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 18)),
                    title: Text(f.description, style: const TextStyle(fontSize: 14, color: kText)),
                    subtitle: Text('${f.categoryName ?? "—"}  •  ${fmtCurrency(f.amount)}/mes', style: const TextStyle(fontSize: 12, color: kMuted)),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: kMuted),
                      color: kSurface,
                      onSelected: (v) { if(v=='edit') _editFixed(f); else _deactivateForward(f); },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, color: kPurple, size: 18), SizedBox(width: 8), Text('Editar', style: TextStyle(color: kText))])),
                        const PopupMenuItem(value: 'del',  child: Row(children: [Icon(Icons.delete_outline, color: kRed, size: 18), SizedBox(width: 8), Text('Desativar', style: TextStyle(color: kRed))])),
                      ],
                    ),
                  ));
                },
              )),
        ),
      ]),
      floatingActionButton: FloatingActionButton(backgroundColor: kPurple, onPressed: _addFixed, child: const Icon(Icons.add)),
    );
  }
}
