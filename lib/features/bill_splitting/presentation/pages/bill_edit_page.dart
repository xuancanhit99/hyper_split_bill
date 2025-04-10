import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert'; // For jsonDecode, utf8, JsonEncoder
import 'package:intl/intl.dart'; // For date formatting
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart'; // Import Bloc, Event, State
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart'; // Import BillEntity
import 'package:go_router/go_router.dart'; // Import go_router for pop and push
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_items_section.dart'; // Import items section
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_participants_section.dart'; // Import participants section
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart'; // Import AuthBloc for user ID
import 'package:hyper_split_bill/core/router/app_router.dart'; // Import AppRoutes for navigation

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
  late TextEditingController _currencyController; // Controller for currency

  // State for parsed data
  bool _isInitializing = true; // Combined parsing/loading state
  String? _parsingError;
  List<BillItemEntity> _items = [];
  List<ParticipantEntity> _participants = [];
  bool _isEditingMode = true; // Start in editing mode
  String?
      _finalBillJsonString; // To store the final JSON after saving internally

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
    _currencyController =
        TextEditingController(); // Initialize currency controller
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
    _currencyController.dispose(); // Dispose currency controller
    _ocrTextController.dispose();
    // Item/Participant controllers are managed within their respective section widgets now
    super.dispose();
  }

  // Helper function to safely parse numeric values from dynamic JSON data
  num? _parseNum(dynamic value, {bool allowNegative = true}) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return allowNegative || value >= 0 ? value : null;
    }
    if (value is String) {
      if (value.trim().isEmpty) {
        return null;
      }
      // Remove common currency symbols, commas, and leading/trailing whitespace
      final sanitizedValue = value
          .replaceAll(RegExp(r'[$,€£¥]'), '') // Add more symbols if needed
          .replaceAll(',', '')
          .trim();
      final parsedValue = num.tryParse(sanitizedValue);
      return parsedValue != null && (allowNegative || parsedValue >= 0)
          ? parsedValue
          : null;
    }
    return null; // Not a num or parsable String
  }

  void _parseStructuredJson(String jsonString) {
    // Reset state before parsing
    _items = [];
    _participants = [];
    _parsingError = null;
    _isInitializing = false; // Mark parsing as done (success or fail)
    _isEditingMode = true; // Ensure starting in edit mode after parsing
    _finalBillJsonString = null; // Clear any previous final JSON

    try {
      print("Attempting to parse JSON in BillEditPage:\n>>>\n$jsonString\n<<<");
      print(
          "Original JSON string received in BillEditPage:\n>>>\n$jsonString\n<<<");
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      print("Parsed data map: $data"); // Log the entire map

      // Check for API-level error first
      if (data.containsKey('error')) {
        print("API returned an error: ${data['error']}");
        throw Exception("Error from structuring API: ${data['error']}");
      }

      // Populate controllers using the safe parsing helper
      final description = data['description'] as String? ?? '';
      print("Parsed description field: '$description'");
      _descriptionController.text = description;

      _totalAmountController.text =
          _parseNum(data['total_amount'])?.toString() ?? '';
      _taxController.text = _parseNum(data['tax_amount'])?.toString() ?? '0.0';
      _tipController.text = _parseNum(data['tip_amount'])?.toString() ?? '0.0';
      _discountController.text =
          _parseNum(data['discount_amount'])?.toString() ?? '0.0';

      // Populate currency code - default to USD if not found or empty
      final currency = data['currency_code'] as String?;
      _currencyController.text = (currency != null && currency.isNotEmpty)
          ? currency.toUpperCase()
          : 'USD'; // Default to USD
      print("Parsed currency code: ${_currencyController.text}");

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

      // Parse items using the safe parsing helper
      if (data['items'] is List) {
        int itemIndex = 0;
        for (var itemMap in (data['items'] as List)) {
          if (itemMap is Map<String, dynamic>) {
            try {
              final itemDescription =
                  itemMap['description'] as String? ?? 'Unknown Item';
              // Quantity should likely be an integer and non-negative
              final itemQuantity =
                  _parseNum(itemMap['quantity'], allowNegative: false)
                          ?.toInt() ??
                      1;
              final itemUnitPrice =
                  _parseNum(itemMap['unit_price'])?.toDouble() ?? 0.0;
              final itemTotalPrice =
                  _parseNum(itemMap['total_price'])?.toDouble() ?? 0.0;

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
    // Only allow picking date if in editing mode
    if (!_isEditingMode) return;

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

  // Renamed original _saveBill to avoid confusion
  void _dispatchSaveEvent(BillEntity billToSave) {
    // Dispatch event to Bloc (which currently mocks the save)
    print("Dispatching SaveBillEvent for user ID: ${billToSave.payerUserId}");
    context.read<BillSplittingBloc>().add(SaveBillEvent(billToSave));
    // Note: The BlocListener will handle showing success/error feedback
    // Pop navigation is removed from here as user stays on page after save.
  }

  // New function to handle internal saving (generating JSON) and locking UI
  void _saveBillInternal() {
    // Basic validation
    final totalAmount = double.tryParse(_totalAmountController.text);
    final billDate = DateTime.tryParse(_dateController.text);
    final taxAmount = double.tryParse(_taxController.text) ??
        0.0; // Keep for potential future use in JSON
    final tipAmount = double.tryParse(_tipController.text) ??
        0.0; // Keep for potential future use in JSON
    final discountAmount = double.tryParse(_discountController.text) ??
        0.0; // Keep for potential future use in JSON
    final currencyCode =
        _currencyController.text.trim().toUpperCase(); // Ensure uppercase

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
    if (currencyCode.isEmpty || currencyCode.length != 3) {
      // Basic validation for currency code
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please enter a valid 3-letter currency code (e.g., USD).')),
      );
      return;
    }

    // Get current user ID
    final authState = context.read<AuthBloc>().state;
    String? currentUserId;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
      print(
          "Attempting to save bill for authenticated user ID: $currentUserId"); // Log the ID
    } else {
      print(
          "Attempting to save bill, but user is not authenticated. Auth state: $authState"); // Log the state if not authenticated
    }
    if (currentUserId == null) {
      print("Internal Save cancelled: currentUserId is null.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated.')),
      );
      return;
    }

    // Create the complete BillEntity with all current data
    final currentBillData = BillEntity(
      id: '', // ID will be assigned by DB or mock later
      totalAmount: totalAmount,
      date: billDate,
      description: _descriptionController.text.trim(),
      payerUserId: currentUserId,
      currencyCode: currencyCode, // Add currency code
      items: _items,
      participants: _participants,
      // TODO: Add tax, tip, discount if they become part of BillEntity
    );

    // Convert the entity to a JSON string for display
    final billMapForJson = {
      'bill_date': DateFormat('yyyy-MM-dd').format(currentBillData.date),
      'description': currentBillData.description,
      'currency_code': currentBillData.currencyCode,
      'total_amount': currentBillData.totalAmount,
      // Include tax, tip, discount in the final JSON even if not in Entity yet
      'tax_amount': taxAmount,
      'tip_amount': tipAmount,
      'discount_amount': discountAmount,
      'payer_user_id': currentBillData.payerUserId,
      'items': currentBillData.items
              ?.map((item) => {
                    'description': item.description,
                    'quantity': item.quantity,
                    'unit_price': item.unitPrice,
                    'total_price': item.totalPrice,
                  })
              .toList() ??
          [],
      'participants': currentBillData.participants
              ?.map((p) => {
                    'name': p.name,
                    // 'user_id': p.userId, // If applicable
                  })
              .toList() ??
          [],
    };
    const jsonEncoder = JsonEncoder.withIndent('  '); // Pretty print
    final generatedJson = jsonEncoder.convert(billMapForJson);

    // Update state to lock UI and show final JSON
    setState(() {
      _finalBillJsonString = generatedJson;
      _isEditingMode = false; // Lock the UI
    });

    print(
        "Internal save complete. Final JSON generated. Dispatching save event...");
    // Dispatch the event to actually save (or mock save) the data
    _dispatchSaveEvent(currentBillData);
  }

  // Function to re-enable editing
  void _toggleEditMode() {
    setState(() {
      _isEditingMode = true;
      _finalBillJsonString = null; // Clear final JSON when editing again
    });
    print("Switched back to editing mode.");
  }

  @override
  Widget build(BuildContext context) {
    // UI lock state is now controlled by _isEditingMode.
    // We still need BlocListener for save success/error feedback.

    return BlocListener<BillSplittingBloc, BillSplittingState>(
      listener: (context, state) {
        // Handle feedback from the actual save attempt (currently mocked)
        if (state is BillSplittingSuccess && !_isEditingMode) {
          // Show success only if we are in the "saved" state internally
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.green),
          );
          // Don't pop here, let user decide when to leave via back button or Bill Bot
          // GoRouter.of(context).pop();
        } else if (state is BillSplittingError) {
          // Show error regardless of edit mode
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
          // If save failed, allow user to edit again
          if (!_isEditingMode) {
            _toggleEditMode();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              _isEditingMode ? 'Edit Bill' : 'Review Bill'), // Dynamic title
          actions: [
            // Show Save or Edit button based on mode
            IconButton(
              icon: Icon(
                  _isEditingMode ? Icons.save_outlined : Icons.edit_outlined),
              tooltip: _isEditingMode ? 'Save Bill Data' : 'Edit Bill Data',
              // Disable save/edit button if Bloc is processing a save triggered by _saveBillInternal
              onPressed: context.watch<BillSplittingBloc>().state
                      is BillSplittingLoading
                  ? null
                  : (_isEditingMode ? _saveBillInternal : _toggleEditMode),
            ),
          ],
        ),
        body: SafeArea(
          // Added SafeArea
          child: ListView(
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
                  enabled: _isEditingMode, // Control based on edit mode
                ),
                const SizedBox(height: 16),
                Row(
                  // Row for amounts and currency
                  children: [
                    Expanded(
                      flex: 2, // Give more space to amount
                      child: TextField(
                        controller: _totalAmountController,
                        decoration:
                            const InputDecoration(labelText: 'Total Amount'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        enabled: _isEditingMode, // Control based on edit mode
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1, // Less space for currency
                      child: TextField(
                        controller: _currencyController,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          counterText: "",
                        ),
                        maxLength: 3,
                        textCapitalization: TextCapitalization.characters,
                        enabled: _isEditingMode, // Control based on edit mode
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2, // More space for date
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Bill Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true, // Date picker handles changes
                        enabled: _isEditingMode, // Control based on edit mode
                        onTap: _isEditingMode
                            ? () => _selectDate(context)
                            : null, // Allow tap only in edit mode
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        enabled: _isEditingMode, // Control based on edit mode
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _tipController,
                        decoration: const InputDecoration(labelText: 'Tip'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        enabled: _isEditingMode, // Control based on edit mode
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _discountController,
                        decoration:
                            const InputDecoration(labelText: 'Discount'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        enabled: _isEditingMode, // Control based on edit mode
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
                      'items_${_items.hashCode}_$_isEditingMode'), // Add mode to key
                  initialItems: _items,
                  enabled: _isEditingMode, // Control based on edit mode
                  onItemsChanged: (updatedItems) {
                    // Only update if in editing mode (although widget should prevent calls)
                    if (_isEditingMode) {
                      _items = updatedItems;
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),

                // --- Participants Section ---
                Text('Participants:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                BillParticipantsSection(
                  key: ValueKey(
                      'participants_${_participants.hashCode}_$_isEditingMode'), // Add mode to key
                  initialParticipants: _participants,
                  enabled: _isEditingMode, // Control based on edit mode
                  onParticipantsChanged: (updatedParticipants) {
                    // Only update if in editing mode
                    if (_isEditingMode) {
                      _participants = updatedParticipants;
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),

                // --- Final Bill JSON Data (Show only when not editing) ---
                if (!_isEditingMode && _finalBillJsonString != null) ...[
                  ExpansionTile(
                    initiallyExpanded: true, // Keep it open initially
                    title: Text(
                      'Final Bill JSON Data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant
                                  .withOpacity(0.3), // Use theme color
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant) // Use theme color
                              ),
                          child: SelectableText(
                            // Allow copying
                            _finalBillJsonString!,
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant // Use theme color for text
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // --- Bill Bot Button (Show only when not editing) ---
                if (!_isEditingMode && _finalBillJsonString != null) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Ask Bill Bot'),
                    onPressed: () {
                      print(
                          "Navigate to Chatbot with JSON:\n$_finalBillJsonString");
                      // Navigate to the chatbot route, passing the final JSON string
                      context.push(AppRoutes.chatbot,
                          extra: _finalBillJsonString);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(), // Add divider after button
                ],

                // --- Raw OCR Text (Optional, always available) ---
                ExpansionTile(
                  title: Text(
                    'Raw OCR/JSON Data (Initial)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: _ocrTextController,
                        maxLines: 10,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Structured JSON data received...',
                        ),
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
