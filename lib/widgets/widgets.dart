import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/models.dart';

// ── Summary Card ──────────────────────────────────────────

class SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: kMuted, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(
              fmtCurrency(value),
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────

class TxTile extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onTap;
  const TxTile({super.key, required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isInc = tx.type == 'income';
    final color = isInc ? kGreen : kRed;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 3, height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tx.description ?? "—"}${tx.badge}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fmtDate(tx.date)}  •  ${tx.categoryName ?? "—"}',
                      style: const TextStyle(fontSize: 11, color: kMuted),
                    ),
                  ],
                ),
              ),
              Text(
                fmtCurrency(tx.amount),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Month Navigator ───────────────────────────────────────

class MonthNav extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onToday;

  const MonthNav({
    super.key,
    required this.year,
    required this.month,
    required this.onPrev,
    required this.onNext,
    this.onToday,
  });

  static const _months = [
    '', 'Janeiro', 'Fevereiro', 'Marco', 'Abril',
    'Maio', 'Junho', 'Julho', 'Agosto',
    'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Expanded(
            child: Text(
              '${_months[month]} $year',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          if (onToday != null)
            IconButton(
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                onPressed: onToday),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11, color: kMuted, letterSpacing: 1.2,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Confirm Bottom Sheet ──────────────────────────────────

Future<bool?> confirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'Confirmar',
  Color confirmColor = kRed,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: kMuted)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kBorder),
                    foregroundColor: kText,
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ── Loading Overlay ───────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;
  const LoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          const ColoredBox(
            color: Colors.black45,
            child: Center(
              child: CircularProgressIndicator(color: kPurple),
            ),
          ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: kMuted),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: kMuted, fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
