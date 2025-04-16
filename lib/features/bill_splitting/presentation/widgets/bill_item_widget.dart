import 'package:flutter/material.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:intl/intl.dart'; // For number formatting

// A widget to display a single bill item within the BillItemsSection list.
class BillItemWidget extends StatelessWidget {
  final BillItemEntity item;
  final VoidCallback onEdit; // Callback when edit button is pressed
  // final bool enabled; // Keep if needed to disable the edit button itself

  const BillItemWidget({
    super.key,
    required this.item,
    required this.onEdit,
    // this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Formatter for currency display
    final currencyFormat = NumberFormat.currency(
        locale: 'en_US', symbol: ''); // Adjust symbol/locale as needed
    final quantityFormat = NumberFormat.decimalPattern();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item.description,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              quantityFormat.format(item.quantity),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              // Display unit price
              currencyFormat.format(item.unitPrice),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              // Display total price
              currencyFormat.format(item.totalPrice),
              textAlign: TextAlign.right,
            ),
          ),
          // IconButton for editing
          IconButton(
            icon: const Icon(Icons.more_vert),
            iconSize: 20.0, // Make icon slightly smaller if needed
            padding: EdgeInsets.zero, // Remove default padding
            constraints:
                const BoxConstraints(), // Remove constraints to allow zero padding
            tooltip: 'Edit Item',
            // Disable edit button if editing is disabled (using parent's enabled state)
            // onPressed: enabled ? onEdit : null,
            onPressed: onEdit, // Assuming parent handles enabled state
          ),
        ],
      ),
    );
  }
}
