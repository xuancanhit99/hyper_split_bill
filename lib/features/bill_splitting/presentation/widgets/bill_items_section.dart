import 'package:flutter/material.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_item_widget.dart';

// Widget to manage the list of bill items (display, add, edit, delete)
class BillItemsSection extends StatefulWidget {
  final List<BillItemEntity> initialItems;
  final bool enabled;
  final Function(List<BillItemEntity>)
      onItemsChanged; // Callback to notify parent

  const BillItemsSection({
    super.key,
    required this.initialItems,
    required this.onItemsChanged,
    this.enabled = true,
  });

  @override
  State<BillItemsSection> createState() => _BillItemsSectionState();
}

class _BillItemsSectionState extends State<BillItemsSection> {
  late List<BillItemEntity> _items;
  // No longer need controllers here, they will be in the dialog
  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems); // Create a mutable copy
    // Ensure all initial items have IDs
    _items = _items.map((item) {
      if (item.id == null || item.id!.isEmpty) {
        return item.copyWith(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}_${_items.indexOf(item)}');
      }
      return item;
    }).toList();
  }

  // Update item details after editing in the dialog
  void _updateItem(int index, BillItemEntity updatedItem) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      _items[index] =
          updatedItem.copyWith(id: _items[index].id); // Keep original ID
    });
    // Notify the parent widget about the change
    widget.onItemsChanged(_items);
  }

  void _addItem() {
    setState(() {
      final newItem = BillItemEntity(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}', // Unique ID for new item
        description: '',
        quantity: 1,
        unitPrice: 0.0,
        totalPrice: 0.0,
      );
      _items.add(newItem);
    });
    widget.onItemsChanged(_items); // Notify parent
    // Optionally, immediately open the edit dialog for the new item:
    // _showEditItemDialog(_items.length - 1);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    widget.onItemsChanged(_items); // Notify parent
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(), // Add header row
        const Divider(height: 1, thickness: 1), // Divider below header
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text('No items added yet.',
                style: TextStyle(color: Colors.grey[600])),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Dismissible(
                key: ValueKey(item.id ?? index), // Unique key for Dismissible
                direction: DismissDirection.endToStart, // Swipe direction
                onDismissed: (direction) {
                  _removeItem(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.description} deleted')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: BillItemWidget(
                  item: item,
                  onEdit: widget.enabled
                      ? () => _showEditItemDialog(index)
                      : () {}, // Show dialog on edit press
                ),
              );
            },
            separatorBuilder: (context, index) =>
                const Divider(height: 1, thickness: 1), // Divider between items
          ),
        const SizedBox(height: 8),
        if (widget.enabled) // Only show Add button if enabled
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Item'),
              onPressed: _addItem,
            ),
          ),
      ],
    );
  }

  // Header Row Widget
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 8.0, horizontal: 4.0), // Match item padding
      child: Row(
        children: [
          const Expanded(
            flex: 4,
            child: Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          const Expanded(
            flex: 1,
            child: Text('Qty',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          const Expanded(
            flex: 2,
            child: Text('Unit Price',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          const Expanded(
            flex: 2,
            child: Text('Total Price',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          // Placeholder for the edit icon width
          IconButton(
            icon: const Icon(Icons.more_vert,
                color: Colors.transparent), // Invisible icon
            onPressed: null,
            iconSize: 20.0,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // --- Edit Item Dialog ---
  Future<void> _showEditItemDialog(int index) async {
    final BillItemEntity currentItem = _items[index];
    final descriptionController =
        TextEditingController(text: currentItem.description);
    final quantityController =
        TextEditingController(text: currentItem.quantity.toString());
    final unitPriceController =
        TextEditingController(text: currentItem.unitPrice.toStringAsFixed(2));
    final totalPriceController =
        TextEditingController(text: currentItem.totalPrice.toStringAsFixed(2));

    // State for checkboxes within the dialog
    bool isQuantityConfirmed = false;
    bool isUnitPriceConfirmed = false;
    bool isTotalPriceConfirmed = false;

    // Function to calculate fields
    void calculatePrices() {
      final quantity = int.tryParse(quantityController.text) ?? 0;
      final unitPrice = double.tryParse(unitPriceController.text) ?? 0.0;
      final totalPrice = double.tryParse(totalPriceController.text) ?? 0.0;

      // Calculation now depends on confirmed fields
      int confirmedCount = (isQuantityConfirmed ? 1 : 0) +
          (isUnitPriceConfirmed ? 1 : 0) +
          (isTotalPriceConfirmed ? 1 : 0);

      if (confirmedCount == 2) {
        if (isQuantityConfirmed &&
            isUnitPriceConfirmed &&
            !isTotalPriceConfirmed) {
          if (quantity > 0 && unitPrice >= 0) {
            final calculatedTotal = quantity * unitPrice;
            totalPriceController.text = calculatedTotal.toStringAsFixed(2);
          }
        } else if (isQuantityConfirmed &&
            isTotalPriceConfirmed &&
            !isUnitPriceConfirmed) {
          if (quantity > 0 && totalPrice >= 0) {
            // Avoid division by zero
            final calculatedUnitPrice =
                (quantity == 0) ? 0.0 : totalPrice / quantity;
            unitPriceController.text = calculatedUnitPrice.toStringAsFixed(2);
          }
        } else if (isUnitPriceConfirmed &&
            isTotalPriceConfirmed &&
            !isQuantityConfirmed) {
          if (unitPrice > 0 && totalPrice >= 0) {
            // Avoid division by zero, result is rounded quantity
            final calculatedQuantity =
                (unitPrice == 0) ? 0 : (totalPrice / unitPrice).round();
            quantityController.text = calculatedQuantity.toString();
          } else if (unitPrice == 0 && totalPrice == 0) {
            // If both unit price and total are 0, quantity could be anything.
            // Let's clear it to force user input or keep existing value.
            // quantityController.text = ''; // Or keep current value
          }
        }
      }
    }

    // --- No longer need listeners for auto-calculation ---
    // quantityController.addListener(calculatePrices);
    // unitPriceController.addListener(calculatePrices);
    // totalPriceController.addListener(calculatePrices); // Recalculate if total is manually changed

    final result = await showDialog<BillItemEntity?>(
      context: context,
      // Use StatefulBuilder to manage dialog's internal state (checkboxes)
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        // Determine which fields are enabled based on confirmations
        bool quantityEnabled = !isQuantityConfirmed &&
            !(isUnitPriceConfirmed && isTotalPriceConfirmed);
        bool unitPriceEnabled = !isUnitPriceConfirmed &&
            !(isQuantityConfirmed && isTotalPriceConfirmed);
        bool totalPriceEnabled = !isTotalPriceConfirmed &&
            !(isQuantityConfirmed && isUnitPriceConfirmed);

        return AlertDialog(
          title:
              Text(currentItem.description.isEmpty ? 'Add Item' : 'Edit Item'),
          content: SingleChildScrollView(
            // Prevent overflow
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12), // Increased spacing
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration:
                            const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        enabled: quantityEnabled,
                      ),
                    ),
                    Checkbox(
                      value: isQuantityConfirmed,
                      // Disable checkbox if the field is implicitly calculated
                      onChanged: (isUnitPriceConfirmed && isTotalPriceConfirmed)
                          ? null
                          : (bool? value) {
                              setDialogState(() {
                                isQuantityConfirmed = value ?? false;
                                // If checking this makes 3 checked, uncheck the oldest or least likely?
                                // Simple approach: if 3 are checked, uncheck the others.
                                if (isQuantityConfirmed &&
                                    isUnitPriceConfirmed &&
                                    isTotalPriceConfirmed) {
                                  isUnitPriceConfirmed =
                                      false; // Example: uncheck unit price
                                  isTotalPriceConfirmed = false;
                                }
                                calculatePrices(); // Recalculate after state change
                              });
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unitPriceController,
                        decoration:
                            const InputDecoration(labelText: 'Unit Price'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'))
                        ],
                        enabled: unitPriceEnabled,
                      ),
                    ),
                    Checkbox(
                      value: isUnitPriceConfirmed,
                      onChanged: (isQuantityConfirmed && isTotalPriceConfirmed)
                          ? null
                          : (bool? value) {
                              setDialogState(() {
                                isUnitPriceConfirmed = value ?? false;
                                if (isQuantityConfirmed &&
                                    isUnitPriceConfirmed &&
                                    isTotalPriceConfirmed) {
                                  isQuantityConfirmed = false;
                                  isTotalPriceConfirmed = false;
                                }
                                calculatePrices();
                              });
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalPriceController,
                        decoration:
                            const InputDecoration(labelText: 'Total Price'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'))
                        ],
                        enabled: totalPriceEnabled,
                      ),
                    ),
                    Checkbox(
                      value: isTotalPriceConfirmed,
                      onChanged: (isQuantityConfirmed && isUnitPriceConfirmed)
                          ? null
                          : (bool? value) {
                              setDialogState(() {
                                isTotalPriceConfirmed = value ?? false;
                                if (isQuantityConfirmed &&
                                    isUnitPriceConfirmed &&
                                    isTotalPriceConfirmed) {
                                  isQuantityConfirmed = false;
                                  isUnitPriceConfirmed = false;
                                }
                                calculatePrices();
                              });
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context)
                    .pop(null); // Indicate deletion by returning null
                _removeItem(index); // Remove the item
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () =>
                  Navigator.of(context).pop(), // Return nothing on cancel
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                // Validation before saving
                final quantity = int.tryParse(quantityController.text);
                final unitPrice = double.tryParse(unitPriceController.text);
                final totalPrice = double.tryParse(totalPriceController.text);
                int confirmedCount = (isQuantityConfirmed ? 1 : 0) +
                    (isUnitPriceConfirmed ? 1 : 0) +
                    (isTotalPriceConfirmed ? 1 : 0);

                if (descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Description cannot be empty.')));
                  return;
                }
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Quantity must be a positive number.')));
                  return;
                }
                if (unitPrice == null ||
                    unitPrice < 0 ||
                    totalPrice == null ||
                    totalPrice < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Prices cannot be negative.')));
                  return;
                }
                // Ensure exactly two fields were confirmed for calculation consistency check
                if (confirmedCount != 2) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Please confirm exactly two values (Quantity, Unit Price, or Total Price) using the checkboxes.')));
                  return;
                }

                // Check calculation consistency based on the final values
                final finalCalculatedTotal = (quantity * unitPrice);
                if ((finalCalculatedTotal - totalPrice).abs() > 0.01) {
                  // Allow small tolerance
                  // This might happen if user manually changed a calculated field after confirmation
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Error: Final values are inconsistent (Qty * Unit Price != Total Price). Please re-confirm.')));
                  return;
                }

                final updatedItem = BillItemEntity(
                  id: currentItem.id, // Keep the original ID
                  description: descriptionController.text.trim(),
                  quantity: quantity,
                  unitPrice: unitPrice,
                  // Use the validated total price from the controller
                  totalPrice: totalPrice,
                );
                Navigator.of(context)
                    .pop(updatedItem); // Return the updated item
              },
            ),
          ],
        );
      }),
    );

    // --- Dispose controllers ---
    // Remove listeners after dialog is closed (No longer needed)
    // quantityController.removeListener(calculatePrices);
    // unitPriceController.removeListener(calculatePrices);
    // totalPriceController.removeListener(calculatePrices);
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    totalPriceController.dispose();

    if (result != null) {
      // If the dialog returned an updated item (Save was pressed)
      _updateItem(index, result);
    }
    // If result is null (Delete or Cancel pressed), item removal is handled by the delete button's onPressed
  }
}
/*
Original build method content:
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No items parsed or added yet.',
                style: TextStyle(color: Colors.grey[600])),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              // Get controllers, ensuring they exist
              final descriptionCtrl = _descriptionControllers.putIfAbsent(
                  item.id, () => TextEditingController(text: item.description));
              final priceCtrl = _priceControllers.putIfAbsent(
                  item.id,
                  () => TextEditingController(
                      text: item.totalPrice.toStringAsFixed(2)));
              final quantityCtrl = _quantityControllers.putIfAbsent(item.id,
                  () => TextEditingController(text: item.quantity.toString()));

              return BillItemWidget(
                key: ValueKey(item.id ?? index), // Use a key
                item: item,
                descriptionController: descriptionCtrl,
                quantityController: quantityCtrl,
                priceController: priceCtrl,
                enabled: widget.enabled,
                onDelete: () => _removeItem(index),
                // Pass update callbacks to BillItemWidget if needed for immediate updates
                // onDescriptionChanged: (value) => _updateItem(index, description: value),
                // onQuantityChanged: (value) => _updateItem(index, quantity: int.tryParse(value)),
                // onPriceChanged: (value) => _updateItem(index, totalPrice: double.tryParse(value)),
              );
            },
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Item'),
          onPressed: widget.enabled ? _addItem : null,
        ),
      ],
    );
*/

/* Original _showEditItemDialog before checkbox logic:
  Future<void> _showEditItemDialog(int index) async {
    final BillItemEntity currentItem = _items[index];
    final descriptionController = TextEditingController(text: currentItem.description);
    final quantityController = TextEditingController(text: currentItem.quantity.toString());
    final unitPriceController = TextEditingController(text: currentItem.unitPrice.toStringAsFixed(2));
    final totalPriceController = TextEditingController(text: currentItem.totalPrice.toStringAsFixed(2));

    // Function to calculate fields
    void calculatePrices() {
      final quantity = int.tryParse(quantityController.text) ?? 0;
      final unitPrice = double.tryParse(unitPriceController.text) ?? 0.0;
      final totalPrice = double.tryParse(totalPriceController.text) ?? 0.0;

      // Basic logic: if quantity and unit price are valid, calculate total.
      // More complex logic can be added here based on which field was last edited.
      if (quantity > 0 && unitPrice > 0) {
        final calculatedTotal = quantity * unitPrice;
        // Avoid unnecessary updates if the value is already correct within tolerance
        if ((calculatedTotal - totalPrice).abs() > 0.001) {
           totalPriceController.text = calculatedTotal.toStringAsFixed(2);
        }
      }
      // Add more cases: e.g., if total and quantity are known, calculate unit price.
      else if (quantity > 0 && totalPrice > 0) {
         final calculatedUnitPrice = totalPrice / quantity;
         if ((calculatedUnitPrice - unitPrice).abs() > 0.001) {
            unitPriceController.text = calculatedUnitPrice.toStringAsFixed(2);
         }
      }
      // Add case for unit price and total known -> quantity (might result in non-integer)
      // Handle potential division by zero if needed.
    }

    // Add listeners for calculation
    quantityController.addListener(calculatePrices);
    unitPriceController.addListener(calculatePrices);
    totalPriceController.addListener(calculatePrices); // Recalculate if total is manually changed

    final result = await showDialog<BillItemEntity?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentItem.description.isEmpty ? 'Add Item' : 'Edit Item'),
        content: SingleChildScrollView( // Prevent overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unitPriceController,
                      decoration: const InputDecoration(labelText: 'Unit Price'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: totalPriceController,
                decoration: const InputDecoration(labelText: 'Total Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop(null); // Indicate deletion by returning null
              _removeItem(index); // Remove the item
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(), // Return nothing on cancel
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              // Validation before saving
              final quantity = int.tryParse(quantityController.text);
              final unitPrice = double.tryParse(unitPriceController.text);
              final totalPrice = double.tryParse(totalPriceController.text);

              if (descriptionController.text.trim().isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Description cannot be empty.')));
                 return;
              }
              if (quantity == null || quantity <= 0) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity must be a positive number.')));
                 return;
              }
               if (unitPrice == null || unitPrice < 0 || totalPrice == null || totalPrice < 0) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prices cannot be negative.')));
                 return;
              }
              // Check calculation consistency (optional but recommended)
              if ((quantity * unitPrice - totalPrice).abs() > 0.01) { // Allow small tolerance
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Total Price does not match Quantity * Unit Price. Please adjust.')));
                 return;
              }

              final updatedItem = BillItemEntity(
                id: currentItem.id, // Keep the original ID
                description: descriptionController.text.trim(),
                quantity: quantity,
                unitPrice: unitPrice,
                totalPrice: totalPrice,
              );
              Navigator.of(context).pop(updatedItem); // Return the updated item
            },
          ),
        ],
      ),
    );

    // Remove listeners after dialog is closed
    quantityController.removeListener(calculatePrices);
    unitPriceController.removeListener(calculatePrices);
    totalPriceController.removeListener(calculatePrices);
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    totalPriceController.dispose();

    if (result != null) {
      // If the dialog returned an updated item (Save was pressed)
      _updateItem(index, result);
    }
    // If result is null (Delete or Cancel pressed), item removal is handled by the delete button's onPressed
  }
*/
