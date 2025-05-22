import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

class EditableRow extends StatelessWidget {
  final IconData? icon;
  final String? textPrefix;
  final String label;
  final String value;
  final String? valueSuffix;
  final VoidCallback? onTap;
  final bool isBold;
  final bool isEditingMode; // To control tap behavior and edit icon visibility

  const EditableRow({
    super.key,
    this.icon,
    this.textPrefix,
    required this.label,
    required this.value,
    this.valueSuffix,
    this.onTap,
    this.isBold = false,
    required this.isEditingMode,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isBold ? 18 : 16,
        );

    // Get the localization instance
    final l10n = AppLocalizations.of(context)!;

    final displayValue = value.isEmpty
        ? l10n.editableRowTapToEdit(label)
        : '$value${valueSuffix ?? ''}';
    return InkWell(
      onTap: isEditingMode ? onTap : null, // Only allow tap in edit mode
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 0),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
            ] else if (textPrefix != null) ...[
              Text(textPrefix!, // Assert non-null here
                  style: textStyle?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .primary)), // Style prefix like icon
              const SizedBox(width: 8), // Smaller gap for text prefix
            ],
            Expanded(
              child: Text(
                displayValue,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isEditingMode &&
                onTap != null) // Show edit indicator only if editable
              Icon(Icons.edit_note_outlined, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
