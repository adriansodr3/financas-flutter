// Widget reutilizável: seletor de categoria com opção de criar nova inline
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../theme.dart';

class CategorySelector extends StatefulWidget {
  final String type; // 'income' | 'expense'
  final void Function(Category?) onChanged;
  final Category? initial;

  const CategorySelector({
    super.key,
    required this.type,
    required this.onChanged,
    this.initial,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  List<Category> _cats = [];
  Category? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _load();
  }

  Future<void> _load() async {
    final cats = await DB.getCategories(type: widget.type);
    if (mounted) {
      setState(() {
        _cats = cats;
        if (_selected == null && cats.isNotEmpty) {
          _selected = cats.first;
          widget.onChanged(_selected);
        }
      });
    }
  }

  Future<void> _createNew() async {
    final nameCtrl = TextEditingController();
    String selIcon = 'more_horiz';

    const icons = <String, IconData>{
      'home': Icons.home_outlined,
      'restaurant': Icons.restaurant_outlined,
      'directions_car': Icons.directions_car_outlined,
      'favorite': Icons.favorite_outline,
      'school': Icons.school_outlined,
      'work': Icons.work_outline,
      'computer': Icons.computer_outlined,
      'receipt_long': Icons.receipt_long_outlined,
      'celebration': Icons.celebration_outlined,
      'fitness_center': Icons.fitness_center_outlined,
      'local_cafe': Icons.local_cafe_outlined,
      'fastfood': Icons.fastfood_outlined,
      'flight': Icons.flight_outlined,
      'smartphone': Icons.smartphone_outlined,
      'pets': Icons.pets_outlined,
      'card_giftcard': Icons.card_giftcard_outlined,
      'local_pharmacy': Icons.local_pharmacy_outlined,
      'music_note': Icons.music_note_outlined,
      'sports_esports': Icons.sports_esports_outlined,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.add_circle_outline, color: kPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Nova ${widget.type == "income" ? "categoria de entrada" : "categoria de despesa"}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome da categoria'),
                ),
                const SizedBox(height: 12),
                const Text('Icone', style: TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6),
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
                            color: sel ? kPurple.withOpacity(0.15) : kCard,
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
                      await DB.createCategory(
                          nameCtrl.text.trim(), widget.type, selIcon);
                      Navigator.pop(ctx);
                      await _load();
                      // Selecionar a nova categoria criada
                      if (mounted) {
                        final newest = _cats.firstWhere(
                            (c) => c.name == nameCtrl.text.trim(),
                            orElse: () => _cats.last);
                        setState(() => _selected = newest);
                        widget.onChanged(newest);
                      }
                    },
                    child: const Text('Criar categoria'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.type == 'income' ? kGreen : kRed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: kPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kPurple.withOpacity(0.5)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.add, color: kPurple, size: 14),
                    SizedBox(width: 4),
                    Text('Nova', style: TextStyle(fontSize: 12, color: kPurple, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              // Categorias existentes
              ..._cats.map((c) {
                final sel = _selected?.id == c.id;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selected = c);
                    widget.onChanged(c);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
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
              }),
            ],
          ),
        ),
      ],
    );
  }
}
