import 'package:intl/intl.dart';

final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
String fmtCurrency(double v) => _currencyFmt.format(v);
String fmtDate(String iso) {
  try {
    final d = DateTime.parse(iso);
    return DateFormat('dd/MM/yyyy').format(d);
  } catch (_) {
    return iso;
  }
}

// ── Category ──────────────────────────────────────────────

class Category {
  final String id;
  final String userId;
  final String name;
  final String type; // income | expense
  final String color;
  final String icon;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.color = '#6366f1',
    this.icon = 'attach_money',
  });

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        name: m['name'] as String,
        type: m['type'] as String,
        color: m['color'] as String? ?? '#6366f1',
        icon: m['icon'] as String? ?? 'attach_money',
      );

  Map<String, dynamic> toInsert() => {
        'user_id': userId,
        'name': name,
        'type': type,
        'color': color,
        'icon': icon,
      };
}

// ── Transaction ───────────────────────────────────────────

class Transaction {
  final String id;
  final String userId;
  final String? categoryId;
  final String type;
  final double amount;
  final String? description;
  final String date;
  final bool isFixed;
  final String? fixedExpenseId;
  final String? installmentId;
  final int? installmentNumber;
  // joined
  final String? categoryName;
  final String? categoryIcon;

  const Transaction({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    this.isFixed = false,
    this.fixedExpenseId,
    this.installmentId,
    this.installmentNumber,
    this.categoryName,
    this.categoryIcon,
  });

  factory Transaction.fromMap(Map<String, dynamic> m) => Transaction(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        categoryId: m['category_id'] as String?,
        type: m['type'] as String,
        amount: (m['amount'] as num).toDouble(),
        description: m['description'] as String?,
        date: m['date'] as String,
        isFixed: m['is_fixed'] as bool? ?? false,
        fixedExpenseId: m['fixed_expense_id'] as String?,
        installmentId: m['installment_id'] as String?,
        installmentNumber: m['installment_number'] as int?,
        categoryName: m['categories'] != null
            ? (m['categories'] as Map)['name'] as String?
            : null,
        categoryIcon: m['categories'] != null
            ? (m['categories'] as Map)['icon'] as String?
            : null,
      );

  String get badge {
    if (isFixed) return ' 📌';
    if (installmentId != null) return ' (${installmentNumber}x)';
    return '';
  }
}

// ── FixedExpense ──────────────────────────────────────────

class FixedExpense {
  final String id;
  final String userId;
  final String? categoryId;
  final String type;
  final double amount;
  final String description;
  final bool active;
  final String validFrom;
  final String? categoryName;
  final String? categoryIcon;

  const FixedExpense({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.description,
    this.active = true,
    required this.validFrom,
    this.categoryName,
    this.categoryIcon,
  });

  factory FixedExpense.fromMap(Map<String, dynamic> m) => FixedExpense(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        categoryId: m['category_id'] as String?,
        type: m['type'] as String,
        amount: (m['amount'] as num).toDouble(),
        description: m['description'] as String,
        active: m['active'] as bool? ?? true,
        validFrom: m['valid_from'] as String,
        categoryName: m['categories'] != null
            ? (m['categories'] as Map)['name'] as String?
            : null,
        categoryIcon: m['categories'] != null
            ? (m['categories'] as Map)['icon'] as String?
            : null,
      );
}

// ── Installment ───────────────────────────────────────────

class Installment {
  final String id;
  final String userId;
  final String? categoryId;
  final String description;
  final double totalAmount;
  final double installmentAmount;
  final int totalParcelas;
  final String startDate;
  final String? categoryName;

  const Installment({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.description,
    required this.totalAmount,
    required this.installmentAmount,
    required this.totalParcelas,
    required this.startDate,
    this.categoryName,
  });

  factory Installment.fromMap(Map<String, dynamic> m) => Installment(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        categoryId: m['category_id'] as String?,
        description: m['description'] as String,
        totalAmount: (m['total_amount'] as num).toDouble(),
        installmentAmount: (m['installment_amount'] as num).toDouble(),
        totalParcelas: m['total_parcelas'] as int,
        startDate: m['start_date'] as String,
        categoryName: m['categories'] != null
            ? (m['categories'] as Map)['name'] as String?
            : null,
      );
}
