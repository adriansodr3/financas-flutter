import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'tx_form_sheet.dart';

class TxActionSheet extends StatelessWidget {
  final Transaction tx;
  final int year, month;
  const TxActionSheet({super.key, required this.tx, required this.year, required this.month});

  @override
  Widget build(BuildContext context) {
    final isInc   = tx.type == 'income';
    final isFixed = tx.isFixed;
    final isInst  = tx.installmentId != null;
    final color   = isInc ? kGreen : kRed;
    final now     = DateTime.now();
    final txDate  = DateTime.tryParse(tx.date);
    final isFuture = txDate != null && txDate.isAfter(DateTime(now.year, now.month, 1));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${tx.description ?? "—"}${tx.badge}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kText)),
            Text('${fmtDate(tx.date)}  •  ${tx.categoryName ?? "—"}', style: const TextStyle(fontSize: 12, color: kMuted)),
          ])),
          Text(fmtCurrency(tx.amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ]),
        if (isFixed || isInst) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isFixed ? kOrange : kPurple).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: (isFixed ? kOrange : kPurple).withOpacity(0.3))),
            child: Text(isFixed ? 'Lancamento fixo' : 'Parcela ${tx.installmentNumber}x',
                style: TextStyle(fontSize: 11, color: isFixed ? kOrange : kPurple)),
          ),
        ],
        const SizedBox(height: 20),

        // Botão Editar
        if (!isInst) SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            await Future.delayed(const Duration(milliseconds: 200));
            if (context.mounted) {
              final ok = await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
                  builder: (_) => TxFormSheet(type: tx.type, year: year, month: month, tx: tx));
              if (ok == true && context.mounted) Navigator.pop(context, true);
            }
          },
          icon: const Icon(Icons.edit_outlined),
          label: Text(isFixed ? 'Editar (somente este mes)' : 'Editar'),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: kPurple), foregroundColor: kPurple, padding: const EdgeInsets.symmetric(vertical: 12)),
        )),
        if (!isInst) const SizedBox(height: 8),

        // Botão Adiantar para mês atual
        if (isFuture) ...[
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () async {
              final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final ok = await confirmSheet(context,
                title: 'Adiantar lançamento',
                body: 'Mover "${tx.description}" para hoje (${fmtDate(today)})?',
                confirmLabel: 'Adiantar',
                confirmColor: kOrange);
              if (ok == true && context.mounted) {
                await DB.advanceTransaction(txId: tx.id, newDate: today);
                if (context.mounted) Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.fast_forward_outlined),
            label: const Text('Adiantar para hoje'),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: kOrange), foregroundColor: kOrange, padding: const EdgeInsets.symmetric(vertical: 12)),
          )),
          const SizedBox(height: 8),
        ],

        // Botão Excluir
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () async {
            final label = isFixed ? 'Excluir lancamento fixo de ${month.toString().padLeft(2,"0")}/$year?'
                : isInst ? 'Excluir esta parcela?' : 'Excluir este lancamento?';
            final ok = await confirmSheet(context, title: 'Excluir', body: label, confirmLabel: 'Excluir');
            if (ok == true && context.mounted) {
              if (isFixed && tx.fixedExpenseId != null) {
                await DB.deleteFixedMonth(tx.id, tx.fixedExpenseId!, year, month);
              } else {
                await DB.deleteTransaction(tx.id);
              }
              if (context.mounted) Navigator.pop(context, true);
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Excluir'),
          style: ElevatedButton.styleFrom(backgroundColor: kRed, padding: const EdgeInsets.symmetric(vertical: 12)),
        )),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: kMuted)))),
      ]),
    );
  }
}
