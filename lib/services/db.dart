import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class DB {
  static final _sb = Supabase.instance.client;
  static String get uid {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('Usuario nao autenticado');
    return user.id;
  }

  // ── Categories ────────────────────────────────────────────

  static Future<List<Category>> getCategories({String? type}) async {
    var q = _sb.from('categories').select().eq('user_id', uid);
    if (type != null) {
      final data = await q.eq('type', type).order('name');
      return (data as List).map((m) => Category.fromMap(m)).toList();
    }
    final data = await q.order('type').order('name');
    return (data as List).map((m) => Category.fromMap(m)).toList();
  }

  static Future<void> createCategory(
      String name, String type, String icon) async {
    await _sb.from('categories').insert({
      'user_id': uid,
      'name': name,
      'type': type,
      'icon': icon,
      'color': type == 'income' ? '#22c55e' : '#ef4444',
    });
  }

  static Future<void> deleteCategory(String id) async {
    await _sb.from('categories').delete().eq('id', id).eq('user_id', uid);
  }

  // ── Seed default categories on first login ────────────────

  static Future<void> seedDefaultCategories() async {
    final user = _sb.auth.currentUser;
    if (user == null) return; // sem sessao, nao faz nada
    final existing = await _sb
        .from('categories')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);
    if ((existing as List).isNotEmpty) return;

    final defaults = [
      {'name': 'Salario', 'type': 'income', 'icon': 'work', 'color': '#22c55e'},
      {'name': 'Freelance', 'type': 'income', 'icon': 'computer', 'color': '#10b981'},
      {'name': 'Outros', 'type': 'income', 'icon': 'add_circle', 'color': '#8b5cf6'},
      {'name': 'Moradia', 'type': 'expense', 'icon': 'home', 'color': '#ef4444'},
      {'name': 'Alimentacao', 'type': 'expense', 'icon': 'restaurant', 'color': '#f97316'},
      {'name': 'Transporte', 'type': 'expense', 'icon': 'directions_car', 'color': '#eab308'},
      {'name': 'Saude', 'type': 'expense', 'icon': 'favorite', 'color': '#14b8a6'},
      {'name': 'Educacao', 'type': 'expense', 'icon': 'school', 'color': '#6366f1'},
      {'name': 'Lazer', 'type': 'expense', 'icon': 'celebration', 'color': '#ec4899'},
      {'name': 'Contas', 'type': 'expense', 'icon': 'receipt_long', 'color': '#64748b'},
      {'name': 'Roupas', 'type': 'expense', 'icon': 'checkroom', 'color': '#a855f7'},
      {'name': 'Outros', 'type': 'expense', 'icon': 'more_horiz', 'color': '#94a3b8'},
    ];

    for (final d in defaults) {
      await _sb.from('categories').insert({...d, 'user_id': uid});
    }
  }

  // ── Transactions ──────────────────────────────────────────

  static Future<List<Transaction>> getTransactions(int year, int month) async {
    final start = '${year.toString().padLeft(4,'0')}-${month.toString().padLeft(2,'0')}-01';
    final endM = month == 12 ? 1 : month + 1;
    final endY = month == 12 ? year + 1 : year;
    final end = '${endY.toString().padLeft(4,'0')}-${endM.toString().padLeft(2,'0')}-01';

    final data = await _sb
        .from('transactions')
        .select('*, categories(name, icon, color)')
        .eq('user_id', uid)
        .gte('date', start)
        .lt('date', end)
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (data as List).map((m) => Transaction.fromMap(m)).toList();
  }

  static Future<double> getBalanceBefore(int year, int month) async {
    final cutoff = '${year.toString().padLeft(4,'0')}-${month.toString().padLeft(2,'0')}-01';
    final data = await _sb
        .from('transactions')
        .select('type, amount')
        .eq('user_id', uid)
        .lt('date', cutoff);
    double inc = 0, exp = 0;
    for (final r in data as List) {
      if (r['type'] == 'income') inc += (r['amount'] as num).toDouble();
      else exp += (r['amount'] as num).toDouble();
    }
    return inc - exp;
  }

  static Future<double> getPendingFromMonth(int year, int month) async {
    final cutoff = '${year.toString().padLeft(4,'0')}-${month.toString().padLeft(2,'0')}-01';
    final data = await _sb
        .from('transactions')
        .select('amount')
        .eq('user_id', uid)
        .eq('type', 'expense')
        .eq('is_fixed', false)
        .gte('date', cutoff);
    final list = data as List;
    double total = 0.0;
    for (final r in list) { total += (r['amount'] as num).toDouble(); }
    return total;
  }

  static Future<void> createTransaction({
    required String type,
    required double amount,
    required String description,
    required String date,
    String? categoryId,
    bool isFixed = false,
    String? fixedExpenseId,
    String? installmentId,
    int? installmentNumber,
  }) async {
    await _sb.from('transactions').insert({
      'user_id': uid,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date,
      'is_fixed': isFixed,
      'fixed_expense_id': fixedExpenseId,
      'installment_id': installmentId,
      'installment_number': installmentNumber,
    });
  }

  static Future<void> updateTransaction({
    required String id,
    required double amount,
    required String description,
    required String date,
    String? categoryId,
  }) async {
    await _sb.from('transactions').update({
      'amount': amount,
      'description': description,
      'date': date,
      'category_id': categoryId,
    }).eq('id', id).eq('user_id', uid);
  }

  static Future<void> deleteTransaction(String id) async {
    await _sb.from('transactions').delete().eq('id', id).eq('user_id', uid);
  }

  static Future<List<Map<String, dynamic>>> getSummaryByCategory(
      int year, int month) async {
    final txs = await getTransactions(year, month);
    final Map<String, Map<String, dynamic>> groups = {};
    for (final t in txs) {
      final key = '${t.categoryId ?? "none"}_${t.type}';
      if (!groups.containsKey(key)) {
        groups[key] = {
          'name': t.categoryName ?? 'Sem categoria',
          'icon': t.categoryIcon ?? 'more_horiz',
          'type': t.type,
          'total': 0.0,
        };
      }
      groups[key]!['total'] = (groups[key]!['total'] as double) + t.amount;
    }
    return groups.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
  }

  // ── Fixed Expenses ────────────────────────────────────────

  static Future<List<FixedExpense>> getActiveFixed() async {
    final data = await _sb
        .from('fixed_expenses')
        .select('*, categories(name, icon, color)')
        .eq('user_id', uid)
        .eq('active', true)
        .order('description');
    return (data as List).map((m) => FixedExpense.fromMap(m)).toList();
  }

  static Future<void> materializeFixed(int year, int month) async {
    final monthStr = '${year.toString().padLeft(4,'0')}-${month.toString().padLeft(2,'0')}';
    final firstDay = '$monthStr-01';
    final nm = month == 12 ? 1 : month + 1;
    final ny = month == 12 ? year + 1 : year;
    final nextDay = '${ny.toString().padLeft(4,"0")}-${nm.toString().padLeft(2,"0")}-01';

    final fixed = await _sb
        .from('fixed_expenses')
        .select()
        .eq('user_id', uid)
        .eq('active', true)
        .lte('valid_from', firstDay);

    for (final fe in fixed as List) {
      // Check skipped
      final skipped = await _sb
          .from('fixed_skipped')
          .select('id')
          .eq('user_id', uid)
          .eq('fixed_expense_id', fe['id'])
          .eq('month', monthStr)
          .limit(1);
      if ((skipped as List).isNotEmpty) continue;

      // Check already materialized
      final already = await _sb
          .from('transactions')
          .select('id')
          .eq('user_id', uid)
          .eq('is_fixed', true)
          .eq('fixed_expense_id', fe['id'])
          .gte('date', firstDay)
          .lt('date', nextDay)
          .limit(1);
      if ((already as List).isNotEmpty) continue;

      await _sb.from('transactions').insert({
        'user_id': uid,
        'category_id': fe['category_id'],
        'type': fe['type'],
        'amount': fe['amount'],
        'description': fe['description'],
        'date': firstDay,
        'is_fixed': true,
        'fixed_expense_id': fe['id'],
      });
    }
  }

  static Future<void> createFixed({
    required String type,
    required double amount,
    required String description,
    String? categoryId,
  }) async {
    final now = DateTime.now();
    final validFrom = '${now.year}-${now.month.toString().padLeft(2,'0')}-01';
    await _sb.from('fixed_expenses').insert({
      'user_id': uid,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'valid_from': validFrom,
    });
  }

  static Future<void> deactivateFixed(String id) async {
    await _sb.from('fixed_expenses').update({'active': false})
        .eq('id', id).eq('user_id', uid);
  }

  static Future<void> deleteFixedMonth(
      String txId, String fixedExpenseId, int year, int month) async {
    final monthStr = '${year.toString().padLeft(4,'0')}-${month.toString().padLeft(2,'0')}';
    // 1. Registrar skip (ignorar se ja existe)
    try {
      await _sb.from('fixed_skipped').insert({
        'user_id': uid,
        'fixed_expense_id': fixedExpenseId,
        'month': monthStr,
      });
    } catch (_) {
      // Ja existe — ok, continua
    }
    // 2. Deletar a transaction do mes
    await _sb.from('transactions').delete().eq('id', txId).eq('user_id', uid);
  }

  static Future<void> editFixedMonth({
    required String txId,
    required String fixedExpenseId,
    required int year,
    required int month,
    required double amount,
    required String description,
    required String date,
    String? categoryId,
    required String type,
  }) async {
    final monthStr = '\${year.toString().padLeft(4,"0")}-\${month.toString().padLeft(2,"0")}';
    // Registrar skip (ignorar se ja existe)
    try {
      await _sb.from('fixed_skipped').insert({
        'user_id': uid,
        'fixed_expense_id': fixedExpenseId,
        'month': monthStr,
      });
    } catch (_) {}
    // Deletar a transaction fixa do mes
    await _sb.from('transactions').delete().eq('id', txId).eq('user_id', uid);
    // Criar novo lancamento avulso com os valores editados
    await createTransaction(
      type: type,
      amount: amount,
      description: description,
      date: date,
      categoryId: categoryId,
    );
  }

  // ── Installments ──────────────────────────────────────────

  static Future<void> updateInstallment({
    required String id,
    required String description,
    String? categoryId,
  }) async {
    // Atualiza o registro principal
    await _sb.from('installments').update({
      'description': description,
      'category_id': categoryId,
    }).eq('id', id).eq('user_id', uid);
    // Atualiza category_id nas parcelas existentes
    await _sb.from('transactions').update({
      'category_id': categoryId,
    }).eq('installment_id', id).eq('user_id', uid);
    // Atualiza prefixo da descricao nas parcelas (mantendo o numero da parcela)
    final parcelas = await _sb
        .from('transactions')
        .select('id, installment_number, description')
        .eq('installment_id', id)
        .eq('user_id', uid);
    // Buscar total de parcelas
    final inst = await _sb.from('installments').select('total_parcelas').eq('id', id).single();
    final total = inst['total_parcelas'] as int;
    for (final p in parcelas as List) {
      final n = p['installment_number'] as int;
      await _sb.from('transactions').update({
        'description': '$description ($n/$total)',
        'category_id': categoryId,
      }).eq('id', p['id']).eq('user_id', uid);
    }
  }

  static Future<List<Installment>> getInstallments() async {
    final data = await _sb
        .from('installments')
        .select('*, categories(name, icon)')
        .eq('user_id', uid)
        .order('start_date', ascending: false);
    return (data as List).map((m) => Installment.fromMap(m)).toList();
  }

  static Future<List<Transaction>> getInstallmentParcelas(String instId) async {
    final data = await _sb
        .from('transactions')
        .select()
        .eq('user_id', uid)
        .eq('installment_id', instId)
        .order('installment_number');
    return (data as List).map((m) => Transaction.fromMap(m)).toList();
  }

  static Future<void> createInstallment({
    required String description,
    required double totalAmount,
    required int nParcelas,
    required String startDate,
    String? categoryId,
  }) async {
    final instAmt = double.parse((totalAmount / nParcelas).toStringAsFixed(2));

    final inst = await _sb.from('installments').insert({
      'user_id': uid,
      'category_id': categoryId,
      'description': description,
      'total_amount': totalAmount,
      'installment_amount': instAmt,
      'total_parcelas': nParcelas,
      'start_date': startDate,
    }).select().single();

    final instId = inst['id'] as String;
    var dt = DateTime.parse(startDate.length == 7 ? '$startDate-01' : startDate);

    for (int i = 0; i < nParcelas; i++) {
      final dateStr =
          '${dt.year}-${dt.month.toString().padLeft(2,'0')}-01';
      await _sb.from('transactions').insert({
        'user_id': uid,
        'category_id': categoryId,
        'type': 'expense',
        'amount': instAmt,
        'description': '$description (${i + 1}/$nParcelas)',
        'date': dateStr,
        'installment_id': instId,
        'installment_number': i + 1,
      });
      dt = DateTime(dt.year, dt.month + 1, 1);
    }
  }

  static Future<Map<String, double>> getInstallmentPaidPending(
      String instId) async {
    final parcelas = await getInstallmentParcelas(instId);
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, 1);
    double paid = 0, pending = 0;
    for (final p in parcelas) {
      final d = DateTime.parse(p.date);
      if (d.isBefore(cutoff)) {
        paid += p.amount;
      } else {
        pending += p.amount;
      }
    }
    return {'paid': paid, 'pending': pending};
  }

  static Future<double> settleInstallment(Installment inst) async {
    final parcelas = await getInstallmentParcelas(inst.id);
    final total = parcelas.fold(0.0, (s, p) => s + p.amount);
    // Delete all parcelas
    await _sb
        .from('transactions')
        .delete()
        .eq('installment_id', inst.id)
        .eq('user_id', uid);
    // Delete installment record
    await _sb.from('installments').delete().eq('id', inst.id).eq('user_id', uid);
    // Create single expense
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    await createTransaction(
      type: 'expense',
      amount: total,
      description: 'Quitacao: ${inst.description}',
      date: dateStr,
      categoryId: inst.categoryId,
    );
    return total;
  }

  static Future<void> editInstallment({
    required String instId,
    required String description,
    String? categoryId,
  }) async {
    // Atualizar registro do parcelamento
    await _sb.from('installments').update({
      'description': description,
      'category_id': categoryId,
    }).eq('id', instId).eq('user_id', uid);
    // Atualizar categoria das transactions vinculadas
    await _sb.from('transactions')
        .update({'category_id': categoryId})
        .eq('installment_id', instId)
        .eq('user_id', uid);
    // Atualizar descrições (manter o padrão "desc (N/total)")
    final parcelas = await _sb.from('transactions')
        .select('id, installment_number')
        .eq('installment_id', instId)
        .eq('user_id', uid)
        .order('installment_number');
    final inst = await _sb.from('installments')
        .select('total_parcelas')
        .eq('id', instId)
        .single();
    final total = inst['total_parcelas'] as int;
    for (final p in parcelas as List) {
      final n = p['installment_number'] as int;
      await _sb.from('transactions').update({
        'description': '\$description (\$n/\$total)',
      }).eq('id', p['id']);
    }
  }

  static Future<void> cancelInstallment(String instId) async {
    await _sb
        .from('transactions')
        .delete()
        .eq('installment_id', instId)
        .eq('user_id', uid);
    await _sb
        .from('installments')
        .delete()
        .eq('id', instId)
        .eq('user_id', uid);
  }
}
