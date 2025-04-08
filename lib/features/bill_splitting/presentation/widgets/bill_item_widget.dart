import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:intl/intl.dart'; // For number formatting

// A widget to display and edit a single bill item within the BillEditPage list.
class BillItemWidget extends StatelessWidget {
  final BillItemEntity item;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final VoidCallback onDelete; // Callback when delete button is pressed
  final bool enabled; // To disable editing when saving

  const BillItemWidget({
    super.key,
    required this.item,
    required this.descriptionController,
    required this.quantityController,
    required this.priceController,
    required this.onDelete,
    this.enabled = true, // Default to enabled
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 4, // Adjust flex factor for description width
            child: TextField(
              controller: descriptionController,
              enabled: enabled,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Item Description',
                border: UnderlineInputBorder(), // Simpler border for list items
              ),
              // No need for onChanged here if state is managed via controllers in parent
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextField(
              controller: quantityController,
              enabled: enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ], // Allow only digits
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Qty',
                border: UnderlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2, // Adjust flex factor for price width
            child: TextField(
              controller: priceController,
              enabled: enabled,
              textAlign: TextAlign.right,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                // Allow numbers and one decimal point
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Total Price',
                border: UnderlineInputBorder(),
                // prefixText: '\$', // Optional: Add currency symbol
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            tooltip: 'Delete Item',
            // Disable delete button if editing is disabled
            onPressed: enabled ? onDelete : null,
          ),
        ],
      ),
    );
  }
}
