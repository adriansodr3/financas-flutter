import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';

/// Widget de seleção de categoria com botão inline para criar nova.
/// Retorna a categoria selecionada via [onChanged].
class CategorySelector extends StatefulWidget {
  final String type; // 'income' | 'expense'
  final Category? initial;
  final ValueChanged<Category?> onChanged;

  const CategorySelector({
    super.key,
    required this.type,
    required this.onChanged,
    this.initial,
  });

  @override
  State<CategorySelector> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategorySelector> {
  List<Category> _cats = [];
  Category? _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.initial;
    _load();
  }

  Future<void> _load() async {
    final cats = await DB.getCategories(type: widget.type);
    if (mounted) {
      setState(() {
        _cats = cats;
        if (_sel == null && cats.isNotEmpty) {
          _sel = cats.first;
          widget.onChanged(_sel);
        }
      });
    }
  }

  Future<void> _createNew() async {
    String selIcon = 'more_horiz';
    final nameCtrl = TextEditingController();
    final icons = <String, IconData>{
      'home': Icons.home_outlined,
      'restaurant': Icons.restaurant_outlined,
      'directions_car': Icons.directions_car_outlined,
      'favorite': Icons.favorite_outline,
      'school': Icons.school_outlined,
      'celebration': Icons.celebration_outlined,
      'receipt_long': Icons.receipt_long_outlined,
      'work': Icons.work_outline,
      'computer': Icons.computer_outlined,
      'checkroom': Icons.checkroom_outlined,
      'attach_money': Icons.attach_money,
      'trending_up': Icons.trending_up,
      'fitness_center': Icons.fitness_center_outlined,
      'music_note': Icons.music_note_outlined,
      'local_cafe': Icons.local_cafe_outlined,
      'sports_bar': Icons.sports_bar_outlined,
      'local_pharmacy': Icons.local_pharmacy_outlined,
      'flight': Icons.flight_outlined,
      'smartphone': Icons.smartphone_outlined,
      'pets': Icons.pets_outlined,
      'fastfood': Icons.fastfood_outlined,
      'card_giftcard': Icons.card_giftcard_outlined,
      'lightbulb': Icons.lightbulb_outline,
      'more_horiz': Icons.more_horiz,
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('Nova Categoria',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText))),
                IconButton(icon: const Icon(Icons.close, color: kMuted), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome da categoria')),
              const SizedBox(height: 12),
              const Text('Icone', style: TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6, crossAxisSpacing: 6, mainAxisSpacing: 6),
                  itemCount: icons.length,
                  itemBuilder: (_, i) {
                    final key = icons.keys.elementAt(i);
                    final ico = icons[key]!;
                    final sel = selIcon == key;
                    return GestureDetector(
                      onTap: () => setSt(() => selIcon = key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: sel ? kPurple.withOpacity(0.2) : kCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: sel ? kPurple : kBorder),
                        ),
                        child: Icon(ico, color: sel ? kPurple : kMuted, size: 20),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await DB.createCategory(nameCtrl.text.trim(), widget.type, selIcon);
                    Navigator.pop(ctx);
                    await _load();
                    // Selecionar a nova categoria
                    final newCat = _cats.firstWhere(
                        (c) => c.name == nameCtrl.text.trim(),
                        orElse: () => _cats.last);
                    if (mounted) setState(() { _sel = newCat; widget.onChanged(_sel); });
                  },
                  child: const Text('Criar Categoria'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.type == 'income' ? kGreen : kRed;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Categoria', style: TextStyle(fontSize: 12, color: kMuted)),
      const SizedBox(height: 6),
      SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // Botão criar nova categoria
            GestureDetector(
              onTap: _createNew,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kPurple.withOpacity(0.5), style: BorderStyle.solid),
                ),
                child: const Row(children: [
                  Icon(Icons.add, size: 14, color: kPurple),
                  SizedBox(width: 4),
                  Text('Nova', style: TextStyle(fontSize: 12, color: kPurple)),
                ]),
              ),
            ),
            // Categorias existentes
            ..._cats.map((c) {
              final sel = _sel?.id == c.id;
              return GestureDetector(
                onTap: () => setState(() { _sel = c; widget.onChanged(c); }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.15) : kCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? color : kBorder, width: sel ? 1.5 : 1),
                  ),
                  child: Text(c.name,
                      style: TextStyle(fontSize: 12,
                          color: sel ? color : kMuted,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                ),
              );
            }),
          ],
        ),
      ),
    ]);
  }
}
