import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _pulseController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _letterSpacing;
  late Animation<double> _progressAnimation;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // Main entrance animation
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Continuous ambient pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Logo entrance physics
    _logoScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoRotate = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Brand text entrance
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _letterSpacing = Tween<double>(begin: 0.5, end: 2.2).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 0.95, curve: Curves.easeOut),
      ),
    );

    // Progress bar fill
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _introController.forward();

    // Auto navigate after animation completes
    _navTimer = Timer(const Duration(milliseconds: 2100), () async {
      if (!mounted) return;
      final state = context.read<AppStateProvider>();
      await state.ensureInitialized();
      if (!mounted) return;

      final String route;
      if (!state.isAuthenticated) {
        // Not logged in -> ALWAYS show Login screen!
        route = '/login';
      } else if (state.isOnboarded) {
        // Already logged in & completed onboarding -> Directly to Dashboard!
        route = '/dashboard';
      } else {
        // Logged in with new account -> Onboarding 4 steps
        route = '/onboarding';
      }
      Navigator.pushReplacementNamed(context, route);
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061512),
      body: Stack(
        children: [
          // Background ambient gradient with animated aura
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse = _pulseController.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 0.85 + (pulse * 0.25),
                      colors: [
                        Color.lerp(
                          const Color(0xFF064E3B),
                          const Color(0xFF0D9488),
                          pulse,
                        )!.withValues(alpha: 0.45),
                        const Color(0xFF071F1B),
                        const Color(0xFF030E0C),
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // Central Animated Brand Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Logo Badge
                AnimatedBuilder(
                  animation: Listenable.merge([_introController, _pulseController]),
                  builder: (context, child) {
                    final pulse = _pulseController.value;
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotate.value,
                        child: Opacity(
                          opacity: _logoFade.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ambient glow ring
                              Container(
                                width: 130 + (pulse * 14),
                                height: 130 + (pulse * 14),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.emeraldPrimary.withValues(alpha: 0.12 + (pulse * 0.08)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.emeraldPrimary.withValues(alpha: 0.25),
                                      blurRadius: 36,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),

                              // Secondary soft ring
                              Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.emeraldAccent.withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                ),
                              ),

                              // Inner Glass-morphic Brand Logo Core
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                      Color(0xFF047857),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1.8,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.leaf,
                                    size: 44,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Animated App Title & Subtitle
                AnimatedBuilder(
                  animation: _introController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFade.value,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            Text(
                              "NutriPath",
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: _letterSpacing.value,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldPrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.emeraldPrimary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Text(
                                "DAILY NUTRITION & HABIT COMPASS",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.emeraldLight,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 52),

                // Sleek animated progress line
                AnimatedBuilder(
                  animation: _introController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFade.value,
                      child: Container(
                        width: 140,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.emeraldAccent,
                                  AppColors.emeraldPrimary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emeraldAccent.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
