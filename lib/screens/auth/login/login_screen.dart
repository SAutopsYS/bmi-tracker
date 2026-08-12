import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bmi_tracker/core/constants/app_strings.dart';
import 'package:bmi_tracker/core/errors/app_failure.dart';
import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/core/validators/input_validators.dart';
import 'package:bmi_tracker/firebase_options.dart';
import 'package:bmi_tracker/providers/providers.dart';
import 'package:bmi_tracker/widgets/common/app_button.dart';
import 'package:bmi_tracker/widgets/common/app_text_field.dart';
import 'package:bmi_tracker/widgets/common/loading_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const String routePath = '/login';
  static const String routeName = 'login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefill email only. Never put DEMO_PASSWORD into the password field.
    if (DemoCredentials.isConfigured) {
      _email.text = DemoCredentials.email;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _goAfterAuth() {
    final profiles = ref.read(profilesProvider).valueOrNull ?? [];
    context.go(profiles.isEmpty ? '/profile-setup' : '/home');
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(authControllerProvider.notifier).signInWithEmail(
          email: _email.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    if (ok) _goAfterAuth();
  }

  Future<void> _google() async {
    ref.read(authControllerProvider.notifier).clearError();
    final ok =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (ok) _goAfterAuth();
  }

  Future<void> _tryDemo() async {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).clearError();
    final ok = await ref.read(authControllerProvider.notifier).signInDemo();
    if (!mounted) return;
    if (ok) _goAfterAuth();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;
    final error = authState.hasError
        ? FailureMapper.fromObject(authState.error!).message
        : null;
    final scheme = Theme.of(context).colorScheme;
    final demoReady = DemoCredentials.isConfigured;

    return LoadingOverlay(
      visible: loading,
      message: 'Signing in...',
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        AppStrings.loginTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppStrings.loginSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.72),
                            ),
                      ),
                      if (!isFirebaseReady) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer
                                .withValues(alpha: 0.65),
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.storage_outlined,
                                color: scheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  AppStrings.localDemoMode,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (demoReady) ...[
                        const SizedBox(height: AppSpacing.xxxl),
                        AppButton(
                          label: AppStrings.demoSignIn,
                          onPressed: loading ? null : _tryDemo,
                          icon: Icons.play_circle_outline_rounded,
                          variant: AppButtonVariant.tonal,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Text(
                                'or email',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ] else
                        const SizedBox(height: AppSpacing.xxxl),
                      if (isFirebaseReady) ...[
                        AppButton(
                          label: AppStrings.continueWithGoogle,
                          onPressed: loading ? null : _google,
                          icon: Icons.g_mobiledata_rounded,
                          variant: AppButtonVariant.tonal,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (!demoReady)
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                child: Text(
                                  'or email',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                        if (!demoReady) const SizedBox(height: AppSpacing.xl),
                      ],
                      AppTextField(
                        controller: _email,
                        label: AppStrings.emailLabel,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        prefixIcon: Icons.mail_outline_rounded,
                        validator: InputValidators.email,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _password,
                        label: AppStrings.passwordLabel,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: InputValidators.password,
                        onSubmitted: (_) => _submit(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: loading
                              ? null
                              : () => context.push('/forgot-password'),
                          child: const Text(AppStrings.forgotPassword),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            error,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: scheme.error),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: AppStrings.signIn,
                        onPressed: loading ? null : _submit,
                        isLoading: loading,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(AppStrings.noAccount),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => context.push('/register'),
                            child: const Text(AppStrings.signUp),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
