import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Keep for potential future Bloc integration here
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/structure_bill_data_usecase.dart';
import 'package:hyper_split_bill/injection_container.dart'; // For sl
import 'dart:convert'; // For jsonDecode
import 'package:intl/intl.dart'; // For date formatting
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart'; // Import Bloc, Event, State
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart'; // Import BillEntity
import 'package:go_router/go_router.dart'; // Import go_router for pop
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_item_widget.dart'; // Import the item widget
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart'; // Import AuthBloc for user ID

class BillEditPage extends StatefulWidget {
  final String ocrResult; // Receive the raw OCR text

  const BillEditPage({super.key, required this.ocrResult});

  @override
  State<BillEditPage> createState() => _BillEditPageState();
}

class _BillEditPageState extends State<BillEditPage> {
  final StructureBillDataUseCase _structureUseCase =
      sl<StructureBillDataUseCase>();

  late TextEditingController _ocrTextController;
  late TextEditingController _descriptionController;
  late TextEditingController _totalAmountController;
  late TextEditingController _dateController;
  // TODO: Add state for items list List<Item> _items = [];

  bool _isParsing = true; // Loading indicator for parsing
  String? _parsingError;
  Map<String, dynamic>? _structuredData; // To hold raw parsed data
  List<BillItemEntity> _items = []; // To hold parsed items
  List<ParticipantEntity> _participants = []; // To hold participants
  // Controllers for item text fields
  final Map<String?, TextEditingController> _itemDescriptionControllers = {};
  final Map<String?, TextEditingController> _itemPriceControllers = {};
  final Map<String?, TextEditingController> _itemQuantityControllers = {};

  @override
  void initState() {
    super.initState();
    _ocrTextController = TextEditingController(text: widget.ocrResult);
    _descriptionController = TextEditingController();
    _totalAmountController = TextEditingController();
    _dateController = TextEditingController();
    // TODO: Implement initial parsing of ocrResult into structured data fields
    _parseOcrResult(); // Call parsing function
  }

  @override
  void dispose() {
    _ocrTextController.dispose();
    _descriptionController.dispose();
    _totalAmountController.dispose();
    _dateController.dispose();
    // Dispose item controllers
    _itemDescriptionControllers
        .forEach((_, controller) => controller.dispose());
    _itemPriceControllers.forEach((_, controller) => controller.dispose());
    _itemQuantityControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _parseOcrResult() async {
    setState(() {
      _isParsing = true;
      _parsingError = null;
    });

    final result = await _structureUseCase(ocrText: widget.ocrResult);

    if (!mounted) return; // Check if widget is still mounted

    result.fold(
      (failure) {
        setState(() {
          _isParsing = false;
          _parsingError = failure.message;
        });
      },
      (jsonString) {
        try {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          _structuredData = data; // Store parsed data

          // Populate controllers
          _descriptionController.text = data['description'] as String? ?? '';
          _totalAmountController.text =
              (data['total_amount'] as num?)?.toString() ?? '';
          // Format date if available
          final dateString = data['bill_date'] as String?;
          if (dateString != null) {
            try {
              final parsedDate = DateTime.parse(dateString);
              _dateController.text = DateFormat('yyyy-MM-dd')
                  .format(parsedDate); // Use intl package
            } catch (e) {
              _dateController.text =
                  dateString; // Keep original string if parsing fails
            }
          } else {
            _dateController.text = '';
          }

          // Parse items and initialize controllers
          _items = [];
          _itemDescriptionControllers.clear();
          _itemPriceControllers.clear();
          _itemQuantityControllers.clear();
          if (data['items'] is List) {
            int itemIndex = 0; // Use index as temporary key if ID is missing
            for (var itemMap in (data['items'] as List)) {
              if (itemMap is Map<String, dynamic>) {
                try {
                  final item = BillItemEntity(
                    id: 'temp_${itemIndex++}', // Assign temporary ID for controller mapping
                    description:
                        itemMap['description'] as String? ?? 'Unknown Item',
                    quantity: (itemMap['quantity'] as num?)?.toInt() ?? 1,
                    unitPrice:
                        (itemMap['unit_price'] as num?)?.toDouble() ?? 0.0,
                    totalPrice:
                        (itemMap['total_price'] as num?)?.toDouble() ?? 0.0,
                  );
                  _items.add(item);
                  // Initialize controllers for this item
                  _itemDescriptionControllers[item.id] =
                      TextEditingController(text: item.description);
                  _itemPriceControllers[item.id] = TextEditingController(
                      text: item.totalPrice.toStringAsFixed(2));
                  _itemQuantityControllers[item.id] =
                      TextEditingController(text: item.quantity.toString());
                } catch (e) {
                  print("Error parsing item: $itemMap. Error: $e");
                }
              }
            }
          }

          // Initialize participants - Start with the current user
          // TODO: Get current user name properly (e.g., from AuthBloc or Profile)
          _participants = [const ParticipantEntity(name: 'Me')];

          setState(() {
            _isParsing = false;
            _parsingError = null;
          });
        } catch (e) {
          // Handle JSON parsing errors
          setState(() {
            _isParsing = false;
            _parsingError = 'Failed to parse structured data: $e';
          });
        }
      },
    );
  }

  void _saveBill() {
    // Basic validation (can be improved)
    final totalAmount = double.tryParse(_totalAmountController.text);
    final billDate =
        DateTime.tryParse(_dateController.text); // Assumes YYYY-MM-DD format

    if (totalAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid total amount.')),
      );
      return;
    }
    if (billDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid date (YYYY-MM-DD).')),
      );
      return;
    }

    // Get current user ID from AuthBloc
    final authState = context.read<AuthBloc>().state;
    String? currentUserId;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: User not authenticated. Cannot save bill.')),
      );
      return; // Cannot save without user ID
    }

    // Create BillEntity from the current state
    // Assuming this is a new bill, ID will be generated by DB/backend
    // If updating an existing bill, you'd need to pass the existing bill ID.
    final billToSave = BillEntity(
      id: '', // ID will be generated by backend/DB
      totalAmount: totalAmount,
      date: billDate,
      description: _descriptionController.text.trim(),
      payerUserId: currentUserId, // Use actual user ID
      // Update items from controllers before creating entity
      // Note: This assumes IDs are still temporary or handled correctly
      items: _items.map((item) {
        final description =
            _itemDescriptionControllers[item.id]?.text ?? item.description;
        final quantity =
            int.tryParse(_itemQuantityControllers[item.id]?.text ?? '') ??
                item.quantity;
        final totalPrice =
            double.tryParse(_itemPriceControllers[item.id]?.text ?? '') ??
                item.totalPrice;
        // TODO: Recalculate unitPrice if needed based on quantity and totalPrice
        return item.copyWith(
          description: description,
          quantity: quantity,
          totalPrice: totalPrice,
          // unitPrice: ...
        );
      }).toList(),
      participants: _participants, // Pass participants list
      // ocrExtractedText: _ocrTextController.text, // Pass raw text if needed
    );

    // Dispatch the event to the Bloc
    context.read<BillSplittingBloc>().add(SaveBillEvent(billToSave));

    // TODO: Add BlocListener to handle saving state (loading, success, error)
    // Maybe show a loading indicator and navigate back on success.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attempting to save bill...')), // Feedback
    );
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(BuildContext context) async {
    // Try to parse the current date in the controller, otherwise use today
    DateTime initialDate =
        DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000), // Allow dates from year 2000
      lastDate: DateTime(2101), // Allow dates up to year 2101
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // --- Date Picker Logic --- (Removed duplicate)
  @override
  Widget build(BuildContext context) {
    // Watch the state for building UI elements based on it
    final state = context.watch<BillSplittingBloc>().state;
    // Wrap the Scaffold with BlocListener to handle saving states
    return BlocListener<BillSplittingBloc, BillSplittingState>(
      // ListenWhen can be used to only listen for relevant saving states
      // listenWhen: (previous, current) =>
      //     current is BillSplittingLoading ||
      //     current is BillSplittingSuccess ||
      //     current is BillSplittingError,
      listener: (context, state) {
        // Handle Saving States
        if (state is BillSplittingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.green),
          );
          // Navigate back after successful save
          // TODO: Decide where to navigate (e.g., home, bill list)
          GoRouter.of(context).pop(); // Use GoRouter to pop
        } else if (state is BillSplittingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
        // Note: BillSplittingLoading state is handled by the _isLoading flag for UI elements
      },
      child: Scaffold(
        // Existing Scaffold becomes the child
        appBar: AppBar(
          title: const Text('Review & Edit Bill'),
          actions: [
            // Show loading indicator during save OR parsing
            if (state is BillSplittingLoading ||
                _isParsing) // Now 'state' is available from context.watch
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))),
              )
            else // Show save button only when not loading/parsing
              IconButton(
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Save Bill',
                onPressed: _saveBill,
              ),
          ],
        ),
        body: ListView(
          // Use ListView for potentially long content
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Loading/Error Indicator for Parsing ---
            if (_isParsing)
              const Center(child: CircularProgressIndicator())
            else if (_parsingError != null)
              Center(
                  child: Text('Error parsing OCR data: $_parsingError',
                      style: TextStyle(color: Colors.red)))
            else ...[
              // --- Structured Data Fields ---
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description / Store Name'),
                // Disable fields while saving
                enabled: !(state
                    is BillSplittingLoading), // Now 'state' is available
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _totalAmountController,
                decoration: const InputDecoration(labelText: 'Total Amount'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: !(state
                    is BillSplittingLoading), // Now 'state' is available
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Bill Date (YYYY-MM-DD)',
                  suffixIcon: Icon(Icons.calendar_today), // Add calendar icon
                ),
                readOnly: true, // Make field read-only
                enabled: !(state
                    is BillSplittingLoading), // Use state from build method
                onTap: () => _selectDate(context), // Show date picker on tap
              ),
              const SizedBox(height: 24),
              const Divider(),

              // --- Display/Edit Items ---
              Text('Items:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildItemsList(), // Use a helper method to build the list
              const SizedBox(height: 24),
              const Divider(),

              // --- Display/Edit Participants ---
              Text('Participants:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildParticipantsList(), // Use a helper method
              const SizedBox(height: 24),
              const Divider(),

              // --- Raw OCR Text (Optional to keep visible) ---
              ExpansionTile(
                // Collapsible section for raw text
                title: Text(
                  'Raw Extracted Text (Editable)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                // Disable expansion tile while saving
                // Disabling ExpansionTile itself might not be the best UX,
                // consider disabling interaction within its children instead if needed.
                // enabled: !(state is BillSplittingLoading),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: _ocrTextController,
                      maxLines: 10, // Allow multiple lines
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Raw text extracted from the bill...',
                      ),
                      enabled: !(state
                          is BillSplittingLoading), // Now 'state' is available
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            // --- Save Button (alternative placement) ---
            // ElevatedButton.icon(
            //   icon: const Icon(Icons.save_outlined),
            //   label: const Text('Save Bill'),
            //   onPressed: _saveBill,
            // ),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Edit Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Bill',
            onPressed: _saveBill,
          ),
        ],
      ),
      body: ListView(
        // Use ListView for potentially long content
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Loading/Error Indicator ---
          if (_isParsing)
            const Center(child: CircularProgressIndicator())
          else if (_parsingError != null)
            Center(
                child: Text('Error parsing OCR data: $_parsingError',
                    style: TextStyle(color: Colors.red)))
          else ...[
            // --- Structured Data Fields ---
            TextField(
              controller: _descriptionController,
              decoration:
                  const InputDecoration(labelText: 'Description / Store Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _totalAmountController,
              decoration: const InputDecoration(labelText: 'Total Amount'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              decoration:
                  const InputDecoration(labelText: 'Bill Date (YYYY-MM-DD)'),
              keyboardType: TextInputType.datetime,
              // TODO: Add Date Picker functionality
            ),
            const SizedBox(height: 24),
            const Divider(),

            // --- Display/Edit Items ---
            Text('Items:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildItemsList(), // Use a helper method to build the list
            const SizedBox(height: 24),
            const Divider(),

            // --- Display/Edit Participants ---
            Text('Participants:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildParticipantsList(), // Use a helper method
            const SizedBox(height: 24),
            const Divider(),

            // --- Raw OCR Text (Optional to keep visible) ---
            ExpansionTile(
              // Collapsible section for raw text
              title: Text(
                'Raw Extracted Text (Editable)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: _ocrTextController,
                    maxLines: 10, // Allow multiple lines
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Raw text extracted from the bill...',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          // --- Save Button (alternative placement) ---
          // ElevatedButton.icon(
          //   icon: const Icon(Icons.save_outlined),
          //   label: const Text('Save Bill'),
          //   onPressed: _saveBill,
          // ),
        ],
      ),
    );
  }

  // --- Helper Widgets for Items and Participants ---

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return const Text('No items parsed or added yet.');
    }
    // Using ListView.builder for potentially long lists
    return ListView.builder(
      shrinkWrap: true, // Important inside another scroll view (ListView)
      physics:
          const NeverScrollableScrollPhysics(), // Disable scrolling for this inner list
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        // TODO: Create a dedicated BillItemWidget for better editing UI
        return ListTile(
          title: Text(item.description),
          subtitle: Text(
              'Qty: ${item.quantity}, Price: ${item.totalPrice.toStringAsFixed(2)}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
            },
          ),
          // TODO: Add onTap to edit item details
        );
      },
    );
    // TODO: Add "Add Item" button
  }

  Widget _buildParticipantsList() {
    if (_participants.isEmpty) {
      return const Text('No participants added yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          // Use Wrap for chips that can flow to the next line
          spacing: 8.0,
          runSpacing: 4.0,
          children: _participants.map((participant) {
            return Chip(
              label: Text(participant.name),
              onDeleted: (_participants.length >
                      1) // Prevent deleting the last one (usually 'Me')
                  ? () {
                      setState(() {
                        _participants.remove(participant);
                      });
                    }
                  : null, // Disable delete for the last participant
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Participant'),
          onPressed: () {
            // TODO: Implement logic to show a dialog or navigate to add participant
            _addParticipantDialog();
          },
        ),
      ],
    );
  }

  // --- Dialog for Adding Participant ---
  Future<void> _addParticipantDialog() async {
    final nameController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Participant'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'Enter participant name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    // Avoid adding duplicate names (case-insensitive check)
                    if (!_participants.any(
                        (p) => p.name.toLowerCase() == name.toLowerCase())) {
                      _participants.add(ParticipantEntity(name: name));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Participant "$name" already exists.')),
                      );
                    }
                  });
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
