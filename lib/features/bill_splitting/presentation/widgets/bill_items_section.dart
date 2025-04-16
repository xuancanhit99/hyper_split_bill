import 'package:flutter/material.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_item_widget.dart';

// --- Stateful Widget for Item Edit Dialog Content ---
class _ItemDialogContent extends StatefulWidget {
  final BillItemEntity initialItem;

  const _ItemDialogContent({super.key, required this.initialItem});

  @override
  _ItemDialogContentState createState() => _ItemDialogContentState();
}

class _ItemDialogContentState extends State<_ItemDialogContent> {
  late final TextEditingController descriptionController;
  late final TextEditingController quantityController;
  late final TextEditingController unitPriceController;
  late final TextEditingController totalPriceController;
  final formKey =
      GlobalKey<FormState>(); // Add form key for validation if needed

  // State for checkboxes within the dialog
  bool isQuantityConfirmed = false;
  bool isUnitPriceConfirmed = false;
  bool isTotalPriceConfirmed = false;

  @override
  void initState() {
    super.initState();
    descriptionController =
        TextEditingController(text: widget.initialItem.description);
    quantityController =
        TextEditingController(text: widget.initialItem.quantity.toString());
    unitPriceController = TextEditingController(
        text: widget.initialItem.unitPrice.toStringAsFixed(2));
    totalPriceController = TextEditingController(
        text: widget.initialItem.totalPrice.toStringAsFixed(2));

    // Initial confirmation state (e.g., confirm existing non-zero values)
    // This logic might need refinement based on desired UX
    isQuantityConfirmed = widget.initialItem.quantity != 0;
    isUnitPriceConfirmed = widget.initialItem.unitPrice != 0.0;
    isTotalPriceConfirmed = widget.initialItem.totalPrice != 0.0;
    // Ensure only two are confirmed initially if possible
    _ensureTwoConfirmed();
    // Initial calculation if needed
    WidgetsBinding.instance.addPostFrameCallback((_) => calculatePrices());
  }

  @override
  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    totalPriceController.dispose();
    super.dispose();
  }

  // Function to ensure only two fields are confirmed initially or after changes
  void _ensureTwoConfirmed() {
    int confirmedCount = (isQuantityConfirmed ? 1 : 0) +
        (isUnitPriceConfirmed ? 1 : 0) +
        (isTotalPriceConfirmed ? 1 : 0);

    if (confirmedCount > 2) {
      // Prioritize unchecking total price, then unit price if still > 2
      if (isTotalPriceConfirmed) isTotalPriceConfirmed = false;
      if (isUnitPriceConfirmed && isQuantityConfirmed)
        isUnitPriceConfirmed = false; // Now exactly 2
    }
    // If less than 2 are confirmed, it's okay, user needs to confirm more.
  }

  // Function to calculate fields
  void calculatePrices() {
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final unitPrice = double.tryParse(unitPriceController.text) ?? 0.0;
    final totalPrice = double.tryParse(totalPriceController.text) ?? 0.0;

    int confirmedCount = (isQuantityConfirmed ? 1 : 0) +
        (isUnitPriceConfirmed ? 1 : 0) +
        (isTotalPriceConfirmed ? 1 : 0);

    if (confirmedCount == 2) {
      if (isQuantityConfirmed &&
          isUnitPriceConfirmed &&
          !isTotalPriceConfirmed) {
        if (quantity >= 0 && unitPrice >= 0) {
          // Allow quantity 0
          final calculatedTotal = quantity * unitPrice;
          // Avoid updating if the text is already the same (prevents cursor jump)
          if (totalPriceController.text != calculatedTotal.toStringAsFixed(2)) {
            totalPriceController.text = calculatedTotal.toStringAsFixed(2);
          }
        }
      } else if (isQuantityConfirmed &&
          isTotalPriceConfirmed &&
          !isUnitPriceConfirmed) {
        if (quantity > 0 && totalPrice >= 0) {
          // quantity > 0 for division
          final calculatedUnitPrice = totalPrice / quantity;
          if (unitPriceController.text !=
              calculatedUnitPrice.toStringAsFixed(2)) {
            unitPriceController.text = calculatedUnitPrice.toStringAsFixed(2);
          }
        } else if (quantity == 0 && totalPrice == 0) {
          if (unitPriceController.text != "0.00")
            unitPriceController.text = "0.00";
        }
      } else if (isUnitPriceConfirmed &&
          isTotalPriceConfirmed &&
          !isQuantityConfirmed) {
        if (unitPrice > 0 && totalPrice >= 0) {
          // unitPrice > 0 for division
          final calculatedQuantity = (totalPrice / unitPrice).round();
          if (quantityController.text != calculatedQuantity.toString()) {
            quantityController.text = calculatedQuantity.toString();
          }
        } else if (unitPrice == 0 && totalPrice == 0) {
          if (quantityController.text != "0")
            quantityController.text = "0"; // Or 1? Depends on UX
        }
      }
    }
    // Trigger rebuild to update enabled states
    setState(() {});
  }

  BillItemEntity? getUpdatedItem() {
    // Validation before saving
    final description = descriptionController.text.trim();
    final quantity = int.tryParse(quantityController.text);
    final unitPrice = double.tryParse(unitPriceController.text);
    final totalPrice = double.tryParse(totalPriceController.text);
    int confirmedCount = (isQuantityConfirmed ? 1 : 0) +
        (isUnitPriceConfirmed ? 1 : 0) +
        (isTotalPriceConfirmed ? 1 : 0);

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description cannot be empty.')));
      return null;
    }
    if (quantity == null || quantity < 0) {
      // Allow 0 quantity
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Quantity must be a non-negative number.')));
      return null;
    }
    if (unitPrice == null ||
        unitPrice < 0 ||
        totalPrice == null ||
        totalPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prices cannot be negative.')));
      return null;
    }
    // Ensure exactly two fields were confirmed for calculation consistency check
    if (confirmedCount != 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Please confirm exactly two values (Quantity, Unit Price, or Total Price) using the checkboxes.')));
      return null;
    }

    // Check calculation consistency based on the final values
    final finalCalculatedTotal = (quantity * unitPrice);
    // Use a small tolerance for floating point comparisons
    if ((finalCalculatedTotal - totalPrice).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Error: Final values are inconsistent (Qty * Unit Price != Total Price). Please re-confirm.')));
      return null;
    }

    return BillItemEntity(
      id: widget.initialItem.id, // Keep the original ID
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which fields are enabled based on confirmations
    bool quantityEnabled = !isQuantityConfirmed &&
        !(isUnitPriceConfirmed && isTotalPriceConfirmed);
    bool unitPriceEnabled = !isUnitPriceConfirmed &&
        !(isQuantityConfirmed && isTotalPriceConfirmed);
    bool totalPriceEnabled = !isTotalPriceConfirmed &&
        !(isQuantityConfirmed && isUnitPriceConfirmed);

    return SingleChildScrollView(
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
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: quantityEnabled,
                  onChanged: (_) => calculatePrices(), // Recalculate on change
                ),
              ),
              Checkbox(
                value: isQuantityConfirmed,
                // Disable checkbox if the field is implicitly calculated
                onChanged: (isUnitPriceConfirmed && isTotalPriceConfirmed)
                    ? null
                    : (bool? value) {
                        setState(() {
                          isQuantityConfirmed = value ?? false;
                          _ensureTwoConfirmed();
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
                  decoration: const InputDecoration(labelText: 'Unit Price'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                  enabled: unitPriceEnabled,
                  onChanged: (_) => calculatePrices(), // Recalculate on change
                ),
              ),
              Checkbox(
                value: isUnitPriceConfirmed,
                onChanged: (isQuantityConfirmed && isTotalPriceConfirmed)
                    ? null
                    : (bool? value) {
                        setState(() {
                          isUnitPriceConfirmed = value ?? false;
                          _ensureTwoConfirmed();
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
                  decoration: const InputDecoration(labelText: 'Total Price'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                  enabled: totalPriceEnabled,
                  onChanged: (_) => calculatePrices(), // Recalculate on change
                ),
              ),
              Checkbox(
                value: isTotalPriceConfirmed,
                onChanged: (isQuantityConfirmed && isUnitPriceConfirmed)
                    ? null
                    : (bool? value) {
                        setState(() {
                          isTotalPriceConfirmed = value ?? false;
                          _ensureTwoConfirmed();
                          calculatePrices();
                        });
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    // Use addPostFrameCallback to ensure state update happens safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _items[index] =
              updatedItem.copyWith(id: _items[index].id); // Keep original ID
        });
        // Notify the parent widget about the change
        widget.onItemsChanged(_items);
      }
    });
  }

  void _addItem() {
    final newItem = BillItemEntity(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}', // Unique ID for new item
      description: '',
      quantity: 1, // Default quantity to 1 instead of 0
      unitPrice: 0.0,
      totalPrice: 0.0,
    );
    // Use addPostFrameCallback for adding item and showing dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _items.add(newItem);
        });
        widget.onItemsChanged(_items); // Notify parent
        // Immediately open the edit dialog for the new item:
        _showEditItemDialog(_items.length - 1, isAdding: true);
      }
    });
  }

  void _removeItem(int index) {
    // Use addPostFrameCallback for safe state update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final item = _items[index]; // Get item before removing
        setState(() {
          _items.removeAt(index);
        });
        widget.onItemsChanged(_items); // Notify parent
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${item.description.isNotEmpty ? item.description : "Item"} deleted')),
        );
      }
    });
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
                direction: widget.enabled
                    ? DismissDirection.endToStart
                    : DismissDirection.none, // Swipe direction only if enabled
                confirmDismiss: (_) async {
                  // Show confirmation dialog before deleting
                  return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: Text(
                                'Are you sure you want to delete "${item.description.isNotEmpty ? item.description : "this item"}"?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context)
                                    .pop(false), // Don't dismiss
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true), // Dismiss
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          );
                        },
                      ) ??
                      false; // Return false if dialog is dismissed
                },
                onDismissed: (direction) {
                  _removeItem(index); // Remove item after confirmation
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
  Future<void> _showEditItemDialog(int index, {bool isAdding = false}) async {
    if (index < 0 || index >= _items.length) return; // Bounds check
    final BillItemEntity currentItem = _items[index];
    // Key to access the state of the dialog content
    final GlobalKey<_ItemDialogContentState> contentKey =
        GlobalKey<_ItemDialogContentState>();

    final result = await showDialog<BillItemEntity?>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismiss
      builder: (context) => AlertDialog(
        // Fix Title: Use isAdding flag
        title: Text(isAdding ? 'Add New Item' : 'Edit Item'),
        content: _ItemDialogContent(
          key: contentKey, // Assign key
          initialItem: currentItem,
        ),
        actions: [
          // Show delete only when editing an existing item
          if (!isAdding)
            TextButton(
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                // Confirm deletion
                final confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: Text(
                              'Are you sure you want to delete "${currentItem.description.isNotEmpty ? currentItem.description : "this item"}"?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    ) ??
                    false;

                if (confirm) {
                  // Pop the edit dialog first, indicating no save
                  Navigator.of(context).pop(null);
                  // Then remove the item (will use postFrameCallback)
                  _removeItem(index);
                }
              },
            ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(), // Return nothing
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              // Access state via key to validate and get value
              final contentState = contentKey.currentState;
              if (contentState != null) {
                final updatedItem = contentState.getUpdatedItem();
                if (updatedItem != null) {
                  Navigator.of(context)
                      .pop(updatedItem); // Return the updated item
                }
                // If updatedItem is null, validation failed, snackbar shown in getUpdatedItem
              }
            },
          ),
        ],
      ),
    );

    // No local controllers to dispose here

    if (result != null) {
      // If the dialog returned an updated item (Save was pressed)
      _updateItem(index, result);
    }
    // If result is null (Cancel pressed or Delete confirmed), do nothing here
    // Deletion is handled within the delete button's logic
  }
}
