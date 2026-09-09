import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../main_screen.dart';
import 'login_screen.dart';

/// The root navigation gate of ESPATI.
///
/// Watches [AuthViewModel.authState] and renders the correct screen with
/// zero manual navigation calls. Firebase's auth stream is the single
/// source of truth — any session change (sign-in, sign-out, token refresh)
/// automatically swaps the widget tree.
///
/// States:
///   [AuthState.unknown]         → yükleniyor (stream henüz cevap vermedi)
///   [AuthState.authenticated]   → [MainScreen] (uygulamanın ana ekranı)
///   [AuthState.unauthenticated] → [LoginScreen] (giriş ekranı)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return switch (authVM.authState) {
      AuthState.unknown => const Scaffold(
          backgroundColor: NeoBrutal.scaffoldBg,
          body: Center(
            child: CircularProgressIndicator(
              color: EspatiColors.terracotta,
            ),
          ),
        ),
      AuthState.authenticated  => const MainScreen(),
      AuthState.unauthenticated => const LoginScreen(),
    };
  }
}
