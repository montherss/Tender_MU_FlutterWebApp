import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/utils/authenticated_file_opener.dart';
import '../../../../core/utils/excel_generator.dart';
import '../../../../injection_container.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../../../core/utils/report_export.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/tender_domain.dart';
import '../cubit/tenders_cubit.dart';

Future<void> _printOrFallbackToExcel(
  BuildContext context, {
  required Future<Uint8List> Function() buildPdf,
  required Future<List<int>> Function() buildExcel,
  required String pdfFileName,
  required String excelFileName,
  bool download = false,
  String? successMessage,
}) async {
  final usedExcelFallback = await exportPdfOrExcel(
    buildPdf: buildPdf,
    buildExcel: buildExcel,
    pdfFileName: pdfFileName,
    excelFileName: excelFileName,
    download: download,
  );
  if (!context.mounted) return;
  if (usedExcelFallback) {
    showAppSnackBar(
      context,
      message:
          'تعذر إنشاء ملف PDF بسبب كبر حجم البيانات، تم إنشاء ملف Excel بنفس التفاصيل بدلاً منه.',
    );
  } else if (successMessage != null) {
    showAppSnackBar(context, message: successMessage);
  }
}

class FinancialCommitmentSection extends StatefulWidget {
  const FinancialCommitmentSection({super.key, required this.tender});

  final TenderDetails tender;

  @override
  State<FinancialCommitmentSection> createState() =>
      _FinancialCommitmentSectionState();
}

class _FinancialCommitmentSectionState
    extends State<FinancialCommitmentSection> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.tender.financialCommitmentNo ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'الالتزام المالي',
              subtitle:
                  'لا يمكن تفعيل بقية أقسام العطاء قبل إدخال رقم الالتزام المالي.',
              icon: Icons.account_balance_wallet_outlined,
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'رقم الالتزام المالي مطلوب'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'رقم الالتزام المالي',
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                BlocBuilder<TenderDetailsCubit, TenderDetailsState>(
                  builder: (context, state) => ElevatedButton.icon(
                    onPressed: state.actionLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              context
                                  .read<TenderDetailsCubit>()
                                  .addFinancialCommitment(
                                    _controller.text.trim(),
                                  );
                            }
                          },
                    icon: state.actionLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BasicInfoSection extends StatefulWidget {
  const BasicInfoSection({super.key, required this.tender});

  final TenderDetails tender;

  @override
  State<BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends State<BasicInfoSection> {
  final _formKey = GlobalKey<FormState>();
  late final _tenderNo = TextEditingController(text: widget.tender.tenderNo);
  late final _subject = TextEditingController(text: widget.tender.subject);
  late final _source = TextEditingController(
    text: widget.tender.documentSourceType,
  );
  late final _supplier = TextEditingController(
    text: widget.tender.supplierCategory,
  );
  late final _location = TextEditingController(
    text: widget.tender.submissionLocation,
  );
  late final _method = TextEditingController(
    text: widget.tender.submissionMethod,
  );
  late final _bond = TextEditingController(
    text: widget.tender.bidBondAmount?.toString(),
  );
  DateTime? _openingDate;
  DateTime? _startDate;
  DateTime? _closeDate;
  DateTime? _saleDeadline;

  @override
  void initState() {
    super.initState();
    _openingDate = widget.tender.openingDate;
    _startDate = widget.tender.startDate;
    _closeDate = widget.tender.closeDate;
    _saleDeadline = widget.tender.documentSaleDeadline;
  }

  @override
  void dispose() {
    for (final controller in [
      _tenderNo,
      _subject,
      _source,
      _supplier,
      _location,
      _method,
      _bond,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'المعلومات الأساسية',
              icon: Icons.description_outlined,
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                _field(_tenderNo, 'رقم العطاء', required: true),
                _field(_subject, 'موضوع العطاء', width: 520, required: true),
                _field(_source, 'مصدر الوثيقة'),
                _field(_supplier, 'فئة المورد'),
                _field(_location, 'مكان التسليم'),
                _field(_method, 'طريقة التسليم'),
                _field(
                  _bond,
                  'قيمة كفالة الدخول',
                  keyboardType: TextInputType.number,
                ),
                _dateTile(
                  'تاريخ الفتح',
                  _openingDate,
                  (value) => setState(() => _openingDate = value),
                ),
                _dateTile(
                  'تاريخ البدء',
                  _startDate,
                  (value) => setState(() => _startDate = value),
                ),
                _dateTile(
                  'تاريخ الإغلاق',
                  _closeDate,
                  (value) => setState(() => _closeDate = value),
                ),
                _dateTile(
                  'آخر موعد بيع الوثائق',
                  _saleDeadline,
                  (value) => setState(() => _saleDeadline = value),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  context.read<TenderDetailsCubit>().saveBasicInfo(
                    BasicInfoRequest(
                      tenderNo: _tenderNo.text,
                      subject: _subject.text,
                      documentSourceType: _source.text,
                      supplierCategory: _supplier.text,
                      submissionLocation: _location.text,
                      submissionMethod: _method.text,
                      bidBondAmount: num.tryParse(_bond.text),
                      openingDate: _openingDate,
                      startDate: _startDate,
                      closeDate: _closeDate,
                      documentSaleDeadline: _saleDeadline,
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ المعلومات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    double width = 250,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      width: width.w,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: required
            ? (value) =>
                  value == null || value.trim().isEmpty ? 'الحقل مطلوب' : null
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _dateTile(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return SizedBox(
      width: 250.w,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(AppDateFormatter.date(value)),
        ),
      ),
    );
  }
}

class ItemsSection extends StatefulWidget {
  const ItemsSection({super.key, required this.tender});

  final TenderDetails tender;

  @override
  State<ItemsSection> createState() => _ItemsSectionState();
}

class _ItemsSectionState extends State<ItemsSection> {
  late List<_ItemDraft> _items;
  final _newItem = _ItemDraft.empty();

  @override
  void initState() {
    super.initState();
    _items = widget.tender.items.map(_ItemDraft.fromItem).toList();
  }

  @override
  void didUpdateWidget(covariant ItemsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tender.items != widget.tender.items) {
      _replaceItems(widget.tender.items);
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    _newItem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'إدارة المواد',
            icon: Icons.inventory_2_outlined,
            trailing: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.tender.items.isEmpty
                      ? null
                      : () => _printOrFallbackToExcel(
                          context,
                          buildPdf: () =>
                              TenderPdfGenerator.itemsPdf(widget.tender),
                          buildExcel: () =>
                              TenderExcelGenerator.itemsExcel(widget.tender),
                          pdfFileName: 'items-${widget.tender.id}.pdf',
                          excelFileName: 'items-${widget.tender.id}.xlsx',
                        ),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('طباعة PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _items.insert(0, _ItemDraft.empty())),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة صف'),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.deepBlue.withValues(alpha: .04),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إضافة مادة جديدة',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _topField(_newItem.itemNo, 'رقم المادة', width: 140),
                    _topField(
                      _newItem.description,
                      'الوصف',
                      width: 360,
                      multiline: true,
                    ),
                    _topField(
                      _newItem.quantity,
                      'الكمية',
                      width: 120,
                      number: true,
                    ),
                    _topField(_newItem.unit, 'الوحدة', width: 120),
                    ElevatedButton.icon(
                      onPressed: _addNewItem,
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('إضافة للقائمة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'المواد الحالية (${_items.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          _HorizontalTableScroll(
            minWidth: 740,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('رقم المادة')),
                DataColumn(label: Text('الوصف')),
                DataColumn(label: Text('الكمية')),
                DataColumn(label: Text('الوحدة')),
                DataColumn(label: Text('حذف')),
              ],
              rows: _items
                  .asMap()
                  .entries
                  .map(
                    (entry) => DataRow(
                      cells: [
                        DataCell(_tableField(entry.value.itemNo, width: 110)),
                        DataCell(
                          _tableField(entry.value.description, width: 280),
                        ),
                        DataCell(
                          _tableField(
                            entry.value.quantity,
                            width: 110,
                            number: true,
                          ),
                        ),
                        DataCell(_tableField(entry.value.unit, width: 110)),
                        DataCell(
                          IconButton(
                            onPressed: _items.length == 1
                                ? null
                                : () => setState(() {
                                    final removed = _items.removeAt(entry.key);
                                    removed.dispose();
                                  }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(height: 16.h),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ElevatedButton.icon(
              onPressed: _saveNewItems,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ المواد'),
            ),
          ),
        ],
      ),
    );
  }

  void _addNewItem() {
    final draft = _newItem.toItem();
    final hasAnyValue = [
      draft.itemNo,
      draft.description,
      draft.quantity?.toString(),
      draft.unit,
    ].whereType<String>().any((value) => value.trim().isNotEmpty);
    if (!hasAnyValue) return;
    setState(() {
      _items.insert(
        0,
        _ItemDraft(
          itemNo: draft.itemNo,
          description: draft.description,
          quantity: draft.quantity,
          unit: draft.unit,
        ),
      );
      _newItem.clear();
    });
  }

  void _saveNewItems() {
    final items = _items
        .where((draft) => draft.id == null && draft.hasAnyValue)
        .map((draft) => draft.toItem())
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد مواد جديدة للحفظ')));
      return;
    }
    context.read<TenderDetailsCubit>().saveItems(items);
  }

  void _replaceItems(List<TenderItem> items) {
    for (final item in _items) {
      item.dispose();
    }
    setState(() {
      _items = items.map(_ItemDraft.fromItem).toList();
    });
  }

  Widget _tableField(
    TextEditingController controller, {
    double width = 140,
    bool number = false,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _topField(
    TextEditingController controller,
    String label, {
    double width = 160,
    bool number = false,
    bool multiline = false,
  }) {
    return SizedBox(
      width: width.w,
      child: TextField(
        controller: controller,
        keyboardType: number
            ? TextInputType.number
            : multiline
            ? TextInputType.multiline
            : TextInputType.text,
        minLines: multiline ? 3 : 1,
        maxLines: multiline ? null : 1,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class SuppliersSection extends StatefulWidget {
  const SuppliersSection({super.key, required this.state});

  final TenderDetailsState state;

  @override
  State<SuppliersSection> createState() => _SuppliersSectionState();
}

class _SuppliersSectionState extends State<SuppliersSection> {
  int? _selectedSupplierId;
  String? _selectedSupplierName;
  final _supplierSearchController = TextEditingController();
  final _supplierSearchFocusNode = FocusNode();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _supplierSearchController.dispose();
    _supplierSearchFocusNode.dispose();
    super.dispose();
  }

  // Only wired to TextFormField's onChanged (fires on user input), not to
  // the controller itself — so the programmatic text update on selection
  // doesn't re-trigger a redundant search.
  void _onQueryChanged(String query) {
    if (_selectedSupplierId != null && query != _selectedSupplierName) {
      setState(() {
        _selectedSupplierId = null;
        _selectedSupplierName = null;
      });
    } else {
      setState(() {});
    }

    _searchDebounce?.cancel();
    final trimmed = query.trim();
    final cubit = context.read<TenderDetailsCubit>();
    if (trimmed.isEmpty) {
      cubit.clearSupplierSearch();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      cubit.searchSuppliers(trimmed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final linkedSuppliers = _uniqueSuppliers(state.tenderSuppliers);
    final showResultsPanel =
        _selectedSupplierId == null &&
        _supplierSearchController.text.trim().isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'إضافة مورد للعطاء',
            subtitle: 'اكتب اسم المورد للبحث عنه ثم أضفه إلى العطاء الحالي.',
            icon: Icons.storefront_outlined,
            trailing: IconButton(
              onPressed: state.suppliersLoading || state.tender == null
                  ? null
                  : () => context.read<TenderDetailsCubit>().loadSuppliersData(
                      state.tender!.id,
                    ),
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث الموردين',
            ),
          ),
          SizedBox(height: 16.h),
          if (state.suppliersLoading)
            const LinearProgressIndicator()
          else
            _AddSupplierForm(
              searchController: _supplierSearchController,
              searchFocusNode: _supplierSearchFocusNode,
              selectedSupplierId: _selectedSupplierId,
              addingSupplier: state.addingSupplier,
              showResultsPanel: showResultsPanel,
              resultsLoading: state.supplierSearchLoading,
              resultsError: state.supplierSearchError,
              results: state.supplierSearchResults,
              onQueryChanged: _onQueryChanged,
              onSelected: (supplier) => setState(() {
                _selectedSupplierId = supplier.id;
                _selectedSupplierName = supplier.displayName;
                _supplierSearchController.value = TextEditingValue(
                  text: supplier.displayName,
                  selection: TextSelection.collapsed(
                    offset: supplier.displayName.length,
                  ),
                );
              }),
              onAdd: () => _addSupplier(context),
            ),
          SizedBox(height: 18.h),
          Text(
            'الموردون المرتبطون بالعطاء (${linkedSuppliers.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 10.h),
          if (state.suppliersLoading)
            const SizedBox.shrink()
          else if (linkedSuppliers.isEmpty)
            const Text(
              'لا يوجد موردون مرتبطون بهذا العطاء بعد.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            _SuppliersTable(suppliers: linkedSuppliers),
        ],
      ),
    );
  }

  Future<void> _addSupplier(BuildContext context) async {
    final supplierId = _selectedSupplierId;
    if (supplierId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اختر المورد قبل الإضافة')));
      return;
    }
    final success = await context
        .read<TenderDetailsCubit>()
        .addSupplierToTender(supplierId);
    if (!context.mounted || !success) return;
    setState(() {
      _selectedSupplierId = null;
      _selectedSupplierName = null;
    });
    _supplierSearchController.clear();
    showAppSnackBar(context, message: 'تم إضافة المورد بنجاح');
  }

  List<Supplier> _uniqueSuppliers(List<Supplier> suppliers) {
    final byId = <int, Supplier>{};
    for (final supplier in suppliers) {
      byId.putIfAbsent(supplier.id, () => supplier);
    }
    return byId.values.toList();
  }
}

class _AddSupplierForm extends StatelessWidget {
  const _AddSupplierForm({
    required this.searchController,
    required this.searchFocusNode,
    required this.selectedSupplierId,
    required this.addingSupplier,
    required this.showResultsPanel,
    required this.resultsLoading,
    required this.resultsError,
    required this.results,
    required this.onQueryChanged,
    required this.onSelected,
    required this.onAdd,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final int? selectedSupplierId;
  final bool addingSupplier;
  final bool showResultsPanel;
  final bool resultsLoading;
  final String? resultsError;
  final List<Supplier> results;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Supplier> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        SizedBox(
          width: 420.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: searchController,
                focusNode: searchFocusNode,
                enabled: !addingSupplier,
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  labelText: 'المورد',
                  hintText: 'اكتب اسم المورد للبحث',
                  suffixIcon: resultsLoading
                      ? Padding(
                          padding: EdgeInsets.all(12.r),
                          child: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
              ),
              if (showResultsPanel) ...[
                SizedBox(height: 6.h),
                _SupplierSearchResultsPanel(
                  loading: resultsLoading,
                  error: resultsError,
                  results: results,
                  onSelected: onSelected,
                ),
              ],
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: addingSupplier || selectedSupplierId == null
              ? null
              : onAdd,
          icon: addingSupplier
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('إضافة المورد'),
        ),
      ],
    );
  }
}

class _SupplierSearchResultsPanel extends StatelessWidget {
  const _SupplierSearchResultsPanel({
    required this.loading,
    required this.error,
    required this.results,
    required this.onSelected,
  });

  final bool loading;
  final String? error;
  final List<Supplier> results;
  final ValueChanged<Supplier> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 260.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: EdgeInsets.all(12.r),
        child: Text(
          error!,
          style: const TextStyle(color: AppColors.danger),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (results.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(12.r),
        child: const Text(
          'لا يوجد موردون بهذا الاسم.',
          style: TextStyle(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final supplier = results[index];
        return InkWell(
          onTap: () => onSelected(supplier),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Text(supplier.displayName),
          ),
        );
      },
    );
  }
}

class _SuppliersTable extends StatelessWidget {
  const _SuppliersTable({required this.suppliers});

  final List<Supplier> suppliers;

  @override
  Widget build(BuildContext context) {
    return _HorizontalTableScroll(
      minWidth: 760,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('الاسم')),
          DataColumn(label: Text('معلومات التواصل')),
          DataColumn(label: Text('الرقم الخارجي')),
          DataColumn(label: Text('النوع')),
        ],
        rows: suppliers
            .map(
              (supplier) => DataRow(
                cells: [
                  DataCell(Text(supplier.displayName)),
                  DataCell(Text(supplier.contactInfo ?? '-')),
                  DataCell(Text(supplier.externalSupplierId ?? '-')),
                  DataCell(Text(supplier.type ?? '-')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class SupplierItemOffersSection extends StatefulWidget {
  const SupplierItemOffersSection({super.key, required this.state});

  final TenderDetailsState state;

  @override
  State<SupplierItemOffersSection> createState() =>
      _SupplierItemOffersSectionState();
}

class _SupplierItemOffersSectionState extends State<SupplierItemOffersSection> {
  int? _lastSelectedSupplierId;
  int? _lastSelectedItemId;
  final _formKey = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _origin = TextEditingController();
  final _unitPrice = TextEditingController();
  final _note = TextEditingController();
  final _alternativeDescription = TextEditingController();
  final _itemSearchController = TextEditingController();
  final _itemSearchFocusNode = FocusNode();
  int? _selectedSupplierId;
  int? _selectedItemId;
  bool _offersRequested = false;
  bool _printingAnalysis = false;

  @override
  void initState() {
    super.initState();
    _unitPrice.addListener(_recalculatePrice);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOffers());
  }

  @override
  void didUpdateWidget(covariant SupplierItemOffersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final suppliers = _uniqueSuppliers(widget.state.tenderSuppliers);
    final items = _itemsWithIds(widget.state.tender?.items ?? const []);
    final supplierStillExists = suppliers.any(
      (supplier) => supplier.id == _selectedSupplierId,
    );
    final itemStillExists = items.any((item) => item.id == _selectedItemId);
    if (!supplierStillExists) {
      if (_lastSelectedSupplierId != null &&
          suppliers.any((s) => s.id == _lastSelectedSupplierId)) {
        _selectedSupplierId = _lastSelectedSupplierId;
      } else {
        _selectedSupplierId = null;
      }
    }
    if (!itemStillExists) {
      if (_lastSelectedItemId != null &&
          items.any((i) => i.id == _lastSelectedItemId)) {
        _selectedItemId = _lastSelectedItemId;
      } else {
        _selectedItemId = null;
      }
      _syncItemSearchText(items);
    }
    if (oldWidget.state.tender?.id != widget.state.tender?.id) {
      _offersRequested = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOffers());
    }
  }

  @override
  void dispose() {
    _price.dispose();
    _origin.dispose();
    _unitPrice.dispose();
    _note.dispose();
    _alternativeDescription.dispose();
    _itemSearchController.dispose();
    _itemSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final suppliers = _uniqueSuppliers(state.tenderSuppliers);
    final items = _itemsWithIds(state.tender?.items ?? const []);
    final selectedItem = _selectedItem(items);
    final hasPrimaryOffer = _hasPrimaryOffer(
      state.supplierItemOffers,
      supplierId: _selectedSupplierId,
      itemId: _selectedItemId,
    );
    final canResolveOfferType =
        _selectedSupplierId != null && _selectedItemId != null;
    final isAlternativeOffer = canResolveOfferType && hasPrimaryOffer;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'إضافة عرض سعر للموردين',
            subtitle:
                'اختر المورد والمادة ثم أدخل السعر وملاحظات العرض والبديل إن وجد.',
            icon: Icons.request_quote_outlined,
            trailing: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      state.supplierItemOffers.isEmpty ||
                          state.tender == null ||
                          _printingAnalysis
                      ? null
                      : () => _exportSupplierOffers(state, download: false),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('طباعة PDF'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      state.supplierItemOffers.isEmpty ||
                          state.tender == null ||
                          _printingAnalysis
                      ? null
                      : () => _exportSupplierOffers(state, download: true),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('تحميل PDF'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      state.supplierItemOffers.isEmpty ||
                          state.tender == null ||
                          _printingAnalysis
                      ? null
                      : () => _exportSupplierOffersWithAnalysis(
                          state,
                          download: true,
                        ),
                  icon: _printingAnalysis
                      ? SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    _printingAnalysis
                        ? 'جاري التحليل...'
                        : 'PDF مع رأي الذكاء الاصطناعي',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          if (state.suppliersLoading)
            const LinearProgressIndicator()
          else if (suppliers.isEmpty || items.isEmpty)
            Text(
              suppliers.isEmpty
                  ? 'أضف مورداً للعطاء أولاً قبل تسجيل عرض السعر.'
                  : 'لا توجد مواد محفوظة بمعرف من الخادم لإضافة عرض سعر عليها.',
              style: const TextStyle(color: AppColors.muted),
            )
          else
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final spacing = 12.w;
                      final fullWidth = constraints.maxWidth;
                      final twoColumnWidth = (fullWidth - spacing) / 2;
                      final compact = fullWidth < 720;
                      final dropdownWidth = compact
                          ? fullWidth
                          : twoColumnWidth.clamp(260.0, 360.0);
                      final smallFieldWidth = compact
                          ? fullWidth
                          : ((fullWidth - spacing * 3) / 4).clamp(150.0, 210.0);
                      final originWidth = compact
                          ? fullWidth
                          : twoColumnWidth.clamp(220.0, 300.0);
                      final noteWidth = compact
                          ? fullWidth
                          : twoColumnWidth.clamp(280.0, 420.0);

                      return Wrap(
                        spacing: spacing,
                        runSpacing: 12.h,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: dropdownWidth,
                            child: DropdownButtonFormField<int>(
                              key: ValueKey(
                                'offer-supplier-$_selectedSupplierId',
                              ),
                              initialValue: _selectedSupplierId,
                              isExpanded: true,
                              menuMaxHeight: 360.h,
                              selectedItemBuilder: (_) => suppliers
                                  .map(
                                    (supplier) => _dropdownSelectedText(
                                      supplier.displayName,
                                    ),
                                  )
                                  .toList(),
                              items: suppliers
                                  .map(
                                    (supplier) => DropdownMenuItem<int>(
                                      value: supplier.id,
                                      child: _dropdownMenuText(
                                        supplier.displayName,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: state.addingSupplierItemOffer
                                  ? null
                                  : (value) => setState(() {
                                      _selectedSupplierId = value;
                                      _alternativeDescription.clear();
                                    }),
                              decoration: const InputDecoration(
                                labelText: 'المورد',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: dropdownWidth,
                            child: Autocomplete<TenderItem>(
                              key: ValueKey('offer-item-${items.length}'),
                              textEditingController: _itemSearchController,
                              focusNode: _itemSearchFocusNode,
                              displayStringForOption: _itemDropdownLabel,
                              optionsBuilder: (textEditingValue) =>
                                  _filterItems(items, textEditingValue.text),
                              onSelected: (item) => setState(() {
                                _selectedItemId = item.id;
                                _alternativeDescription.clear();
                                _recalculatePrice();
                              }),
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) => TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    enabled: !state.addingSupplierItemOffer,
                                    onFieldSubmitted: (_) => onFieldSubmitted(),
                                    decoration: const InputDecoration(
                                      labelText: 'المادة',
                                      hintText: 'اكتب رقم أو اسم المادة',
                                      suffixIcon: Icon(Icons.search),
                                    ),
                                  ),
                              optionsViewBuilder:
                                  (context, onSelected, options) => Align(
                                    alignment: AlignmentDirectional.topStart,
                                    child: Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: 360.h,
                                          maxWidth: dropdownWidth,
                                        ),
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          itemBuilder: (context, index) {
                                            final item = options.elementAt(
                                              index,
                                            );
                                            return InkWell(
                                              onTap: () => onSelected(item),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 10.h,
                                                ),
                                                child: _dropdownMenuText(
                                                  _itemDropdownLabel(item),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          SizedBox(
                            width: smallFieldWidth,
                            child: TextFormField(
                              controller: _unitPrice,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final parsed = num.tryParse(value ?? '');
                                if (parsed == null) return 'سعر الوحدة مطلوب';
                                if (parsed <= 0) return 'أدخل سعراً صحيحاً';
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'سعر الوحدة الواحدة',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: smallFieldWidth,
                            child: TextFormField(
                              controller: _price,
                              readOnly: true,
                              validator: (value) {
                                final parsed = num.tryParse(value ?? '');
                                if (parsed == null) return 'المجموع مطلوب';
                                if (parsed <= 0) return 'المجموع غير صحيح';
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'السعر / المجموع',
                                helperMaxLines: 2,
                                helperText: selectedItem?.quantity == null
                                    ? 'اختر مادة لها كمية لحساب السعر'
                                    : 'سعر الوحدة × ${selectedItem!.quantity}',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: originWidth,
                            child: TextFormField(
                              controller: _origin,
                              decoration: const InputDecoration(
                                labelText: 'بلد المنشأ',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: noteWidth,
                            child: TextFormField(
                              controller: _note,
                              decoration: const InputDecoration(
                                labelText: 'ملاحظات العرض',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isAlternativeOffer,
                          onChanged: null,
                          title: const Text('عرض بديل'),
                          subtitle: Text(
                            _offerTypeMessage(
                              canResolveOfferType: canResolveOfferType,
                              hasPrimaryOffer: hasPrimaryOffer,
                            ),
                          ),
                        ),
                        if (isAlternativeOffer) ...[
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _alternativeDescription,
                            decoration: const InputDecoration(
                              labelText: 'وصف البديل',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: ElevatedButton.icon(
                      onPressed: state.addingSupplierItemOffer
                          ? null
                          : () => _save(context),
                      icon: state.addingSupplierItemOffer
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('حفظ عرض السعر'),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 20.h),
          Text(
            'عروض الأسعار (${state.supplierItemOffers.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 10.h),
          if (state.supplierItemOffersLoading)
            const LinearProgressIndicator()
          else if (state.supplierItemOffers.isEmpty)
            const Text(
              'لا توجد عروض أسعار محفوظة لهذا العطاء بعد.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            _SupplierItemOffersTable(offers: state.supplierItemOffers),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final supplierId = _selectedSupplierId;
    final itemId = _selectedItemId;
    if (supplierId == null || itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر المورد والمادة قبل الحفظ')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    _lastSelectedSupplierId = supplierId;
    _lastSelectedItemId = itemId;
    final success = await context
        .read<TenderDetailsCubit>()
        .addSupplierItemOffer(
          supplierId: supplierId,
          tenderItemId: itemId,
          price: num.parse(_price.text),
          origin: _origin.text,
          unitPrice: num.parse(_unitPrice.text),
          note: _note.text,
          isAlternative: _hasPrimaryOffer(
            widget.state.supplierItemOffers,
            supplierId: supplierId,
            itemId: itemId,
          ),
          alternativeDescription: _alternativeDescription.text,
        );
    if (!context.mounted || !success) return;
    _clearForm();
    showAppSnackBar(context, message: 'تم حفظ عرض السعر بنجاح');
  }

  void _loadOffers() {
    if (!mounted || _offersRequested || widget.state.tender == null) return;
    _offersRequested = true;
    if (_selectedSupplierId != null) {
      _lastSelectedSupplierId = _selectedSupplierId;
    }
    if (_selectedItemId != null) {
      _lastSelectedItemId = _selectedItemId;
    }
    context.read<TenderDetailsCubit>().loadSupplierItemOffers();
  }

  Future<void> _exportSupplierOffers(
    TenderDetailsState state, {
    required bool download,
  }) async {
    final tender = state.tender;
    if (tender == null) return;

    await _printOrFallbackToExcel(
      context,
      buildPdf: () => TenderPdfGenerator.supplierItemOffersPdf(
        tender,
        state.supplierItemOffers,
      ),
      buildExcel: () => TenderExcelGenerator.supplierItemOffersExcel(
        tender,
        state.supplierItemOffers,
      ),
      pdfFileName: 'supplier-offers-${tender.id}.pdf',
      excelFileName: 'supplier-offers-${tender.id}.xlsx',
      download: download,
      successMessage: download ? 'تم تجهيز كشف عروض الأسعار للتحميل' : null,
    );
  }

  Future<void> _exportSupplierOffersWithAnalysis(
    TenderDetailsState state, {
    required bool download,
  }) async {
    final tender = state.tender;
    if (tender == null || _printingAnalysis) return;

    setState(() => _printingAnalysis = true);
    var dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AiAnalysisLoadingDialog(),
    );

    try {
      final analysis = await sl<TenderRepository>().getAnalysisByTenderId(
        tender.id,
      );
      if (!mounted) return;
      if (dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      await _exportSupplierOffersPdf(
        tender: tender,
        offers: state.supplierItemOffers,
        analysis: analysis,
        download: download,
        fileName: 'supplier-offers-${tender.id}.pdf',
      );
    } on AppException catch (error) {
      if (!mounted) return;
      if (dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      showAppSnackBar(context, message: error.message, isError: true);
    } catch (error) {
      debugPrint('Failed to export supplier offers with analysis: $error');
      if (!mounted) return;
      if (dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      showAppSnackBar(
        context,
        message: 'تعذر توليد كشف عروض الأسعار مع تحليل الذكاء الاصطناعي.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _printingAnalysis = false);
    }
  }

  Future<void> _exportSupplierOffersPdf({
    required TenderDetails tender,
    required List<SupplierItemOffer> offers,
    required TenderAnalysis analysis,
    required bool download,
    required String fileName,
  }) async {
    try {
      await _saveOrPrintPdf(
        TenderPdfGenerator.supplierItemOffersPdf(
          tender,
          offers,
          analysis: analysis,
          compactAnalysis: true,
        ),
        fileName,
        download: download,
      );
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: download
            ? 'تم تجهيز الكشف مع التحليل للتحميل'
            : 'تم تجهيز الكشف مع التحليل',
      );
      return;
    } catch (error) {
      debugPrint(
        'Analysis PDF generation failed, retrying without analysis: $error',
      );
    }

    await _printOrFallbackToExcel(
      context,
      buildPdf: () => TenderPdfGenerator.supplierItemOffersPdf(tender, offers),
      buildExcel: () =>
          TenderExcelGenerator.supplierItemOffersExcel(tender, offers),
      pdfFileName: fileName,
      excelFileName: fileName.replaceAll(RegExp(r'\.pdf$'), '.xlsx'),
      download: download,
      successMessage: download
          ? 'تم تجهيز الكشف بدون صفحة التحليل للتحميل'
          : 'تم تجهيز الكشف بدون صفحة التحليل',
    );
  }

  Future<void> _saveOrPrintPdf(
    Future<Uint8List> pdf,
    String fileName, {
    required bool download,
  }) async {
    if (download) {
      await TenderPdfGenerator.downloadPdf(pdf, fileName);
    } else {
      await TenderPdfGenerator.printPdf(pdf, fileName);
    }
  }

  void _clearForm() {
    setState(() {
      _lastSelectedSupplierId = _selectedSupplierId;
      _lastSelectedItemId = _selectedItemId;
      _selectedItemId = null;
      _price.clear();
      _origin.clear();
      _unitPrice.clear();
      _note.clear();
      _alternativeDescription.clear();
      _syncItemSearchText(
        _itemsWithIds(widget.state.tender?.items ?? const []),
      );
    });
  }

  List<Supplier> _uniqueSuppliers(List<Supplier> suppliers) {
    final byId = <int, Supplier>{};
    for (final supplier in suppliers) {
      byId.putIfAbsent(supplier.id, () => supplier);
    }
    return byId.values.toList();
  }

  List<TenderItem> _itemsWithIds(List<TenderItem> items) {
    return items.where((item) => item.id != null).toList();
  }

  TenderItem? _selectedItem(List<TenderItem> items) {
    for (final item in items) {
      if (item.id == _selectedItemId) return item;
    }
    return null;
  }

  String _itemDropdownLabel(TenderItem item) {
    return '${item.itemNo ?? item.id} - ${item.description ?? 'مادة'}';
  }

  Iterable<TenderItem> _filterItems(List<TenderItem> items, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return items;
    return items.where((item) {
      final itemNo = (item.itemNo ?? item.id?.toString() ?? '').toLowerCase();
      final description = (item.description ?? '').toLowerCase();
      return itemNo.contains(trimmed) || description.contains(trimmed);
    });
  }

  void _syncItemSearchText(List<TenderItem> items) {
    if (_selectedItemId == null) {
      _itemSearchController.text = '';
      return;
    }
    final item = _selectedItem(items);
    _itemSearchController.text = item != null ? _itemDropdownLabel(item) : '';
  }

  Widget _dropdownSelectedText(String text) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  Widget _dropdownMenuText(String text) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 520.w),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
      ),
    );
  }

  void _recalculatePrice() {
    final unitPrice = num.tryParse(_unitPrice.text);
    final items = _itemsWithIds(widget.state.tender?.items ?? const []);
    final quantity = _selectedItem(items)?.quantity;
    if (unitPrice == null || unitPrice <= 0 || quantity == null) {
      _price.clear();
      return;
    }
    _price.text = _formatOfferNumber(unitPrice * quantity);
  }

  String _formatOfferNumber(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  bool _hasPrimaryOffer(
    List<SupplierItemOffer> offers, {
    required int? supplierId,
    required int? itemId,
  }) {
    if (supplierId == null || itemId == null) return false;
    return offers.any(
      (offer) =>
          offer.supplierId == supplierId &&
          offer.itemId == itemId &&
          !offer.hasAlternative,
    );
  }

  String _offerTypeMessage({
    required bool canResolveOfferType,
    required bool hasPrimaryOffer,
  }) {
    if (!canResolveOfferType) {
      return 'اختر المورد والمادة لتحديد هل العرض أساسي أم بديل.';
    }
    if (hasPrimaryOffer) {
      return 'يوجد عرض أساسي لهذه المادة من هذا المورد، لذلك سيتم حفظ العرض كبديل';
    }
    return 'لا يوجد عرض أساسي بعد، سيتم حفظ هذا العرض كأساسي ';
  }
}

class _AiAnalysisLoadingDialog extends StatefulWidget {
  const _AiAnalysisLoadingDialog();

  @override
  State<_AiAnalysisLoadingDialog> createState() =>
      _AiAnalysisLoadingDialogState();
}

class _AiAnalysisLoadingDialogState extends State<_AiAnalysisLoadingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: 430.w,
          padding: EdgeInsets.all(26.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            // gradient: LinearGradient(
            //   begin: Alignment.topRight,
            //   end: Alignment.bottomLeft,
            //   colors: [
            //     AppColors.primary.withValues(alpha: .10),
            //     Colors.white,
            //     AppColors.gold.withValues(alpha: .10),
            //   ],
            // ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 6.28318,
                    child: child,
                  );
                },
                child: Container(
                  width: 72.r,
                  height: 72.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: .28),
                      width: 6,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'الذكاء الاصطناعي يحلل العروض',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              const Text(
                'يتم الآن قراءة عروض الموردين وموازنة الجودة الفنية مع السعر لاختيار التوصيات الأنسب. قد تستغرق العملية بعض الوقت.',
                style: TextStyle(color: AppColors.muted, height: 1.6),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 22.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(minHeight: 8),
              ),
              SizedBox(height: 10.h),
              Text(
                'يرجى الانتظار حتى اكتمال التحليل وتوليد الكشف...',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplierItemOffersTable extends StatelessWidget {
  const _SupplierItemOffersTable({required this.offers});

  final List<SupplierItemOffer> offers;

  @override
  Widget build(BuildContext context) {
    return _HorizontalTableScroll(
      minWidth: 1280,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('المورد')),
          DataColumn(label: Text('رقم المادة')),
          DataColumn(label: Text('الوصف')),
          DataColumn(label: Text('الكمية')),
          DataColumn(label: Text('الوحدة')),
          DataColumn(label: Text('بلد المنشأ')),
          DataColumn(label: Text('سعر الوحدة')),
          DataColumn(label: Text('السعر')),
          DataColumn(label: Text('بديل')),
          DataColumn(label: Text('الملاحظات')),
          DataColumn(label: Text('وصف البديل')),
        ],
        rows: offers
            .map(
              (offer) => DataRow(
                cells: [
                  DataCell(Text(offer.supplierName ?? '-')),
                  DataCell(Text(offer.itemNo ?? offer.itemId.toString())),
                  DataCell(
                    SizedBox(width: 220, child: Text(offer.description ?? '-')),
                  ),
                  DataCell(Text(offer.quantity?.toString() ?? '-')),
                  DataCell(Text(offer.unit ?? '-')),
                  DataCell(Text(offer.origin ?? '-')),
                  DataCell(Text(offer.unitPrice?.toString() ?? '-')),
                  DataCell(Text(offer.price?.toString() ?? '-')),
                  DataCell(Text(offer.hasAlternative ? 'نعم' : 'لا')),
                  DataCell(
                    SizedBox(width: 180, child: Text(offer.note ?? '-')),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(offer.alternativeDescription ?? '-'),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class TenderItemAssignmentSection extends StatefulWidget {
  const TenderItemAssignmentSection({super.key, required this.state});

  final TenderDetailsState state;

  @override
  State<TenderItemAssignmentSection> createState() =>
      _TenderItemAssignmentSectionState();
}

class _TenderItemAssignmentSectionState
    extends State<TenderItemAssignmentSection> {
  bool _dataRequested = false;
  int? _editingTenderItemId;
  _AwardView _view = _AwardView.byItem;
  _AwardFilter _filter = _AwardFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void didUpdateWidget(covariant TenderItemAssignmentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.tender?.id != widget.state.tender?.id) {
      _dataRequested = false;
      _editingTenderItemId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final board = _AwardBoard.from(
      items: state.tender?.items ?? const [],
      offers: state.supplierItemOffers,
      assignments: state.itemAssignments,
    );
    final editingTenderItemId =
        board.assignedItemIds.contains(_editingTenderItemId)
        ? _editingTenderItemId
        : null;
    final loading =
        state.supplierItemOffersLoading || state.itemAssignmentsLoading;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'إحالة عطاء',
            subtitle:
                'استعرض عروض الشركات لكل مادة مرتبة تصاعدياً، ثم نفذ إحالة فنية أو رئيسية مباشرة.',
            icon: Icons.assignment_turned_in_outlined,
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                OutlinedButton.icon(
                  onPressed: state.tender == null
                      ? null
                      : () => _printOrFallbackToExcel(
                          context,
                          buildPdf: () => TenderPdfGenerator.itemAssignmentsPdf(
                            state.tender!,
                            state.tenderSuppliers,
                            state.itemAssignments,
                          ),
                          buildExcel: () =>
                              TenderExcelGenerator.itemAssignmentsExcel(
                                state.tender!,
                                state.tenderSuppliers,
                                state.itemAssignments,
                              ),
                          pdfFileName:
                              'item-assignments-${state.tender!.id}.pdf',
                          excelFileName:
                              'item-assignments-${state.tender!.id}.xlsx',
                        ),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('طباعة PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: state.tender == null
                      ? null
                      : () => _printOrFallbackToExcel(
                          context,
                          buildPdf: () =>
                              TenderPdfGenerator.companiesAssignmentPdf(
                                state.tender!,
                                state.tenderSuppliers,
                                state.itemAssignments,
                              ),
                          buildExcel: () =>
                              TenderExcelGenerator.companiesAssignmentExcel(
                                state.tender!,
                                state.tenderSuppliers,
                                state.itemAssignments,
                              ),
                          pdfFileName:
                              'companies-assignment-${state.tender!.id}.pdf',
                          excelFileName:
                              'companies-assignment-${state.tender!.id}.xlsx',
                        ),
                  icon: const Icon(Icons.domain_outlined),
                  label: const Text('عرض إحالة الشركات'),
                ),
                IconButton(
                  onPressed: loading ? null : _refreshData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تحديث الإحالات والعروض',
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          if (loading) ...[
            const LinearProgressIndicator(),
            SizedBox(height: 12.h),
          ],
          _AwardStatsBar(board: board),
          SizedBox(height: 16.h),
          _AwardToolbar(
            view: _view,
            filter: _filter,
            board: board,
            onViewChanged: (view) => setState(() => _view = view),
            onFilterChanged: (filter) => setState(() => _filter = filter),
            onQueryChanged: (query) =>
                setState(() => _query = query.trim().toLowerCase()),
          ),
          SizedBox(height: 16.h),
          if (!loading && board.items.isEmpty)
            const Text(
              'لا توجد مواد أو عروض أسعار لإحالتها بعد.',
              style: TextStyle(color: AppColors.muted),
            )
          else if (_view == _AwardView.byItem)
            ..._buildItemCards(board, editingTenderItemId)
          else
            ..._buildSupplierCards(board, editingTenderItemId),
        ],
      ),
    );
  }

  List<Widget> _buildItemCards(_AwardBoard board, int? editingTenderItemId) {
    final items = board.items.where((item) {
      final statusMatches = switch (_filter) {
        _AwardFilter.all => true,
        _AwardFilter.pending => !item.isAssigned,
        _AwardFilter.assigned => item.isAssigned,
      };
      return statusMatches && item.matches(_query);
    }).toList();
    if (items.isEmpty) return [const _AwardEmptyResult()];
    return items
        .map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _AwardItemCard(
              key: ValueKey('award-item-${item.itemId}'),
              item: item,
              board: board,
              editing: editingTenderItemId == item.itemId,
              loadingOfferIds: widget.state.loadingItemAssignments,
              onAssign: _openAssignmentDialog,
              onStartEdit: () =>
                  setState(() => _editingTenderItemId = item.itemId),
              onCancelEdit: () => setState(() => _editingTenderItemId = null),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildSupplierCards(
    _AwardBoard board,
    int? editingTenderItemId,
  ) {
    final cards = <Widget>[];
    for (final supplier in board.suppliers) {
      final supplierMatches = supplier.name.toLowerCase().contains(_query);
      final offers = supplier.offers.where((offer) {
        final item = board.itemById[offer.itemId];
        final statusMatches = switch (_filter) {
          _AwardFilter.all => true,
          _AwardFilter.pending => !(item?.isAssigned ?? false),
          _AwardFilter.assigned => board.assignmentByOfferId.containsKey(
            offer.id,
          ),
        };
        final queryMatches =
            supplierMatches || (item?.matches(_query) ?? false);
        return statusMatches && queryMatches;
      }).toList();
      if (offers.isEmpty) continue;
      cards.add(
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _AwardSupplierCard(
            key: ValueKey('award-supplier-${supplier.id}'),
            supplier: supplier,
            visibleOffers: offers,
            board: board,
            editingTenderItemId: editingTenderItemId,
            loadingOfferIds: widget.state.loadingItemAssignments,
            onAssign: _openAssignmentDialog,
            onStartEdit: (itemId) =>
                setState(() => _editingTenderItemId = itemId),
          ),
        ),
      );
    }
    if (cards.isEmpty) return [const _AwardEmptyResult()];
    return cards;
  }

  void _loadData() {
    if (!mounted || _dataRequested || widget.state.tender == null) return;
    _dataRequested = true;
    final cubit = context.read<TenderDetailsCubit>();
    cubit.loadSupplierItemOffers();
    cubit.loadItemAssignments();
  }

  void _refreshData() {
    final cubit = context.read<TenderDetailsCubit>();
    cubit.loadSupplierItemOffers();
    cubit.loadItemAssignments();
  }

  Future<void> _openAssignmentDialog(
    SupplierItemOffer offer,
    String assignmentType,
  ) async {
    final assignedItemIds = _assignedItemIds(widget.state.itemAssignments);
    final itemAssigned = assignedItemIds.contains(offer.itemId);
    if (itemAssigned && _editingTenderItemId != offer.itemId) {
      showAppSnackBar(
        context,
        message: 'هذه المادة محالة مسبقاً، اضغط تغيير الإحالة أولاً',
      );
      return;
    }
    final result = await showDialog<_ItemAssignmentDraft>(
      context: context,
      builder: (_) =>
          _ItemAssignmentDialog(offer: offer, assignmentType: assignmentType),
    );
    if (result == null || !mounted) return;
    final success = await context.read<TenderDetailsCubit>().addItemAssignment(
      supplierItemOfferId: offer.id,
      assignmentType: assignmentType,
      assignedPrice: result.assignedPrice,
      note: result.note,
    );
    if (!mounted || !success) return;
    setState(() => _editingTenderItemId = null);
    showAppSnackBar(context, message: 'تمت إحالة العرض بنجاح');
  }

  Set<int> _assignedItemIds(List<ItemAssignment> assignments) {
    return assignments
        .map((assignment) => assignment.tenderItemId)
        .where((itemId) => itemId > 0)
        .toSet();
  }
}

enum _AwardView { byItem, bySupplier }

enum _AwardFilter { all, pending, assigned }

String _awardAmount(num? value) {
  if (value == null) return '-';
  final text = value.toStringAsFixed(3);
  return text.contains('.')
      ? text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : text;
}

/// Item-centric view of the offers and assignments of one tender, with
/// items ordered ascending by item number and offers by price.
class _AwardBoard {
  _AwardBoard._({
    required this.items,
    required this.suppliers,
    required this.assignmentByOfferId,
    required this.lowestOfferIdByItem,
  }) : itemById = {for (final item in items) item.itemId: item};

  factory _AwardBoard.from({
    required List<TenderItem> items,
    required List<SupplierItemOffer> offers,
    required List<ItemAssignment> assignments,
  }) {
    final offersByItem = <int, List<SupplierItemOffer>>{};
    for (final offer in offers) {
      offersByItem.putIfAbsent(offer.itemId, () => []).add(offer);
    }
    final assignmentsByItem = <int, List<ItemAssignment>>{};
    for (final assignment in assignments) {
      if (assignment.tenderItemId <= 0) continue;
      assignmentsByItem
          .putIfAbsent(assignment.tenderItemId, () => [])
          .add(assignment);
    }

    final awardItems = <int, _AwardItem>{};
    for (final item in items) {
      final id = item.id;
      if (id == null) continue;
      awardItems[id] = _AwardItem(
        itemId: id,
        itemNo: item.itemNo,
        description: item.description,
        quantity: item.quantity,
        unit: item.unit,
        offers: offersByItem[id] ?? const [],
        assignments: assignmentsByItem[id] ?? const [],
      );
    }
    for (final entry in offersByItem.entries) {
      if (awardItems.containsKey(entry.key)) continue;
      final sample = entry.value.firstWhere(
        (offer) => !offer.hasAlternative,
        orElse: () => entry.value.first,
      );
      awardItems[entry.key] = _AwardItem(
        itemId: entry.key,
        itemNo: sample.itemNo,
        description: sample.description,
        quantity: sample.quantity,
        unit: sample.unit,
        offers: entry.value,
        assignments: assignmentsByItem[entry.key] ?? const [],
      );
    }

    final sortedItems = awardItems.values.toList()
      ..sort((a, b) {
        final result = compareItemNo(a.itemNo, b.itemNo);
        return result != 0 ? result : a.itemId.compareTo(b.itemId);
      });
    for (final item in sortedItems) {
      item.offers.sort(_compareOffersByPrice);
    }
    final itemOrder = {
      for (final entry in sortedItems.asMap().entries)
        entry.value.itemId: entry.key,
    };

    final suppliersById = <int, _AwardSupplier>{};
    for (final offer in offers) {
      suppliersById
          .putIfAbsent(
            offer.supplierId,
            () => _AwardSupplier(
              id: offer.supplierId,
              name: offer.supplierName ?? 'شركة ${offer.supplierId}',
            ),
          )
          .offers
          .add(offer);
    }
    final assignmentByOfferId = {
      for (final assignment in assignments)
        assignment.supplierItemOfferId: assignment,
    };
    final suppliers = suppliersById.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final supplier in suppliers) {
      supplier.offers.sort((a, b) {
        final result = (itemOrder[a.itemId] ?? 0).compareTo(
          itemOrder[b.itemId] ?? 0,
        );
        if (result != 0) return result;
        if (a.hasAlternative != b.hasAlternative) {
          return a.hasAlternative ? 1 : -1;
        }
        return a.id.compareTo(b.id);
      });
    }

    final lowestOfferIdByItem = <int, int>{};
    for (final item in sortedItems) {
      final lowest = item.offers.where((offer) => offer.price != null);
      if (item.offers.length > 1 && lowest.isNotEmpty) {
        lowestOfferIdByItem[item.itemId] = lowest.first.id;
      }
    }

    return _AwardBoard._(
      items: sortedItems,
      suppliers: suppliers,
      assignmentByOfferId: assignmentByOfferId,
      lowestOfferIdByItem: lowestOfferIdByItem,
    );
  }

  final List<_AwardItem> items;
  final List<_AwardSupplier> suppliers;
  final Map<int, ItemAssignment> assignmentByOfferId;
  final Map<int, int> lowestOfferIdByItem;
  final Map<int, _AwardItem> itemById;

  Set<int> get assignedItemIds =>
      items.where((item) => item.isAssigned).map((item) => item.itemId).toSet();

  int get assignedCount => items.where((item) => item.isAssigned).length;

  num get assignedTotal => items.fold<num>(
    0,
    (sum, item) =>
        sum +
        item.assignments.fold<num>(
          0,
          (s, a) => s + (a.assignedPrice ?? a.price ?? 0),
        ),
  );

  bool isLowest(SupplierItemOffer offer) =>
      lowestOfferIdByItem[offer.itemId] == offer.id;

  static int _compareOffersByPrice(SupplierItemOffer a, SupplierItemOffer b) {
    final aPrice = a.price;
    final bPrice = b.price;
    if (aPrice != null && bPrice != null && aPrice != bPrice) {
      return aPrice.compareTo(bPrice);
    }
    if ((aPrice == null) != (bPrice == null)) return aPrice == null ? 1 : -1;
    if (a.hasAlternative != b.hasAlternative) return a.hasAlternative ? 1 : -1;
    return a.id.compareTo(b.id);
  }
}

class _AwardItem {
  _AwardItem({
    required this.itemId,
    required this.itemNo,
    required this.description,
    required this.quantity,
    required this.unit,
    required List<SupplierItemOffer> offers,
    required this.assignments,
  }) : offers = [...offers];

  final int itemId;
  final String? itemNo;
  final String? description;
  final num? quantity;
  final String? unit;
  final List<SupplierItemOffer> offers;
  final List<ItemAssignment> assignments;

  bool get isAssigned => assignments.isNotEmpty;

  String get label {
    final no = itemNo?.trim();
    return no == null || no.isEmpty ? '$itemId' : no;
  }

  String get title {
    final text = description?.trim();
    return text == null || text.isEmpty ? 'مادة $label' : text;
  }

  int get supplierCount =>
      offers.map((offer) => offer.supplierId).toSet().length;

  bool matches(String query) {
    if (query.isEmpty) return true;
    return label.toLowerCase().contains(query) ||
        title.toLowerCase().contains(query) ||
        offers.any(
          (offer) => (offer.supplierName ?? '').toLowerCase().contains(query),
        );
  }
}

class _AwardSupplier {
  _AwardSupplier({required this.id, required this.name});

  final int id;
  final String name;
  final List<SupplierItemOffer> offers = [];
}

class _AwardStatsBar extends StatelessWidget {
  const _AwardStatsBar({required this.board});

  final _AwardBoard board;

  @override
  Widget build(BuildContext context) {
    final total = board.items.length;
    final assigned = board.assignedCount;
    final progress = total == 0 ? 0.0 : assigned / total;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _AwardStatTile(
                icon: Icons.inventory_2_outlined,
                label: 'إجمالي المواد',
                value: '$total',
                color: AppColors.deepBlue,
              ),
              _AwardStatTile(
                icon: Icons.task_alt,
                label: 'مواد محالة',
                value: '$assigned',
                color: AppColors.success,
              ),
              _AwardStatTile(
                icon: Icons.hourglass_empty,
                label: 'بانتظار الإحالة',
                value: '${total - assigned}',
                color: AppColors.gold,
              ),
              _AwardStatTile(
                icon: Icons.domain_outlined,
                label: 'الشركات المشاركة',
                value: '${board.suppliers.length}',
                color: AppColors.teal,
              ),
              _AwardStatTile(
                icon: Icons.payments_outlined,
                label: 'قيمة الإحالات',
                value: _awardAmount(board.assignedTotal),
                color: AppColors.primaryDark,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: AppColors.success,
                    backgroundColor: AppColors.border,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'نسبة الإنجاز ${(progress * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AwardStatTile extends StatelessWidget {
  const _AwardStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: color.withValues(alpha: .2)),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AwardToolbar extends StatelessWidget {
  const _AwardToolbar({
    required this.view,
    required this.filter,
    required this.board,
    required this.onViewChanged,
    required this.onFilterChanged,
    required this.onQueryChanged,
  });

  final _AwardView view;
  final _AwardFilter filter;
  final _AwardBoard board;
  final ValueChanged<_AwardView> onViewChanged;
  final ValueChanged<_AwardFilter> onFilterChanged;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final total = board.items.length;
    final assigned = board.assignedCount;
    return Wrap(
      spacing: 12.w,
      runSpacing: 10.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<_AwardView>(
          segments: const [
            ButtonSegment(
              value: _AwardView.byItem,
              icon: Icon(Icons.inventory_2_outlined),
              label: Text('حسب المادة'),
            ),
            ButtonSegment(
              value: _AwardView.bySupplier,
              icon: Icon(Icons.domain_outlined),
              label: Text('حسب الشركة'),
            ),
          ],
          selected: {view},
          onSelectionChanged: (selection) => onViewChanged(selection.first),
        ),
        SizedBox(
          width: 280,
          child: TextField(
            onChanged: onQueryChanged,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search),
              hintText: 'بحث برقم المادة أو الوصف أو الشركة',
            ),
          ),
        ),
        Wrap(
          spacing: 8.w,
          children: [
            ChoiceChip(
              label: Text('الكل ($total)'),
              selected: filter == _AwardFilter.all,
              onSelected: (_) => onFilterChanged(_AwardFilter.all),
            ),
            ChoiceChip(
              label: Text('بانتظار الإحالة (${total - assigned})'),
              selected: filter == _AwardFilter.pending,
              onSelected: (_) => onFilterChanged(_AwardFilter.pending),
            ),
            ChoiceChip(
              label: Text('محالة ($assigned)'),
              selected: filter == _AwardFilter.assigned,
              onSelected: (_) => onFilterChanged(_AwardFilter.assigned),
            ),
          ],
        ),
      ],
    );
  }
}

class _AwardEmptyResult extends StatelessWidget {
  const _AwardEmptyResult();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: const Center(
        child: Text(
          'لا توجد نتائج مطابقة للبحث أو الفلتر الحالي.',
          style: TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}

class _AwardItemCard extends StatelessWidget {
  const _AwardItemCard({
    super.key,
    required this.item,
    required this.board,
    required this.editing,
    required this.loadingOfferIds,
    required this.onAssign,
    required this.onStartEdit,
    required this.onCancelEdit,
  });

  final _AwardItem item;
  final _AwardBoard board;
  final bool editing;
  final Set<int> loadingOfferIds;
  final void Function(SupplierItemOffer offer, String assignmentType) onAssign;
  final VoidCallback onStartEdit;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    final accent = editing
        ? AppColors.teal
        : item.isAssigned
        ? AppColors.success
        : AppColors.gold;
    final lowest = item.offers.where((offer) => offer.price != null);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accent.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(18.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('award-item-tile-${item.itemId}'),
          initiallyExpanded: !item.isAssigned || editing,
          tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          leading: _AwardItemNumberBadge(label: item.label, color: accent),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _AwardMetaText(
                  icon: Icons.straighten,
                  text:
                      'الكمية: ${_awardAmount(item.quantity)} ${item.unit ?? ''}',
                ),
                _AwardMetaText(
                  icon: Icons.domain_outlined,
                  text:
                      'عروض: ${item.offers.length} من ${item.supplierCount} شركة',
                ),
                if (lowest.isNotEmpty)
                  _AwardMetaText(
                    icon: Icons.trending_down,
                    text: 'أقل سعر: ${_awardAmount(lowest.first.price)}',
                  ),
                _AwardItemStatusPill(item: item, editing: editing),
              ],
            ),
          ),
          children: [
            if (editing)
              _AwardEditBanner(itemLabel: item.label, onCancel: onCancelEdit),
            if (item.offers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'لا توجد عروض أسعار لهذه المادة.',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...item.offers.asMap().entries.map(
                (entry) => _AwardOfferTile(
                  offer: entry.value,
                  rank: entry.key + 1,
                  title:
                      entry.value.supplierName ??
                      'شركة ${entry.value.supplierId}',
                  isLowest: board.isLowest(entry.value),
                  assignment: board.assignmentByOfferId[entry.value.id],
                  itemAssigned: item.isAssigned,
                  editing: editing,
                  loading: loadingOfferIds.contains(entry.value.id),
                  onAssign: onAssign,
                  onStartEdit: onStartEdit,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AwardSupplierCard extends StatelessWidget {
  const _AwardSupplierCard({
    super.key,
    required this.supplier,
    required this.visibleOffers,
    required this.board,
    required this.editingTenderItemId,
    required this.loadingOfferIds,
    required this.onAssign,
    required this.onStartEdit,
  });

  final _AwardSupplier supplier;
  final List<SupplierItemOffer> visibleOffers;
  final _AwardBoard board;
  final int? editingTenderItemId;
  final Set<int> loadingOfferIds;
  final void Function(SupplierItemOffer offer, String assignmentType) onAssign;
  final ValueChanged<int> onStartEdit;

  @override
  Widget build(BuildContext context) {
    final wonAssignments = supplier.offers
        .map((offer) => board.assignmentByOfferId[offer.id])
        .whereType<ItemAssignment>()
        .toList();
    final wonTotal = wonAssignments.fold<num>(
      0,
      (sum, a) => sum + (a.assignedPrice ?? a.price ?? 0),
    );
    final offeredItems = supplier.offers.map((o) => o.itemId).toSet().length;
    final color = wonAssignments.isEmpty ? AppColors.muted : AppColors.success;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(18.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('award-supplier-tile-${supplier.id}'),
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          leading: CircleAvatar(
            backgroundColor: AppColors.deepBlue.withValues(alpha: .08),
            foregroundColor: AppColors.deepBlue,
            child: Text(
              supplier.name.trim().isEmpty
                  ? '؟'
                  : supplier.name.trim().characters.first,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          title: Text(
            supplier.name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _AwardMetaText(
                  icon: Icons.inventory_2_outlined,
                  text: 'قدمت عروضاً على $offeredItems مادة',
                ),
                _AwardPill(
                  icon: Icons.task_alt,
                  label: 'محال عليها: ${wonAssignments.length} مادة',
                  color: color,
                ),
                if (wonAssignments.isNotEmpty)
                  _AwardMetaText(
                    icon: Icons.payments_outlined,
                    text: 'قيمة الإحالة: ${_awardAmount(wonTotal)}',
                  ),
              ],
            ),
          ),
          children: visibleOffers.map((offer) {
            final item = board.itemById[offer.itemId];
            final editing = editingTenderItemId == offer.itemId;
            return _AwardOfferTile(
              offer: offer,
              title: item == null
                  ? 'مادة ${offer.itemNo ?? offer.itemId}'
                  : '${item.label} - ${item.title}',
              leadingLabel: item?.label ?? offer.itemNo,
              isLowest: board.isLowest(offer),
              assignment: board.assignmentByOfferId[offer.id],
              itemAssigned: item?.isAssigned ?? false,
              assignedElsewhereTo: _assignedElsewhereTo(item, offer),
              editing: editing,
              loading: loadingOfferIds.contains(offer.id),
              onAssign: onAssign,
              onStartEdit: () => onStartEdit(offer.itemId),
            );
          }).toList(),
        ),
      ),
    );
  }

  String? _assignedElsewhereTo(_AwardItem? item, SupplierItemOffer offer) {
    if (item == null || !item.isAssigned) return null;
    if (board.assignmentByOfferId.containsKey(offer.id)) return null;
    return item.assignments.first.supplierName ?? 'شركة أخرى';
  }
}

class _AwardItemNumberBadge extends StatelessWidget {
  const _AwardItemNumberBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Fixed size: ListTile.leading must not expand to the tile width.
    return Container(
      width: 52,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _AwardItemStatusPill extends StatelessWidget {
  const _AwardItemStatusPill({required this.item, required this.editing});

  final _AwardItem item;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    if (editing) {
      return const _AwardPill(
        icon: Icons.edit_note_outlined,
        label: 'وضع تغيير الإحالة',
        color: AppColors.teal,
      );
    }
    if (!item.isAssigned) {
      return const _AwardPill(
        icon: Icons.hourglass_empty,
        label: 'بانتظار الإحالة',
        color: AppColors.gold,
      );
    }
    final assignment = item.assignments.first;
    return _AwardPill(
      icon: Icons.task_alt,
      label:
          'محالة ${assignment.isTechnical ? 'فنياً' : 'رئيسياً'} إلى ${assignment.supplierName ?? '-'}',
      color: AppColors.success,
    );
  }
}

class _AwardPill extends StatelessWidget {
  const _AwardPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        border: Border.all(color: color.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AwardMetaText extends StatelessWidget {
  const _AwardMetaText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        SizedBox(width: 4.w),
        Text(
          text,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _AwardEditBanner extends StatelessWidget {
  const _AwardEditBanner({required this.itemLabel, required this.onCancel});

  final String itemLabel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: .08),
        border: Border.all(color: AppColors.teal.withValues(alpha: .3)),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_outlined, color: AppColors.teal),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'اختر عرضاً آخر للمادة $itemLabel لإعادة الإحالة.',
              style: const TextStyle(color: AppColors.teal),
            ),
          ),
          TextButton(onPressed: onCancel, child: const Text('إلغاء التعديل')),
        ],
      ),
    );
  }
}

class _AwardOfferTile extends StatelessWidget {
  const _AwardOfferTile({
    required this.offer,
    required this.title,
    required this.isLowest,
    required this.assignment,
    required this.itemAssigned,
    required this.editing,
    required this.loading,
    required this.onAssign,
    required this.onStartEdit,
    this.rank,
    this.leadingLabel,
    this.assignedElsewhereTo,
  });

  final SupplierItemOffer offer;
  final String title;
  final bool isLowest;
  final ItemAssignment? assignment;
  final bool itemAssigned;
  final bool editing;
  final bool loading;
  final void Function(SupplierItemOffer offer, String assignmentType) onAssign;
  final VoidCallback onStartEdit;
  final int? rank;
  final String? leadingLabel;
  final String? assignedElsewhereTo;

  @override
  Widget build(BuildContext context) {
    final isAssigned = assignment != null;
    final locked = itemAssigned && !editing;
    final borderColor = isAssigned
        ? AppColors.success
        : isLowest
        ? AppColors.gold
        : AppColors.border;
    return Opacity(
      opacity: locked && !isAssigned ? .6 : 1,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isAssigned
              ? AppColors.success.withValues(alpha: .06)
              : offer.hasAlternative
              ? AppColors.gold.withValues(alpha: .05)
              : AppColors.background,
          border: Border.all(
            color: borderColor.withValues(alpha: isAssigned ? .6 : .5),
            width: isAssigned ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = _details();
            final actions = _actions();
            if (constraints.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  SizedBox(height: 10.h),
                  actions,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: details),
                SizedBox(width: 12.w),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _details() {
    final description = offer.hasAlternative
        ? offer.alternativeDescription ?? offer.description
        : null;
    final note = offer.note?.trim();
    final rankOrLabel = leadingLabel ?? (rank == null ? null : '$rank');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rankOrLabel != null) ...[
          Container(
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Text(
              rankOrLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.muted,
              ),
            ),
          ),
          SizedBox(width: 10.w),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  _AwardPill(
                    icon: offer.hasAlternative
                        ? Icons.swap_horiz
                        : Icons.check_box_outlined,
                    label: offer.hasAlternative ? 'بديل' : 'أساسي',
                    color: offer.hasAlternative
                        ? AppColors.gold
                        : AppColors.deepBlue,
                  ),
                  if (isLowest)
                    const _AwardPill(
                      icon: Icons.trending_down,
                      label: 'الأقل سعراً',
                      color: AppColors.gold,
                    ),
                  if (assignment != null)
                    _AwardPill(
                      icon: Icons.verified,
                      label:
                          'محالة ${assignment!.isTechnical ? 'فنية' : 'رئيسية'} بسعر ${_awardAmount(assignment!.assignedPrice ?? assignment!.price)}',
                      color: AppColors.success,
                    ),
                  if (assignedElsewhereTo != null)
                    _AwardPill(
                      icon: Icons.lock_outline,
                      label: 'محالة إلى $assignedElsewhereTo',
                      color: AppColors.muted,
                    ),
                ],
              ),
              if (description != null && description.trim().isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  'وصف البديل: $description',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 6.h),
              Wrap(
                spacing: 14.w,
                runSpacing: 4.h,
                children: [
                  _AwardMetaText(
                    icon: Icons.sell_outlined,
                    text: 'سعر الوحدة: ${_awardAmount(offer.unitPrice)}',
                  ),
                  _AwardMetaText(
                    icon: Icons.public,
                    text: 'بلد المنشأ: ${offer.origin ?? '-'}',
                  ),
                  if (note != null && note.isNotEmpty)
                    _AwardMetaText(
                      icon: Icons.sticky_note_2_outlined,
                      text: note,
                    ),
                  if ((assignment?.assignmentNote ?? '').trim().isNotEmpty)
                    _AwardMetaText(
                      icon: Icons.comment_outlined,
                      text:
                          'ملاحظة الإحالة: ${assignment!.assignmentNote!.trim()}',
                    ),
                  if (assignment?.createdAt != null)
                    _AwardMetaText(
                      icon: Icons.event_outlined,
                      text: AppDateFormatter.dateTime(assignment!.createdAt),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    final price = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'السعر الإجمالي',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        Text(
          _awardAmount(offer.price),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isLowest ? AppColors.primaryDark : AppColors.text,
          ),
        ),
      ],
    );
    final Widget buttons;
    if (assignment != null && !editing) {
      buttons = OutlinedButton.icon(
        onPressed: onStartEdit,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('تغيير الإحالة'),
      );
    } else {
      final enabled = !itemAssigned || editing;
      buttons = Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          _AssignmentTableButton(
            label: editing ? 'تعديل فنية' : 'فنية',
            icon: Icons.engineering_outlined,
            loading: loading,
            filled: false,
            color: AppColors.teal,
            enabled: enabled,
            onPressed: () => onAssign(offer, 'TEC'),
          ),
          _AssignmentTableButton(
            label: editing ? 'تعديل رئيسية' : 'رئيسية',
            icon: Icons.verified_outlined,
            loading: loading,
            filled: true,
            color: AppColors.deepBlue,
            enabled: enabled,
            onPressed: () => onAssign(offer, 'MAIN'),
          ),
        ],
      );
    }
    return Wrap(
      spacing: 16.w,
      runSpacing: 8.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [price, buttons],
    );
  }
}

class _AssignmentTableButton extends StatelessWidget {
  const _AssignmentTableButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.filled,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final bool filled;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            fixedSize: const Size(138, 40),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: color,
            fixedSize: const Size(138, 40),
            padding: EdgeInsets.zero,
            side: BorderSide(color: color.withValues(alpha: .45)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          );
    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: filled ? Colors.white : color,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              SizedBox(width: 6.w),
              Text(label),
            ],
          );
    if (filled) {
      return ElevatedButton(
        onPressed: loading || !enabled ? null : onPressed,
        style: style,
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: loading || !enabled ? null : onPressed,
      style: style,
      child: child,
    );
  }
}

class _ItemAssignmentDraft {
  const _ItemAssignmentDraft({required this.assignedPrice, this.note});

  final num assignedPrice;
  final String? note;
}

class _ItemAssignmentDialog extends StatefulWidget {
  const _ItemAssignmentDialog({
    required this.offer,
    required this.assignmentType,
  });

  final SupplierItemOffer offer;
  final String assignmentType;

  @override
  State<_ItemAssignmentDialog> createState() => _ItemAssignmentDialogState();
}

class _ItemAssignmentDialogState extends State<_ItemAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _assignedPrice = TextEditingController(
    text: widget.offer.price?.toString() ?? '',
  );
  final _note = TextEditingController();

  @override
  void dispose() {
    _assignedPrice.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignmentLabel = widget.assignmentType == 'TEC'
        ? 'إحالة فنية'
        : 'إحالة رئيسية';
    return AlertDialog(
      title: Text(assignmentLabel),
      content: SizedBox(
        width: 480.w,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المورد: ${widget.offer.supplierName ?? '-'}'),
              SizedBox(height: 6.h),
              Text('المادة: ${widget.offer.itemNo ?? widget.offer.itemId}'),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _assignedPrice,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = num.tryParse(value ?? '');
                  if (parsed == null) return 'السعر المحال مطلوب';
                  if (parsed <= 0) return 'أدخل سعراً صحيحاً';
                  return null;
                },
                decoration: const InputDecoration(labelText: 'السعر المحال'),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'ملاحظة الإحالة'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('حفظ الإحالة')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _ItemAssignmentDraft(
        assignedPrice: num.parse(_assignedPrice.text),
        note: _note.text,
      ),
    );
  }
}

class AttachmentsSection extends StatelessWidget {
  const AttachmentsSection({super.key, required this.state});

  final TenderDetailsState state;

  TenderDetails get tender => state.tender!;

  @override
  Widget build(BuildContext context) {
    final progress = state.uploadProgress;
    final isUploading = state.actionLoading && progress != null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'المرفقات',
            icon: Icons.attach_file_outlined,
          ),
          SizedBox(height: 16.h),
          InkWell(
            onTap: isUploading
                ? null
                : () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                      withData: true,
                    );
                    if (result != null && context.mounted) {
                      context.read<TenderDetailsCubit>().uploadFiles(
                        result.files,
                      );
                    }
                  },
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(28.r),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.teal, width: 1.2),
                color: AppColors.teal.withValues(alpha: .05),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 42.r,
                    color: AppColors.teal,
                  ),
                  SizedBox(height: 10.h),
                  const Text('اسحب الملفات هنا أو اضغط لاختيار عدة ملفات'),
                  if (progress != null) ...[
                    SizedBox(height: 14.h),
                    LinearProgressIndicator(value: progress),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الوثائق المحملة (${tender.attachments.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 10.h),
                if (tender.attachments.isEmpty)
                  const Text(
                    'لا توجد مرفقات مرفوعة بعد.',
                    style: TextStyle(color: AppColors.muted),
                  )
                else
                  ...tender.attachments.map((file) {
                    final isDeleting =
                        file.id != null &&
                        state.deletingAttachmentIds.contains(file.id);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _fileIcon(file.type ?? file.name),
                        color: AppColors.deepBlue,
                      ),
                      title: Text(file.name ?? '-'),
                      subtitle: Text(
                        '${file.type ?? 'ملف'} | ${AppDateFormatter.dateTime(file.uploadDate)}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton(
                            onPressed: file.id == null || isDeleting
                                ? null
                                : () => _openAttachment(context, file),
                            icon: const Icon(Icons.open_in_new),
                            tooltip: 'فتح الملف',
                          ),
                          if (isDeleting)
                            SizedBox(
                              width: 24.r,
                              height: 24.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          else
                            IconButton(
                              onPressed: file.id == null
                                  ? null
                                  : () => _confirmAndDeleteAttachment(
                                      context,
                                      file,
                                    ),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'حذف الملف',
                              color: AppColors.danger,
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String? value) {
    final file = value?.toLowerCase() ?? '';
    if (file.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (file.contains('image') ||
        file.endsWith('.png') ||
        file.endsWith('.jpg')) {
      return Icons.image_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Future<void> _openAttachment(
    BuildContext context,
    TenderAttachment file,
  ) async {
    final attachmentId = file.id;
    if (attachmentId == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري تحميل الملف...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await AuthenticatedFileOpener.openAttachment(
        sl(),
        attachmentId: attachmentId,
        fileName: file.name,
      );
    } on AppException catch (error) {
      if (context.mounted) {
        showAppSnackBar(context, message: error.message, isError: true);
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, message: 'تعذر فتح الملف', isError: true);
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _confirmAndDeleteAttachment(
    BuildContext context,
    TenderAttachment file,
  ) async {
    final attachmentId = file.id;
    if (attachmentId == null) return;

    final fileName = file.name?.trim().isNotEmpty == true
        ? file.name!.trim()
        : 'هذا الملف';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف "$fileName"؟\nلا يمكن التراجع عن هذا الإجراء.',
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
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final deleted = await context.read<TenderDetailsCubit>().deleteAttachment(
      attachmentId,
    );

    if (deleted && context.mounted) {
      showAppSnackBar(context, message: 'تم حذف المرفق بنجاح');
    }
  }
}

class CategoryTypeSection extends StatefulWidget {
  const CategoryTypeSection({super.key, required this.tender});

  final TenderDetails tender;

  @override
  State<CategoryTypeSection> createState() => _CategoryTypeSectionState();
}

class _CategoryTypeSectionState extends State<CategoryTypeSection> {
  static const investment = 'لجنة اللوازم و الخدمات الاستثمارية';
  static const _purchaseContractTypes = [
    'لجنة شراء و الخدمات الفنية (الرئيسية)',
    investment,
    'لجنة شراء مباشر (خاصة) اقل من 5000 دينار اردني',
  ];
  static const _investmentCommitteeTypes = ['فرعية', 'رئيسية'];
  static const _tenderTypes = [
    'مناقصة محدودة',
    'مناقصة عامة',
    'استدراج عروض',
    'التزام',
  ];

  late String? _category = _parseCategory(widget.tender.category);
  late String? _investmentCommitteeType = _parseInvestmentCommitteeType(
    widget.tender.category,
  );
  late String? _type = _parseTenderType(widget.tender.type);

  @override
  void didUpdateWidget(covariant CategoryTypeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tender.category != widget.tender.category ||
        oldWidget.tender.type != widget.tender.type) {
      setState(() {
        _category = _parseCategory(widget.tender.category);
        _investmentCommitteeType = _parseInvestmentCommitteeType(
          widget.tender.category,
        );
        _type = _parseTenderType(widget.tender.type);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'الفئة والنوع',
            subtitle:
                'راجع القيم المخزنة ثم اختر نوع عقد الشراء ونوع المناقصة للحفظ.',
            icon: Icons.category_outlined,
          ),
          SizedBox(height: 16.h),
          _StoredCategoryTypeResult(tender: widget.tender),
          SizedBox(height: 18.h),
          Text('حفظ قيم جديدة', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 10.h),
          _RadioGroup<String>(
            title: 'نوع عقد الشراء',
            value: _category,
            options: _purchaseContractTypes,
            onChanged: (value) {
              setState(() {
                _category = value;
                if (value != investment) _investmentCommitteeType = null;
              });
            },
          ),
          if (_category == investment) ...[
            SizedBox(height: 8.h),
            _RadioGroup<String>(
              title: 'تصنيف لجنة اللوازم و الخدمات الاستثمارية',
              value: _investmentCommitteeType,
              options: _investmentCommitteeTypes,
              onChanged: (value) =>
                  setState(() => _investmentCommitteeType = value),
            ),
          ],
          SizedBox(height: 12.h),
          _RadioGroup<String>(
            title: 'نوع المناقصة',
            value: _type,
            options: _tenderTypes,
            onChanged: (value) => setState(() => _type = value),
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: BlocBuilder<TenderDetailsCubit, TenderDetailsState>(
              builder: (context, state) => ElevatedButton.icon(
                onPressed: state.actionLoading ? null : () => _save(context),
                icon: state.actionLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('حفظ الفئة والنوع'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save(BuildContext context) {
    final category = _effectiveCategory;
    if (category == null || _type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر نوع عقد الشراء ونوع المناقصة قبل الحفظ'),
        ),
      );
      return;
    }
    context.read<TenderDetailsCubit>().saveCategory(category, _type);
  }

  String? get _effectiveCategory {
    if (_category == null) return null;
    if (_category == investment) {
      if (_investmentCommitteeType == null) return null;
      return '$investment ($_investmentCommitteeType)';
    }
    return _category;
  }

  String? _parseCategory(String? value) {
    final cleaned = _cleanValue(value);
    if (cleaned == null) return null;
    if (cleaned.contains(investment)) return investment;
    if (_purchaseContractTypes.contains(cleaned)) return cleaned;
    return null;
  }

  String? _parseInvestmentCommitteeType(String? value) {
    final cleaned = _cleanValue(value);
    if (cleaned == null || !cleaned.contains(investment)) return null;
    if (cleaned.contains('فرعية')) return 'فرعية';
    if (cleaned.contains('رئيسية')) return 'رئيسية';
    return null;
  }

  String? _parseTenderType(String? value) {
    final cleaned = _cleanValue(value);
    if (cleaned == null || !_tenderTypes.contains(cleaned)) return null;
    return cleaned;
  }

  String? _cleanValue(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class _RadioGroup<T> extends StatelessWidget {
  const _RadioGroup({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final T? value;
  final List<T> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 6.h),
          Material(
            type: MaterialType.transparency,
            child: RadioGroup<T>(
              groupValue: value,
              onChanged: onChanged,
              child: Column(
                children: options
                    .map(
                      (option) => RadioListTile<T>(
                        value: option,
                        title: Text(option.toString()),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoredCategoryTypeResult extends StatelessWidget {
  const _StoredCategoryTypeResult({required this.tender});

  final TenderDetails tender;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'النتائج المخزنة',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _StoredValueChip(label: 'الفئة', value: tender.category),
              _StoredValueChip(label: 'النوع', value: tender.type),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoredValueChip extends StatelessWidget {
  const _StoredValueChip({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim().isEmpty ?? true ? 'غير محفوظ' : value!.trim();
    return Chip(
      label: Text('$label: $text'),
      backgroundColor: AppColors.deepBlue.withValues(alpha: .08),
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class AssignmentsSection extends StatelessWidget {
  const AssignmentsSection({super.key, required this.state});

  final TenderDetailsState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'نظام الإحالة',
            icon: Icons.fact_check_outlined,
            trailing: SegmentedButton<AssignmentFilter>(
              segments: const [
                ButtonSegment(value: AssignmentFilter.all, label: Text('الكل')),
                ButtonSegment(
                  value: AssignmentFilter.approved,
                  label: Text('موافق'),
                ),
                ButtonSegment(
                  value: AssignmentFilter.rejected,
                  label: Text('مرفوض'),
                ),
              ],
              selected: {state.assignmentFilter},
              onSelectionChanged: (value) => context
                  .read<TenderDetailsCubit>()
                  .setAssignmentFilter(value.first),
            ),
          ),
          SizedBox(height: 16.h),
          _HorizontalTableScroll(
            minWidth: 920,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('المادة')),
                DataColumn(label: Text('الوصف')),
                DataColumn(label: Text('قرار فني')),
                DataColumn(label: Text('اللجنة الرئيسية')),
              ],
              rows: state.filteredItems.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.itemNo ?? '-')),
                    DataCell(
                      SizedBox(
                        width: 320,
                        child: Text(item.description ?? '-'),
                      ),
                    ),
                    DataCell(
                      _AssignmentButtons(
                        item: item,
                        technical: true,
                        loading: state.loadingAssignments.contains(
                          't-${item.id}',
                        ),
                      ),
                    ),
                    DataCell(
                      _AssignmentButtons(
                        item: item,
                        technical: false,
                        loading: state.loadingAssignments.contains(
                          'm-${item.id}',
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class PdfSection extends StatelessWidget {
  const PdfSection({super.key, required this.tender});

  final TenderDetails tender;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'PDF',
            subtitle: 'توليد مستندات احترافية للمواد ووثيقة العطاء الرسمية.',
            icon: Icons.picture_as_pdf_outlined,
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              ElevatedButton.icon(
                onPressed: () => _printOrFallbackToExcel(
                  context,
                  buildPdf: () => TenderPdfGenerator.itemsPdf(tender),
                  buildExcel: () => TenderExcelGenerator.itemsExcel(tender),
                  pdfFileName: 'items-${tender.id}.pdf',
                  excelFileName: 'items-${tender.id}.xlsx',
                ),
                icon: const Icon(Icons.print_outlined),
                label: const Text('طباعة المواد PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () => TenderPdfGenerator.printPdf(
                  TenderPdfGenerator.officialTenderPdf(tender),
                  'tender-${tender.id}.pdf',
                ),
                icon: const Icon(Icons.preview_outlined),
                label: const Text('معاينة الوثيقة'),
              ),
              OutlinedButton.icon(
                onPressed: () => TenderPdfGenerator.downloadPdf(
                  TenderPdfGenerator.officialTenderPdf(tender),
                  'tender-${tender.id}.pdf',
                ),
                icon: const Icon(Icons.download_outlined),
                label: const Text('تحميل الوثيقة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HorizontalTableScroll extends StatefulWidget {
  const _HorizontalTableScroll({required this.child, required this.minWidth});

  final Widget child;
  final double minWidth;

  @override
  State<_HorizontalTableScroll> createState() => _HorizontalTableScrollState();
}

class _HorizontalTableScrollState extends State<_HorizontalTableScroll> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > widget.minWidth
            ? constraints.maxWidth
            : widget.minWidth;
        return Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: width),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _AssignmentButtons extends StatelessWidget {
  const _AssignmentButtons({
    required this.item,
    required this.technical,
    required this.loading,
  });

  final TenderItem item;
  final bool technical;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final value = technical ? item.technicalAssignment : item.mainAssignment;
    if (loading) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        _AssignmentActionButton(
          label: 'موافق',
          selected: value == 1,
          color: AppColors.success,
          onPressed: () => _changeAssignment(context, value: 1),
        ),
        _AssignmentActionButton(
          label: 'مرفوض',
          selected: value == 0,
          color: AppColors.danger,
          onPressed: () => _changeAssignment(context, value: 0),
        ),
      ],
    );
  }

  void _changeAssignment(BuildContext context, {required int value}) {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يمكن تعديل الإحالة: معرف المادة غير موجود من الخادم',
          ),
        ),
      );
      return;
    }
    context.read<TenderDetailsCubit>().changeAssignment(
      item: item,
      technical: technical,
      value: value,
    );
  }
}

class _AssignmentActionButton extends StatelessWidget {
  const _AssignmentActionButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = selected
        ? ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: .45)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          );
    final child = Text(label);
    if (selected) {
      return ElevatedButton(onPressed: onPressed, style: style, child: child);
    }
    return OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}

class _ItemDraft {
  _ItemDraft({
    this.id,
    String? itemNo,
    String? description,
    num? quantity,
    String? unit,
  }) : itemNo = TextEditingController(text: itemNo),
       description = TextEditingController(text: description),
       quantity = TextEditingController(text: quantity?.toString()),
       unit = TextEditingController(text: unit);

  factory _ItemDraft.empty() => _ItemDraft();

  factory _ItemDraft.fromItem(TenderItem item) => _ItemDraft(
    id: item.id,
    itemNo: item.itemNo,
    description: item.description,
    quantity: item.quantity,
    unit: item.unit,
  );

  final int? id;
  final TextEditingController itemNo;
  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unit;

  bool get hasAnyValue => [
    itemNo.text,
    description.text,
    quantity.text,
    unit.text,
  ].any((value) => value.trim().isNotEmpty);

  TenderItem toItem() => TenderItem(
    id: id,
    itemNo: itemNo.text.trim(),
    description: description.text.trim(),
    quantity: num.tryParse(quantity.text),
    unit: unit.text.trim(),
  );

  void dispose() {
    itemNo.dispose();
    description.dispose();
    quantity.dispose();
    unit.dispose();
  }

  void clear() {
    itemNo.clear();
    description.clear();
    quantity.clear();
    unit.clear();
  }
}
