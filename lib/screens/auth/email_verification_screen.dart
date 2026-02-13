import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

class EmailVerificationScreen extends HookConsumerWidget {
  final String email;
  final String? firstName;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    this.firstName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeControllers = List.generate(6, (_) => useTextEditingController());
    final focusNodes = List.generate(6, (_) => useFocusNode());
    final isLoading = useState<bool>(false);
    final resendCooldown = useState<int>(0);
    final errorMessage = useState<String?>(null);
    final timerRef = useRef<StreamSubscription?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-focus first field on mount
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        focusNodes[0].requestFocus();
      });
      return null;
    }, []);

    // Dispose timer on unmount
    useEffect(() {
      return () {
        timerRef.value?.cancel();
      };
    }, []);

    // Handle code input
    void onCodeChanged(int index, String value) {
      if (value.length > 1) {
        // Handle paste
        final pastedCode = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (pastedCode.length == 6) {
          for (int i = 0; i < 6 && i < pastedCode.length; i++) {
            codeControllers[i].text = pastedCode[i];
            if (i < 5) {
              focusNodes[i + 1].requestFocus();
            }
          }
          if (pastedCode.length == 6) {
            focusNodes[5].unfocus();
            _verifyCode(context, ref, codeControllers, focusNodes, isLoading, errorMessage);
          }
        } else if (pastedCode.isNotEmpty) {
          codeControllers[index].text = pastedCode[0];
        }
      } else if (value.isNotEmpty) {
        codeControllers[index].text = value;
        if (index < 5) {
          focusNodes[index + 1].requestFocus();
        } else {
          focusNodes[index].unfocus();
          _verifyCode(context, ref, codeControllers, focusNodes, isLoading, errorMessage);
        }
      } else {
        codeControllers[index].text = '';
        if (index > 0) {
          focusNodes[index - 1].requestFocus();
        }
      }
    }

    // Start resend cooldown timer
    void startResendCooldown() {
      // Cancel existing timer if any
      timerRef.value?.cancel();
      
      resendCooldown.value = 60;
      timerRef.value = Stream.periodic(const Duration(seconds: 1), (i) => i)
          .take(60)
          .listen((tick) {
        resendCooldown.value = 60 - tick - 1;
        if (resendCooldown.value == 0) {
          timerRef.value?.cancel();
          timerRef.value = null;
        }
      });
    }

    // Mask email
    String maskEmail(String email) {
      final parts = email.split('@');
      if (parts.length != 2) return email;
      final username = parts[0];
      final domain = parts[1];
      if (username.length <= 2) {
        return '${username[0]}***@$domain';
      }
      return '${username[0]}***@$domain';
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Verifying your email...',
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      PanAfricanColors.primaryDark,
                      PanAfricanColors.secondaryDark,
                    ]
                  : [
                      PanAfricanColors.primaryLight.withOpacity(0.1),
                      PanAfricanColors.secondaryLight.withOpacity(0.1),
                    ],
            ),
          ),
          child: ResponsiveSafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: Semantics(
                      label: 'Back',
                      button: true,
                      child: IconButton(
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
                  ),
                  
                  SizedBox(height: PanAfricanSpacing.xl),
                  
                  // Icon
                  Center(
                    child: Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            PanAfricanColors.primaryLight,
                            PanAfricanColors.secondaryLight,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: PanAfricanColors.primaryLight.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mark_email_read_outlined,
                        size: 50.sp,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: Offset(0.8, 0.8), duration: 400.ms),
                  
                  SizedBox(height: PanAfricanSpacing.xl),
                  
                  // Title
                  Text(
                    'Verify Your Email',
                    style: PanAfricanTypography.headlineLarge(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.1, duration: 400.ms),
                  
                  SizedBox(height: PanAfricanSpacing.md),
                  
                  // Subtitle
                  Text(
                    'We\'ve sent a 6-digit verification code to',
                    style: PanAfricanTypography.bodyLarge(context).copyWith(
                      color: isDark
                          ? PanAfricanColors.textSecondaryDark
                          : PanAfricanColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms),
                  
                  SizedBox(height: PanAfricanSpacing.xs),
                  
                  // Email (masked)
                  Text(
                    maskEmail(email),
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: PanAfricanColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms),
                  
                  SizedBox(height: PanAfricanSpacing.xl),
                  
                  // Error message
                  if (errorMessage.value != null)
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                      decoration: BoxDecoration(
                        color: PanAfricanColors.error.withOpacity(0.1),
                        borderRadius: PanAfricanRadius.lgBR,
                        border: Border.all(
                          color: PanAfricanColors.error,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: PanAfricanColors.error,
                            size: 20.sp,
                          ),
                          SizedBox(width: PanAfricanSpacing.sm),
                          Expanded(
                            child: Text(
                              errorMessage.value!,
                              style: PanAfricanTypography.bodyMedium(context).copyWith(
                                color: PanAfricanColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .shake(duration: 300.ms),
                  
                  // Code input fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 50.w,
                        height: 60.h,
                        child: TextField(
                          controller: codeControllers[index],
                          focusNode: focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: PanAfricanTypography.headlineMedium(context).copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Verification code digit ${index + 1}',
                            counterText: '',
                            filled: true,
                            fillColor: isDark
                                ? PanAfricanColors.surfaceContainerDark
                                : PanAfricanColors.surfaceContainerLight,
                            border: OutlineInputBorder(
                              borderRadius: PanAfricanRadius.mdBR,
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: PanAfricanRadius.mdBR,
                              borderSide: BorderSide(
                                color: isDark
                                    ? PanAfricanColors.borderDark
                                    : PanAfricanColors.borderLight,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: PanAfricanRadius.mdBR,
                              borderSide: BorderSide(
                                color: PanAfricanColors.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: PanAfricanRadius.mdBR,
                              borderSide: BorderSide(
                                color: PanAfricanColors.error,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) => onCodeChanged(index, value),
                        ),
                      );
                    }),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms)
                      .slideY(begin: 0.1, duration: 400.ms),
                  
                  SizedBox(height: PanAfricanSpacing.xl),
                  
                  // Resend button
                  Center(
                    child: Semantics(
                      label: resendCooldown.value > 0
                          ? 'Resend code available in ${resendCooldown.value} seconds'
                          : 'Resend verification code',
                      button: true,
                      enabled: resendCooldown.value == 0,
                      child: TextButton(
                        onPressed: resendCooldown.value > 0
                          ? null
                          : () async {
                              HapticFeedback.lightImpact();
                              errorMessage.value = null;
                              isLoading.value = true;
                              try {
                                await ref
                                    .read(apiProvider.notifier)
                                    .resendVerification(email);
                                startResendCooldown();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Verification code resent to your email',
                                      ),
                                      backgroundColor: PanAfricanColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ErrorHandler.showError(context, e);
                                }
                              } finally {
                                isLoading.value = false;
                              }
                            },
                        child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            color: resendCooldown.value > 0
                                ? (isDark
                                    ? PanAfricanColors.textSecondaryDark
                                    : PanAfricanColors.textSecondaryLight)
                                : PanAfricanColors.primary,
                            size: 20.sp,
                          ),
                          SizedBox(width: PanAfricanSpacing.xs),
                          Text(
                            resendCooldown.value > 0
                                ? 'Resend code in ${resendCooldown.value}s'
                                : 'Resend Code',
                            style: PanAfricanTypography.bodyMedium(context).copyWith(
                              color: resendCooldown.value > 0
                                  ? (isDark
                                      ? PanAfricanColors.textSecondaryDark
                                      : PanAfricanColors.textSecondaryLight)
                                  : PanAfricanColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms),
                  
                  SizedBox(height: PanAfricanSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyCode(
    BuildContext context,
    WidgetRef ref,
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
    ValueNotifier<bool> isLoading,
    ValueNotifier<String?> errorMessage,
  ) async {
    final code = controllers.map((c) => c.text).join();
    if (code.length != 6) {
      errorMessage.value = 'Please enter the complete 6-digit code';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      await ref.read(apiProvider.notifier).verifyEmail(email, code);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email verified successfully!'),
            backgroundColor: PanAfricanColors.success,
          ),
        );
        
        // Navigate back or to home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      // Clear code fields on error
      for (var controller in controllers) {
        controller.clear();
      }
      if (context.mounted && focusNodes.isNotEmpty) {
        focusNodes[0].requestFocus();
      }
    } finally {
      isLoading.value = false;
    }
  }
}
