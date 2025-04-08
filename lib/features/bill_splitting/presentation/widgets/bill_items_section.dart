import 'package:flutter/material.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
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
  // Controllers managed within this widget's state
  final Map<String?, TextEditingController> _descriptionControllers = {};
  final Map<String?, TextEditingController> _priceControllers = {};
  final Map<String?, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems); // Create a mutable copy
    _initializeControllers();
  }

  // Initialize controllers for existing items
  void _initializeControllers() {
    _clearControllers(); // Clear previous controllers first
    for (var item in _items) {
      // Ensure each item has a unique temporary ID if it's null
      final itemId = item.id ??
          'temp_${DateTime.now().millisecondsSinceEpoch}_${_items.indexOf(item)}';
      final itemWithId = item.id == null ? item.copyWith(id: itemId) : item;
      if (item.id == null)
        _items[_items.indexOf(item)] =
            itemWithId; // Update item in list if ID was added

      _descriptionControllers[itemWithId.id] =
          TextEditingController(text: itemWithId.description);
      _priceControllers[itemWithId.id] =
          TextEditingController(text: itemWithId.totalPrice.toStringAsFixed(2));
      _quantityControllers[itemWithId.id] =
          TextEditingController(text: itemWithId.quantity.toString());
    }
  }

  // Clear and dispose existing controllers
  void _clearControllers() {
    _descriptionControllers.forEach((_, controller) => controller.dispose());
    _priceControllers.forEach((_, controller) => controller.dispose());
    _quantityControllers.forEach((_, controller) => controller.dispose());
    _descriptionControllers.clear();
    _priceControllers.clear();
    _quantityControllers.clear();
  }

  @override
  void dispose() {
    _clearControllers(); // Dispose all controllers
    super.dispose();
  }

  // Update item details based on TextField changes
  void _updateItem(int index,
      {String? description, int? quantity, double? totalPrice}) {
    if (index < 0 || index >= _items.length) return;
    final currentItem = _items[index];
    // Update the item in the local list
    _items[index] = currentItem.copyWith(
      description: description,
      quantity: quantity,
      totalPrice: totalPrice,
      // TODO: Decide how to handle unitPrice update if needed
    );
    // Notify the parent widget about the change
    widget.onItemsChanged(_items);
  }

  void _addItem() {
    setState(() {
      final newItem = BillItemEntity(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary unique ID
        description: '',
        quantity: 1,
        unitPrice: 0.0,
        totalPrice: 0.0,
      );
      _items.add(newItem);
      // Initialize controllers for the new item
      _descriptionControllers[newItem.id] = TextEditingController();
      _priceControllers[newItem.id] = TextEditingController(text: '0.00');
      _quantityControllers[newItem.id] = TextEditingController(text: '1');
    });
    widget.onItemsChanged(_items); // Notify parent
  }

  void _removeItem(int index) {
    final itemToRemove = _items[index];
    setState(() {
      _items.removeAt(index);
      // Dispose and remove controllers
      _descriptionControllers.remove(itemToRemove.id)?.dispose();
      _priceControllers.remove(itemToRemove.id)?.dispose();
      _quantityControllers.remove(itemToRemove.id)?.dispose();
    });
    widget.onItemsChanged(_items); // Notify parent
  }

  @override
  Widget build(BuildContext context) {
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
  }
}
