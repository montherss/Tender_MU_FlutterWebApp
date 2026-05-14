import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/tender_domain.dart';
import '../cubit/tenders_cubit.dart';
import '../widgets/tender_sections.dart';

class TenderDetailsPage extends StatelessWidget {
  const TenderDetailsPage({super.key, required this.tenderId});

  final int tenderId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TenderDetailsCubit, TenderDetailsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) =>
          showAppSnackBar(context, message: state.errorMessage!, isError: true),
      builder: (context, state) {
        return Scaffold(
          body: ResponsivePage(
            child: switch (state.status) {
              ViewStatus.loading ||
              ViewStatus.initial => const LoadingSkeleton(rows: 7),
              ViewStatus.failure => EmptyState(
                title: 'تعذر تحميل تفاصيل العطاء',
                message: state.errorMessage ?? 'تحقق من الاتصال بالخادم.',
                icon: Icons.error_outline,
              ),
              ViewStatus.success => _DetailsContent(state: state),
            },
          ),
        );
      },
    );
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({required this.state});

  final TenderDetailsState state;

  @override
  Widget build(BuildContext context) {
    final tender = state.tender!;
    final locked = tender.needsFinancialCommitment;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _DetailsHeader(tender: tender)),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        SliverToBoxAdapter(
          child: FinancialCommitmentSection(
            key: ValueKey(
              'financial-${tender.id}-${tender.financialCommitmentNo}',
            ),
            tender: tender,
          ),
        ),
        if (locked) ...[
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          const SliverToBoxAdapter(
            child: EmptyState(
              title: 'الأقسام الأخرى غير مفعلة',
              message:
                  'أدخل رقم الالتزام المالي أولاً لتفعيل المعلومات والمواد والمرفقات والإحالات وملفات PDF.',
              icon: Icons.lock_outline,
            ),
          ),
        ] else ...[
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          SliverToBoxAdapter(
            child: _DetailsTabs(tender: tender, state: state),
          ),
        ],
      ],
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.tender});

  final TenderDetails tender;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(24.r),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/tenders'),
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'العودة',
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل العطاء #${tender.id}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 6.h),
                Text(
                  tender.subject ??
                      tender.purchaseRequestNo ??
                      'عطاء بدون عنوان',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          StatusChip(label: tender.status),
        ],
      ),
    );
  }
}

class _DetailsTabs extends StatefulWidget {
  const _DetailsTabs({required this.tender, required this.state});

  final TenderDetails tender;
  final TenderDetailsState state;

  @override
  State<_DetailsTabs> createState() => _DetailsTabsState();
}

class _DetailsTabsState extends State<_DetailsTabs>
    with TickerProviderStateMixin {
  late final TabController _controller = TabController(length: 8, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(12.r),
      child: Column(
        children: [
          TabBar(
            controller: _controller,
            isScrollable: true,
            tabs: const [
              Tab(text: 'الفئة والنوع'),
              Tab(text: 'المعلومات الأساسية'),
              Tab(text: 'المواد'),
              Tab(text: 'الموردين'),
              Tab(text: 'عروض الأسعار'),
              Tab(text: 'إحالة عطاء'),
              Tab(text: 'الإحالات'),
              //Tab(text: 'PDF'),
              Tab(text: 'المرفقات'),
            ],
          ),
          SizedBox(
            height: 650.h,
            child: TabBarView(
              controller: _controller,
              children: [
                _tab(
                  CategoryTypeSection(
                    key: ValueKey('category-${widget.tender.hashCode}'),
                    tender: widget.tender,
                  ),
                ),
                _tab(
                  BasicInfoSection(
                    key: ValueKey('basic-${widget.tender.hashCode}'),
                    tender: widget.tender,
                  ),
                ),
                _tab(
                  ItemsSection(
                    key: ValueKey('items-${widget.tender.hashCode}'),
                    tender: widget.tender,
                  ),
                ),
                _tab(SuppliersSection(state: widget.state)),
                _tab(SupplierItemOffersSection(state: widget.state)),
                _tab(TenderItemAssignmentSection(state: widget.state)),
                _tab(AssignmentsSection(state: widget.state)),
                //_tab(PdfSection(key: ValueKey('pdf-${widget.tender.hashCode}'), tender: widget.tender)),
                _tab(
                  AttachmentsSection(
                    key: ValueKey('attachments-${widget.tender.hashCode}'),
                    tender: widget.tender,
                    progress: widget.state.uploadProgress,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(Widget child) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(14.r),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: child,
      ),
    );
  }
}
