import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert'; // For jsonDecode, utf8
import 'package:intl/intl.dart'; // For date formatting
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart'; // Import Bloc, Event, State
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart'; // Import BillEntity
import 'package:go_router/go_router.dart'; // Import go_router for pop
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_items_section.dart'; // Import items section
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_participants_section.dart'; // Import participants section
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart'; // Import AuthBloc for user ID

class BillEditPage extends StatefulWidget {
  final String structuredJsonString; // Receive the structured JSON string

  const BillEditPage({super.key, required this.structuredJsonString});

  @override
  State<BillEditPage> createState() => _BillEditPageState();
}

class _BillEditPageState extends State<BillEditPage> {
  // Controllers for main bill fields
  late TextEditingController _descriptionController;
  late TextEditingController _totalAmountController;
  late TextEditingController _dateController;
  late TextEditingController _taxController;
  late TextEditingController _tipController;
  late TextEditingController _discountController;
  late TextEditingController _ocrTextController; // To display raw JSON/OCR

  // State for parsed data
  bool _isInitializing = true; // Combined parsing/loading state
  String? _parsingError;
  List<BillItemEntity> _items = [];
  List<ParticipantEntity> _participants = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _descriptionController = TextEditingController();
    _totalAmountController = TextEditingController();
    _dateController = TextEditingController();
    _taxController = TextEditingController();
    _tipController = TextEditingController();
    _discountController = TextEditingController();
    _ocrTextController = TextEditingController(
        text: widget.structuredJsonString); // Show the received JSON

    // Parse the received JSON string directly
    _parseStructuredJson(widget.structuredJsonString);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _totalAmountController.dispose();
    _dateController.dispose();
    _taxController.dispose();
    _tipController.dispose();
    _discountController.dispose();
    _ocrTextController.dispose();
    // Item/Participant controllers are managed within their respective section widgets now
    super.dispose();
  }

  void _parseStructuredJson(String jsonString) {
    // Reset state before parsing
    _items = [];
    _participants = [];
    _parsingError = null;
    _isInitializing = false; // Mark parsing as done (success or fail)

    try {
      print("Attempting to parse JSON in BillEditPage:\n>>>\n$jsonString\n<<<");
      print(
          "Original JSON string received in BillEditPage:\n>>>\n$jsonString\n<<<");
      // Revert: jsonDecode handles Dart's internal string encoding (UTF-16) correctly.
      // Explicit utf8.decode on codeUnits (UTF-16) was incorrect and caused the error.
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      print("Parsed data map: $data"); // Log the entire map

      // Check for API-level error first
      if (data.containsKey('error')) {
        print("API returned an error: ${data['error']}");
        throw Exception("Error from structuring API: ${data['error']}");
      }

      // Populate controllers
      final description = data['description'] as String? ?? '';
      print("Parsed description field: '$description'");
      _descriptionController.text = description;
      _totalAmountController.text =
          (data['total_amount'] as num?)?.toString() ?? '';
      _taxController.text = (data['tax_amount'] as num?)?.toString() ?? '0.0';
      _tipController.text = (data['tip_amount'] as num?)?.toString() ?? '0.0';
      _discountController.text =
          (data['discount_amount'] as num?)?.toString() ?? '0.0';

      // Format date if available
      final dateString = data['bill_date'] as String?;
      if (dateString != null) {
        try {
          final parsedDate = DateTime.parse(dateString);
          _dateController.text = DateFormat('yyyy-MM-dd').format(parsedDate);
        } catch (e) {
          _dateController.text = dateString;
          print(
              "Warning: Could not parse date string '$dateString'. Keeping original.");
        }
      } else {
        _dateController.text = '';
      }

      // Parse items
      if (data['items'] is List) {
        int itemIndex = 0;
        for (var itemMap in (data['items'] as List)) {
          if (itemMap is Map<String, dynamic>) {
            try {
              final itemDescription =
                  itemMap['description'] as String? ?? 'Unknown Item';
              final itemQuantity = (itemMap['quantity'] as num?)?.toInt() ?? 1;
              final itemUnitPrice =
                  (itemMap['unit_price'] as num?)?.toDouble() ?? 0.0;
              final itemTotalPrice =
                  (itemMap['total_price'] as num?)?.toDouble() ?? 0.0;

              print(
                  "Parsing item ${itemIndex + 1}: description='$itemDescription', quantity=$itemQuantity, unitPrice=$itemUnitPrice, totalPrice=$itemTotalPrice");

              _items.add(BillItemEntity(
                id: 'temp_${itemIndex++}', // Temporary ID for UI list
                description: itemDescription,
                quantity: itemQuantity,
                unitPrice: itemUnitPrice,
                totalPrice: itemTotalPrice,
              ));
            } catch (e, s) {
              // Add stack trace
              print(
                  "Error parsing item map: $itemMap. Error: $e\nStackTrace: $s");
              // Optionally add a placeholder or skip the item
            }
          }
        }
      }

      // Initialize participants - Start with the current user
      // Use context.read only if initState is guaranteed to run after BlocProvider is available
      // It's safer to access Bloc in build or callbacks if unsure.
      // For initState, consider passing user info differently or delaying participant init.
      // For simplicity now, we assume AuthBloc is available higher up.
      final authState = context.read<AuthBloc>().state;
      String currentUserName = 'Me';
      if (authState is AuthAuthenticated) {
        currentUserName = authState.user.email?.split('@').first ?? 'Me';
      }
      _participants = [ParticipantEntity(name: currentUserName)]; // ID is null

      // Update UI after successful parsing
      setState(() {});
    } catch (e, s) {
      print("Error parsing structured JSON: $e\nStackTrace: $s");
      setState(() {
        _parsingError = 'Failed to parse structured data: $e';
      });
    }
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate =
        DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveBill() {
    // Basic validation
    final totalAmount = double.tryParse(_totalAmountController.text);
    final billDate = DateTime.tryParse(_dateController.text);
    final taxAmount = double.tryParse(_taxController.text) ?? 0.0;
    final tipAmount = double.tryParse(_tipController.text) ?? 0.0;
    final discountAmount = double.tryParse(_discountController.text) ?? 0.0;

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

    // Get current user ID
    final authState = context.read<AuthBloc>().state;
    String? currentUserId;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated.')),
      );
      return;
    }

    // Create BillEntity
    final billToSave = BillEntity(
      id: '', // Will be generated by DB
      totalAmount: totalAmount,
      date: billDate,
      description: _descriptionController.text.trim(),
      payerUserId: currentUserId,
      items: _items, // Get updated items from state
      participants: _participants, // Get updated participants from state
      // TODO: Add tax, tip, discount to BillEntity if needed in DB schema
      // taxAmount: taxAmount,
      // tipAmount: tipAmount,
      // discountAmount: discountAmount,
      // ocrExtractedText: widget.structuredJsonString,
    );

    // Dispatch event
    context.read<BillSplittingBloc>().add(SaveBillEvent(billToSave));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BillSplittingBloc>().state;
    final bool isSaving = state is BillSplittingLoading;

    return BlocListener<BillSplittingBloc, BillSplittingState>(
      listener: (context, state) {
        if (state is BillSplittingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.green),
          );
          GoRouter.of(context).pop(); // Go back on success
        } else if (state is BillSplittingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review & Edit Bill'),
          actions: [
            if (isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))),
              )
            else
              IconButton(
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Save Bill',
                onPressed: _saveBill,
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (_isInitializing) // Show loading only during initial parse
              const Center(child: CircularProgressIndicator())
            else if (_parsingError != null)
              Padding(
                // Add padding for error message
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                    child: Text('Error parsing OCR data: $_parsingError',
                        style: TextStyle(color: Colors.red))),
              )
            else ...[
              // --- Structured Data Fields ---
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description / Store Name'),
                enabled: !isSaving,
              ),
              const SizedBox(height: 16),
              Row(
                // Row for amounts
                children: [
                  Expanded(
                    child: TextField(
                      controller: _totalAmountController,
                      decoration:
                          const InputDecoration(labelText: 'Total Amount'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: !isSaving,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Bill Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      enabled: !isSaving,
                      onTap: () => _selectDate(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Optional fields for Tax, Tip, Discount
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taxController,
                      decoration: const InputDecoration(labelText: 'Tax'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: !isSaving,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _tipController,
                      decoration: const InputDecoration(labelText: 'Tip'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: !isSaving,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _discountController,
                      decoration: const InputDecoration(labelText: 'Discount'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: !isSaving,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),

              // --- Items Section ---
              Text('Items:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              BillItemsSection(
                key: ValueKey(
                    'items_${_items.hashCode}'), // Use hashCode for key
                initialItems: _items,
                enabled: !isSaving,
                onItemsChanged: (updatedItems) {
                  _items = updatedItems;
                },
              ),
              const SizedBox(height: 24),
              const Divider(),

              // --- Participants Section ---
              Text('Participants:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              BillParticipantsSection(
                // Use the dedicated widget
                key: ValueKey(
                    'participants_${_participants.hashCode}'), // Use hashCode for key
                initialParticipants: _participants,
                enabled: !isSaving,
                onParticipantsChanged: (updatedParticipants) {
                  _participants = updatedParticipants;
                },
              ),
              const SizedBox(height: 24),
              const Divider(),

              // --- Raw OCR Text (Optional) ---
              ExpansionTile(
                title: Text(
                  'Raw OCR/JSON Data',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller:
                          _ocrTextController, // Shows the JSON string now
                      maxLines: 10,
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Structured JSON data received...',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
