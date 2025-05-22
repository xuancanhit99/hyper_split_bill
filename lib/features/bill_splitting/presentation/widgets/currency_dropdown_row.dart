import 'package:flutter/material.dart';
import 'package:hyper_split_bill/core/constants/currencies.dart'; // Import currency map

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
    final textStyle = Theme.of(context).textTheme.titleMedium;
    final selectedCurrencyCode = currencyController.text;
    // Get the currency name from the map, fallback to code if not found
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
                        // Get the currency name from the map, fallback to code if not found
                        final name = cCurrencyMap[code] ?? code;
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text(
                              '$code - $name', // Display code and non-localized name
                              style: textStyle,
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: onChanged, // Use the passed callback
                      menuMaxHeight: 300.0,
                    ),
                  )
                : Text(
                    // Display as plain text when not editing, using the non-localized name
                    '$selectedCurrencyCode - $currencyName', // Display code and non-localized name
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
          ), // Closes Expanded
          if (isEditingMode) // Show edit indicator only if editable
            Icon(Icons.edit_note_outlined, size: 18, color: Colors.grey[600]),
        ],
      ),
    );
  }
}
