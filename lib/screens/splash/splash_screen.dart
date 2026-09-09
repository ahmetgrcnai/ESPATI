import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../auth/auth_wrapper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPLASH SCREEN (Design System Step 65 — rebuilt).
//
// The *only* branded boot moment in the app — flutter_native_splash has
// been removed entirely (see main.dart), so there is no native splash to
// hand off from anymore. This widget owns 100% of the boot branding: logo,
// slogan, colors, entrance animation.
//
// Routes to [AuthWrapper] (not directly to MainScreen) — AuthWrapper is
// ESPATI's existing auth-check routing logic (watches
// [AuthViewModel.authState] and shows Login vs Main accordingly); jumping
// straight to MainScreen would skip that gate and let an unauthenticated
// user reach the main app.
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(milliseconds: 2500);
  static const _entranceDuration = Duration(milliseconds: 650);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: _entranceDuration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    // Slight overshoot (easeOutBack) — a small, snappy "pop" on entrance
    // rather than a flat linear grow, consistent with the Neo-Brutalist
    // spring feel NeoBrutalistButton uses for presses elsewhere in the app.
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    Future.delayed(_splashDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo — square Neo-Brutalist block, thick darkBrown border,
                // hard offset shadow. Same visual language as every other
                // branded square block in the app (EditProfileScreen's
                // avatar, AddEditPetScreen's photo picker).
                Container(
                  width: 140,
                  height: 140,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(3),
                    boxShadow: NeoBrutal.shadow(const Offset(6, 6)),
                  ),
                  child: Image.asset(
                    'assets/app_icon.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),

                // Slogan — directly underneath the logo.
                Text(
                  'Burada kuralları patiler koyar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 36),

                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: EspatiColors.sageGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
