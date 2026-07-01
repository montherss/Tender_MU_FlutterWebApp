import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/invoice_domain.dart';
import '../cubit/invoice_cubit.dart';

class InvoiceExtractorPage extends StatelessWidget {
  const InvoiceExtractorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceCubit, InvoiceState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) =>
          showAppSnackBar(context, message: state.errorMessage!, isError: true),
      builder: (context, state) {
        final isLoading = state.status == InvoiceExtractionStatus.loading;
        return Scaffold(
          body: ResponsivePage(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InvoiceHeader(isLoading: isLoading),
                  SizedBox(height: 20.h),
                  AppCard(
                    padding: EdgeInsets.all(22.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'استخراج بيانات الفاتورة',
                          subtitle:
                              'ارفع ملف PDF أو صورة JPG/PNG، وسيبقى التطبيق في وضع انتظار حتى تعود نتيجة التحليل من الخادم.',
                          icon: Icons.receipt_long_outlined,
                          trailing:
                              state.invoice == null &&
                                  state.selectedFileName == null
                              ? null
                              : TextButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : context.read<InvoiceCubit>().clear,
                                  icon: const Icon(Icons.refresh_outlined),
                                  label: const Text('إعادة تعيين'),
                                ),
                        ),
                        SizedBox(height: 18.h),
                        ResponsiveRowColumn(
                          layout:
                              ResponsiveBreakpoints.of(
                                context,
                              ).smallerThan(TABLET)
                              ? ResponsiveRowColumnType.COLUMN
                              : ResponsiveRowColumnType.ROW,
                          rowSpacing: 18.w,
                          columnSpacing: 18.h,
                          rowCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResponsiveRowColumnItem(
                              rowFlex: 1,
                              child: _InvoiceUploadBox(
                                isLoading: isLoading,
                                progress: state.uploadProgress,
                                fileName: state.selectedFileName,
                              ),
                            ),
                            ResponsiveRowColumnItem(
                              rowFlex: 2,
                              child: state.invoice == null
                                  ? _InvoiceResultPlaceholder(
                                      isLoading: isLoading,
                                    )
                                  : _InvoiceResult(invoice: state.invoice!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InvoiceHeader extends StatelessWidget {
  const _InvoiceHeader({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(24.r),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26.r,
            backgroundColor: AppColors.primary.withValues(alpha: .1),
            foregroundColor: AppColors.primary,
            child: const Icon(Icons.document_scanner_outlined),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تحليل الفواتير',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 4.h),
                const Text(
                  'استخراج بيانات العميل والأصناف والإجمالي من ملف فاتورة.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: isLoading ? null : () => context.go('/tenders'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('العودة للرئيسية'),
          ),
        ],
      ),
    );
  }
}

class _InvoiceUploadBox extends StatelessWidget {
  const _InvoiceUploadBox({
    required this.isLoading,
    required this.progress,
    required this.fileName,
  });

  final bool isLoading;
  final double? progress;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final showIndeterminateProgress =
        isLoading && (progress == null || progress! >= 1);
    return InkWell(
      onTap: isLoading ? null : () => _pickInvoiceFile(context),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary, width: 1.2),
          color: AppColors.primary.withValues(alpha: .05),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 42.r,
              color: AppColors.primary,
            ),
            SizedBox(height: 10.h),
            Text(
              isLoading
                  ? 'جاري رفع وتحليل الملف...'
                  : 'اضغط لاختيار ملف فاتورة',
              style: const TextStyle(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              fileName ?? 'الصيغ المدعومة: PDF, JPG, PNG',
              style: const TextStyle(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            if (isLoading) ...[
              SizedBox(height: 14.h),
              _AiProcessingIndicator(
                progress: showIndeterminateProgress ? null : progress,
                compact: true,
              ),
              SizedBox(height: 10.h),
              const Text(
                'قد تستغرق معالجة الذكاء الاصطناعي وقتًا أطول، يرجى عدم إغلاق الشاشة حتى تظهر البيانات.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickInvoiceFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !context.mounted) return;
    await context.read<InvoiceCubit>().extractInvoice(result.files.single);
  }
}

class _InvoiceResultPlaceholder extends StatelessWidget {
  const _InvoiceResultPlaceholder({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        color: Colors.white,
      ),
      child: isLoading
          ? const _AiProcessingIndicator()
          : Row(
              children: [
                const Icon(Icons.description_outlined, color: AppColors.muted),
                SizedBox(width: 10.w),
                const Expanded(
                  child: Text(
                    'ستظهر هنا بيانات الفاتورة بعد نجاح الاستخراج.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AiProcessingIndicator extends StatefulWidget {
  const _AiProcessingIndicator({this.progress, this.compact = false});

  final double? progress;
  final bool compact;

  @override
  State<_AiProcessingIndicator> createState() => _AiProcessingIndicatorState();
}

class _AiProcessingIndicatorState extends State<_AiProcessingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = .55 + (_controller.value * .45);
        final scale = .94 + (_controller.value * .08);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: widget.compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.compact ? 34.r : 44.r,
                    height: widget.compact ? 34.r : 44.r,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: Opacity(
                      opacity: opacity,
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Column(
                    crossAxisAlignment: widget.compact
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تتم معالجة الفاتورة باستخدام الذكاء الاصطناعي',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (!widget.compact) ...[
                        SizedBox(height: 4.h),
                        const Text(
                          'نحلل محتوى الملف ونستخرج بيانات العميل والأصناف والإجمالي.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.compact ? 10.h : 16.h),
            LinearProgressIndicator(value: widget.progress),
          ],
        );
      },
    );
  }
}

class _InvoiceResult extends StatelessWidget {
  const _InvoiceResult({required this.invoice});

  final ExtractedInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12.w,
            runSpacing: 10.h,
            children: [
              _InvoiceInfoPill(
                icon: Icons.person_outline,
                label: 'العميل',
                value: invoice.customer.name ?? '-',
              ),
              _InvoiceInfoPill(
                icon: Icons.phone_outlined,
                label: 'الهاتف',
                value: invoice.customer.phone ?? '-',
              ),
              _InvoiceInfoPill(
                icon: Icons.calendar_today_outlined,
                label: 'التاريخ',
                value: invoice.date ?? '-',
              ),
              _InvoiceInfoPill(
                icon: Icons.payments_outlined,
                label: 'الإجمالي',
                value: _formatAmount(invoice.total),
                highlight: true,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'الأصناف المستخرجة',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          _InvoiceItemsTable(items: invoice.items),
        ],
      ),
    );
  }
}

class _InvoiceInfoPill extends StatelessWidget {
  const _InvoiceInfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.success : AppColors.primary;
    return Container(
      constraints: BoxConstraints(minWidth: 180.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceItemsTable extends StatelessWidget {
  const _InvoiceItemsTable({required this.items});

  final List<InvoiceItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'لم يتم استخراج أصناف من الفاتورة.',
        style: TextStyle(color: AppColors.muted),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          AppColors.primary.withValues(alpha: .06),
        ),
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('الصنف')),
          DataColumn(label: Text('الكمية')),
          DataColumn(label: Text('السعر')),
          DataColumn(label: Text('المجموع')),
        ],
        rows: items
            .map(
              (item) => DataRow(
                cells: [
                  DataCell(Text(item.serial?.toString() ?? '-')),
                  DataCell(Text(item.name ?? '-')),
                  DataCell(Text(_formatAmount(item.quantity))),
                  DataCell(Text(_formatAmount(item.price))),
                  DataCell(Text(_formatAmount(item.lineTotal))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

String _formatAmount(num? value) {
  if (value == null) return '-';
  if (value % 1 == 0) return value.toInt().toString();
  return value.toStringAsFixed(2);
}
