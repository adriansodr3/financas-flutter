import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';

class TxFormSheet extends StatefulWidget {
  final String type;
  final int year, month;
  final Transaction? tx; // não-nulo = edição
  const TxFormSheet({
    super.key,
    required this.type,
    required this.year,
    required this.month,
    this.tx,
  });
  @override
  State<TxFormSheet> createState() => _TxFormSheetState();
}

class _TxFormSheetState extends State<TxFormSheet> {
  final _amtCtrl  = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  List<Category> _cats = [];
  Category? _selCat;
  bool _loading = false;

  bool get _isEdit => widget.tx != null;

  @override
  void initState() {
    super.initState();
    _loadCats();
    if (_isEdit) {
      final tx = widget.tx!;
      _amtCtrl.text  = tx.amount.toStringAsFixed(2);
      _descCtrl.text = tx.description ?? '';
      _dateCtrl.text = tx.date;
    } else {
      _dateCtrl.text =
          '${widget.year}-${widget.month.toString().padLeft(2,'0')}-01';
    }
  }

  Future<void> _loadCats() async {
    final cats = await DB.getCategories(type: widget.type);
    if (mounted) {
      setState(() {
        _cats = cats;
        if (_isEdit && widget.tx!.categoryId != null) {
          _selCat = cats.firstWhere(
            (c) => c.id == widget.tx!.categoryId,
            orElse: () => cats.isNotEmpty ? cats.first : cats.first,
          );
        } else {
          _selCat = cats.isNotEmpty ? cats.first : null;
        }
      });
    }
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amtCtrl.text.replaceAll(',', '.'));
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valor invalido')));
      return;
    }
    final desc = _descCtrl.text.trim();
    final date = _dateCtrl.text.trim();

    setState(() => _loading = true);
    try {
      if (_isEdit) {
        final tx = widget.tx!;
        if (tx.isFixed && tx.fixedExpenseId != null) {
          await DB.editFixedMonth(
            txId: tx.id,
            fixedExpenseId: tx.fixedExpenseId!,
            year: widget.year,
            month: widget.month,
            amount: amt,
            description: desc,
            date: date,
            categoryId: _selCat?.id,
            type: widget.type,
          );
        } else {
          await DB.updateTransaction(
            id: tx.id,
            amount: amt,
            description: desc,
            date: date,
            categoryId: _selCat?.id,
          );
        }
      } else {
        await DB.createTransaction(
          type: widget.type,
          amount: amt,
          description: desc,
          date: date,
          categoryId: _selCat?.id,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInc   = widget.type == 'income';
    final color   = isInc ? kGreen : kRed;
    final title   = _isEdit
        ? 'Editar lancamento${widget.tx!.isFixed ? " (este mes)" : ""}'
        : isInc ? 'Nova Entrada' : 'Nova Despesa';

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 4, height: 28,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
            ]),
            const SizedBox(height: 20),

            // Valor
            TextField(
              controller: _amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),

            // Descrição
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descricao'),
            ),
            const SizedBox(height: 12),

            // Data
            TextField(
              controller: _dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Data (AAAA-MM-DD)',
                prefixIcon: Icon(Icons.calendar_today_outlined, color: kMuted),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: kPurple, surface: kSurface),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  _dateCtrl.text =
                      '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
                }
              },
              readOnly: true,
            ),
            const SizedBox(height: 12),

            // Categoria
            if (_cats.isNotEmpty) ...[
              const Text('Categoria',
                  style: TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = _cats[i];
                    final sel = _selCat?.id == c.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selCat = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? color.withOpacity(0.15) : kCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? color : kBorder, width: sel ? 1.5 : 1),
                        ),
                        child: Text(c.name,
                            style: TextStyle(
                                fontSize: 12,
                                color: sel ? color : kMuted,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Salvar alteracoes' : 'Lancar',
                        style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
