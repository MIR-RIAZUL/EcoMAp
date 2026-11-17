import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/screens/cloud_backup_auth_screen.dart';
import '../../backup/providers/sync_providers.dart';
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
              'EchoMap is designed as a peaceful, private, offline-first personal memory journal with optional Supabase cloud backup. Every entry, photo, and coordinate is securely preserved locally on your device.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'Version 1.0.0 • Built with Flutter, Drift & Supabase',
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
              '100% Offline-First & Private Storage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '• Local Mode (Default): No registration required. All data remains strictly on your device.\n'
              '• Cloud Backup (Optional): Back up memories to your private Supabase database protected by Row Level Security.\n'
              '• Photos: Uploaded to your isolated private folder in `memory-photos`.\n'
              '• Zero tracking, telemetry, or external ad tracking.\n'
              '• Logging out will NEVER delete your local memories.',
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

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out of Cloud Backup?',
      message:
          'Signing out will switch EchoMap back to Local Mode. All your local memories and photos will remain completely safe on this device.',
      confirmLabel: 'Sign Out',
      isDestructive: false,
      icon: Icons.logout_rounded,
    );

    if (confirmed && context.mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
      await ref.read(cloudBackupEnabledProvider.notifier).setEnabled(false);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Signed out. EchoMap is now in Local Mode.',
          ),
          backgroundColor: AppColors.darkSurfaceVariant,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleSyncNow(BuildContext context, WidgetRef ref) async {
    final syncNotifier = ref.read(syncProvider.notifier);
    final result = await syncNotifier.syncNow();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.summary),
        backgroundColor:
            result.success ? AppColors.primary : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final isCloudEnabled = ref.watch(cloudBackupEnabledProvider);
    final currentUser = ref.watch(currentUserProvider);
    final syncState = ref.watch(syncProvider);

    final isAuthenticated = currentUser != null;
    final isCloudModeActive = isCloudEnabled && isAuthenticated;

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

          // Cloud Backup & Sync Section
          _buildSectionHeader('Cloud Backup & Storage', Icons.cloud_outlined),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Badge & Toggle
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isCloudModeActive
                                  ? AppColors.brightCyan
                                  : AppColors.tertiary)
                              .withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCloudModeActive
                              ? Icons.cloud_done_rounded
                              : Icons.offline_pin_rounded,
                          color: isCloudModeActive
                              ? AppColors.brightCyan
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCloudModeActive
                                  ? 'Cloud Backup Mode'
                                  : 'Local Mode (Default)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCloudModeActive
                                  ? 'Connected to Supabase'
                                  : '100% offline & private on device',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isCloudModeActive,
                        activeTrackColor: AppColors.brightCyan,
                        onChanged: (bool enable) async {
                          if (enable) {
                            if (!isAuthenticated) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CloudBackupAuthScreen(),
                                ),
                              );
                            } else {
                              await ref
                                  .read(cloudBackupEnabledProvider.notifier)
                                  .setEnabled(true);
                            }
                          } else {
                            // Return to Local Mode without signing out
                            await ref
                                .read(cloudBackupEnabledProvider.notifier)
                                .setEnabled(false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Switched to Local Mode.'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),

                  // Content when in Local Mode
                  if (!isCloudModeActive) ...[
                    const SizedBox(height: 12),
                    Text(
                      'No registration or login required. All features work completely offline. You can voluntarily enable cloud backup whenever you wish.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CloudBackupAuthScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                        label: Text(
                          isAuthenticated
                              ? 'Activate Cloud Backup'
                              : 'Sign In / Set Up Cloud Backup',
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Content when in Cloud Backup Mode
                  if (isCloudModeActive) ...[
                    const Divider(height: 24),

                    // User Account Details
                    Row(
                      children: [
                        const Icon(
                          Icons.account_circle_outlined,
                          size: 20,
                          color: AppColors.brightCyan,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentUser.email ?? 'Authenticated User',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Last Sync Time Info
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            syncState.lastSyncTime != null
                                ? 'Last synced: ${DateFormat('d MMM yyyy, h:mm a').format(syncState.lastSyncTime!)}'
                                : 'Not synced yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Sync Error message if any
                    if (syncState.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                syncState.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Sync Now Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: syncState.isSyncing
                            ? null
                            : () => _handleSyncNow(context, ref),
                        icon: syncState.isSyncing
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: Text(
                          syncState.isSyncing ? 'Syncing...' : 'Sync Now',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Sign Out Option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => _handleSignOut(context, ref),
                          icon: const Icon(
                            Icons.logout_rounded,
                            size: 16,
                            color: AppColors.favorite,
                          ),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.favorite,
                            ),
                          ),
                        ),
                        Text(
                          'Local data preserved',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
