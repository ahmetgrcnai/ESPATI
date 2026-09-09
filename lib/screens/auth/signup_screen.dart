import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/google_sign_in_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ad Soyad gerekli.';
    if (value.trim().length < 2) return 'En az 2 karakter girin.';
    return null;
  }

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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Şifre tekrarı gerekli.';
    if (value != _passwordController.text) return 'Şifreler eşleşmiyor.';
    return null;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _signUp(AuthViewModel authVM) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await authVM.signUpWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
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
                  style: GoogleFonts.poppins(fontSize: 13)),
              backgroundColor: AppColors.error,
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
                // ── Back button ──────────────────────────────────────────────
                const AuthBackButton(),

                const SizedBox(height: 16),

                // ── Heading ──────────────────────────────────────────────────
                const AuthIconBadge(icon: Icons.pets_rounded, size: 72),
                const SizedBox(height: 16),
                Text(
                  'Hesap Oluştur',
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'ESPATI ailesine katılın!',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // ── Name ─────────────────────────────────────────────────────
                AuthTextField(
                  controller: _nameController,
                  label: 'Ad Soyad',
                  hint: 'Ahmet Yılmaz',
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  validator: _validateName,
                ),
                const SizedBox(height: 16),

                // ── Email ─────────────────────────────────────────────────────
                AuthTextField(
                  controller: _emailController,
                  label: 'E-posta',
                  hint: 'ornek@email.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                // ── Password ──────────────────────────────────────────────────
                AuthTextField(
                  controller: _passwordController,
                  label: 'Şifre',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),

                // ── Confirm password ──────────────────────────────────────────
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: 'Şifre Tekrarı',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirmPassword,
                  onFieldSubmitted: (_) => _signUp(authVM),
                ),

                const SizedBox(height: 28),

                // ── Sign up button ────────────────────────────────────────────
                AuthPrimaryButton(
                  label: 'Kayıt Ol',
                  isLoading: authVM.isSubmitting,
                  onPressed: () => _signUp(authVM),
                ),

                const SizedBox(height: 24),

                // ── Divider ───────────────────────────────────────────────────
                const AuthOrDivider(),

                const SizedBox(height: 24),

                // ── Google ────────────────────────────────────────────────────
                GoogleSignInButton(
                  isLoading: authVM.isSubmitting,
                  onPressed: () => _signInWithGoogle(authVM),
                ),

                const SizedBox(height: 32),

                // ── Login link ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Zaten hesabınız var mı?',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.black.withValues(alpha: 0.65)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      ),
                      child: Text(
                        'Giriş Yapın',
                        style: GoogleFonts.poppins(
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
