import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_state_provider.dart';
import '../../models/weight_record.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isWeekly = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.slate400 : const Color(0xFF64748B);
    final cardBg = isDark ? AppColors.slate800 : Colors.white;
    final borderColor = isDark ? AppColors.slate700 : const Color(0xFFE2E8F0);

    // Compute real analytics metrics
    final weightLostKg = (state.startWeight - state.currentWeight);
    final lostText = weightLostKg > 0
        ? '${weightLostKg.toStringAsFixed(1)} kg'
        : '0.0 kg';

    final weeklyList = state.weeklyCompliance;
    final loggedDaysCount = weeklyList.where((d) => (d['hasLogs'] as bool? ?? false)).length;
    final compliantDaysCount = weeklyList.where((d) => (d['hasLogs'] as bool? ?? false) && (d['isWithinBudget'] as bool? ?? false)).length;
    final onTargetText = loggedDaysCount > 0 ? '$compliantDaysCount/$loggedDaysCount days' : '0/7 days';

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate900 : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Analytics & Subtitle
              Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your habits and progress over time.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 18),

              // 3 Top Stat Cards (Lost, Streak, On Target)
              Row(
                children: [
                  Expanded(
                    child: _TopStatCard(
                      icon: LucideIcons.trendingDown,
                      iconColor: const Color(0xFF10B981),
                      label: 'Lost',
                      value: lostText,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TopStatCard(
                      icon: LucideIcons.flame,
                      iconColor: const Color(0xFFE17328),
                      label: 'Streak',
                      value: '${state.streakDays} days',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TopStatCard(
                      icon: LucideIcons.sparkles,
                      iconColor: const Color(0xFF17A4E2),
                      label: 'On target',
                      value: onTargetText,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Weight progression Card
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weight progression',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Current: ${state.currentWeight.toStringAsFixed(1)} kg • Target: ${state.profile.targetWeight.toStringAsFixed(1)} kg',
                              style: TextStyle(fontSize: 11.5, color: textMuted),
                            ),
                          ],
                        ),
                        // Toggle: Weekly / Monthly
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.slate700 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => setState(() => _isWeekly = true),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isWeekly
                                        ? (isDark ? AppColors.slate800 : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _isWeekly
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Weekly',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _isWeekly ? FontWeight.w700 : FontWeight.w500,
                                      color: _isWeekly ? textDark : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() => _isWeekly = false),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: !_isWeekly
                                        ? (isDark ? AppColors.slate800 : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: !_isWeekly
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Monthly',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: !_isWeekly ? FontWeight.w700 : FontWeight.w500,
                                      color: !_isWeekly ? textDark : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _DynamicWeightProgressionPainter(
                          records: state.weightHistory,
                          currentWeight: state.currentWeight,
                          targetWeight: state.profile.targetWeight,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Calorie consistency vs budget Card
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Calorie consistency ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          TextSpan(
                            text: 'vs ${state.metrics.budget} kcal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _DynamicCalorieConsistencyPainter(
                          dailyStats: state.weeklyCompliance,
                          targetKcal: state.metrics.budget,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // AI Weekly Feedback Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF063328) : const Color(0xFFEDF6F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF0D9488) : const Color(0xFFB6E8D7),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          size: 18,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AI Weekly Feedback',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: textDark,
                        ),
                        children: [
                          const TextSpan(text: 'Welcome, '),
                          TextSpan(
                            text: '${state.profile.name.isNotEmpty ? state.profile.name : "Friend"}!',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (loggedDaysCount > 0) ...[
                            TextSpan(text: ' You have logged meals for $loggedDaysCount day(s) this week, staying within budget on '),
                            TextSpan(
                              text: '$compliantDaysCount day(s).',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ] else ...[
                            const TextSpan(text: ' Start logging your daily meals to build your weekly consistency trend!'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'What went well',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _FeedbackBullet(
                      text: state.waterGlasses > 0
                          ? 'Consistent water hydration habit (${(state.waterGlasses * 0.25).toStringAsFixed(1)}L logged today).'
                          : 'Daily hydration goal: 8-12 glasses to maintain optimal metabolism.',
                      textDark: textDark,
                    ),
                    const SizedBox(height: 4),
                    _FeedbackBullet(
                      text: state.walkMinutes > 0
                          ? 'Walking activity recorded (${state.walkMinutes} mins today).'
                          : 'Target 30-40 mins of daily walking for sustained fat loss.',
                      textDark: textDark,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tips for next week',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TipNumbered(
                      number: '1',
                      contentSpan: const TextSpan(
                        children: [
                          TextSpan(text: 'Log your meals right after eating to maintain accurate calorie tracking.'),
                        ],
                      ),
                      textDark: textDark,
                    ),
                    const SizedBox(height: 6),
                    _TipNumbered(
                      number: '2',
                      contentSpan: const TextSpan(
                        children: [
                          TextSpan(text: 'Prioritize South Asian protein sources like boiled eggs, lentil dal, and lean fish.'),
                        ],
                      ),
                      textDark: textDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _TopStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.slate800 : Colors.white;
    final borderColor = isDark ? AppColors.slate700 : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.slate400 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBullet extends StatelessWidget {
  final String text;
  final Color textDark;

  const _FeedbackBullet({required this.text, required this.textDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(
            Icons.circle,
            size: 5.5,
            color: Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: textDark,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _TipNumbered extends StatelessWidget {
  final String number;
  final TextSpan contentSpan;
  final Color textDark;

  const _TipNumbered({
    required this.number,
    required this.contentSpan,
    required this.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. ',
          style: TextStyle(fontSize: 12.5, color: textDark, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12.5, color: textDark, height: 1.35),
              children: [contentSpan],
            ),
          ),
        ),
      ],
    );
  }
}

/// Dynamic painter for Weight Progression line chart
class _DynamicWeightProgressionPainter extends CustomPainter {
  final List<WeightRecord> records;
  final double currentWeight;
  final double targetWeight;
  final bool isDark;

  _DynamicWeightProgressionPainter({
    required this.records,
    required this.currentWeight,
    required this.targetWeight,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 38.0;
    const bottomPadding = 24.0;
    const topPadding = 10.0;
    const rightPadding = 10.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final gridPaint = Paint()
      ..color = isDark ? AppColors.slate700 : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      fontSize: 10,
      color: isDark ? AppColors.slate400 : const Color(0xFF94A3B8),
      fontWeight: FontWeight.w500,
    );

    final weights = records.map((r) => r.weight).toList();
    if (weights.isEmpty) {
      weights.add(currentWeight);
    }

    final maxW = (weights.reduce((a, b) => a > b ? a : b) + 2.0).ceilToDouble();
    final minW = (weights.reduce((a, b) => a < b ? a : b) - 2.0).floorToDouble();
    final range = (maxW - minW) > 0 ? (maxW - minW) : 10.0;
    final midW = ((maxW + minW) / 2).roundToDouble();

    final yLevels = [
      {'val': maxW.toStringAsFixed(0), 'ratio': 0.0},
      {'val': midW.toStringAsFixed(0), 'ratio': 0.5},
      {'val': minW.toStringAsFixed(0), 'ratio': 1.0},
    ];

    for (var lvl in yLevels) {
      final y = topPadding + (chartHeight * (lvl['ratio'] as double));

      _drawDashedLine(
        canvas,
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      final tp = TextPainter(
        text: TextSpan(text: lvl['val'] as String, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 6, y - tp.height / 2));
    }

    // X Labels based on records length or W1..W7
    final count = weights.length;
    final xStep = count > 1 ? chartWidth / (count - 1) : chartWidth;

    for (int i = 0; i < count; i++) {
      final x = leftPadding + (i * xStep);
      final tp = TextPainter(
        text: TextSpan(text: 'W${i + 1}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height));
    }

    if (weights.length == 1) {
      // Draw single point and horizontal line
      final y = topPadding + (chartHeight * (1.0 - (weights[0] - minW) / range));
      final pointPaint = Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(leftPadding + chartWidth / 2, y), 5.0, pointPaint);
      return;
    }

    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = leftPadding + (i * xStep);
      final norm = ((weights[i] - minW) / range).clamp(0.0, 1.0);
      final y = topPadding + (chartHeight * (1.0 - norm));
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.fill;
    for (var pt in points) {
      canvas.drawCircle(pt, 3.5, dotPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 3.5;
    const dashSpace = 3.5;
    double distance = 0.0;
    final totalDistance = (end.dx - start.dx);

    while (distance < totalDistance) {
      final currentX = start.dx + distance;
      final nextX = (currentX + dashWidth).clamp(start.dx, end.dx);
      canvas.drawLine(Offset(currentX, start.dy), Offset(nextX, start.dy), paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Dynamic painter for Calorie Consistency bar chart
class _DynamicCalorieConsistencyPainter extends CustomPainter {
  final List<Map<String, dynamic>> dailyStats;
  final int targetKcal;
  final bool isDark;

  _DynamicCalorieConsistencyPainter({
    required this.dailyStats,
    required this.targetKcal,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 38.0;
    const bottomPadding = 24.0;
    const topPadding = 12.0;
    const rightPadding = 10.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final gridPaint = Paint()
      ..color = isDark ? AppColors.slate700 : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      fontSize: 10,
      color: isDark ? AppColors.slate400 : const Color(0xFF94A3B8),
      fontWeight: FontWeight.w500,
    );

    const maxY = 2000.0;
    final yLevels = [2000, 1500, 1000, 500, 0];

    for (var val in yLevels) {
      final ratio = (maxY - val) / maxY;
      final y = topPadding + (chartHeight * ratio);

      _drawDashedLine(
        canvas,
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      final tp = TextPainter(
        text: TextSpan(text: '$val', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 6, y - tp.height / 2));
    }

    // Red dashed reference line at targetKcal
    final targetY = topPadding + (chartHeight * ((maxY - targetKcal) / maxY).clamp(0.0, 1.0));
    final redDashedPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(leftPadding, targetY),
      Offset(size.width - rightPadding, targetY),
      redDashedPaint,
    );

    // Default 7 days if empty
    final fallbackDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final count = dailyStats.isNotEmpty ? dailyStats.length : 7;
    final colWidth = chartWidth / count;
    final barWidth = colWidth * 0.62;

    for (int i = 0; i < count; i++) {
      final dayLabel = dailyStats.isNotEmpty
          ? (dailyStats[i]['dayOfWeek'] ?? '')
          : fallbackDays[i % 7];

      final consumed = dailyStats.isNotEmpty
          ? ((dailyStats[i]['consumedKcal'] as num?)?.toDouble() ?? 0.0)
          : 0.0;

      final isOver = consumed > targetKcal;
      final barColor = consumed == 0
          ? (isDark ? AppColors.slate700 : const Color(0xFFE2E8F0))
          : (isOver ? const Color(0xFFF97316) : const Color(0xFF10B981));

      final barPaint = Paint()..color = barColor..style = PaintingStyle.fill;

      final centerX = leftPadding + (i * colWidth) + (colWidth / 2);
      final barHeight = (consumed / maxY).clamp(0.0, 1.0) * chartHeight;
      final barTop = topPadding + (chartHeight - (barHeight > 0 ? barHeight : 4));

      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(centerX - (barWidth / 2), barTop, barWidth, barHeight > 0 ? barHeight : 4),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      canvas.drawRRect(barRect, barPaint);

      // Day Label
      final tp = TextPainter(
        text: TextSpan(text: dayLabel, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(centerX - tp.width / 2, size.height - tp.height));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 3.5;
    const dashSpace = 3.5;
    double distance = 0.0;
    final totalDistance = (end.dx - start.dx);

    while (distance < totalDistance) {
      final currentX = start.dx + distance;
      final nextX = (currentX + dashWidth).clamp(start.dx, end.dx);
      canvas.drawLine(Offset(currentX, start.dy), Offset(nextX, start.dy), paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
