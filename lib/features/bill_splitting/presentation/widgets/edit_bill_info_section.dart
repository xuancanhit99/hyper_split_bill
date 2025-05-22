import 'package:flutter/material.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/editable_row.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/currency_dropdown_row.dart';
import 'dart:math'; // For abs()
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
// Import AmountType from BillEditPage (adjust path if necessary, or define locally if preferred)
import 'package:hyper_split_bill/features/bill_splitting/presentation/pages/bill_edit_page.dart'
    show AmountType;

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
  final VoidCallback onToggleItemDetails;
  final bool showItemDetails;
  final String Function(num?) formatCurrencyValue;
  final double? calculatedTotalAmount;
  final VoidCallback? onUpdateTotalAmount;

  // New fields for input type handling
  final AmountType taxInputType;
  final AmountType tipInputType;
  final AmountType discountInputType;
  final ValueChanged<AmountType> onTaxInputTypeChanged;
  final ValueChanged<AmountType> onTipInputTypeChanged;
  final ValueChanged<AmountType> onDiscountInputTypeChanged;

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
    required this.onToggleItemDetails,
    required this.showItemDetails,
    this.calculatedTotalAmount,
    this.onUpdateTotalAmount,
    required this.taxInputType, // Add to constructor
    required this.tipInputType, // Add to constructor
    required this.discountInputType, // Add to constructor
    required this.onTaxInputTypeChanged, // Add to constructor
    required this.onTipInputTypeChanged, // Add to constructor
    required this.onDiscountInputTypeChanged, // Add to constructor
  });

  // Helper to parse number from controller text safely
  num? _parseNumFromController(TextEditingController controller) {
    if (controller.text.isEmpty) return null;
    // Basic parsing, assumes _parseNum handles complex cases elsewhere
    final sanitized =
        controller.text.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
    return num.tryParse(sanitized);
  }

  @override
  Widget build(BuildContext context) {
    // Get the localization instance
    final l10n = AppLocalizations.of(context)!;

    // Determine if the update button should be enabled
    bool showUpdateButton = false;
    bool isUpdateButtonEnabled = false;
    if (isEditingMode &&
        calculatedTotalAmount != null &&
        onUpdateTotalAmount != null) {
      final currentTotal = _parseNumFromController(totalAmountController);
      // Show button if calculated value exists
      showUpdateButton = true;
      // Enable button only if current total is parseable and differs significantly
      if (currentTotal != null &&
          (currentTotal - calculatedTotalAmount!).abs() > 0.01) {
        isUpdateButtonEnabled = true;
      }
    }

    return Column(
      children: [
        // --- Main Bill Info ---
        EditableRow(
          isEditingMode: isEditingMode,
          icon: Icons.store_mall_directory_outlined,
          label: l10n.editBillInfoSectionDescriptionLabel, // Localized
          value: descriptionController.text,
          onTap: onEditDescription,
        ),
        const Divider(height: 1),
        EditableRow(
          isEditingMode: isEditingMode,
          icon: Icons.calendar_today_outlined,
          label: l10n.editBillInfoSectionDateLabel, // Localized
          value: dateController.text,
          onTap: onSelectDate,
        ),
        const Divider(height: 1),
        // Custom Row for Total Amount to align value with BillItemWidget Total Price column
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 0),
          child: Row(
            children: [
              Expanded(
                flex: 7, // Align label with Description + Qty + Unit Price
                child: Text(
                  l10n.editBillInfoSectionTotalAmountPrefix, // Localized label
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, // Keep it bold
                        color: Theme.of(context)
                            .colorScheme
                            .primary, // Style prefix like icon/label
                      ),
                ),
              ),
              Expanded(
                flex: 2, // Align value with Total Price column
                child: InkWell(
                  // Make the value area tappable
                  onTap: isEditingMode ? onEditTotalAmount : null,
                  child: Align(
                    alignment:
                        Alignment.centerRight, // Align value to the right
                    child: Text(
                      formatCurrencyValue(_parseNumFromController(
                          totalAmountController)), // Formatted value
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, // Keep it bold
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              // Add placeholder for the popup menu button alignment
              const SizedBox(
                  width:
                      40), // Approximate width of the PopupMenuButton + padding
            ],
          ),
        ),
        // Only show this divider if in editing mode OR if any optional fields below it are shown
        if (isEditingMode || showTax || showTip || showDiscount || showCurrency)
          const Divider(height: 1),

        // --- Conditionally Display Optional Fields ---
        if (showTax) ...[
          Row(
            children: [
              Expanded(
                child: EditableRow(
                  isEditingMode: isEditingMode,
                  textPrefix: "${l10n.editBillInfoSectionTaxLabel}:",
                  label: l10n.editBillInfoSectionTaxLabel,
                  value: taxController.text,
                  valueSuffix: taxInputType == AmountType.percentage
                      ? '%'
                      : currencyController.text,
                  onTap: onEditTax,
                ),
              ),
              if (isEditingMode)
                ToggleButtons(
                  isSelected: [
                    taxInputType == AmountType.percentage,
                    taxInputType == AmountType.fixed
                  ],
                  onPressed: (index) {
                    onTaxInputTypeChanged(
                        index == 0 ? AmountType.percentage : AmountType.fixed);
                  },
                  constraints:
                      const BoxConstraints(minHeight: 32.0, minWidth: 40.0),
                  children: const <Widget>[
                    Text('%'),
                    Icon(Icons.attach_money)
                  ], // Consider localizing currency icon/text
                ),
            ],
          ),
          const Divider(height: 1),
        ],
        if (showTip) ...[
          Row(
            children: [
              Expanded(
                child: EditableRow(
                  isEditingMode: isEditingMode,
                  textPrefix: "${l10n.editBillInfoSectionTipLabel}:",
                  label: l10n.editBillInfoSectionTipLabel,
                  value: tipController.text,
                  valueSuffix: tipInputType == AmountType.percentage
                      ? '%'
                      : currencyController.text,
                  onTap: onEditTip,
                ),
              ),
              if (isEditingMode)
                ToggleButtons(
                  isSelected: [
                    tipInputType == AmountType.percentage,
                    tipInputType == AmountType.fixed
                  ],
                  onPressed: (index) {
                    onTipInputTypeChanged(
                        index == 0 ? AmountType.percentage : AmountType.fixed);
                  },
                  constraints:
                      const BoxConstraints(minHeight: 32.0, minWidth: 40.0),
                  children: const <Widget>[Text('%'), Icon(Icons.attach_money)],
                ),
            ],
          ),
          const Divider(height: 1),
        ],
        if (showDiscount) ...[
          Row(
            children: [
              Expanded(
                child: EditableRow(
                  isEditingMode: isEditingMode,
                  textPrefix: "${l10n.editBillInfoSectionDiscountLabel}:",
                  label: l10n.editBillInfoSectionDiscountLabel,
                  value: discountController.text,
                  valueSuffix: discountInputType == AmountType.percentage
                      ? '%'
                      : currencyController.text,
                  onTap: onEditDiscount,
                ),
              ),
              if (isEditingMode)
                ToggleButtons(
                  isSelected: [
                    discountInputType == AmountType.percentage,
                    discountInputType == AmountType.fixed
                  ],
                  onPressed: (index) {
                    onDiscountInputTypeChanged(
                        index == 0 ? AmountType.percentage : AmountType.fixed);
                  },
                  constraints:
                      const BoxConstraints(minHeight: 32.0, minWidth: 40.0),
                  children: const <Widget>[Text('%'), Icon(Icons.attach_money)],
                ),
            ],
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

        // --- Action Buttons Row ---
        if (isEditingMode)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Align buttons
              children: [
                // Update Total Button (conditionally shown and enabled)
                if (showUpdateButton)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l10n
                        .editBillInfoSectionUpdateTotalButtonLabel), // Use localized string
                    onPressed: isUpdateButtonEnabled
                        ? onUpdateTotalAmount
                        : null, // Enable/disable based on comparison
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isUpdateButtonEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      side: BorderSide(
                          color: isUpdateButtonEnabled
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  )
                else
                  const SizedBox(), // Placeholder to maintain alignment if button not shown

                // Group the action buttons
                Row(
                  mainAxisSize: MainAxisSize.min, // Take minimum space
                  children: [
                    // Toggle Item Details Button
                    IconButton(
                      icon: Icon(showItemDetails
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      tooltip: showItemDetails
                          ? l10n
                              .editBillInfoSectionToggleDetailsHideTooltip // Localized
                          : l10n
                              .editBillInfoSectionToggleDetailsShowTooltip, // Localized
                      onPressed: onToggleItemDetails,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary, // Use secondary color
                    ),
                    const SizedBox(width: 8), // Space between buttons
                    // Add Optional Fields Button
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: l10n
                          .editBillInfoSectionAddOptionalTooltip, // Localized
                      onPressed: onAddOptionalFields,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
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
