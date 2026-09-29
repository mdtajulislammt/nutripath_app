import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../core/constants/app_colors.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _targetWeightCtrl;
  late TextEditingController _calorieCtrl;

  final List<String> _availableConditions = [
    'Diabetes',
    'High BP',
    'Thyroid',
    'Fatty Liver',
    'Gastric',
    'None',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateProvider>();
    _nameCtrl = TextEditingController(text: state.profile.name);
    _weightCtrl = TextEditingController(text: state.profile.weight.toInt().toString());
    _targetWeightCtrl = TextEditingController(text: state.profile.targetWeight.toInt().toString());
    _calorieCtrl = TextEditingController(
      text: (state.profile.kcalOverride ?? state.metrics.budget).toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _calorieCtrl.dispose();
    super.dispose();
  }

  void _toggleCondition(String cond, AppStateProvider state) {
    final current = List<String>.from(state.profile.conditions);
    if (cond == 'None') {
      current.clear();
      current.add('None');
    } else {
      current.remove('None');
      if (current.contains(cond)) {
        current.remove(cond);
        if (current.isEmpty) {
          current.add('None');
        }
      } else {
        current.add(cond);
      }
    }
    state.updateProfile(state.profile.copyWith(conditions: current));
  }


  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.slate400 : const Color(0xFF64748B);
    final cardBg = isDark ? AppColors.slate800 : Colors.white;
    final borderColor = isDark ? AppColors.slate700 : const Color(0xFFE2E8F0);
    final inputBg = isDark ? AppColors.slate700 : Colors.white;

    final profile = state.profile;
    final isGoogleLinked = profile.isGoogleLinked;
    final daysOnDiet = state.totalDaysOnDiet;
    final weightLost = (110.0 - profile.weight).clamp(0.0, 100.0);
    final totalTargetLoss = (110.0 - profile.targetWeight).clamp(1.0, 100.0);
    final lossProgress = (weightLost / totalTargetLoss).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate900 : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Account, Google sync, and personalized diet targets.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 18),

              // 1. Google Account Card ("google diye login korte parbe")
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isGoogleLinked ? const Color(0xFF10B981) : borderColor,
                    width: isGoogleLinked ? 1.4 : 1.1,
                  ),
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
                      children: [
                        // Avatar or Google Photo
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'T',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (isGoogleLinked)
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(child: _GoogleGLogo(size: 14)),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      isGoogleLinked
                                          ? (profile.googleDisplayName ?? profile.name)
                                          : profile.name,
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: textDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isGoogleLinked) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Color(0xFF10B981),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isGoogleLinked
                                    ? (profile.googleEmail ?? 'Connected Google Account')
                                    : 'Guest Account • Not Synced',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isGoogleLinked
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF97316),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isGoogleLinked ? 'Cloud Sync Active' : 'Cloud Sync Off',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isGoogleLinked
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF97316),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Google Action Button
                    if (isGoogleLinked)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              _GoogleGLogo(size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Google Account Connected',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () async {
                              await state.signOutGoogle();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'Switch / Sign out',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/login'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.slate700 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _GoogleGLogo(size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Diet Journey Progress Overview ("koto din dore diet kortesi")
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Diet Milestone',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5F3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Day $daysOnDiet active',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatBox(label: 'Starting', value: '110.0 kg', textDark: textDark, textMuted: textMuted),
                        _StatBox(label: 'Current', value: '${profile.weight.toStringAsFixed(1)} kg', textDark: textDark, textMuted: textMuted),
                        _StatBox(label: 'Target', value: '${profile.targetWeight.toStringAsFixed(1)} kg', textDark: textDark, textMuted: textMuted),
                        _StatBox(label: 'Lost', value: '${weightLost.toStringAsFixed(1)} kg', textDark: const Color(0xFF10B981), textMuted: textMuted),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: lossProgress,
                        minHeight: 7,
                        backgroundColor: isDark ? AppColors.slate700 : const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Body Profile & Measurements
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
                    Text(
                      'Body Measurements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current weight (kg)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textDark),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 1.1),
                                ),
                                child: TextField(
                                  controller: _weightCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  onChanged: (val) {
                                    final p = double.tryParse(val);
                                    if (p != null && p > 20) {
                                      state.updateProfile(profile.copyWith(weight: p));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Target weight (kg)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textDark),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 1.1),
                                ),
                                child: TextField(
                                  controller: _targetWeightCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  onChanged: (val) {
                                    final p = double.tryParse(val);
                                    if (p != null && p > 20) {
                                      state.updateProfile(profile.copyWith(targetWeight: p));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Health conditions
                    Text(
                      'Health conditions',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textDark),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableConditions.map((cond) {
                        final isSelected = profile.conditions.contains(cond);
                        return InkWell(
                          onTap: () => _toggleCondition(cond, state),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : (isDark ? AppColors.slate700 : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                    : (isDark ? AppColors.slate600 : const Color(0xFFE2E8F0)),
                                width: 1.1,
                              ),
                            ),
                            child: Text(
                              cond,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : textDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Daily Calorie Ceiling
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
                    Text(
                      'Daily calorie ceiling',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI প্রস্তাবিত টার্গেট: ${state.metrics.autoBudget} kcal (আপনার ডেটা অনুযায়ী)। কাস্টম করতে চাইলে লিখুন, অথবা AI অটো টার্গেটে ফিরতে খালি রাখুন।',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: 1.1),
                            ),
                            child: TextField(
                              controller: _calorieCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              onChanged: (val) {
                                final parsed = int.tryParse(val);
                                state.setKcalOverride(parsed);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            state.setKcalOverride(null);
                            _calorieCtrl.text = state.metrics.budget.toString();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.slate700 : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppColors.slate600 : const Color(0xFFE2E8F0),
                                width: 1.1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.refreshCw, size: 15, color: textDark),
                                const SizedBox(width: 6),
                                Text(
                                  'Auto',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Dark Theme Switch
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    const Icon(LucideIcons.moon, size: 22, color: Color(0xFF10B981)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dark theme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark)),
                          const SizedBox(height: 2),
                          Text('Easier on the eyes at night', style: TextStyle(fontSize: 12, color: textMuted)),
                        ],
                      ),
                    ),
                    Switch(
                      value: state.isDark,
                      activeThumbColor: const Color(0xFF10B981),
                      activeTrackColor: const Color(0xFFD1FAE5),
                      onChanged: (_) => state.toggleTheme(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Redo onboarding centered link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    );
                  },
                  child: Text(
                    'Redo onboarding',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color textDark;
  final Color textMuted;

  const _StatBox({
    required this.label,
    required this.value,
    required this.textDark,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11.5, color: textMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
      ],
    );
  }
}

class _GoogleGLogo extends StatelessWidget {
  final double size;

  const _GoogleGLogo({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGLogoPainter()),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw the 4 colored Google "G" segments
    final paintBlue = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    final paintGreen = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;
    final paintYellow = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final paintRed = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final innerRadius = radius * 0.55;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    // Blue segment: right horizontal bar & arc
    final bluePath = Path()
      ..moveTo(center.dx, center.dy - (radius * 0.2))
      ..lineTo(center.dx + radius, center.dy - (radius * 0.2))
      ..lineTo(center.dx + radius, center.dy + (radius * 0.2))
      ..arcTo(rect, 0, 0.8, false)
      ..lineTo(center.dx + (innerRadius * 0.7), center.dy)
      ..close();
    canvas.drawPath(bluePath, paintBlue);

    // Green segment: bottom right to bottom left arc
    final greenPath = Path()
      ..arcTo(rect, 0.7, 1.0, false)
      ..arcTo(innerRect, 1.7, -1.0, false)
      ..close();
    canvas.drawPath(greenPath, paintGreen);

    // Yellow segment: left bottom arc
    final yellowPath = Path()
      ..arcTo(rect, 1.7, 1.0, false)
      ..arcTo(innerRect, 2.7, -1.0, false)
      ..close();
    canvas.drawPath(yellowPath, paintYellow);

    // Red segment: top arc
    final redPath = Path()
      ..arcTo(rect, 2.7, 1.0, false)
      ..arcTo(innerRect, 3.7, -1.0, false)
      ..close();
    canvas.drawPath(redPath, paintRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
