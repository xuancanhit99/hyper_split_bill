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
import 'package:hyper_split_bill/core/constants/currencies.dart'; // Import the new currency constants file

class BillEditPage extends StatefulWidget {
  final String structuredJsonString; // Receive the structured JSON string

  const BillEditPage({super.key, required this.structuredJsonString});

  @override
  State<BillEditPage> createState() => _BillEditPageState();
}

class _BillEditPageState extends State<BillEditPage> {
  // Dynamic list to hold currencies for the dropdown, initialized in initState
  late List<String> _dropdownCurrencies;
  // Controllers for main bill fields
  late TextEditingController _descriptionController;
  late TextEditingController _totalAmountController;
  late TextEditingController _dateController;
  late TextEditingController _taxController;
  late TextEditingController _tipController;
  late TextEditingController _discountController;
  late TextEditingController _ocrTextController; // To display raw JSON/OCR
  late TextEditingController _currencyController; // Holds the selected value

  // State for parsed data
  bool _isInitializing = true; // Combined parsing/loading state
  String? _parsingError;
  List<BillItemEntity> _items = [];
  List<ParticipantEntity> _participants = [];
  bool _isEditingMode = true; // Start in editing mode
  String? _finalBillJsonString; // Stores the final JSON after saving internally

  // State for optional field visibility
  bool _showTax = false;
  bool _showTip = false;
  bool _showDiscount = false;
  bool _showCurrency = false; // Currency starts hidden as per requirement

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

    // Initialize the dynamic currency list using the imported constant list
    _dropdownCurrencies =
        List.from(cCommonCurrencies); // Start with common currencies

    // Parse the received JSON string directly, which might update _dropdownCurrencies
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
    _currencyController.dispose();
    _ocrTextController.dispose();
    super.dispose();
  }

  // Helper function to safely parse numeric values from dynamic JSON data
  num? _parseNum(dynamic value, {bool allowNegative = true}) {
    if (value == null) return null;
    if (value is num) return allowNegative || value >= 0 ? value : null;
    if (value is String) {
      if (value.trim().isEmpty) return null;
      final sanitizedValue =
          value.replaceAll(RegExp(r'[$,€£¥]'), '').replaceAll(',', '').trim();
      final parsedValue = num.tryParse(sanitizedValue);
      return parsedValue != null && (allowNegative || parsedValue >= 0)
          ? parsedValue
          : null;
    }
    return null;
  }

  void _parseStructuredJson(String jsonString) {
    _items = [];
    _participants = [];
    _parsingError = null;
    _isInitializing = false;
    _isEditingMode = true;
    _finalBillJsonString = null;

    try {
      print("Attempting to parse JSON in BillEditPage:\n>>>\n$jsonString\n<<<");
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      print("Parsed data map: $data");

      if (data.containsKey('error')) {
        throw Exception("Error from structuring API: ${data['error']}");
      }

      _descriptionController.text = data['description'] as String? ?? '';
      _totalAmountController.text =
          _parseNum(data['total_amount'])?.toString() ?? '';

      // Parse optional fields and set initial visibility
      final taxAmount = _parseNum(data['tax_amount']);
      _taxController.text = taxAmount?.toString() ?? '0.0';
      _showTax = taxAmount != null && taxAmount != 0;

      final tipAmount = _parseNum(data['tip_amount']);
      _tipController.text = tipAmount?.toString() ?? '0.0';
      _showTip = tipAmount != null && tipAmount != 0;

      final discountAmount = _parseNum(data['discount_amount']);
      _discountController.text = discountAmount?.toString() ?? '0.0';
      _showDiscount = discountAmount != null && discountAmount != 0;

      // Currency parsing (visibility starts false, but controller needs value)
      final parsedCurrency = data['currency_code'] as String?;
      String effectiveCurrency = 'USD';
      if (parsedCurrency != null && parsedCurrency.isNotEmpty) {
        final upperCaseCurrency = parsedCurrency.toUpperCase();
        if (upperCaseCurrency.length == 3) {
          effectiveCurrency = upperCaseCurrency;
          if (!_dropdownCurrencies.contains(effectiveCurrency)) {
            // No need for setState here as it's called after parsing completes
            _dropdownCurrencies.add(effectiveCurrency);
            _dropdownCurrencies.sort();
            print(
                "Added parsed currency '$effectiveCurrency' to dropdown list.");
          }
        } else {
          print(
              "Warning: Parsed currency '$parsedCurrency' is invalid. Defaulting to USD.");
        }
      } else {
        print("Warning: No currency code found in JSON. Defaulting to USD.");
      }
      if (!_dropdownCurrencies.contains('USD')) {
        _dropdownCurrencies.insert(0, 'USD');
      }
      _currencyController.text = effectiveCurrency;
      print(
          "Selected currency code after parsing: ${_currencyController.text}");

      final dateString = data['bill_date'] as String?;
      if (dateString != null) {
        try {
          _dateController.text =
              DateFormat('yyyy-MM-dd').format(DateTime.parse(dateString));
        } catch (e) {
          _dateController.text = dateString;
          print(
              "Warning: Could not parse date string '$dateString'. Keeping original.");
        }
      } else {
        _dateController.text = '';
      }

      if (data['items'] is List) {
        int itemIndex = 0;
        for (var itemMap in (data['items'] as List)) {
          if (itemMap is Map<String, dynamic>) {
            try {
              _items.add(BillItemEntity(
                id: 'temp_${itemIndex++}',
                description:
                    itemMap['description'] as String? ?? 'Unknown Item',
                quantity: _parseNum(itemMap['quantity'], allowNegative: false)
                        ?.toInt() ??
                    1,
                unitPrice: _parseNum(itemMap['unit_price'])?.toDouble() ?? 0.0,
                totalPrice:
                    _parseNum(itemMap['total_price'])?.toDouble() ?? 0.0,
              ));
            } catch (e, s) {
              print(
                  "Error parsing item map: $itemMap. Error: $e\nStackTrace: $s");
            }
          }
        }
      }

      final authState = context.read<AuthBloc>().state;
      String currentUserName = 'Me';
      if (authState is AuthAuthenticated) {
        currentUserName = authState.user.email?.split('@').first ?? 'Me';
      }
      _participants = [ParticipantEntity(name: currentUserName)];

      setState(() {}); // Update UI after successful parsing
    } catch (e, s) {
      print("Error parsing structured JSON: $e\nStackTrace: $s");
      setState(() {
        _parsingError = 'Failed to parse structured data: $e';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
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

  void _dispatchSaveEvent(BillEntity billToSave) {
    print("Dispatching SaveBillEvent for user ID: ${billToSave.payerUserId}");
    context.read<BillSplittingBloc>().add(SaveBillEvent(billToSave));
  }

  void _saveBillInternal() {
    final totalAmount = double.tryParse(_totalAmountController.text);
    final billDate = DateTime.tryParse(_dateController.text);
    final taxAmount = double.tryParse(_taxController.text) ?? 0.0;
    final tipAmount = double.tryParse(_tipController.text) ?? 0.0;
    final discountAmount = double.tryParse(_discountController.text) ?? 0.0;
    final currencyCode = _currencyController.text.trim().toUpperCase();

    if (totalAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid total amount.')));
      return;
    }
    if (billDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid date (YYYY-MM-DD).')));
      return;
    }
    if (!_dropdownCurrencies.contains(currencyCode)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Invalid currency selected. Please choose from the list.')));
      return;
    }

    final authState = context.read<AuthBloc>().state;
    String? currentUserId;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not authenticated.')));
      return;
    }

    final currentBillData = BillEntity(
      id: '',
      totalAmount: totalAmount,
      date: billDate,
      description: _descriptionController.text.trim(),
      payerUserId: currentUserId!, // We know it's not null here
      currencyCode: currencyCode,
      items: _items,
      participants: _participants,
    );

    final billMapForJson = {
      'bill_date': DateFormat('yyyy-MM-dd').format(currentBillData.date),
      'description': currentBillData.description,
      'currency_code': currentBillData.currencyCode,
      'total_amount': currentBillData.totalAmount,
      'tax_amount': taxAmount,
      'tip_amount': tipAmount,
      'discount_amount': discountAmount,
      'payer_user_id': currentBillData.payerUserId,
      'items': currentBillData.items?.map((item) => item.toJson()).toList() ??
          [], // Assuming toJson exists
      'participants':
          currentBillData.participants?.map((p) => p.toJson()).toList() ??
              [], // Assuming toJson exists
    };
    const jsonEncoder = JsonEncoder.withIndent('  ');
    final generatedJson = jsonEncoder.convert(billMapForJson);

    // Removed logic to collapse tiles

    setState(() {
      _finalBillJsonString = generatedJson;
      _isEditingMode = false;
    });

    print("Internal save complete. Dispatching save event...");
    _dispatchSaveEvent(currentBillData);
  }

  void _toggleEditMode() {
    // Removed logic to collapse tiles

    setState(() {
      _isEditingMode = true;
      _finalBillJsonString = null;
    });
    print("Switched back to editing mode.");
  }

  // --- Helper Widget for Editable Rows ---
  Widget _buildEditableRow({
    required BuildContext context,
    IconData? icon, // Optional icon
    required String label, // Label is now just for semantics/debugging
    required String value,
    VoidCallback? onTap,
    bool isBold = false,
  }) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isBold ? 18 : 16, // Slightly larger if bold
        );

    return InkWell(
      onTap: onTap, // Enable tap only if onTap is provided
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 12.0, horizontal: 0), // Adjust padding
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12), // Space between icon and text
            ],
            Expanded(
              child: Text(
                value.isEmpty
                    ? 'Tap to edit $label'
                    : value, // Show placeholder if empty
                style: textStyle,
                overflow: TextOverflow.ellipsis, // Prevent long text overflow
              ),
            ),
            if (onTap != null) // Show edit indicator only if editable
              Icon(Icons.edit_note_outlined, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // --- Placeholder Dialog Methods ---
  void _showEditDescriptionDialog() {
    // TODO: Implement dialog to edit description
    print("Tapped to edit description");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Description editing not implemented yet.')),
    );
  }

  void _showEditTotalAmountDialog() {
    // TODO: Implement dialog to edit total amount
    print("Tapped to edit total amount");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Total Amount editing not implemented yet.')),
    );
  }

  void _showEditTaxDialog() {
    // TODO: Implement dialog to edit tax
    print("Tapped to edit tax");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tax editing not implemented yet.')),
    );
  }

  void _showEditTipDialog() {
    // TODO: Implement dialog to edit tip
    print("Tapped to edit tip");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tip editing not implemented yet.')),
    );
  }

  void _showEditDiscountDialog() {
    // TODO: Implement dialog to edit discount
    print("Tapped to edit discount");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Discount editing not implemented yet.')),
    );
  }

  // --- Dialog to Add Optional Fields ---
  void _showAddFieldDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Use StatefulBuilder to manage checkbox state within the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Optional Fields'),
              content: SingleChildScrollView(
                // Use SingleChildScrollView if content might overflow
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CheckboxListTile(
                      title: const Text('Tax'),
                      value: _showTax,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          _showTax = value ?? false;
                        });
                        // Also update the main page state when dialog closes or immediately
                        setState(() {});
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Tip'),
                      value: _showTip,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          _showTip = value ?? false;
                        });
                        setState(() {});
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Discount'),
                      value: _showDiscount,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          _showDiscount = value ?? false;
                        });
                        setState(() {});
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Currency'),
                      value: _showCurrency,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          _showCurrency = value ?? false;
                        });
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Done'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Trigger a final setState on the main page if needed,
                    // though individual onChanged might be sufficient.
                    setState(() {});
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Helper for Currency Dropdown Row ---
  Widget _buildCurrencyDropdownRow() {
    final textStyle = Theme.of(context).textTheme.titleMedium;

    // Find the full name for the selected currency code
    final selectedCurrencyCode = _currencyController.text;
    final currencyName = cCurrencyMap[selectedCurrencyCode] ??
        selectedCurrencyCode; // Fallback to code if name not found

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 4.0, horizontal: 0), // Reduced vertical padding slightly
      child: Row(
        children: [
          Icon(Icons.attach_money_outlined,
              size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: _isEditingMode
                ? DropdownButtonHideUnderline(
                    // Hide default underline
                    child: DropdownButton<String>(
                      value: _dropdownCurrencies.contains(selectedCurrencyCode)
                          ? selectedCurrencyCode
                          : (_dropdownCurrencies.isNotEmpty
                              ? _dropdownCurrencies.first
                              : null),
                      isExpanded: true, // Make dropdown take available space
                      items: _dropdownCurrencies.map((String code) {
                        final name = cCurrencyMap[code] ?? code;
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text('$code - $name',
                              style: textStyle,
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null &&
                            _dropdownCurrencies.contains(newValue)) {
                          setState(() {
                            _currencyController.text = newValue;
                          });
                        }
                      },
                      menuMaxHeight: 300.0,
                      // Style the dropdown button itself if needed
                      // style: textStyle,
                    ),
                  )
                : Text(
                    // Display as plain text when not editing
                    '$selectedCurrencyCode - $currencyName',
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (_isEditingMode) // Show edit indicator only if editable
            Icon(Icons.edit_note_outlined, size: 18, color: Colors.grey[600]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BillSplittingBloc, BillSplittingState>(
      listener: (context, state) {
        if (state is BillSplittingSuccess && !_isEditingMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.green),
          );
        } else if (state is BillSplittingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
          if (!_isEditingMode) {
            _toggleEditMode(); // Go back to editing
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditingMode ? 'Edit Bill' : 'Review Bill'),
          actions: [
            IconButton(
              icon: Icon(
                  _isEditingMode ? Icons.save_outlined : Icons.edit_outlined),
              tooltip: _isEditingMode ? 'Save Bill Data' : 'Edit Bill Data',
              onPressed: context.watch<BillSplittingBloc>().state
                      is BillSplittingLoading
                  ? null
                  : (_isEditingMode ? _saveBillInternal : _toggleEditMode),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (_isInitializing)
                const Center(child: CircularProgressIndicator())
              else if (_parsingError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                      child: Text('Error parsing OCR data: $_parsingError',
                          style: TextStyle(color: Colors.red))),
                )
              else ...[
                // --- Structured Data Fields ---
                _buildEditableRow(
                  context: context,
                  icon: Icons.store_mall_directory_outlined,
                  label: 'Description / Store', // Placeholder label
                  value: _descriptionController.text,
                  onTap: _isEditingMode
                      ? () => _showEditDescriptionDialog()
                      : null,
                ),
                const Divider(height: 1),
                _buildEditableRow(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  label: 'Date', // Placeholder label
                  value: _dateController.text, // Consider formatting if needed
                  onTap: _isEditingMode ? () => _selectDate(context) : null,
                ),
                const Divider(height: 1),
                _buildEditableRow(
                  context: context,
                  // No icon for Total Amount as per requirement, but keep structure
                  label: 'Total Amount', // Placeholder label
                  value:
                      _totalAmountController.text, // Add currency symbol later
                  isBold: true, // Apply bold style
                  onTap: _isEditingMode
                      ? () => _showEditTotalAmountDialog()
                      : null,
                ),
                const Divider(height: 1),

                // --- Optional Fields Section ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end, // Align button to the right
                    children: [
                      // Optional: Add a label if needed
                      // const Text("Optional Fields:"),
                      // const Spacer(), // Pushes button to the right
                      if (_isEditingMode) // Only show add button in edit mode
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Add Tax, Tip, Discount, Currency',
                          onPressed: _showAddFieldDialog,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ),

                // Conditionally display optional fields
                if (_showTax) ...[
                  _buildEditableRow(
                    context: context,
                    icon: Icons.receipt_long_outlined, // Example icon
                    label: 'Tax',
                    value: _taxController.text, // Add currency symbol later
                    onTap: _isEditingMode ? () => _showEditTaxDialog() : null,
                  ),
                  const Divider(height: 1),
                ],
                if (_showTip) ...[
                  _buildEditableRow(
                    context: context,
                    icon: Icons.room_service_outlined, // Example icon
                    label: 'Tip',
                    value: _tipController.text, // Add currency symbol later
                    onTap: _isEditingMode ? () => _showEditTipDialog() : null,
                  ),
                  const Divider(height: 1),
                ],
                if (_showDiscount) ...[
                  _buildEditableRow(
                    context: context,
                    icon: Icons.local_offer_outlined, // Example icon
                    label: 'Discount',
                    value:
                        _discountController.text, // Add currency symbol later
                    onTap:
                        _isEditingMode ? () => _showEditDiscountDialog() : null,
                  ),
                  const Divider(height: 1),
                ],
                if (_showCurrency) ...[
                  _buildCurrencyDropdownRow(), // Use a specific widget for currency dropdown
                  const Divider(height: 1),
                ],

                // Add some space before the main divider if optional fields are shown
                if (_showTax || _showTip || _showDiscount || _showCurrency)
                  const SizedBox(height: 16),

                const Divider(), // Divider before Items section

                // --- Items Section ---
                BillItemsSection(
                  key: ValueKey('items_${_items.hashCode}_$_isEditingMode'),
                  initialItems: _items,
                  enabled: _isEditingMode,
                  onItemsChanged: (updatedItems) {
                    if (_isEditingMode) _items = updatedItems;
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
                      'participants_${_participants.hashCode}_$_isEditingMode'),
                  initialParticipants: _participants,
                  enabled: _isEditingMode,
                  onParticipantsChanged: (updatedParticipants) {
                    if (_isEditingMode) _participants = updatedParticipants;
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),

                // --- Final Bill JSON Data (Show only when not editing) ---
                if (!_isEditingMode && _finalBillJsonString != null) ...[
                  ExpansionTile(
                    // Removed controller and state management for expansion
                    initiallyExpanded: true, // Keep it open initially
                    title: Text('Final Bill JSON Data',
                        style: Theme.of(context).textTheme.titleMedium),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant)),
                          child: SelectableText(
                            _finalBillJsonString!,
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
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
                      context.push(AppRoutes.chatbot,
                          extra: _finalBillJsonString);
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                ],

                // --- Raw OCR Text (Styled like Final JSON, always available) ---
                ExpansionTile(
                  // Removed controller and state management for expansion
                  initiallyExpanded: false, // Default to collapsed
                  title: Text('Raw OCR/JSON Data (Initial)',
                      style: Theme.of(context).textTheme.titleSmall),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 8.0, bottom: 16.0), // Match padding
                      child: Container(
                        // Use Container for styling
                        padding: const EdgeInsets.all(12.0), // Match padding
                        decoration: BoxDecoration(
                            // Match decoration
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant)),
                        child: SelectableText(
                          // Use SelectableText
                          _ocrTextController.text, // Get text from controller
                          style: TextStyle(
                              // Match style
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Add some space at the bottom
              ],
            ],
          ),
        ),
      ),
    );
  }
}
