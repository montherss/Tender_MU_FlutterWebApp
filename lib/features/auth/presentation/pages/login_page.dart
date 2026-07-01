import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userNameFocus = FocusNode();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _userNameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _userNameFocus.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          showAppSnackBar(
            context,
            message: state.message ?? 'تم تسجيل الدخول بنجاح',
          );
          if (state.isAdmin) {
            context.go(AppConstants.adminPath);
          } else {
            context.go(AppConstants.tendersPath);
          }
        } else if (state.status == AuthStatus.failure) {
          showAppSnackBar(
            context,
            message: state.errorMessage ?? 'تعذر تسجيل الدخول',
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const _LoginBackground(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        constraints.maxWidth >= 900 &&
                        constraints.maxHeight >= 560;

                    return Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 24.h,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isWide ? 1040 : 440,
                            minHeight: isWide
                                ? (constraints.maxHeight - 48.h)
                                    .clamp(480.0, 720.0)
                                : 0,
                          ),
                          child: isWide
                              ? _WideLoginCard(
                                  isLoading: isLoading,
                                  formKey: _formKey,
                                  userNameFocus: _userNameFocus,
                                  userNameController: _userNameController,
                                  passwordController: _passwordController,
                                  obscurePassword: _obscurePassword,
                                  onTogglePassword: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  onSubmit: () => _submit(isLoading),
                                )
                              : _CompactLoginCard(
                                  isLoading: isLoading,
                                  formKey: _formKey,
                                  userNameFocus: _userNameFocus,
                                  userNameController: _userNameController,
                                  passwordController: _passwordController,
                                  obscurePassword: _obscurePassword,
                                  onTogglePassword: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  onSubmit: () => _submit(isLoading),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit(bool isLoading) {
    if (isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().login(
          userName: _userNameController.text,
          password: _passwordController.text,
        );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFFFFF5F5),
            AppColors.background,
            AppColors.primary.withValues(alpha: .06),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowCircle(
              diameter: 320,
              color: AppColors.primary.withValues(alpha: .12),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _GlowCircle(
              diameter: 280,
              color: AppColors.primaryDark.withValues(alpha: .08),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _WideLoginCard extends StatelessWidget {
  const _WideLoginCard({
    required this.isLoading,
    required this.formKey,
    required this.userNameFocus,
    required this.userNameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final bool isLoading;
  final GlobalKey<FormState> formKey;
  final FocusNode userNameFocus;
  final TextEditingController userNameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: .14),
              blurRadius: 48,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: _BrandPanel()),
                Expanded(
                  child: ColoredBox(
                    color: AppColors.surface,
                    child: _LoginForm(
                      formKey: formKey,
                      isLoading: isLoading,
                      userNameFocus: userNameFocus,
                      userNameController: userNameController,
                      passwordController: passwordController,
                      obscurePassword: obscurePassword,
                      onTogglePassword: onTogglePassword,
                      onSubmit: onSubmit,
                      padding: EdgeInsets.symmetric(
                        horizontal: 48.w,
                        vertical: 48.h,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactLoginCard extends StatelessWidget {
  const _CompactLoginCard({
    required this.isLoading,
    required this.formKey,
    required this.userNameFocus,
    required this.userNameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final bool isLoading;
  final GlobalKey<FormState> formKey;
  final FocusNode userNameFocus;
  final TextEditingController userNameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _LoginLogo(height: 168),
        SizedBox(height: 20.h),
        Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: .08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: _LoginForm(
              formKey: formKey,
              isLoading: isLoading,
              userNameFocus: userNameFocus,
              userNameController: userNameController,
              passwordController: passwordController,
              obscurePassword: obscurePassword,
              onTogglePassword: onTogglePassword,
              onSubmit: onSubmit,
              padding: EdgeInsets.all(24.r),
              showHeaderLogo: false,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          AppConstants.universityName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 48.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _LoginLogo(height: 220, onLightBackground: true),
            SizedBox(height: 28.h),
            Text(
              AppConstants.universityName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .92),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppConstants.appTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: 16.h),
            Text(
              'منصة موحدة لإدارة العطاءات والمواد والمرفقات والمتابعة الفنية.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .82),
                    height: 1.6,
                  ),
            ),
            SizedBox(height: 28.h),
            const _BrandFeature(
              icon: Icons.assignment_outlined,
              label: 'إدارة العطاءات والمواد',
            ),
            SizedBox(height: 10.h),
            const _BrandFeature(
              icon: Icons.verified_outlined,
              label: 'متابعة القرارات والمرفقات',
            ),
            const Spacer(),
            const AppCopyrightFooter(lightText: true),
          ],
        ),
      ),
    );
  }
}

class _BrandFeature extends StatelessWidget {
  const _BrandFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Colors.white.withValues(alpha: .9)),
        SizedBox(width: 10.w),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .88),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo({required this.height, this.onLightBackground = false});

  final double height;
  final bool onLightBackground;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      AppConstants.loginLogoAsset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!onLightBackground) return logo;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: logo,
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.isLoading,
    required this.userNameFocus,
    required this.userNameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.padding,
    this.showHeaderLogo = true,
  });

  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final FocusNode userNameFocus;
  final TextEditingController userNameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final EdgeInsetsGeometry padding;
  final bool showHeaderLogo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeaderLogo) ...[
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
            Text(
              'تسجيل الدخول',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: 6.h),
            const Text(
              'أدخل بيانات حسابك للوصول إلى النظام.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            SizedBox(height: 28.h),
            TextFormField(
              controller: userNameController,
              focusNode: userNameFocus,
              textInputAction: TextInputAction.next,
              enabled: !isLoading,
              autofillHints: const [AutofillHints.username],
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال اسم المستخدم';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              enabled: !isLoading,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                  onPressed: isLoading ? null : onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال كلمة المرور';
                }
                return null;
              },
            ),
            SizedBox(height: 28.h),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('تسجيل الدخول'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
