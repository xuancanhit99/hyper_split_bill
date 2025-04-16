import 'package:flutter/material.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_item_widget.dart';
import 'dart:math'; // For random number generation

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

    // Initial confirmation state: Confirm existing non-zero values by default
    isQuantityConfirmed = widget.initialItem.quantity != 0;
    isUnitPriceConfirmed = widget.initialItem.unitPrice != 0.0;
    isTotalPriceConfirmed = widget.initialItem.totalPrice != 0.0;
    // Ensure only two are confirmed initially if possible
    _ensureTwoConfirmed();
    // Initial calculation if needed (e.g., if loaded data only had 2 values)
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

  // Function to calculate fields based on confirmed values
  void calculatePrices() {
    // Use current text values, default to 0 if parsing fails
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final unitPrice = double.tryParse(unitPriceController.text) ?? 0.0;
    final totalPrice = double.tryParse(totalPriceController.text) ?? 0.0;

    int confirmedCount = (isQuantityConfirmed ? 1 : 0) +
        (isUnitPriceConfirmed ? 1 : 0) +
        (isTotalPriceConfirmed ? 1 : 0);

    // Only calculate if exactly two fields are confirmed
    if (confirmedCount == 2) {
      String calculatedValueStr = ""; // To store the calculated value as string

      if (isQuantityConfirmed &&
          isUnitPriceConfirmed &&
          !isTotalPriceConfirmed) {
        if (quantity >= 0 && unitPrice >= 0) {
          calculatedValueStr = (quantity * unitPrice).toStringAsFixed(2);
          // Update only if different to prevent cursor jumps
          if (totalPriceController.text != calculatedValueStr) {
            totalPriceController.text = calculatedValueStr;
          }
        }
      } else if (isQuantityConfirmed &&
          isTotalPriceConfirmed &&
          !isUnitPriceConfirmed) {
        if (quantity > 0 && totalPrice >= 0) {
          // quantity > 0 for division
          calculatedValueStr = (totalPrice / quantity).toStringAsFixed(2);
          if (unitPriceController.text != calculatedValueStr) {
            unitPriceController.text = calculatedValueStr;
          }
        } else if (quantity == 0 && totalPrice == 0) {
          // Handle 0/0 case
          if (unitPriceController.text != "0.00")
            unitPriceController.text = "0.00";
        }
      } else if (isUnitPriceConfirmed &&
          isTotalPriceConfirmed &&
          !isQuantityConfirmed) {
        if (unitPrice > 0 && totalPrice >= 0) {
          // unitPrice > 0 for division
          calculatedValueStr = (totalPrice / unitPrice).round().toString();
          if (quantityController.text != calculatedValueStr) {
            quantityController.text = calculatedValueStr;
          }
        } else if (unitPrice == 0 && totalPrice == 0) {
          // Handle 0/0 case
          if (quantityController.text != "0") quantityController.text = "0";
        }
      }
    }
    // Trigger rebuild to update enabled states of text fields
    if (mounted) setState(() {});
  }

  // Method to be called by the dialog's save button
  BillItemEntity? getValidatedItem() {
    // Use current text values, default to 0 or empty if parsing fails
    final description = descriptionController.text.trim();
    final quantity = int.tryParse(quantityController.text);
    final unitPrice = double.tryParse(unitPriceController.text);
    final totalPrice = double.tryParse(totalPriceController.text);
    int confirmedCount = (isQuantityConfirmed ? 1 : 0) +
        (isUnitPriceConfirmed ? 1 : 0) +
        (isTotalPriceConfirmed ? 1 : 0);

    // --- Start Validation ---
    if (description.isEmpty) {
      _showValidationError('Description cannot be empty.');
      return null;
    }
    if (quantity == null || quantity < 0) {
      _showValidationError('Quantity must be a non-negative number.');
      return null;
    }
    if (unitPrice == null ||
        unitPrice < 0 ||
        totalPrice == null ||
        totalPrice < 0) {
      _showValidationError('Prices cannot be negative.');
      return null;
    }
    if (confirmedCount != 2) {
      _showValidationError(
          'Please confirm exactly two values (Quantity, Unit Price, or Total Price) using the checkboxes.');
      return null;
    }

    // Final consistency check
    final finalCalculatedTotal = (quantity * unitPrice);
    if ((finalCalculatedTotal - totalPrice).abs() > 0.01) {
      // Tolerance
      _showValidationError(
          'Error: Final values are inconsistent (Qty * Unit Price != Total Price). Please re-confirm.');
      return null;
    }
    // --- End Validation ---

    // If all validations pass, return the entity
    return BillItemEntity(
      // Use initial ID if editing, generate if adding (will be handled outside)
      id: widget.initialItem.id,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }

  // Helper to show validation errors
  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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
          const SizedBox(height: 12),
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
                onChanged: quantityEnabled ||
                        isQuantityConfirmed // Allow unchecking if enabled
                    ? (bool? value) {
                        setState(() {
                          isQuantityConfirmed = value ?? false;
                          _ensureTwoConfirmed();
                          calculatePrices();
                        });
                      }
                    : null, // Disable if calculated
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
                onChanged: unitPriceEnabled || isUnitPriceConfirmed
                    ? (bool? value) {
                        setState(() {
                          isUnitPriceConfirmed = value ?? false;
                          _ensureTwoConfirmed();
                          calculatePrices();
                        });
                      }
                    : null, // Disable if calculated
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
                onChanged: totalPriceEnabled || isTotalPriceConfirmed
                    ? (bool? value) {
                        setState(() {
                          isTotalPriceConfirmed = value ?? false;
                          _ensureTwoConfirmed();
                          calculatePrices();
                        });
                      }
                    : null, // Disable if calculated
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
  final bool showItemDetails; // New: Control Qty/Unit Price visibility

  const BillItemsSection({
    super.key,
    required this.initialItems,
    required this.onItemsChanged,
    required this.showItemDetails, // Add to constructor
    this.enabled = true,
  });

  @override
  State<BillItemsSection> createState() => _BillItemsSectionState();
}

class _BillItemsSectionState extends State<BillItemsSection> {
  late List<BillItemEntity> _items;
  final Random _random = Random(); // For generating unique IDs

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems); // Create a mutable copy
    // Ensure all initial items have unique IDs
    _items = _items.map((item) {
      if (item.id == null ||
          item.id!.isEmpty ||
          _items.where((i) => i.id == item.id).length > 1) {
        return item.copyWith(id: _generateUniqueId());
      }
      return item;
    }).toList();
  }

  String _generateUniqueId() {
    return 'item_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
  }

  // Update item details after editing in the dialog
  void _updateItem(BillItemEntity originalItem, BillItemEntity updatedItem) {
    final index = _items.indexWhere((item) => item.id == originalItem.id);
    if (index == -1) return; // Item not found (should not happen)

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Ensure ID remains the same
          _items[index] = updatedItem.copyWith(id: originalItem.id);
        });
        widget.onItemsChanged(_items);
      }
    });
  }

  // Add a new item after getting data from the dialog
  void _addItem(BillItemEntity newItem) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Ensure the new item has a unique ID before adding
          _items.add(newItem.copyWith(id: _generateUniqueId()));
        });
        widget.onItemsChanged(_items);
      }
    });
  }

  void _removeItemById(String itemId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final originalLength = _items.length;
        setState(() {
          _items.removeWhere((item) => item.id == itemId);
        });
        // Only show snackbar and notify if an item was actually removed
        if (_items.length < originalLength) {
          widget.onItemsChanged(_items);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted')),
          );
        }
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
              // Use item.id as the key for Dismissible
              final dismissibleKey = ValueKey(item.id ?? _generateUniqueId());
              return Dismissible(
                key: dismissibleKey,
                direction: widget.enabled
                    ? DismissDirection.endToStart
                    : DismissDirection.none,
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: Text(
                                'Are you sure you want to delete "${item.description.isNotEmpty ? item.description : "this item"}"?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          );
                        },
                      ) ??
                      false;
                },
                onDismissed: (direction) {
                  // Use ID to remove, safer if list order changes unexpectedly
                  _removeItemById(item.id!);
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: BillItemWidget(
                  item: item,
                  // Pass the item to edit to the dialog function
                  onEdit: widget.enabled
                      ? () => _showItemDialog(itemToEdit: item)
                      : () {},
                  showItemDetails: widget.showItemDetails, // Pass down
                ),
              );
            },
            separatorBuilder: (context, index) =>
                const Divider(height: 1, thickness: 1),
          ),
        const SizedBox(height: 8),
        if (widget.enabled)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Item'),
              // Call _showItemDialog without itemToEdit for adding
              onPressed: () => _showItemDialog(),
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
          // Conditionally show Qty header
          if (widget.showItemDetails) ...[
            const Expanded(
              flex: 1,
              child: Text('Qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
          // Conditionally show Unit Price header
          if (widget.showItemDetails) ...[
            const Expanded(
              flex: 2,
              child: Text('Unit Price',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
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

  // --- Unified Add/Edit Item Dialog ---
  Future<void> _showItemDialog({BillItemEntity? itemToEdit}) async {
    final bool isAdding = itemToEdit == null;
    // Provide default values if adding
    final BillItemEntity initialItemData = itemToEdit ??
        BillItemEntity(
            id: '',
            description: '',
            quantity: 1,
            unitPrice: 0.0,
            totalPrice: 0.0);

    // Key to access the state of the dialog content
    final GlobalKey<_ItemDialogContentState> contentKey =
        GlobalKey<_ItemDialogContentState>();

    final result = await showDialog<BillItemEntity?>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismiss
      builder: (context) => AlertDialog(
        title: Text(isAdding ? 'Add New Item' : 'Edit Item'),
        content: _ItemDialogContent(
          key: contentKey,
          initialItem: initialItemData,
        ),
        actions: [
          // Only show delete button when editing
          if (!isAdding)
            TextButton(
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: Text(
                              'Are you sure you want to delete "${itemToEdit.description.isNotEmpty ? itemToEdit.description : "this item"}"?'),
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
                  Navigator.of(context)
                      .pop(null); // Pop dialog, indicate no save
                  _removeItemById(itemToEdit.id!); // Remove item by ID
                }
              },
            ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(), // Return null
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              final contentState = contentKey.currentState;
              if (contentState != null) {
                final validatedItem = contentState.getValidatedItem();
                if (validatedItem != null) {
                  // Pop dialog returning the validated item
                  Navigator.of(context).pop(validatedItem);
                }
                // If null, validation failed, snackbar shown in content widget
              }
            },
          ),
        ],
      ),
    );

    // --- Handle Dialog Result ---
    if (result != null) {
      if (isAdding) {
        _addItem(result); // Add the new item returned from the dialog
      } else {
        _updateItem(itemToEdit!, result); // Update the existing item
      }
    }
    // If result is null (Cancel or Delete), do nothing further here.
  }
}
