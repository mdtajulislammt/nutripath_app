import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/meal_slot.dart';
import '../../models/food_item.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_meal_parser.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';

class MealLoggingDialog extends StatefulWidget {
  final MealSlot targetSlot;

  const MealLoggingDialog({super.key, required this.targetSlot});

  @override
  State<MealLoggingDialog> createState() => _MealLoggingDialogState();
}

class _MealLoggingDialogState extends State<MealLoggingDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  List<FoodItem> _parsedPreview = [];
  String _filterCategory = 'All';

  List<dynamic> _backendFoods = [];
  bool _isLoadingFoods = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBackendFoods();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textCtrl.dispose();
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBackendFoods() async {
    setState(() => _isLoadingFoods = true);
    try {
      final foods = await ApiService.instance.getFoods(
        query: _searchCtrl.text.trim(),
        category: _filterCategory == 'All' ? null : _filterCategory.toUpperCase(),
        limit: 50,
      );
      if (mounted && foods != null) {
        setState(() {
          _backendFoods = foods;
          _isLoadingFoods = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingFoods = false);
  }

  void _onTextChange(String text) {
    // 1. Instant local parse
    setState(() {
      _parsedPreview = BanglaMealParser.parse(text);
    });

    // 2. Debounced smart backend parse
    _debounceTimer?.cancel();
    if (text.trim().isNotEmpty) {
      _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
        try {
          final serverParsed = await ApiService.instance.parseBanglaMeal(text);
          if (mounted && serverParsed != null && serverParsed.isNotEmpty) {
            setState(() {
              _parsedPreview = serverParsed;
            });
          }
        } catch (_) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final slotTarget = (state.metrics.budget * widget.targetSlot.targetShare).round();
    final previewKcal = _parsedPreview.fold(0, (sum, i) => sum + i.kcal);
    final willExceed = (state.slotKcal(widget.targetSlot) + previewKcal) > slotTarget;

    final categories = ['All', 'Carbs', 'Protein', 'Vegetables', 'Fruits', 'Dairy', 'Snacks', 'Beverage'];

    // Fallback to local catalog if backend foods empty
    final localCatalog = BanglaMealParser.catalog.where((item) {
      final matchesCat = _filterCategory == 'All' || item.category == _filterCategory;
      final q = _searchCtrl.text.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.keys.any((k) => k.contains(q));
      return matchesCat && matchesSearch;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.targetSlot.icon, color: AppColors.emeraldDark, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Log ${widget.targetSlot.label}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Target: $slotTarget kcal",
                            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.emeraldPrimary,
                labelColor: AppColors.emeraldDark,
                unselectedLabelColor: AppColors.slate500,
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(LucideIcons.sparkles, size: 16),
                    text: "Natural Text / Voice",
                  ),
                  Tab(
                    icon: Icon(LucideIcons.list, size: 16),
                    text: "Food Catalog",
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Natural Text & Voice
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _textCtrl,
                          onChanged: _onTextChange,
                          decoration: InputDecoration(
                            hintText: "e.g. 1 ta dim ar 1 bati pepe bhaji kheyesi",
                            prefixIcon: const Icon(LucideIcons.messageSquare, color: AppColors.emeraldPrimary, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(LucideIcons.mic, color: AppColors.emeraldPrimary),
                              tooltip: 'Voice Input',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Voice logging ready. Say: '1 plate bhat ar 100g murgir mangsho'"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Parsed Items Preview:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (_parsedPreview.isNotEmpty)
                              Text(
                                "Total: $previewKcal kcal",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emeraldDark,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: _parsedPreview.isEmpty
                              ? Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(16),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.languages, size: 36, color: AppColors.slate400),
                                      SizedBox(height: 8),
                                      Text(
                                        "Type freely in Banglish, Bengali, or English!\nExample: '2 roti 1 bati dal o dim'",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppColors.slate500, fontSize: 12, height: 1.4),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _parsedPreview.length,
                                  itemBuilder: (ctx, i) {
                                    final item = _parsedPreview[i];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: const BorderSide(color: AppColors.slate200),
                                      ),
                                      child: ListTile(
                                        dense: true,
                                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(
                                          '${item.qty} • P: ${item.p}g | C: ${item.c}g | F: ${item.f}g',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: Text(
                                          '${item.kcal} kcal',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.emeraldDark,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),

                    // Tab 2: Food Catalog Quick Select
                    Column(
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (val) {
                            setState(() {});
                            _debounceTimer?.cancel();
                            _debounceTimer = Timer(const Duration(milliseconds: 300), _loadBackendFoods);
                          },
                          decoration: InputDecoration(
                            hintText: "Search food (e.g. bhat, dim, dal)...",
                            prefixIcon: const Icon(LucideIcons.search, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                      _loadBackendFoods();
                                    },
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories.map((cat) {
                              final isSel = _filterCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                                  selected: isSel,
                                  selectedColor: AppColors.emeraldLight,
                                  labelStyle: TextStyle(
                                    color: isSel ? AppColors.emeraldDark : AppColors.slate700,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() => _filterCategory = cat);
                                      _loadBackendFoods();
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _isLoadingFoods
                              ? const Center(child: CircularProgressIndicator(color: AppColors.emeraldPrimary))
                              : _backendFoods.isNotEmpty
                                  ? ListView.builder(
                                      itemCount: _backendFoods.length,
                                      itemBuilder: (ctx, i) {
                                        final item = _backendFoods[i];
                                        final bName = item['bengaliName'] ?? item['name'] ?? '';
                                        final eName = item['name'] ?? '';
                                        final title = bName.isNotEmpty && bName != eName ? '$bName ($eName)' : eName;
                                        final servingQty = item['servingQty'] ?? '1 serving';
                                        final kcal = (item['kcal'] as num?)?.toInt() ?? 0;
                                        final p = (item['proteinG'] as num?)?.toDouble() ?? 0.0;
                                        final c = (item['carbsG'] as num?)?.toDouble() ?? 0.0;
                                        final f = (item['fatG'] as num?)?.toDouble() ?? 0.0;

                                        return Card(
                                          margin: const EdgeInsets.symmetric(vertical: 3),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            side: const BorderSide(color: AppColors.slate200),
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            subtitle: Text(
                                              '$kcal kcal per $servingQty • P: ${p}g C: ${c}g F: ${f}g',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                            trailing: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.emeraldPrimary,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                minimumSize: const Size(50, 32),
                                              ),
                                              onPressed: () {
                                                state.addMealItem(
                                                  widget.targetSlot,
                                                  FoodItem(
                                                    id: item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                                    name: title,
                                                    qty: servingQty,
                                                    kcal: kcal,
                                                    p: p,
                                                    c: c,
                                                    f: f,
                                                  ),
                                                );
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Add", style: TextStyle(fontSize: 12)),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : ListView.builder(
                                      itemCount: localCatalog.length,
                                      itemBuilder: (ctx, i) {
                                        final item = localCatalog[i];
                                        return Card(
                                          margin: const EdgeInsets.symmetric(vertical: 3),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            side: const BorderSide(color: AppColors.slate200),
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            subtitle: Text(
                                              '${item.kcal} kcal per ${item.unit} • P: ${item.p}g C: ${item.c}g',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                            trailing: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.emeraldPrimary,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                minimumSize: const Size(50, 32),
                                              ),
                                              onPressed: () {
                                                state.addMealItem(
                                                  widget.targetSlot,
                                                  FoodItem(
                                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                                    name: item.name,
                                                    qty: '1 ${item.unit}',
                                                    kcal: item.kcal,
                                                    p: item.p,
                                                    c: item.c,
                                                    f: item.f,
                                                  ),
                                                );
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Add", style: TextStyle(fontSize: 12)),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Exceed Warning
              if (willExceed && _parsedPreview.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Notice: Adding this meal will exceed this slot's recommended calorie ceiling.",
                          style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _parsedPreview.isEmpty
                        ? null
                        : () {
                            for (var item in _parsedPreview) {
                              state.addMealItem(widget.targetSlot, item);
                            }
                            Navigator.pop(context);
                          },
                    child: Text(
                      _parsedPreview.isEmpty
                          ? "Confirm & Log"
                          : "Confirm & Log ($previewKcal kcal)",
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
