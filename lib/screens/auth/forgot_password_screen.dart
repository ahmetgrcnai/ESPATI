import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ── Validator ──────────────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-posta adresi gerekli.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Geçerli bir e-posta girin.';
    return null;
  }

  // ── Action ─────────────────────────────────────────────────────────────────

  Future<void> _sendResetEmail(AuthViewModel authVM) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await authVM.sendPasswordResetEmail(
      email: _emailController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    }
  }

  // ── Snackbar helpers ───────────────────────────────────────────────────────

  void _handleMessages(AuthViewModel authVM) {
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

    if (authVM.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(authVM.successMessage!,
                  style: GoogleFonts.nunitoSans(fontSize: 13)),
              backgroundColor: EspatiColors.sageGreen,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Colors.black, width: 2),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
        authVM.clearSuccess();
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    _handleMessages(authVM);

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
                // ── Back ─────────────────────────────────────────────────────
                const AuthBackButton(),

                const SizedBox(height: 32),

                // ── Icon ─────────────────────────────────────────────────────
                const AuthIconBadge(
                  icon: Icons.lock_reset_rounded,
                  color: EspatiColors.lightBlue,
                ),

                const SizedBox(height: 24),

                // ── Heading ───────────────────────────────────────────────────
                Text(
                  'Şifremi Unuttum',
                  style: GoogleFonts.baloo2(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'E-posta adresinizi girin. Şifre sıfırlama bağlantısını\nhemen gönderelim.',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // ── Email ─────────────────────────────────────────────────────
                AuthTextField(
                  controller: _emailController,
                  label: 'E-posta',
                  hint: 'ornek@email.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: _validateEmail,
                  onFieldSubmitted: (_) => _sendResetEmail(authVM),
                ),

                const SizedBox(height: 28),

                // ── Send button ───────────────────────────────────────────────
                AuthPrimaryButton(
                  label: 'Sıfırlama Bağlantısı Gönder',
                  isLoading: authVM.isSubmitting,
                  onPressed: () => _sendResetEmail(authVM),
                ),

                const SizedBox(height: 24),

                // ── Back to login ─────────────────────────────────────────────
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Giriş ekranına dön',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14,
                      color: EspatiColors.terracotta,
                      fontWeight: FontWeight.w600,
                    ),
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
