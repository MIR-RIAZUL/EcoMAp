import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';

class CloudBackupAuthScreen extends ConsumerStatefulWidget {
  const CloudBackupAuthScreen({super.key});

  @override
  ConsumerState<CloudBackupAuthScreen> createState() =>
      _CloudBackupAuthScreenState();
}

class _CloudBackupAuthScreenState extends ConsumerState<CloudBackupAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showConfigureCredentialsDialog() {
    final urlController =
        TextEditingController(text: SupabaseConfig.url);
    final keyController =
        TextEditingController(text: SupabaseConfig.anonKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Supabase'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your Supabase Project URL and Public Anon Key. You can also define these in `.env` or via `--dart-define`.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Project URL',
                  hintText: 'https://xyzcompany.supabase.co',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Publishable Anon Key',
                  hintText: 'eyJhbGciOi...',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final scaffold = ScaffoldMessenger.of(context);
              await SupabaseConfig.saveCredentials(
                url: urlController.text.trim(),
                anonKey: keyController.text.trim(),
              );
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                setState(() {});
                scaffold.showSnackBar(
                  const SnackBar(
                    content: Text('Supabase credentials updated.'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!SupabaseConfig.isConfigured) {
      _showConfigureCredentialsDialog();
      return;
    }

    final authNotifier = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool success;
    if (_isSignUp) {
      success = await authNotifier.signUp(email: email, password: password);
    } else {
      success = await authNotifier.signIn(email: email, password: password);
    }

    if (mounted) {
      final authState = ref.read(authControllerProvider);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authState.successMessage ??
                  (_isSignUp ? 'Account created!' : 'Signed in!'),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      } else if (authState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_reset_rounded,
            color: AppColors.primary, size: 36),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered email address and we will send you a password reset link.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address.'),
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(authControllerProvider.notifier)
                  .resetPassword(email);
              if (mounted) {
                final authState = ref.read(authControllerProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (authState.successMessage ??
                              'Reset instructions sent!')
                          : (authState.errorMessage ??
                              'Failed to send reset link.'),
                    ),
                    backgroundColor:
                        success ? AppColors.primary : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Cloud Account' : 'Cloud Backup Sign In'),
        actions: [
          IconButton(
            tooltip: 'Configure Supabase Keys',
            icon: const Icon(Icons.settings_suggest_outlined),
            onPressed: _showConfigureCredentialsDialog,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Emblem & Cloud Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.brightCyan.withAlpha(80),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.cloud_sync_rounded,
                        size: 48,
                        color: AppColors.brightCyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isSignUp
                        ? 'Join EchoMap Cloud'
                        : 'Welcome Back to EchoMap',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? 'Create a secure Supabase account to back up and sync your private memories and photos.'
                        : 'Sign in to access your cloud-backed memories. Your local data remains completely intact.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Missing Config Warning Card if credentials not set
                  if (!SupabaseConfig.isConfigured) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade700),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.amber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Supabase Credentials Needed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap the top-right settings icon or configure `.env` with SUPABASE_URL and SUPABASE_ANON_KEY.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.amber.shade200
                                        : Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Password is required';
                      }
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password for Sign Up
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Forgot Password Link (Only for Sign In)
                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : _showForgotPasswordDialog,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.brightCyan,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Submit Action Button
                  FilledButton(
                    onPressed: authState.isLoading ? null : _handleSubmit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isSignUp ? 'Create Cloud Account' : 'Sign In',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Toggle between Sign In and Sign Up
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? 'Already have an account?'
                            : "Don't have an account?",
                        style: const TextStyle(fontSize: 13),
                      ),
                      TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .reset();
                                });
                              },
                        child: Text(
                          _isSignUp ? 'Sign In' : 'Sign Up',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brightCyan,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Return to Local Mode Option
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Return to Local Mode'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
