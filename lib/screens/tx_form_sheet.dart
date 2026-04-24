import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';
import 'category_inline.dart';

class TxFormSheet extends StatefulWidget {
  final String type;
  final int year, month;
  final Transaction? tx;
  const TxFormSheet({super.key, required this.type, required this.year, required this.month, this.tx});
  @override
  State<TxFormSheet> createState() => _TxFormSheetState();
}

class _TxFormSheetState extends State<TxFormSheet> {
  final _amtCtrl  = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  Category? _selCat;
  bool _loading = false;

  bool get _isEdit => widget.tx != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final tx = widget.tx!;
      _amtCtrl.text  = tx.amount.toStringAsFixed(2);
      _descCtrl.text = tx.description ?? '';
      _dateCtrl.text = tx.date;
    } else {
      _dateCtrl.text = '${widget.year}-${widget.month.toString().padLeft(2,'0')}-01';
    }
  }

  @override
  void dispose() {
    _amtCtrl.dispose(); _descCtrl.dispose(); _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kPurple, surface: kSurface)),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
    }
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amtCtrl.text.replaceAll(',', '.'));
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valor invalido')));
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        final tx = widget.tx!;
        if (tx.isFixed && tx.fixedExpenseId != null) {
          await DB.editFixedMonth(
            txId: tx.id, fixedExpenseId: tx.fixedExpenseId!,
            year: widget.year, month: widget.month,
            amount: amt, description: _descCtrl.text.trim(),
            date: _dateCtrl.text.trim(), categoryId: _selCat?.id, type: widget.type);
        } else {
          await DB.updateTransaction(
            id: tx.id, amount: amt, description: _descCtrl.text.trim(),
            date: _dateCtrl.text.trim(), categoryId: _selCat?.id);
        }
      } else {
        await DB.createTransaction(
          type: widget.type, amount: amt,
          description: _descCtrl.text.trim(),
          date: _dateCtrl.text.trim(), categoryId: _selCat?.id);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInc  = widget.type == 'income';
    final color  = isInc ? kGreen : kRed;
    final title  = _isEdit
        ? 'Editar${widget.tx!.isFixed ? " (este mes)" : ""}'
        : isInc ? 'Nova Entrada' : 'Nova Despesa';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 4, height: 28,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
            ]),
            const SizedBox(height: 20),
            TextField(
              controller: _amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descricao'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Data',
                prefixIcon: Icon(Icons.calendar_today_outlined, color: kMuted, size: 18),
                suffixIcon: Icon(Icons.edit_calendar_outlined, color: kMuted, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            CategorySelector(
              type: widget.type,
              onChanged: (c) => _selCat = c,
              initial: null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
