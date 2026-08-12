import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bmi_tracker/core/constants/app_strings.dart';
import 'package:bmi_tracker/core/errors/app_failure.dart';
import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/core/validators/input_validators.dart';
import 'package:bmi_tracker/providers/providers.dart';
import 'package:bmi_tracker/widgets/common/app_button.dart';
import 'package:bmi_tracker/widgets/common/app_text_field.dart';
import 'package:bmi_tracker/widgets/common/loading_overlay.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const String routePath = '/forgot-password';
  static const String routeName = 'forgotPassword';

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text.trim());
    if (!mounted) return;
    if (ok) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;
    final error = authState.hasError
        ? FailureMapper.fromObject(authState.error!).message
        : null;
    final scheme = Theme.of(context).colorScheme;

    return LoadingOverlay(
      visible: loading,
      message: 'Sending reset link...',
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: _sent
                    ? Column(
                        children: [
                          const SizedBox(height: AppSpacing.xxxl),
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mark_email_read_outlined,
                              size: 36,
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Check your inbox',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            AppStrings.resetEmailSent,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.75),
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          AppButton(
                            label: 'Back to sign in',
                            onPressed: () => context.go('/login'),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppStrings.forgotPasswordTitle,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              AppStrings.forgotPasswordSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.72),
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            AppTextField(
                              controller: _email,
                              label: AppStrings.emailLabel,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.email],
                              prefixIcon: Icons.mail_outline_rounded,
                              validator: InputValidators.email,
                              onSubmitted: (_) => _submit(),
                            ),
                            if (error != null) ...[
                              const SizedBox(height: AppSpacing.lg),
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
                            const SizedBox(height: AppSpacing.xxl),
                            AppButton(
                              label: AppStrings.sendResetLink,
                              onPressed: loading ? null : _submit,
                              isLoading: loading,
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
