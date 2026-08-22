import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Placeholder notifications list. No backend source exists yet — this is
/// wired up so a future feed (e.g. a Supabase `notifications` table) can
/// replace the empty state without touching the bell's navigation.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: const EmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications yet',
        subtitle: 'You\'re all caught up. We\'ll let you know when '
            'something needs your attention.',
      ),
    );
  }
}