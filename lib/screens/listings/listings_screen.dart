import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// İlanlar (Lost & Found) screen — placeholder for upcoming feature.
class ListingsScreen extends StatelessWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanlar'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_rounded,
              size: 72,
              color: AppColors.softTeal.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'İlanlar',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Kayıp & Bulunan ilanları yakında burada!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
