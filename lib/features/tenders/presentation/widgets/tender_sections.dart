import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:universal_html/html.dart' as html;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/tender_domain.dart';
import '../cubit/tenders_cubit.dart';

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
                      : () => TenderPdfGenerator.printPdf(
                          TenderPdfGenerator.itemsPdf(widget.tender),
                          'items-${widget.tender.id}.pdf',
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
                    _topField(_newItem.description, 'الوصف', width: 360),
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
  }) {
    return SizedBox(
      width: width.w,
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
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

  @override
  void didUpdateWidget(covariant SuppliersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedStillExists = widget.state.suppliers.any(
      (supplier) => supplier.id == _selectedSupplierId,
    );
    if (!selectedStillExists) _selectedSupplierId = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final linkedSuppliers = _uniqueSuppliers(state.tenderSuppliers);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'إضافة مورد للعطاء',
            subtitle: 'اختر مورداً من القائمة ثم أضفه إلى العطاء الحالي.',
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
              suppliers: state.suppliers,
              selectedSupplierId: _selectedSupplierId,
              addingSupplier: state.addingSupplier,
              onChanged: (value) => setState(() => _selectedSupplierId = value),
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
    setState(() => _selectedSupplierId = null);
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
    required this.suppliers,
    required this.selectedSupplierId,
    required this.addingSupplier,
    required this.onChanged,
    required this.onAdd,
  });

  final List<Supplier> suppliers;
  final int? selectedSupplierId;
  final bool addingSupplier;
  final ValueChanged<int?> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 420.w,
          child: DropdownButtonFormField<int>(
            initialValue: selectedSupplierId,
            items: suppliers
                .map(
                  (supplier) => DropdownMenuItem<int>(
                    value: supplier.id,
                    child: Text(supplier.displayName),
                  ),
                )
                .toList(),
            onChanged: addingSupplier || suppliers.isEmpty ? null : onChanged,
            decoration: const InputDecoration(labelText: 'المورد'),
            hint: Text(
              suppliers.isEmpty ? 'لا يوجد موردون متاحون' : 'اختر المورد',
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: addingSupplier || suppliers.isEmpty ? null : onAdd,
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
  final _formKey = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _note = TextEditingController();
  final _alternativeDescription = TextEditingController();
  int? _selectedSupplierId;
  int? _selectedItemId;
  bool _isAlternative = false;
  bool _offersRequested = false;

  @override
  void initState() {
    super.initState();
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
    if (!supplierStillExists) _selectedSupplierId = null;
    if (!itemStillExists) _selectedItemId = null;
    if (oldWidget.state.tender?.id != widget.state.tender?.id) {
      _offersRequested = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOffers());
    }
  }

  @override
  void dispose() {
    _price.dispose();
    _note.dispose();
    _alternativeDescription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final suppliers = _uniqueSuppliers(state.tenderSuppliers);
    final items = _itemsWithIds(state.tender?.items ?? const []);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'إضافة عرض سعر للموردين',
            subtitle:
                'اختر المورد والمادة ثم أدخل السعر وملاحظات العرض والبديل إن وجد.',
            icon: Icons.request_quote_outlined,
            trailing: OutlinedButton.icon(
              onPressed:
                  state.supplierItemOffers.isEmpty || state.tender == null
                  ? null
                  : () => TenderPdfGenerator.printPdf(
                      TenderPdfGenerator.supplierItemOffersPdf(
                        state.tender!,
                        state.supplierItemOffers,
                      ),
                      'supplier-offers-${state.tender!.id}.pdf',
                    ),
              icon: const Icon(Icons.print_outlined),
              label: const Text('طباعة PDF'),
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
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 300.w,
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('offer-supplier-$_selectedSupplierId'),
                          initialValue: _selectedSupplierId,
                          items: suppliers
                              .map(
                                (supplier) => DropdownMenuItem<int>(
                                  value: supplier.id,
                                  child: Text(supplier.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: state.addingSupplierItemOffer
                              ? null
                              : (value) =>
                                    setState(() => _selectedSupplierId = value),
                          decoration: const InputDecoration(
                            labelText: 'المورد',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 300.w,
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('offer-item-$_selectedItemId'),
                          initialValue: _selectedItemId,
                          items: items
                              .map(
                                (item) => DropdownMenuItem<int>(
                                  value: item.id,
                                  child: Text(
                                    '${item.itemNo ?? item.id} - ${item.description ?? 'مادة'}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: state.addingSupplierItemOffer
                              ? null
                              : (value) =>
                                    setState(() => _selectedItemId = value),
                          decoration: const InputDecoration(
                            labelText: 'المادة',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 160.w,
                        child: TextFormField(
                          controller: _price,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final parsed = num.tryParse(value ?? '');
                            if (parsed == null) return 'السعر مطلوب';
                            if (parsed <= 0) return 'أدخل سعراً صحيحاً';
                            return null;
                          },
                          decoration: const InputDecoration(labelText: 'السعر'),
                        ),
                      ),
                      SizedBox(
                        width: 300.w,
                        child: TextFormField(
                          controller: _note,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات العرض',
                          ),
                        ),
                      ),
                    ],
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
                          value: _isAlternative,
                          onChanged: state.addingSupplierItemOffer
                              ? null
                              : (value) =>
                                    setState(() => _isAlternative = value),
                          title: const Text('عرض بديل'),
                          subtitle: const Text(
                            'فعّل هذا الخيار إذا كان العرض لمادة بديلة.',
                          ),
                        ),
                        if (_isAlternative) ...[
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
    final success = await context
        .read<TenderDetailsCubit>()
        .addSupplierItemOffer(
          supplierId: supplierId,
          tenderItemId: itemId,
          price: num.parse(_price.text),
          note: _note.text,
          isAlternative: _isAlternative,
          alternativeDescription: _alternativeDescription.text,
        );
    if (!context.mounted || !success) return;
    _clearForm();
    showAppSnackBar(context, message: 'تم حفظ عرض السعر بنجاح');
  }

  void _loadOffers() {
    if (!mounted || _offersRequested || widget.state.tender == null) return;
    _offersRequested = true;
    context.read<TenderDetailsCubit>().loadSupplierItemOffers();
  }

  void _clearForm() {
    setState(() {
      _selectedSupplierId = null;
      _selectedItemId = null;
      _isAlternative = false;
      _price.clear();
      _note.clear();
      _alternativeDescription.clear();
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
}

class _SupplierItemOffersTable extends StatelessWidget {
  const _SupplierItemOffersTable({required this.offers});

  final List<SupplierItemOffer> offers;

  @override
  Widget build(BuildContext context) {
    return _HorizontalTableScroll(
      minWidth: 1080,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('المورد')),
          DataColumn(label: Text('رقم المادة')),
          DataColumn(label: Text('الوصف')),
          DataColumn(label: Text('الكمية')),
          DataColumn(label: Text('الوحدة')),
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'إحالة عطاء',
            subtitle:
                'اختر عرض السعر ثم نفذ إحالة فنية أو رئيسية مع السعر والملاحظة.',
            icon: Icons.assignment_turned_in_outlined,
            trailing: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                OutlinedButton.icon(
                  onPressed: state.tender == null
                      ? null
                      : () => TenderPdfGenerator.printPdf(
                          TenderPdfGenerator.itemAssignmentsPdf(
                            state.tender!,
                            state.tenderSuppliers,
                            state.itemAssignments,
                          ),
                          'item-assignments-${state.tender!.id}.pdf',
                        ),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('طباعة PDF'),
                ),
                IconButton(
                  onPressed:
                      state.supplierItemOffersLoading ||
                          state.itemAssignmentsLoading
                      ? null
                      : _refreshData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تحديث الإحالات والعروض',
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'عروض الأسعار المتاحة (${state.supplierItemOffers.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 10.h),
          if (state.supplierItemOffersLoading)
            const LinearProgressIndicator()
          else if (state.supplierItemOffers.isEmpty)
            const Text(
              'لا توجد عروض أسعار لإحالتها بعد.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            _AssignmentOffersTable(
              offers: state.supplierItemOffers,
              loadingOfferIds: state.loadingItemAssignments,
              onAssign: _openAssignmentDialog,
            ),
          SizedBox(height: 22.h),
          Text(
            'المواد المحالة (${state.itemAssignments.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 10.h),
          if (state.itemAssignmentsLoading)
            const LinearProgressIndicator()
          else if (state.itemAssignments.isEmpty)
            const Text(
              'لا توجد مواد محالة لهذا العطاء بعد.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            _ItemAssignmentsTable(assignments: state.itemAssignments),
        ],
      ),
    );
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
    showAppSnackBar(context, message: 'تمت إحالة العرض بنجاح');
  }
}

class _AssignmentOffersTable extends StatelessWidget {
  const _AssignmentOffersTable({
    required this.offers,
    required this.loadingOfferIds,
    required this.onAssign,
  });

  final List<SupplierItemOffer> offers;
  final Set<int> loadingOfferIds;
  final void Function(SupplierItemOffer offer, String assignmentType) onAssign;

  @override
  Widget build(BuildContext context) {
    return _HorizontalTableScroll(
      minWidth: 1180,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('المورد')),
          DataColumn(label: Text('رقم المادة')),
          DataColumn(label: Text('الوصف')),
          DataColumn(label: Text('السعر')),
          DataColumn(label: Text('بديل')),
          DataColumn(label: Text('الملاحظة')),
          DataColumn(label: Text('إحالة فنية')),
          DataColumn(label: Text('إحالة رئيسية')),
        ],
        rows: offers.map((offer) {
          final loading = loadingOfferIds.contains(offer.id);
          return DataRow(
            cells: [
              DataCell(Text(offer.supplierName ?? '-')),
              DataCell(Text(offer.itemNo ?? offer.itemId.toString())),
              DataCell(
                SizedBox(width: 220, child: Text(offer.description ?? '-')),
              ),
              DataCell(Text(offer.price?.toString() ?? '-')),
              DataCell(Text(offer.hasAlternative ? 'نعم' : 'لا')),
              DataCell(SizedBox(width: 180, child: Text(offer.note ?? '-'))),
              DataCell(
                _AssignmentTableButton(
                  label: 'إحالة فنية',
                  icon: Icons.engineering_outlined,
                  loading: loading,
                  filled: false,
                  color: AppColors.teal,
                  onPressed: () => onAssign(offer, 'TEC'),
                ),
              ),
              DataCell(
                _AssignmentTableButton(
                  label: 'إحالة رئيسية',
                  icon: Icons.verified_outlined,
                  loading: loading,
                  filled: true,
                  color: AppColors.deepBlue,
                  onPressed: () => onAssign(offer, 'MAIN'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
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
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final bool filled;
  final Color color;
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
        onPressed: loading ? null : onPressed,
        style: style,
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: style,
      child: child,
    );
  }
}

class _ItemAssignmentsTable extends StatelessWidget {
  const _ItemAssignmentsTable({required this.assignments});

  final List<ItemAssignment> assignments;

  @override
  Widget build(BuildContext context) {
    return _HorizontalTableScroll(
      minWidth: 1180,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('المورد')),
          DataColumn(label: Text('نوع الإحالة')),
          DataColumn(label: Text('سعر العرض')),
          DataColumn(label: Text('السعر المحال')),
          DataColumn(label: Text('بديل')),
          DataColumn(label: Text('ملاحظة العرض')),
          DataColumn(label: Text('ملاحظة الإحالة')),
          DataColumn(label: Text('تاريخ الإحالة')),
        ],
        rows: assignments
            .map(
              (assignment) => DataRow(
                cells: [
                  DataCell(Text(assignment.supplierName ?? '-')),
                  DataCell(Text(assignment.isTechnical ? 'فنية' : 'رئيسية')),
                  DataCell(Text(assignment.price?.toString() ?? '-')),
                  DataCell(Text(assignment.assignedPrice?.toString() ?? '-')),
                  DataCell(Text(assignment.hasAlternative ? 'نعم' : 'لا')),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(assignment.offerNote ?? '-'),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(assignment.assignmentNote ?? '-'),
                    ),
                  ),
                  DataCell(
                    Text(AppDateFormatter.dateTime(assignment.createdAt)),
                  ),
                ],
              ),
            )
            .toList(),
      ),
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
  const AttachmentsSection({
    super.key,
    required this.tender,
    required this.progress,
  });

  final TenderDetails tender;
  final double? progress;

  @override
  Widget build(BuildContext context) {
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
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                allowMultiple: true,
                withData: true,
              );
              if (result != null && context.mounted) {
                context.read<TenderDetailsCubit>().uploadFiles(result.files);
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
                  ...tender.attachments.map(
                    (file) => ListTile(
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
                        children: [
                          IconButton(
                            onPressed: file.url == null
                                ? null
                                : () => _openAttachment(file.url!),
                            icon: const Icon(Icons.open_in_new),
                            tooltip: 'فتح الملف',
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'حذف اختياري',
                          ),
                        ],
                      ),
                    ),
                  ),
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

  void _openAttachment(String url) {
    final serverBaseUrl = AppConstants.apiBaseUrl.replaceFirst('/api', '');
    final fullUrl = url.startsWith('http') ? url : '$serverBaseUrl$url';
    html.window.open(fullUrl, '_blank');
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
          RadioGroup<T>(
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
                onPressed: () => TenderPdfGenerator.printPdf(
                  TenderPdfGenerator.itemsPdf(tender),
                  'items-${tender.id}.pdf',
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
