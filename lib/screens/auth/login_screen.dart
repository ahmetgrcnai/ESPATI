import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-posta adresi gerekli.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Geçerli bir e-posta girin.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Şifre gerekli.';
    if (value.length < 6) return 'Şifre en az 6 karakter olmalı.';
    return null;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _signIn(AuthViewModel authVM) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await authVM.signInWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _signInWithGoogle(AuthViewModel authVM) async {
    FocusScope.of(context).unfocus();
    await authVM.signInWithGoogle();
  }

  // ── Snackbar helpers ───────────────────────────────────────────────────────

  void _showErrorIfNeeded(AuthViewModel authVM) {
    if (authVM.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(authVM.errorMessage!,
                  style: GoogleFonts.nunitoSans(fontSize: 13)),
              backgroundColor: EspatiColors.red,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Colors.black, width: 2),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        authVM.clearError();
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    _showErrorIfNeeded(authVM);

    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // ── Logo ────────────────────────────────────────────────────
                const _Logo(),

                const SizedBox(height: 36),

                // ── Heading ─────────────────────────────────────────────────
                Text(
                  'Hoş Geldiniz 🐾',
                  style: GoogleFonts.baloo2(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Patili dostlarınızla buluşmak için giriş yapın.',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // ── Email ────────────────────────────────────────────────────
                AuthTextField(
                  controller: _emailController,
                  label: 'E-posta',
                  hint: 'ornek@email.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                // ── Password ─────────────────────────────────────────────────
                AuthTextField(
                  controller: _passwordController,
                  label: 'Şifre',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                  onFieldSubmitted: (_) => _signIn(authVM),
                ),

                // ── Forgot password ──────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: Text(
                      'Şifremi Unuttum',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13,
                        color: EspatiColors.terracotta,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Sign in button ───────────────────────────────────────────
                AuthPrimaryButton(
                  label: 'Giriş Yap',
                  isLoading: authVM.isSubmitting,
                  onPressed: () => _signIn(authVM),
                ),

                const SizedBox(height: 24),

                // ── Divider ──────────────────────────────────────────────────
                const AuthOrDivider(),

                const SizedBox(height: 24),

                // ── Google ───────────────────────────────────────────────────
                GoogleSignInButton(
                  isLoading: authVM.isSubmitting,
                  onPressed: () => _signInWithGoogle(authVM),
                ),

                const SizedBox(height: 36),

                // ── Sign up link ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hesabınız yok mu?',
                      style: GoogleFonts.nunitoSans(
                          fontSize: 13, color: Colors.black.withValues(alpha: 0.65)),
                    ),
                    TextButton(
                      // Push (not pushReplacement) — SignUpScreen's own back
                      // button just pops back to this exact screen; a
                      // replace here left nothing underneath it to pop to,
                      // which is exactly why that back button did nothing.
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignUpScreen()),
                      ),
                      child: Text(
                        'Kayıt Olun',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 14,
                          color: EspatiColors.terracotta,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AuthIconBadge(icon: Icons.pets_rounded),
        const SizedBox(height: 14),
        Text(
          'ESPATI',
          style: GoogleFonts.baloo2(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
