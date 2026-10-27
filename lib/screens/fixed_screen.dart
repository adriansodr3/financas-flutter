import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../services/push_service.dart';
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
  bool _notifEnabled = false;
  bool _notifLoading = false;
  int _year = DateTime.now().year, _month = DateTime.now().month;

  List<FixedExpense> get _filtered =>
      _filterCat == null ? _all : _all.where((f) => f.categoryName == _filterCat).toList();

  List<String> get _catOptions =>
      _all.map((f) => f.categoryName ?? '—').toSet().toList()..sort();

  @override
  void initState() {
    super.initState();
    load();
    if (kIsWeb) _checkNotifStatus();
  }

  Future<void> _checkNotifStatus() async {
    if (!PushService.isSupported) return;
    final has = await DB.hasPushSubscription();
    if (mounted) setState(() => _notifEnabled = has);
  }

  Future<void> _toggleNotifications() async {
    if (_notifLoading) return;
    setState(() => _notifLoading = true);
    try {
      if (_notifEnabled) {
        // Desativar
        final endpoint = await PushService.unsubscribe();
        if (endpoint != null) await DB.deletePushSubscription(endpoint);
        if (mounted) setState(() => _notifEnabled = false);
      } else {
        // Ativar
        final sub = await PushService.subscribe();
        if (sub != null) {
          await DB.savePushSubscription(
            endpoint: sub['endpoint']!,
            p256dh: sub['p256dh']!,
            auth: sub['auth']!,
          );
          if (mounted) setState(() => _notifEnabled = true);
        } else if (PushService.permissionState == 'denied') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Permissão de notificação bloqueada. Habilite nas configurações do navegador.'),
              duration: Duration(seconds: 4),
            ));
          }
        }
      }
    } finally {
      if (mounted) setState(() => _notifLoading = false);
    }
  }

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
    final descCtrl  = TextEditingController(text: f.description);
    final amtCtrl   = TextEditingController(text: f.amount.toStringAsFixed(2));
    final dueDayCtrl= TextEditingController(text: f.dueDay?.toString() ?? '');
    Category? selCat;

    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24,20,24,40), child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Editar Fixo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Novos valores aplicam do mês atual em diante.', style: TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 16),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descricao')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Novo valor', prefixText: 'R\$ '))),
            const SizedBox(width: 12),
            SizedBox(width: 110, child: TextField(controller: dueDayCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Vence dia',
                hintText: '1–31',
                prefixIcon: Icon(Icons.notifications_outlined, size: 18),
              ))),
          ]),
          const SizedBox(height: 16),
          CategorySelector(type: f.type, onChanged: (c) => selCat = c),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text.replaceAll(',','.'));
              if (amt == null || descCtrl.text.trim().isEmpty) return;
              final dd = int.tryParse(dueDayCtrl.text.trim());
              await DB.editFixedForward(
                fixedId: f.id,
                amount: amt,
                description: descCtrl.text.trim(),
                categoryId: selCat?.id ?? f.categoryId,
                fromYear: _year, fromMonth: _month,
                dueDay: (dd != null && dd >= 1 && dd <= 31) ? dd : null,
              );
              Navigator.pop(ctx); load();
            },
            child: const Text('Salvar'),
          )),
        ])))));
  }

  Future<void> _addFixed() async {
    String selType = 'expense';
    Category? selCat;
    final descCtrl    = TextEditingController();
    final amtCtrl     = TextEditingController();
    final dueDayCtrl  = TextEditingController();
    String dateStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-01';

    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24,20,24,40), child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Novo Fixo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
          Row(children: [
            Expanded(child: TextField(controller: amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor mensal', prefixText: 'R\$ '))),
            const SizedBox(width: 12),
            SizedBox(width: 110, child: TextField(controller: dueDayCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Vence dia',
                hintText: '1–31',
                prefixIcon: Icon(Icons.notifications_outlined, size: 18),
              ))),
          ]),
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
                  Text(DateFormat('MM/yyyy').format(DateTime.parse(dateStr)), style: const TextStyle()),
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
              final dd = int.tryParse(dueDayCtrl.text.trim());
              await DB.createFixed(
                type: selType, amount: amt,
                description: descCtrl.text.trim(),
                categoryId: selCat?.id,
                validFrom: dateStr,
                dueDay: (dd != null && dd >= 1 && dd <= 31) ? dd : null,
              );
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
            appBar: AppBar(elevation: 0,
        title: const Text('Gastos e Receitas Fixos', style: TextStyle(fontSize: 16)),
        actions: [
          // Toggle de notificações de vencimento
          if (kIsWeb && PushService.isSupported)
            _notifLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: kMuted, strokeWidth: 2)))
              : IconButton(
                  tooltip: _notifEnabled ? 'Notificações ativas' : 'Ativar notificações de vencimento',
                  icon: Icon(
                    _notifEnabled ? Icons.notifications_active : Icons.notifications_none,
                    color: _notifEnabled ? kPurple : kMuted,
                  ),
                  onPressed: _toggleNotifications,
                ),
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
                  final days = f.daysUntilDue;
                  final dueBadgeColor = days == null ? null
                      : days < 0  ? kRed
                      : days <= 3 ? kRed
                      : days <= 7 ? kOrange
                      : kGreen;
                  final dueBadgeText = days == null ? null
                      : days < 0  ? 'Venceu há ${(-days)} dia${(-days)==1?"":"s"}'
                      : days == 0 ? 'Vence hoje!'
                      : days == 1 ? 'Vence amanhã'
                      : 'Vence em $days dias';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    shape: dueBadgeColor != null && dueBadgeColor != kGreen
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: dueBadgeColor.withOpacity(0.5), width: 1.5))
                      : null,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(
                        leading: Container(width: 40, height: 40,
                          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                          child: Icon(isInc ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 18)),
                        title: Text(f.description, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          '${f.categoryName ?? "—"}  •  ${fmtCurrency(f.amount)}/mes'
                          '${f.dueDay != null ? "  •  dia ${f.dueDay}" : ""}',
                          style: const TextStyle(fontSize: 12, color: kMuted)),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: kMuted),
                          color: kSurface,
                          onSelected: (v) { if(v=='edit') _editFixed(f); else _deactivateForward(f); },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, color: kPurple, size: 18), SizedBox(width: 8), Text('Editar', style: TextStyle())])),
                            const PopupMenuItem(value: 'del',  child: Row(children: [Icon(Icons.delete_outline, color: kRed, size: 18), SizedBox(width: 8), Text('Desativar', style: TextStyle(color: kRed))])),
                          ],
                        ),
                      ),
                      if (dueBadgeText != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: Row(children: [
                            Icon(dueBadgeColor == kGreen
                                ? Icons.check_circle_outline
                                : Icons.alarm_outlined,
                              color: dueBadgeColor, size: 14),
                            const SizedBox(width: 5),
                            Text(dueBadgeText,
                              style: TextStyle(fontSize: 11, color: dueBadgeColor, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                    ]),
                  );
                },
              )),
        ),
      ]),
      floatingActionButton: FloatingActionButton(backgroundColor: kPurple, onPressed: _addFixed, child: const Icon(Icons.add)),
    );
  }
}
