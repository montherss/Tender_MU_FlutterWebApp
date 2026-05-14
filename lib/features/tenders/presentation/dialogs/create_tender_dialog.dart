import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/tender_domain.dart';
import '../cubit/tenders_cubit.dart';

class CreateTenderDialog extends StatefulWidget {
  const CreateTenderDialog({super.key});

  @override
  State<CreateTenderDialog> createState() => _CreateTenderDialogState();
}

class _CreateTenderDialogState extends State<CreateTenderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _purchaseRequestController = TextEditingController();

  @override
  void dispose() {
    _purchaseRequestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إنشاء عطاء جديد'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _purchaseRequestController,
            decoration: const InputDecoration(
              labelText: 'رقم طلب الشراء',
              prefixIcon: Icon(Icons.request_quote_outlined),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        BlocBuilder<TendersCubit, TendersState>(
          builder: (context, state) {
            return ElevatedButton.icon(
              onPressed: state.isCreating
                  ? null
                  : () async {
                      await context.read<TendersCubit>().createTender(
                            CreateTenderRequest(purchaseRequestNo: _purchaseRequestController.text),
                          );
                      if (context.mounted) Navigator.of(context).pop(true);
                    },
              icon: state.isCreating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
              label: const Text('إنشاء'),
            );
          },
        ),
      ],
    );
  }
}
