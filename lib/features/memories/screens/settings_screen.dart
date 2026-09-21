import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleClearAllMemories(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Erase All Memories?',
      message:
          'This will permanently delete all your journal entries, photos, and locations stored on this device. This action CANNOT be undone.',
      confirmLabel: 'Erase Everything',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed && context.mounted) {
      final repo = ref.read(memoryRepositoryProvider);
      await repo.deleteAllMemories();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All memories have been erased.'),
          backgroundColor: AppColors.darkSurfaceVariant,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.explore_rounded,
              color: AppColors.primary, size: 36),
        ),
        title: const Text('EchoMap'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Life as a Memory Map',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'EchoMap is designed as a peaceful, private, offline-first personal memory journal. Every entry, photo, and coordinate stays strictly on your Android device without any external cloud syncing or tracking.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'Version 1.0.0 • Built with Flutter & Drift',
              style: TextStyle(fontSize: 12, color: AppColors.lightCyan),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.tertiary.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_rounded,
              color: AppColors.tertiary, size: 36),
        ),
        title: const Text('Privacy First'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '100% Offline & On-Device Storage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '• No accounts or registration required.\n'
              '• Zero tracking, telemetry, or analytics.\n'
              '• All memory titles, descriptions, and coordinates are saved in a local SQLite database.\n'
              '• Images are kept in your app-specific internal documents directory.\n'
              '• OpenStreetMap tiles are requested only when viewing the map.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Theme Section Header
          _buildSectionHeader('Appearance', Icons.palette_outlined),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(newSelection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Privacy & Storage Section
          _buildSectionHeader('Privacy & Data', Icons.security_rounded),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined,
                      color: AppColors.tertiary),
                  title: const Text('Privacy Information'),
                  subtitle: const Text('How your memories and data are stored'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showPrivacyDialog(context),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded,
                      color: AppColors.favorite),
                  title: const Text(
                    'Clear All Memories',
                    style: TextStyle(color: AppColors.favorite),
                  ),
                  subtitle: const Text('Permanently erase all journal entries'),
                  onTap: () => _handleClearAllMemories(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About Section
          _buildSectionHeader('About', Icons.info_outline_rounded),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.explore_rounded,
                      color: AppColors.primary),
                  title: const Text(AppConstants.appName),
                  subtitle: const Text(AppConstants.appTagline),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showAboutDialog(context),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                const ListTile(
                  leading: Icon(Icons.tag_rounded),
                  title: Text('App Version'),
                  trailing: Text(
                    AppConstants.appVersion,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
