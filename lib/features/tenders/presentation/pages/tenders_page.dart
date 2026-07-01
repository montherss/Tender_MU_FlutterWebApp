import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/tender_domain.dart';
import '../cubit/tenders_cubit.dart';
import '../dialogs/create_tender_dialog.dart';

class TendersPage extends StatelessWidget {
  const TendersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TendersCubit, TendersState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) =>
          showAppSnackBar(context, message: state.errorMessage!, isError: true),
      builder: (context, state) {
        return Scaffold(
          body: ResponsivePage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroHeader(
                  onExtractInvoice: () =>
                      context.go(AppConstants.invoiceExtractorPath),
                  onCreate: () async {
                    final created = await showDialog<bool>(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<TendersCubit>(),
                        child: const CreateTenderDialog(),
                      ),
                    );
                    if (created == true && context.mounted) {
                      showAppSnackBar(
                        context,
                        message: 'تم إنشاء العطاء وتحديث القائمة',
                      );
                    }
                  },
                ),
                SizedBox(height: 20.h),
                _SearchAndFilter(state: state),
                SizedBox(height: 18.h),
                Expanded(child: _TendersContent(state: state)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onCreate, required this.onExtractInvoice});

  final VoidCallback onCreate;
  final VoidCallback onExtractInvoice;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(26.r),
      child: Row(
        children: [
          Image.asset(
            AppConstants.brandLogoAsset,
            width: 56,
            height: 56,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نظام إدارة العطاءات',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 4.h),
                Text(
                  AppConstants.universityName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                const Text(
                  'إدارة العطاءات والمواد والمرفقات والقرارات الفنية من لوحة ويب مؤسسية واحدة.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              OutlinedButton.icon(
                onPressed: onExtractInvoice,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('تحليل فاتورة'),
              ),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('إنشاء عطاء'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({required this.state});

  final TendersState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: ResponsiveRowColumn(
        layout: ResponsiveBreakpoints.of(context).smallerThan(TABLET)
            ? ResponsiveRowColumnType.COLUMN
            : ResponsiveRowColumnType.ROW,
        rowSpacing: 12.w,
        columnSpacing: 12.h,
        children: [
          ResponsiveRowColumnItem(
            rowFlex: 2,
            child: TextField(
              onChanged: context.read<TendersCubit>().search,
              decoration: const InputDecoration(
                hintText: 'ابحث برقم العطاء أو الحالة أو رقم الالتزام...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          ResponsiveRowColumnItem(
            child: SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                initialValue: state.statusFilter,
                decoration: const InputDecoration(
                  labelText: 'فلترة حسب الحالة',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('كل الحالات'),
                  ),
                  ...state.statuses.map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  ),
                ],
                onChanged: context.read<TendersCubit>().setStatusFilter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TendersContent extends StatelessWidget {
  const _TendersContent({required this.state});

  final TendersState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == ViewStatus.loading) {
      return const LoadingSkeleton(rows: 6);
    }
    if (state.status == ViewStatus.failure) {
      return EmptyState(
        title: 'تعذر تحميل العطاءات',
        message:
            state.errorMessage ?? 'تحقق من تشغيل واجهة API على localhost:8080',
        icon: Icons.wifi_off_outlined,
      );
    }
    final tenders = state.filteredTenders;
    if (tenders.isEmpty) {
      return const EmptyState(
        title: 'لا توجد عطاءات',
        message: 'أنشئ عطاء جديد أو غيّر معايير البحث والفلترة.',
      );
    }
    return ListView.separated(
      itemCount: tenders.length,
      separatorBuilder: (_, _) => SizedBox(height: 14.h),
      itemBuilder: (context, index) => _TenderCard(tender: tenders[index]),
    );
  }
}

class _TenderCard extends StatelessWidget {
  const _TenderCard({required this.tender});

  final TenderSummary tender;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/tenders/${tender.id}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: .1),
            foregroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              '#${tender.id}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(width: 18.w),
          Expanded(
            child: Wrap(
              runSpacing: 12.h,
              spacing: 28.w,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Info(
                  label: 'رقم طلب الشراء',
                  value: tender.purchaseRequestNo ?? '-',
                ),
                _Info(
                  label: 'تاريخ الإنشاء',
                  value: AppDateFormatter.dateTime(tender.createdAt),
                ),
                _Info(
                  label: 'رقم الالتزام المالي',
                  value: tender.financialCommitmentNo ?? 'غير مدخل',
                ),
                StatusChip(label: tender.status),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.go('/tenders/${tender.id}'),
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'عرض التفاصيل',
          ),
          IconButton(
            onPressed: () => context.go('/tenders/${tender.id}'),
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة',
          ),
          IconButton(
            onPressed: () => context.go('/tenders/${tender.id}'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل',
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
          SizedBox(height: 4.h),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
