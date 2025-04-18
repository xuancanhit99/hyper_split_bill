import 'package:flutter/material.dart';
import 'package:hyper_split_bill/core/constants/currencies.dart'; // Import currency map
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

class CurrencyDropdownRow extends StatelessWidget {
  final bool isEditingMode;
  final TextEditingController currencyController;
  final List<String> dropdownCurrencies;
  final ValueChanged<String?> onChanged; // Callback for when currency changes

  const CurrencyDropdownRow({
    super.key,
    required this.isEditingMode,
    required this.currencyController,
    required this.dropdownCurrencies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Get the localization instance
    final l10n = AppLocalizations.of(context)!;

    final textStyle = Theme.of(context).textTheme.titleMedium;
    final selectedCurrencyCode = currencyController.text;
    // Use the map constant defined in currencies.dart
    final currencyName =
        cCurrencyMap[selectedCurrencyCode] ?? selectedCurrencyCode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      child: Row(
        children: [
          Icon(Icons.attach_money_outlined,
              size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: isEditingMode
                ? DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dropdownCurrencies.contains(selectedCurrencyCode)
                          ? selectedCurrencyCode
                          : (dropdownCurrencies.isNotEmpty
                              ? dropdownCurrencies.first
                              : null),
                      isExpanded: true,
                      items: dropdownCurrencies.map((String code) {
                        // Use the map constant here as well
                        final name = cCurrencyMap[code] ?? code;
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text(
                              l10n.currencyDisplayFormat(
                                  code, name), // Use localized format
                              style: textStyle,
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: onChanged, // Use the passed callback
                      menuMaxHeight: 300.0,
                    ),
                  )
                : Text(
                    // Display as plain text when not editing
                    l10n.currencyDisplayFormat(selectedCurrencyCode,
                        currencyName), // Use localized format
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (isEditingMode) // Show edit indicator only if editable
            Icon(Icons.edit_note_outlined, size: 18, color: Colors.grey[600]),
        ],
      ),
    );
  }
}
