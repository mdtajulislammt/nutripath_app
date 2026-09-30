import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_state_provider.dart';

class GoogleLoginScreen extends StatefulWidget {
  final bool initialIsRegister;
  const GoogleLoginScreen({super.key, this.initialIsRegister = false});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isSigningIn = false;
  late AnimationController _animController;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Real Firebase Google Sign-In
  Future<void> _handleGoogleAuth() async {
    setState(() => _isSigningIn = true);

    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // Mobile (Android / iOS) Native Google Account Selector
        try {
          final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
          try {
            await googleSignIn.signOut();
          } catch (_) {}

          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
          if (googleUser == null) {
            if (mounted) setState(() => _isSigningIn = false);
            return;
          }

          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        } catch (nativeErr) {
          debugPrint('Native GoogleSignIn fallback: $nativeErr');
          final googleProvider = GoogleAuthProvider();
          googleProvider.setCustomParameters({'prompt': 'select_account'});
          userCredential = await FirebaseAuth.instance.signInWithProvider(googleProvider);
        }
      }

      final user = userCredential.user;
      if (user != null) {
        final idToken = await user.getIdToken();
        final email = user.email ?? '';
        final name = user.displayName ?? (email.isNotEmpty ? email.split('@').first : 'NutriPath User');
        final avatarUrl = user.photoURL;
        final uid = user.uid;
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        if (!mounted) return;
        final state = context.read<AppStateProvider>();
        final success = await state.signInWithGoogle(
          email: email,
          name: name,
          idToken: idToken,
          avatarUrl: avatarUrl,
          firebaseUid: uid,
          isNewUser: isNewUser,
        );

        if (success && mounted) {
          final route = state.isOnboarded ? '/dashboard' : '/onboarding';
          Navigator.pushReplacementNamed(context, route);
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      if (mounted) {
        if (e.code == 'popup-closed-by-user' || e.code == 'canceled') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('সাইন-ইন বাতিল করা হয়েছে')),
          );
        } else {
          _showErrorDialog(e.message ?? e.code, errorCode: e.code);
        }
      }
    } catch (e) {
      debugPrint('Google Sign-in error: $e');
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _performDirectLogin({
    required String email,
    required String name,
  }) async {
    setState(() => _isSigningIn = true);

    try {
      final state = context.read<AppStateProvider>();
      final success = await state.signInWithGoogle(
        email: email,
        name: name,
      );

      if (success && mounted) {
        final route = state.isOnboarded ? '/dashboard' : '/onboarding';
        Navigator.pushReplacementNamed(context, route);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('লগইন ব্যর্থ হয়েছে: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _showErrorDialog(String errorMsg, {String? errorCode}) {
    String friendlyMessage = errorMsg;
    final code = (errorCode ?? '').toLowerCase();
    final lower = errorMsg.toLowerCase();

    if (code == 'configuration-not-found' || code == 'operation-not-allowed') {
      friendlyMessage =
          'Firebase Console-এ Google Sign-in সক্রিয় (Enabled) করা নেই।\n\n'
          '👉 সমাধান:\n'
          '১. Firebase Console > Authentication > Sign-in method-এ গিয়ে Google Provider অন করুন।\n'
          '২. অথবা এখনই কোনো সেটআপ ছাড়াই সরাসরি প্রবেশ করতে নিচের "ডেমো অ্যাকাউন্ট" ব্যবহার করুন।';
    } else if (code == 'unauthorized-domain') {
      friendlyMessage =
          'এই ডোমেইনটি (localhost) Firebase Authorized Domains-এ যুক্ত নেই।\n'
          'Firebase Console > Authentication > Settings-এ localhost যুক্ত করুন অথবা ডেমো অ্যাকাউন্ট ব্যবহার করুন।';
    } else if (code == 'popup-blocked' || lower.contains('popup') || lower.contains('blocked')) {
      friendlyMessage = 'ব্রাউজারে পপ-আপ ব্লক করা হয়েছে। ব্রাউজারের URL বারে পপ-আপ অনুমোদন (Allow) করুন অথবা নিচের "ডেমো অ্যাকাউন্ট" দিয়ে সরাসরি প্রবেশ করুন।';
    } else if (lower.contains('network') || lower.contains('failed')) {
      friendlyMessage = 'নেটওয়ার্ক সংযোগে সমস্যা হয়েছে। ইন্টারনেট কানেকশন চেক করে আবার চেষ্টা করুন।';
    } else if (errorMsg.trim() == 'Error') {
      friendlyMessage = 'গুগল সাইন-ইনে সমস্যা দেখা দিয়েছে। আপনি নিচের "ডেমো অ্যাকাউন্ট" ব্যবহার করে সরাসরি প্রবেশ করতে পারেন।';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131D24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('লগইন তথ্য', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          friendlyMessage,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.45),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showQuickTestSheet();
            },
            child: const Text('ডেমো অ্যাকাউন্ট দিয়ে প্রবেশ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ঠিক আছে', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }

  void _showQuickTestSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111E1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'ডেমো অ্যাকাউন্ট নির্বাচন করুন',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF10B981),
                  child: Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: const Text('Md Tajul Islam', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                subtitle: const Text('tajul.dev@gmail.com', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF10B981)),
                onTap: () {
                  Navigator.pop(ctx);
                  _performDirectLogin(
                    email: 'tajul.dev@gmail.com',
                    name: 'Md Tajul Islam',
                  );
                },
              ),
              Divider(height: 12, color: Colors.white.withValues(alpha: 0.08)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF059669),
                  child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: const Text('Tajul Islam', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                subtitle: const Text('mdtajulislam.dev@gmail.com', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF10B981)),
                onTap: () {
                  Navigator.pop(ctx);
                  _performDirectLogin(
                    email: 'mdtajulislam.dev@gmail.com',
                    name: 'Tajul Islam',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071412),
      body: Stack(
        children: [
          // Ambient soft luminous orbs
          Positioned(
            top: -50,
            left: -30,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Floating Brand Emblem
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: child,
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft glow aura behind the emblem
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (context, child) {
                                return Container(
                                  width: 120 * _pulseAnim.value,
                                  height: 120 * _pulseAnim.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF10B981).withValues(alpha: 0.28),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Main Squircle Brand Emblem
                            Container(
                              width: 86,
                              height: 86,
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
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.45),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.leaf,
                                  size: 42,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Brand Name
                      const Text(
                        'NutriPath',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Minimal 1-line Tagline
                      const Text(
                        'AI পুষ্টি ও ডায়েট ট্র্যাকার',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 52),

                      // Google Sign-In Action
                      if (_isSigningIn)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: CircularProgressIndicator(color: Color(0xFF10B981)),
                        )
                      else
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleGoogleAuth,
                            borderRadius: BorderRadius.circular(16),
                            child: Ink(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoogleGLogo(size: 22),
                                  SizedBox(width: 12),
                                  Text(
                                    'Google দিয়ে শুরু করুন',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Prominent Demo Access
                      OutlinedButton.icon(
                        onPressed: _showQuickTestSheet,
                        icon: const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF10B981)),
                        label: const Text(
                          'ডেমো অ্যাকাউন্ট দিয়ে লগইন করুন',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Official Vector Google 'G' Logo
class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({this.size = 22});

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
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Blue Path
    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green Path
    final greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1)
      ..lineTo(2.18, 14.1)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow Path
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final yellowPath = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(5.84, 7.06)
      ..lineTo(2.18, 7.06)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.94)
      ..lineTo(5.84, 14.09)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red Path
    final redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    final redPath = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.06)
      ..lineTo(5.84, 9.9)
      ..cubicTo(6.71, 7.3, 9.14, 5.38, 12.0, 5.38)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
