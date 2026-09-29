import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/diet_day_log.dart';
import '../../models/meal_slot.dart';
import '../../models/food_item.dart';
import '../../services/api_service.dart';

class DietHistoryScreen extends StatefulWidget {
  const DietHistoryScreen({super.key});

  @override
  State<DietHistoryScreen> createState() => _DietHistoryScreenState();
}

class _DietHistoryScreenState extends State<DietHistoryScreen> {
  String _selectedFilter = 'All'; // 'All', 'Within Budget', 'Over Budget'

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.slate400 : const Color(0xFF64748B);
    final cardBg = isDark ? AppColors.slate800 : Colors.white;
    final borderColor = isDark ? AppColors.slate700 : const Color(0xFFE2E8F0);

    final allLogs = state.allDayLogs;
    final daysOnDiet = state.totalDaysOnDiet;

    final filteredLogs = allLogs.where((log) {
      if (_selectedFilter == 'Within Budget') return log.isWithinBudget;
      if (_selectedFilter == 'Over Budget') return !log.isWithinBudget;
      return true;
    }).toList();

    final onTargetCount = allLogs.where((l) => l.isWithinBudget).length;
    final avgKcal = allLogs.isNotEmpty
        ? (allLogs.fold(0, (sum, l) => sum + l.consumedKcal) / allLogs.length).round()
        : 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate900 : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await state.initBackendSync();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Header
                Text(
                  'Diet History',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily meal logs, calories, and journey progress.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 18),

                // Journey Milestone Card ("koto din dhore diet kortesi")
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF064E3B), const Color(0xFF0F3E33)]
                          : [const Color(0xFF00A778), const Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00A778).withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  LucideIcons.flame,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DIET JOURNEY',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Text(
                                    'Consistency Tracking',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$onTargetCount/${allLogs.length} Target Hit',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Large "Days on diet" Counter
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$daysOnDiet',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DAYS ON DIET',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Active streak of clean nutrition',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                      const SizedBox(height: 14),

                      // Milestone mini stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MilestoneMiniStat(
                            label: 'Start Weight',
                            value: '${state.startWeight.toStringAsFixed(1)} kg',
                          ),
                          _MilestoneMiniStat(
                            label: 'Current',
                            value: '${state.currentWeight.toStringAsFixed(1)} kg',
                          ),
                          _MilestoneMiniStat(
                            label: 'Daily Avg',
                            value: '$avgKcal kcal',
                          ),
                          _MilestoneMiniStat(
                            label: 'Target',
                            value: '${state.profile.targetWeight.toStringAsFixed(1)} kg',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Filter Chips Row (All, Within Budget, Over Budget)
                Row(
                  children: [
                    Text(
                      'Daily Logs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    ...['All', 'Within Budget', 'Over Budget'].map((f) {
                      final isSel = _selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: InkWell(
                          onTap: () => setState(() => _selectedFilter = f),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFEAF5F3))
                                  : (isDark ? AppColors.slate800 : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSel ? const Color(0xFF10B981) : borderColor,
                                width: isSel ? 1.3 : 1.0,
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel
                                    ? const Color(0xFF10B981)
                                    : (isDark ? AppColors.slate300 : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 12),

                // History logs list
                if (filteredLogs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.calendarX, size: 36, color: Color(0xFF10B981)),
                        const SizedBox(height: 12),
                        Text(
                          'No logs found',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Log meals today to see them tracked in your history!',
                          style: TextStyle(fontSize: 12.5, color: textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredLogs.map((log) {
                    final isToday = log.id == 'today';
                    return _DayLogCard(
                      log: log,
                      isToday: isToday,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textDark: textDark,
                      textMuted: textMuted,
                      isDark: isDark,
                      onTap: () => _openDayDetailsModal(context, log),
                    );
                  }),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDayDetailsModal(BuildContext context, DietDayLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DayDetailsBottomSheet(log: log),
    );
  }
}

class _MilestoneMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MilestoneMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DayLogCard extends StatelessWidget {
  final DietDayLog log;
  final bool isToday;
  final Color cardBg;
  final Color borderColor;
  final Color textDark;
  final Color textMuted;
  final bool isDark;
  final VoidCallback onTap;

  const _DayLogCard({
    required this.log,
    required this.isToday,
    required this.cardBg,
    required this.borderColor,
    required this.textDark,
    required this.textMuted,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWithin = log.isWithinBudget;
    final diffKcal = (log.consumedKcal - log.targetKcal).abs();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isToday ? const Color(0xFF10B981) : borderColor,
          width: isToday ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Date & Badge Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.slate700 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            log.weekday.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          log.formattedDate,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isWithin
                            ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFEAF5F3))
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isWithin
                            ? 'Within Budget'
                            : '+$diffKcal kcal over',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isWithin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Calorie Bar & Number Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${log.consumedKcal}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${log.targetKcal} kcal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${log.totalFoodItemsCount} items',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: textMuted,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (log.consumedKcal / (log.targetKcal > 0 ? log.targetKcal : 1)).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: isDark ? AppColors.slate700 : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isWithin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Macro badges row & water/walk
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _MiniMacroBadge(
                          label: 'P',
                          grams: '${log.consumedProtein.round()}g',
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        _MiniMacroBadge(
                          label: 'C',
                          grams: '${log.consumedCarbs.round()}g',
                          color: const Color(0xFF17A4E2),
                        ),
                        const SizedBox(width: 6),
                        _MiniMacroBadge(
                          label: 'F',
                          grams: '${log.consumedFat.round()}g',
                          color: const Color(0xFFE17328),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(LucideIcons.droplets, size: 12, color: Color(0xFF17A4E2)),
                        const SizedBox(width: 3),
                        Text(
                          '${(log.waterGlasses * 0.25).toStringAsFixed(1)}L',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.footprints, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 3),
                        Text(
                          '${log.walkMinutes}m',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniMacroBadge extends StatelessWidget {
  final String label;
  final String grams;
  final Color color;

  const _MiniMacroBadge({required this.label, required this.grams, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $grams',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Rich Day Details Bottom Sheet with Live API Fetch
class _DayDetailsBottomSheet extends StatefulWidget {
  final DietDayLog log;

  const _DayDetailsBottomSheet({required this.log});

  @override
  State<_DayDetailsBottomSheet> createState() => _DayDetailsBottomSheetState();
}

class _DayDetailsBottomSheetState extends State<_DayDetailsBottomSheet> {
  Map<MealSlot, List<FoodItem>> _meals = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _meals = Map.from(widget.log.meals);
    final isEmpty = _meals.values.every((list) => list.isEmpty);
    if (isEmpty && widget.log.id != 'today') {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.log.date);
      final data = await ApiService.instance.getHistoryDateDetail(dateStr);
      if (mounted && data != null && data['slots'] != null) {
        final slots = data['slots'] as Map<String, dynamic>;
        final newMeals = <MealSlot, List<FoodItem>>{
          MealSlot.breakfast: [],
          MealSlot.lunch: [],
          MealSlot.snack: [],
          MealSlot.dinner: [],
        };

        slots.forEach((key, val) {
          final slot = ApiService.instance.backendToSlot(key);
          final itemsList = val['items'] as List<dynamic>? ?? [];
          newMeals[slot] = itemsList.map((item) {
            return FoodItem(
              id: item['id'] ?? '',
              name: item['name'] ?? '',
              qty: item['qty'] ?? '1 serving',
              kcal: (item['kcal'] as num?)?.toInt() ?? 0,
              p: (item['proteinG'] as num?)?.toDouble() ?? 0.0,
              c: (item['carbsG'] as num?)?.toDouble() ?? 0.0,
              f: (item['fatG'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();
        });

        setState(() {
          _meals = newMeals;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.slate900 : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.slate400 : const Color(0xFF64748B);
    final borderColor = isDark ? AppColors.slate700 : const Color(0xFFE2E8F0);
    final log = widget.log;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate700 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.formattedDate,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total: ${log.consumedKcal} kcal / ${log.targetKcal} kcal target',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Summary Stats Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DetailMetricCol(label: 'Protein', val: '${log.consumedProtein.round()}g', color: const Color(0xFF10B981)),
                _DetailMetricCol(label: 'Carbs', val: '${log.consumedCarbs.round()}g', color: const Color(0xFF17A4E2)),
                _DetailMetricCol(label: 'Fats', val: '${log.consumedFat.round()}g', color: const Color(0xFFE17328)),
                _DetailMetricCol(label: 'Water', val: '${(log.waterGlasses * 0.25).toStringAsFixed(1)}L', color: const Color(0xFF17A4E2)),
                _DetailMetricCol(label: 'Walk', val: '${log.walkMinutes}m', color: const Color(0xFF10B981)),
              ],
            ),
          ),

          // Meal Slots List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.emeraldPrimary))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: MealSlot.values.map((slot) {
                      final items = _meals[slot] ?? [];
                      final slotTotalKcal = items.fold(0, (sum, i) => sum + i.kcal);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.slate800 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.utensils,
                                      size: 15,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      slot.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFEAF5F3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$slotTotalKcal kcal',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (items.isEmpty)
                              Text(
                                'No food logged in this slot.',
                                style: TextStyle(fontSize: 12.5, color: textMuted, fontStyle: FontStyle.italic),
                              )
                            else
                              ...items.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: textDark,
                                              ),
                                            ),
                                            Text(
                                              '${item.qty} • P:${item.p.round()}g C:${item.c.round()}g F:${item.f.round()}g',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${item.kcal} kcal',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailMetricCol extends StatelessWidget {
  final String label;
  final String val;
  final Color color;

  const _DetailMetricCol({required this.label, required this.val, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}
