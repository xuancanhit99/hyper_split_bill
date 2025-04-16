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
      _taxController.text = _parseNum(data['tax_amount'])?.toString() ?? '0.0';
      _tipController.text = _parseNum(data['tip_amount'])?.toString() ?? '0.0';
      _discountController.text =
          _parseNum(data['discount_amount'])?.toString() ?? '0.0';

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
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                            labelText: 'Description / Store Name'),
                        enabled: _isEditingMode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Bill Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        enabled: _isEditingMode,
                        onTap:
                            _isEditingMode ? () => _selectDate(context) : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _totalAmountController,
                        decoration:
                            const InputDecoration(labelText: 'Total Amount'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        enabled: _isEditingMode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _dropdownCurrencies
                                .contains(_currencyController.text)
                            ? _currencyController.text
                            : (_dropdownCurrencies.isNotEmpty
                                ? _dropdownCurrencies.first
                                : null),
                        items: _dropdownCurrencies
                            .map((String currency) => DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency),
                                ))
                            .toList(),
                        onChanged: _isEditingMode
                            ? (String? newValue) {
                                if (newValue != null &&
                                    _dropdownCurrencies.contains(newValue)) {
                                  setState(() {
                                    _currencyController.text = newValue;
                                  });
                                }
                              }
                            : null,
                        decoration:
                            const InputDecoration(labelText: 'Currency'),
                        menuMaxHeight: 300.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taxController,
                        decoration: const InputDecoration(labelText: 'Tax'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        enabled: _isEditingMode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _tipController,
                        decoration: const InputDecoration(labelText: 'Tip'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        enabled: _isEditingMode,
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
                        enabled: _isEditingMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),

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
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder for missing toJson methods - replace with actual implementation if needed
extension BillItemEntityJson on BillItemEntity {
  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
      };
}

extension ParticipantEntityJson on ParticipantEntity {
  Map<String, dynamic> toJson() => {
        'name': name,
        // 'user_id': userId, // Uncomment if userId is part of the entity
      };
}
