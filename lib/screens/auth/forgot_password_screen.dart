import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/validators.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/title_logo.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController(text: kDebugMode ? "atif@gmail.com" : null);
    final formKey = GlobalObjectKey<FormState>(context);
    final isLoading = ref.watch(apiProvider).isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            icon: Icon(
              PanAfricanIcons.back,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 0.1.sh),
                  Center(child: const TitleLogo()),
                  SizedBox(height: PanAfricanSpacing.xl),
                  
                  // Title
                  Text(
                    'Reset Password',
                    style: PanAfricanTypography.headlineMedium(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  Text(
                    'Enter your email address and we\'ll send you instructions to reset your password.',
                    style: PanAfricanTypography.bodyMedium(context).copyWith(
                      color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: PanAfricanSpacing.xl),
                  
                  // Email field
                  Text(
                    'Email',
                    style: PanAfricanTypography.labelLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: Validators.emailValidator,
                    style: PanAfricanTypography.bodyLarge(context),
                    decoration: InputDecoration(
                      hintText: 'Enter your registered email',
                      prefixIcon: Icon(Icons.email_outlined, color: PanAfricanColors.primary),
                      filled: true,
                      fillColor: isDark
                          ? PanAfricanColors.surfaceContainerDark
                          : PanAfricanColors.surfaceContainerLight,
                      border: OutlineInputBorder(
                        borderRadius: PanAfricanRadius.lgBR,
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: PanAfricanRadius.lgBR,
                        borderSide: BorderSide(
                          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: PanAfricanRadius.lgBR,
                        borderSide: BorderSide(
                          color: PanAfricanColors.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: PanAfricanRadius.lgBR,
                        borderSide: BorderSide(color: PanAfricanColors.error, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: PanAfricanSpacing.md,
                        vertical: PanAfricanSpacing.md,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: PanAfricanSpacing.lg),
                  
                  // Reset button
                  GestureDetector(
                    onTap: () async {
                      if (!formKey.currentState!.validate()) {
                        HapticFeedback.mediumImpact();
                        return;
                      }
                      HapticFeedback.mediumImpact();
                      try {
                        final result =
                            await ref.read(apiProvider.notifier).resetPassword(emailController.text.trim());
                        if (result != true) {
                          if (context.mounted) {
                            ErrorHandler.showError(
                              context,
                              Exception('Failed to reset password. Please try again.'),
                            );
                          }
                          return;
                        }
                        if (context.mounted) {
                          await ref.read(dialogProvider('')).showPlatformDialogue(
                              title: "Reset Password",
                              content: Text(
                                "An email with instructions to reset your password has been sent to ${emailController.text.trim()}",
                              ));
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ErrorHandler.showError(context, e);
                        }
                      }
                    },
                    child: Container(
                      height: 56.h,
                      decoration: BoxDecoration(
                        gradient: PanAfricanGradients.forest,
                        borderRadius: PanAfricanRadius.lgBR,
                        boxShadow: PanAfricanShadows.glowGreen(0.3),
                      ),
                      child: Center(
                        child: Text(
                          'Reset Password',
                          style: PanAfricanTypography.titleLarge(context).copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
