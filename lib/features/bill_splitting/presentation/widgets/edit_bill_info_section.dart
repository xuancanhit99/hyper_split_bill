import 'package:flutter/material.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/editable_row.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/currency_dropdown_row.dart';

class EditBillInfoSection extends StatelessWidget {
  final bool isEditingMode;
  final TextEditingController descriptionController;
  final TextEditingController dateController;
  final TextEditingController totalAmountController;
  final TextEditingController taxController;
  final TextEditingController tipController;
  final TextEditingController discountController;
  final TextEditingController currencyController;
  final bool showTax;
  final bool showTip;
  final bool showDiscount;
  final bool showCurrency;
  final List<String> dropdownCurrencies;
  final VoidCallback onEditDescription;
  final VoidCallback onSelectDate;
  final VoidCallback onEditTotalAmount;
  final VoidCallback onEditTax;
  final VoidCallback onEditTip;
  final VoidCallback onEditDiscount;
  final ValueChanged<String?> onCurrencyChanged;
  final VoidCallback onAddOptionalFields;
  final String Function(num?) formatCurrencyValue; // Pass formatting function

  const EditBillInfoSection({
    super.key,
    required this.isEditingMode,
    required this.descriptionController,
    required this.dateController,
    required this.totalAmountController,
    required this.taxController,
    required this.tipController,
    required this.discountController,
    required this.currencyController,
    required this.showTax,
    required this.showTip,
    required this.showDiscount,
    required this.showCurrency,
    required this.dropdownCurrencies,
    required this.onEditDescription,
    required this.onSelectDate,
    required this.onEditTotalAmount,
    required this.onEditTax,
    required this.onEditTip,
    required this.onEditDiscount,
    required this.onCurrencyChanged,
    required this.onAddOptionalFields,
    required this.formatCurrencyValue,
  });

  // Helper to parse number from controller text safely for display formatting
  num? _parseNumFromController(TextEditingController controller) {
    if (controller.text.isEmpty) return null;
    // Basic parsing for display, assumes _parseNum handles complex cases elsewhere
    return num.tryParse(controller.text.replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Main Bill Info ---
        EditableRow(
          isEditingMode: isEditingMode,
          icon: Icons.store_mall_directory_outlined,
          label: 'Description / Store',
          value: descriptionController.text,
          onTap: onEditDescription,
        ),
        const Divider(height: 1),
        EditableRow(
          isEditingMode: isEditingMode,
          icon: Icons.calendar_today_outlined,
          label: 'Date',
          value: dateController.text,
          onTap: onSelectDate,
        ),
        const Divider(height: 1),
        EditableRow(
          isEditingMode: isEditingMode,
          textPrefix: "Total Amount:",
          label: 'Total Amount',
          // Format the parsed value for display
          value: formatCurrencyValue(
              _parseNumFromController(totalAmountController)),
          isBold: true,
          onTap: onEditTotalAmount,
        ),
        const Divider(height: 1),

        // --- Conditionally Display Optional Fields ---
        if (showTax) ...[
          EditableRow(
            isEditingMode: isEditingMode,
            textPrefix: "Tax:", // Use text prefix
            label: 'Tax',
            value: taxController.text, // Raw value from controller
            valueSuffix: "%", // Add suffix
            onTap: onEditTax,
          ),
          const Divider(height: 1),
        ],
        if (showTip) ...[
          EditableRow(
            isEditingMode: isEditingMode,
            textPrefix: "Tip:", // Use text prefix
            label: 'Tip',
            value: tipController.text, // Raw value from controller
            valueSuffix: "%", // Add suffix
            onTap: onEditTip,
          ),
          const Divider(height: 1),
        ],
        if (showDiscount) ...[
          EditableRow(
            isEditingMode: isEditingMode,
            textPrefix: "Discount:", // Use text prefix
            label: 'Discount',
            value: discountController.text, // Raw value from controller
            valueSuffix: "%", // Add suffix
            onTap: onEditDiscount,
          ),
          const Divider(height: 1),
        ],
        if (showCurrency) ...[
          CurrencyDropdownRow(
            isEditingMode: isEditingMode,
            currencyController: currencyController,
            dropdownCurrencies: dropdownCurrencies,
            onChanged: onCurrencyChanged,
          ),
          const Divider(height: 1),
        ],

        // --- Add Optional Fields Button ---
        // Positioned below the optional fields
        if (isEditingMode) // Only show button in edit mode
          Padding(
            padding: const EdgeInsets.only(top: 8.0), // Add space above
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add Tax, Tip, Discount, Currency',
                  onPressed: onAddOptionalFields,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),

        // Add space before the main divider if optional fields are shown or button is present
        if (showTax || showTip || showDiscount || showCurrency || isEditingMode)
          const SizedBox(height: 16),
      ],
    );
  }
}
