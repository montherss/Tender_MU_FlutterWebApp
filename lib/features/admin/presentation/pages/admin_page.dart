import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/admin_cubit.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.userName, required this.role});

  final String userName;
  final String role;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AdminCubit, AdminState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == AdminStatus.success &&
                state.successMessage != null) {
              showAppSnackBar(context, message: state.successMessage!);
            } else if (state.status == AdminStatus.failure &&
                state.errorMessage != null) {
              showAppSnackBar(
                context,
                message: state.errorMessage!,
                isError: true,
              );
            }
          },
        ),
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == AuthStatus.loggedOut) {
              context.go(AppConstants.loginPath);
            } else if (state.status == AuthStatus.failure &&
                state.errorMessage != null) {
              showAppSnackBar(
                context,
                message: state.errorMessage!,
                isError: true,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;
            return isWide
                ? _WideLayout(
                    userName: widget.userName,
                    role: widget.role,
                    selectedIndex: _selectedIndex,
                    onSelectIndex: (i) => setState(() => _selectedIndex = i),
                  )
                : _CompactLayout(
                    userName: widget.userName,
                    role: widget.role,
                    selectedIndex: _selectedIndex,
                    onSelectIndex: (i) => setState(() => _selectedIndex = i),
                  );
          },
        ),
      ),
    );
  }
}

// ─── Wide Layout (≥ 800px) ──────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.userName,
    required this.role,
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  final String userName;
  final String role;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Sidebar(
          userName: userName,
          role: role,
          selectedIndex: selectedIndex,
          onSelectIndex: onSelectIndex,
        ),
        Expanded(
          child: Column(
            children: [
              _TopBar(userName: userName, role: role),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(28.r),
                  child: _PanelContent(selectedIndex: selectedIndex),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Compact Layout (< 800px) ───────────────────────────────────────────────

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.userName,
    required this.role,
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  final String userName;
  final String role;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CompactHeader(userName: userName, role: role),
        _TabBar(
          selectedIndex: selectedIndex,
          onSelectIndex: onSelectIndex,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.r),
            child: _PanelContent(selectedIndex: selectedIndex),
          ),
        ),
      ],
    );
  }
}

// ─── Sidebar ────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.userName,
    required this.role,
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  final String userName;
  final String role;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo + university
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 24.h),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppConstants.brandLogoAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  AppConstants.universityName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppConstants.appTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withValues(alpha: .15), height: 1),
          SizedBox(height: 16.h),

          // Nav items
          _SidebarItem(
            icon: Icons.person_add_outlined,
            label: 'إضافة مستخدم',
            isSelected: selectedIndex == 0,
            onTap: () => onSelectIndex(0),
          ),
          SizedBox(height: 8.h),
          _SidebarItem(
            icon: Icons.store_outlined,
            label: 'إضافة مورد',
            isSelected: selectedIndex == 1,
            onTap: () => onSelectIndex(1),
          ),

          const Spacer(),

          // User info
          Container(
            margin: EdgeInsets.all(16.r),
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withValues(alpha: .2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 3.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: .3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _roleLabel(role),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Logout
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                final isLoggingOut =
                    authState.status == AuthStatus.loggingOut;
                return TextButton.icon(
                  onPressed: isLoggingOut
                      ? null
                      : () => _confirmLogout(context),
                  icon: isLoggingOut
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withValues(alpha: .75),
                          ),
                        )
                      : Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: .75),
                        ),
                  label: Text(
                    isLoggingOut ? 'جاري الخروج...' : 'تسجيل الخروج',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: .18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: .65),
                ),
                SizedBox(width: 10.w),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: .75),
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Top Bar (wide) ──────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.userName, required this.role});

  final String userName;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            'لوحة تحكم المدير',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const Spacer(),
          _UserChip(userName: userName, role: role),
          SizedBox(width: 12.w),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final isLoggingOut =
                  authState.status == AuthStatus.loggingOut;
              return isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.muted,
                      ),
                    )
                  : IconButton(
                      tooltip: 'تسجيل الخروج',
                      onPressed: () => _confirmLogout(context),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.muted,
                      ),
                    );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Compact Header ──────────────────────────────────────────────────────────

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.userName, required this.role});

  final String userName;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 48.h, 16.w, 16.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                AppConstants.brandLogoAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة تحكم المدير',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final isLoggingOut =
                  authState.status == AuthStatus.loggingOut;
              return isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : IconButton(
                      tooltip: 'تسجيل الخروج',
                      onPressed: () => _confirmLogout(context),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                    );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Tab Bar (compact) ───────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Row(
        children: [
          _TabItem(
            icon: Icons.person_add_outlined,
            label: 'إضافة مستخدم',
            isSelected: selectedIndex == 0,
            onTap: () => onSelectIndex(0),
          ),
          _TabItem(
            icon: Icons.store_outlined,
            label: 'إضافة مورد',
            isSelected: selectedIndex == 1,
            onTap: () => onSelectIndex(1),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.muted,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.muted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── User Chip ───────────────────────────────────────────────────────────────

class _UserChip extends StatelessWidget {
  const _UserChip({required this.userName, required this.role});

  final String userName;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.text,
                ),
              ),
              Text(
                _roleLabel(role),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Panel Content ───────────────────────────────────────────────────────────

class _PanelContent extends StatelessWidget {
  const _PanelContent({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      child: selectedIndex == 0
          ? const _AddUserPanel(key: ValueKey('user'))
          : const _AddSupplierPanel(key: ValueKey('supplier')),
    );
  }
}

// ─── Add User Panel ──────────────────────────────────────────────────────────

class _AddUserPanel extends StatefulWidget {
  const _AddUserPanel({super.key});

  @override
  State<_AddUserPanel> createState() => _AddUserPanelState();
}

class _AddUserPanelState extends State<_AddUserPanel> {
  final _formKey = GlobalKey<FormState>();
  final _userNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'USER';
  bool _obscurePassword = true;
  int _dropdownKey = 0;

  static const _roles = ['ADMIN', 'USER', 'REVIEWER'];
  static const _roleLabels = {
    'ADMIN': 'مدير النظام',
    'USER': 'مستخدم',
    'REVIEWER': 'مراجع',
  };

  @override
  void dispose() {
    _userNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AdminCubit>().createUser(
          userName: _userNameCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _selectedRole,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminCubit, AdminState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status &&
          curr.action == AdminActionType.createUser,
      listener: (context, state) {
        if (state.status == AdminStatus.success) {
          _formKey.currentState?.reset();
          _userNameCtrl.clear();
          _passwordCtrl.clear();
          setState(() {
            _selectedRole = 'USER';
            _dropdownKey++;
          });
        }
      },
      child: _FormCard(
        title: 'إضافة مستخدم جديد',
        subtitle: 'أنشئ حسابًا جديدًا وحدد صلاحياته في النظام',
        icon: Icons.person_add_alt_1_outlined,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FieldLabel(label: 'اسم المستخدم'),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _userNameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'مثال: ahmad_ali',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'الرجاء إدخال اسم المستخدم';
                  }
                  if (v.trim().length < 3) {
                    return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              _FieldLabel(label: 'كلمة المرور'),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'كلمة مرور قوية',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'الرجاء إدخال كلمة المرور';
                  }
                  if (v.length < 3) return 'كلمة المرور قصيرة جداً';
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              _FieldLabel(label: 'الصلاحية'),
              SizedBox(height: 6.h),
              DropdownButtonFormField<String>(
                key: ValueKey('role_$_dropdownKey'),
                initialValue: _selectedRole,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                items: _roles
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Row(
                          children: [
                            _RoleDot(role: r),
                            SizedBox(width: 8.w),
                            Text('${_roleLabels[r]} ($r)'),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedRole = v);
                },
              ),
              SizedBox(height: 28.h),
              BlocBuilder<AdminCubit, AdminState>(
                builder: (context, state) {
                  final isLoading = state.isLoadingUser;
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_rounded),
                      label: Text(isLoading ? 'جاري الإنشاء...' : 'إنشاء الحساب'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add Supplier Panel ───────────────────────────────────────────────────────

class _AddSupplierPanel extends StatefulWidget {
  const _AddSupplierPanel({super.key});

  @override
  State<_AddSupplierPanel> createState() => _AddSupplierPanelState();
}

class _AddSupplierPanelState extends State<_AddSupplierPanel> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _selectedType = 'LOCAL';
  bool _isManual = true;
  int _dropdownKey = 0;

  static const _types = ['LOCAL', 'FOREIGN'];
  static const _typeLabels = {'LOCAL': 'محلي', 'FOREIGN': 'أجنبي'};

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AdminCubit>().addSupplier(
          externalSupplierId: _idCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          type: _selectedType,
          contactInfo: _contactCtrl.text.trim(),
          isManual: _isManual ? 1 : 0,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminCubit, AdminState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status &&
          curr.action == AdminActionType.addSupplier,
      listener: (context, state) {
        if (state.status == AdminStatus.success) {
          _formKey.currentState?.reset();
          _idCtrl.clear();
          _nameCtrl.clear();
          _contactCtrl.clear();
          setState(() {
            _selectedType = 'LOCAL';
            _isManual = true;
            _dropdownKey++;
          });
        }
      },
      child: _FormCard(
        title: 'إضافة مورد جديد',
        subtitle: 'سجّل مورداً جديداً وأدخل بياناته الأساسية',
        icon: Icons.store_mall_directory_outlined,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 560;
                  final fieldWidth =
                      isWide ? (constraints.maxWidth - 16) / 2 : double.infinity;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(label: 'رقم المورد الخارجي'),
                            SizedBox(height: 6.h),
                            TextFormField(
                              controller: _idCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'مثال: SUP-2026-001',
                                prefixIcon: Icon(Icons.tag_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'الرجاء إدخال رقم المورد';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(label: 'اسم المورد'),
                            SizedBox(height: 6.h),
                            TextFormField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'مثال: شركة الأمل للتجهيزات',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'الرجاء إدخال اسم المورد';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(label: 'نوع المورد'),
                            SizedBox(height: 6.h),
                            DropdownButtonFormField<String>(
                              key: ValueKey('type_$_dropdownKey'),
                              initialValue: _selectedType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: _types
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        '${_typeLabels[t]} ($t)',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedType = v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(label: 'معلومات التواصل'),
                            SizedBox(height: 6.h),
                            TextFormField(
                              controller: _contactCtrl,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                hintText: 'البريد الإلكتروني | رقم الهاتف',
                                prefixIcon: Icon(Icons.contact_phone_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'الرجاء إدخال معلومات التواصل';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_note_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدخال يدوي',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'هل تمت إضافة هذا المورد يدوياً من قِبل الإدارة؟',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isManual,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: .4),
                      onChanged: (v) => setState(() => _isManual = v),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28.h),
              BlocBuilder<AdminCubit, AdminState>(
                builder: (context, state) {
                  final isLoading = state.isLoadingSupplier;
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_business_rounded),
                      label: Text(isLoading ? 'جاري الإضافة...' : 'إضافة المورد'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Helpers ──────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 680),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: .05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .06),
                  AppColors.primary.withValues(alpha: .02),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: const Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.r),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.text,
      ),
    );
  }
}

class _RoleDot extends StatelessWidget {
  const _RoleDot({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'ADMIN' => AppColors.danger,
      'REVIEWER' => AppColors.gold,
      _ => AppColors.success,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

String _roleLabel(String role) {
  return switch (role.toUpperCase()) {
    'ADMIN' => 'مدير النظام',
    'USER' => 'مستخدم',
    'REVIEWER' => 'مراجع',
    _ => role,
  };
}

Future<void> _confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
          SizedBox(width: 10),
          Text('تسجيل الخروج'),
        ],
      ),
      content: const Text(
        'هل أنت متأكد من رغبتك في تسجيل الخروج من النظام؟',
        style: TextStyle(color: AppColors.muted, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('خروج'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    context.read<AuthCubit>().logout();
  }
}
