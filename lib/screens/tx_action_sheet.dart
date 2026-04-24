// tx_action_sheet.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'tx_form_sheet.dart';

class TxActionSheet extends StatelessWidget {
  final Transaction tx;
  final int year, month;
  const TxActionSheet({
    super.key,
    required this.tx,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final isInc   = tx.type == 'income';
    final isFixed = tx.isFixed;
    final isInst  = tx.installmentId != null;
    final color   = isInc ? kGreen : kRed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4, height: 40,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tx.description ?? "—"}${tx.badge}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kText)),
                Text('${fmtDate(tx.date)}  •  ${tx.categoryName ?? "—"}',
                    style: const TextStyle(fontSize: 12, color: kMuted)),
              ],
            )),
            Text(fmtCurrency(tx.amount),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ]),
          if (isFixed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kOrange.withOpacity(0.3)),
                ),
                child: const Text('Lancamento fixo — acao somente neste mes',
                    style: TextStyle(fontSize: 11, color: kOrange)),
              ),
            ),
          if (isInst)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kPurple.withOpacity(0.3)),
                ),
                child: const Text('Parcela — nao pode ser editada individualmente',
                    style: TextStyle(fontSize: 11, color: kPurple)),
              ),
            ),
          const SizedBox(height: 20),

          // Botão Editar (não para parcelas)
          if (!isInst) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 200));
                  if (context.mounted) {
                    final ok = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => TxFormSheet(
                        type: tx.type,
                        year: year,
                        month: month,
                        tx: tx,
                      ),
                    );
                    if (ok == true && context.mounted) Navigator.pop(context, true);
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(isFixed ? 'Editar (somente este mes)' : 'Editar'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kPurple),
                  foregroundColor: kPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Botão Excluir
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final label = isFixed
                    ? 'Excluir lancamento fixo somente em ${month.toString().padLeft(2,"0")}/$year?'
                    : isInst
                        ? 'Excluir esta parcela?'
                        : 'Excluir este lancamento?';
                final ok = await confirmSheet(
                  context,
                  title: 'Excluir',
                  body: label,
                  confirmLabel: 'Excluir',
                );
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
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: kMuted)),
            ),
          ),
        ],
      ),
    );
  }
}
