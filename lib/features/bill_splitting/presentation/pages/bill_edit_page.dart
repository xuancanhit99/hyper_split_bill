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

// --- Stateful Widget for Description Dialog Content ---
class _DescriptionDialogContent extends StatefulWidget {
  final String initialValue;

  const _DescriptionDialogContent({super.key, required this.initialValue});

  @override
  _DescriptionDialogContentState createState() =>
      _DescriptionDialogContentState();
}

class _DescriptionDialogContentState extends State<_DescriptionDialogContent> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String get currentValue => controller.text.trim();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration:
          const InputDecoration(hintText: 'Enter description or store name'),
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

// --- Stateful Widget for Numeric Dialog Content ---
class _NumericDialogContent extends StatefulWidget {
  final String initialValue;
  final String? hintText;
  final String? valueSuffix;
  final bool allowNegative;
  final num? Function(dynamic, {bool allowNegative})
      parseNumFunc; // Pass helper

  const _NumericDialogContent({
    super.key,
    required this.initialValue,
    this.hintText,
    this.valueSuffix,
    this.allowNegative = false,
    required this.parseNumFunc,
  });

  @override
  _NumericDialogContentState createState() => _NumericDialogContentState();
}

class _NumericDialogContentState extends State<_NumericDialogContent> {
  late final TextEditingController controller;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String get currentValue => controller.text.isEmpty ? '0' : controller.text;
  bool validate() => formKey.currentState!.validate();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: TextFormField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(
            decimal: true, signed: widget.allowNegative),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Enter value',
          suffixText: widget.valueSuffix,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return null; // Allow empty, treat as 0
          }
          final number =
              widget.parseNumFunc(value, allowNegative: widget.allowNegative);
          if (number == null) {
            return 'Please enter a valid number';
          }
          return null; // Valid
        },
      ),
    );
  }
}

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

  // Date formatters
  final DateFormat _displayDateFormat = DateFormat('dd-MM-yyyy');
  final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

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

  // --- Formatting Helper ---
  String _formatCurrencyValue(num? value) {
    if (value == null) return '';
    // Use NumberFormat for flexible formatting
    // '0.##' pattern removes trailing zeros and '.00'
    final format = NumberFormat('0.##');
    return format.format(value);
  }

  // Helper function to safely parse numeric values from dynamic JSON data
  num? _parseNum(dynamic value, {bool allowNegative = true}) {
    if (value == null) return null;
    if (value is num) return allowNegative || value >= 0 ? value : null;
    if (value is String) {
      if (value.trim().isEmpty) return null;
      final sanitizedValue = value
          .replaceAll(RegExp(r'[$,€£¥%]'), '')
          .replaceAll(',', '.') // Ensure decimal point is '.' for parsing
          .trim();
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
      // Store raw numeric string in controller, format for display later
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

      // Date Parsing with dd-MM-yyyy display format
      final dateString = data['bill_date'] as String?;
      if (dateString != null && dateString.isNotEmpty) {
        DateTime? parsedDate;
        try {
          // First try ISO format (common backend format)
          parsedDate = _isoDateFormat.parseStrict(dateString);
        } catch (_) {
          // Try common US format
          try {
            parsedDate = DateFormat('MM/dd/yyyy').parseStrict(dateString);
          } catch (_) {
            // Try common EU format
            try {
              parsedDate = DateFormat('dd/MM/yyyy').parseStrict(dateString);
            } catch (_) {
              // Try display format itself
              try {
                parsedDate = _displayDateFormat.parseStrict(dateString);
              } catch (_) {
                print(
                    "Warning: Could not parse date string '$dateString' into known formats. Keeping original.");
                _dateController.text = dateString; // Fallback
              }
            }
          }
        }
        if (parsedDate != null) {
          _dateController.text = _displayDateFormat.format(parsedDate);
        } else if (_dateController.text.isEmpty) {
          // Ensure controller is not empty if parsing failed but string existed
          _dateController.text = dateString;
        }
      } else {
        _dateController.text = ''; // Set empty if no date string
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
    DateTime initialDate = DateTime.now(); // Default to now
    try {
      // Try parsing the current text in display format
      initialDate = _displayDateFormat.parseStrict(_dateController.text);
    } catch (_) {
      // If parsing fails, keep the default (DateTime.now())
      print(
          "Could not parse current date text: ${_dateController.text}. Using today's date as initial.");
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        // Update controller with display format
        _dateController.text = _displayDateFormat.format(picked);
      });
    }
  }

  void _dispatchSaveEvent(BillEntity billToSave) {
    print("Dispatching SaveBillEvent for user ID: ${billToSave.payerUserId}");
    context.read<BillSplittingBloc>().add(SaveBillEvent(billToSave));
  }

  void _saveBillInternal() {
    final totalAmount = _parseNum(_totalAmountController.text); // Use helper
    final taxAmount = _parseNum(_taxController.text) ?? 0.0;
    final tipAmount = _parseNum(_tipController.text) ?? 0.0;
    final discountAmount = _parseNum(_discountController.text) ?? 0.0;
    final currencyCode = _currencyController.text.trim().toUpperCase();

    // Validate Total Amount
    if (totalAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid total amount.')));
      return;
    }

    // Validate and Parse Date
    DateTime? parsedBillDate;
    try {
      parsedBillDate = _displayDateFormat.parseStrict(_dateController.text);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid date (dd-MM-yyyy).')));
      return;
    }

    // Validate Currency
    if (!_dropdownCurrencies.contains(currencyCode)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Invalid currency selected. Please choose from the list.')));
      return;
    }

    // Get User ID
    final authState = context.read<AuthBloc>().state;
    String? currentUserId;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not authenticated.')));
      return;
    }

    // Create Bill Entity
    final currentBillData = BillEntity(
      id: '', // ID will be generated by backend/storage
      totalAmount: totalAmount.toDouble(), // Convert num to double
      date: parsedBillDate,
      description: _descriptionController.text.trim(),
      payerUserId: currentUserId!, // We know it's not null here
      currencyCode: currencyCode,
      items: _items,
      participants: _participants,
      // Note: Tax, Tip, Discount are not part of BillEntity currently
      // They are handled separately in the JSON map below if needed
    );

    // Create JSON Map for potential saving/display
    final billMapForJson = {
      'bill_date':
          _isoDateFormat.format(currentBillData.date), // Save in ISO format
      'description': currentBillData.description,
      'currency_code': currentBillData.currencyCode,
      'total_amount': currentBillData.totalAmount,
      'tax_amount': taxAmount, // Include tax if needed
      'tip_amount': tipAmount, // Include tip if needed
      'discount_amount': discountAmount, // Include discount if needed
      'payer_user_id': currentBillData.payerUserId,
      'items':
          currentBillData.items?.map((item) => item.toJson()).toList() ?? [],
      'participants':
          currentBillData.participants?.map((p) => p.toJson()).toList() ?? [],
    };
    const jsonEncoder = JsonEncoder.withIndent('  ');
    final generatedJson = jsonEncoder.convert(billMapForJson);

    setState(() {
      _finalBillJsonString = generatedJson;
      _isEditingMode = false; // Switch to review mode
    });

    print("Internal save complete. Dispatching save event...");
    _dispatchSaveEvent(currentBillData); // Dispatch event with BillEntity
  }

  void _toggleEditMode() {
    setState(() {
      _isEditingMode = !_isEditingMode; // Toggle edit mode
      if (_isEditingMode) {
        _finalBillJsonString = null; // Clear final JSON when going back to edit
      }
    });
    print("Switched to ${_isEditingMode ? 'editing' : 'review'} mode.");
  }

  // --- Helper Widget for Editable Rows ---
  Widget _buildEditableRow({
    required BuildContext context,
    IconData? icon,
    String? textPrefix, // Optional text prefix instead of icon
    required String label, // Used for placeholder text
    required String value,
    String? valueSuffix, // Optional suffix (like '%')
    VoidCallback? onTap,
    bool isBold = false,
  }) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isBold ? 18 : 16,
        );

    final displayValue =
        value.isEmpty ? 'Tap to edit $label' : '$value${valueSuffix ?? ''}';

    return InkWell(
      onTap: _isEditingMode ? onTap : null, // Only allow tap in edit mode
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 0),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
            ] else if (textPrefix != null) ...[
              Text(textPrefix,
                  style: textStyle?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .primary)), // Style prefix like icon
              const SizedBox(width: 8), // Smaller gap for text prefix
            ],
            Expanded(
              child: Text(
                displayValue,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isEditingMode &&
                onTap != null) // Show edit indicator only if editable
              Icon(Icons.edit_note_outlined, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // --- Edit Dialog Methods ---
  Future<void> _showEditDescriptionDialog() async {
    // Key to access the state of the dialog content
    final GlobalKey<_DescriptionDialogContentState> contentKey =
        GlobalKey<_DescriptionDialogContentState>();

    final String? newDescription = await showDialog<String>(
      context: context,
      // Prevent dismissal by tapping outside - ensures proper flow
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Edit Description'),
        content: _DescriptionDialogContent(
          key: contentKey, // Assign key
          initialValue: _descriptionController.text,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(), // Return null on cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Access value via key and pop
              final value = contentKey.currentState?.currentValue;
              Navigator.of(context).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // No local controller to dispose here

    // Update the state if needed (using post frame callback)
    if (newDescription != null &&
        newDescription != _descriptionController.text) {
      // Delay setState until after the frame finishes to avoid race conditions
      // during dialog closing/deactivation.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Check if the widget is still in the tree
          setState(() {
            _descriptionController.text = newDescription;
          });
        }
      });
    }
  }

  // --- Reusable Numeric Edit Dialog (Decoupled Controller) ---
  Future<String?> _showEditNumericDialog({
    required String title,
    required String initialValue,
    String? hintText,
    String? valueSuffix,
    bool allowNegative = false,
  }) async {
    // Key to access the state of the dialog content
    final GlobalKey<_NumericDialogContentState> contentKey =
        GlobalKey<_NumericDialogContentState>();

    final String? newValue = await showDialog<String>(
      context: context,
      // Prevent dismissal by tapping outside - ensures proper flow
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: _NumericDialogContent(
          key: contentKey, // Assign key
          initialValue: initialValue,
          hintText: hintText,
          valueSuffix: valueSuffix,
          allowNegative: allowNegative,
          parseNumFunc: _parseNum, // Pass the helper function
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(), // Return null on cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Access state via key to validate and get value
              final contentState = contentKey.currentState;
              if (contentState != null && contentState.validate()) {
                Navigator.of(context).pop(contentState.currentValue);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // No local controller or form key to dispose here

    // Return the new value (or null if cancelled)
    return newValue;
  }

  // --- Specific Edit Dialog Implementations using the decoupled helper ---

  Future<void> _showEditTotalAmountDialog() async {
    final String? newValue = await _showEditNumericDialog(
      title: 'Edit Total Amount',
      initialValue: _totalAmountController.text,
      allowNegative: false,
    );
    if (newValue != null && newValue != _totalAmountController.text) {
      // Delay setState until after the frame finishes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _totalAmountController.text = newValue;
          });
        }
      });
    }
  }

  Future<void> _showEditTaxDialog() async {
    final String? newValue = await _showEditNumericDialog(
      title: 'Edit Tax',
      initialValue: _taxController.text,
      valueSuffix: '%',
      allowNegative: false,
    );
    if (newValue != null && newValue != _taxController.text) {
      // Delay setState until after the frame finishes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _taxController.text = newValue;
          });
        }
      });
    }
  }

  Future<void> _showEditTipDialog() async {
    final String? newValue = await _showEditNumericDialog(
      title: 'Edit Tip',
      initialValue: _tipController.text,
      valueSuffix: '%',
      allowNegative: false,
    );
    if (newValue != null && newValue != _tipController.text) {
      // Delay setState until after the frame finishes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _tipController.text = newValue;
          });
        }
      });
    }
  }

  Future<void> _showEditDiscountDialog() async {
    final String? newValue = await _showEditNumericDialog(
      title: 'Edit Discount',
      initialValue: _discountController.text,
      valueSuffix: '%',
      allowNegative: false,
    );
    if (newValue != null && newValue != _discountController.text) {
      // Delay setState until after the frame finishes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _discountController.text = newValue;
          });
        }
      });
    }
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CheckboxListTile(
                      title: const Text('Tax'),
                      value: _showTax,
                      onChanged: !_isEditingMode
                          ? null
                          : (bool? value) {
                              // Disable in review mode
                              setDialogState(() {
                                _showTax = value ?? false;
                              });
                              setState(() {});
                            },
                    ),
                    CheckboxListTile(
                      title: const Text('Tip'),
                      value: _showTip,
                      onChanged: !_isEditingMode
                          ? null
                          : (bool? value) {
                              // Disable in review mode
                              setDialogState(() {
                                _showTip = value ?? false;
                              });
                              setState(() {});
                            },
                    ),
                    CheckboxListTile(
                      title: const Text('Discount'),
                      value: _showDiscount,
                      onChanged: !_isEditingMode
                          ? null
                          : (bool? value) {
                              // Disable in review mode
                              setDialogState(() {
                                _showDiscount = value ?? false;
                              });
                              setState(() {});
                            },
                    ),
                    CheckboxListTile(
                      title: const Text('Currency'),
                      value: _showCurrency,
                      onChanged: !_isEditingMode
                          ? null
                          : (bool? value) {
                              // Disable in review mode
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
                    // No need for extra setState here as individual onChanged handles it
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
    final selectedCurrencyCode = _currencyController.text;
    // Use the map constant defined in currencies.dart
    final currencyName =
        cCurrencyMap[selectedCurrencyCode] ?? selectedCurrencyCode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      child: Row(
        children: [
          Icon(Icons.attach_money_outlined,
              size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: _isEditingMode
                ? DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _dropdownCurrencies.contains(selectedCurrencyCode)
                          ? selectedCurrencyCode
                          : (_dropdownCurrencies.isNotEmpty
                              ? _dropdownCurrencies.first
                              : null),
                      isExpanded: true,
                      items: _dropdownCurrencies.map((String code) {
                        // Use the map constant here as well
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
          // Optionally navigate away or disable further editing
        } else if (state is BillSplittingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Save Error: ${state.message}"), // Add prefix
                backgroundColor: Theme.of(context).colorScheme.error),
          );
          // Allow user to stay in edit mode or toggle back if save failed from review mode
          if (!_isEditingMode) {
            setState(() {
              _isEditingMode = true;
            }); // Go back to editing on error
          }
        } else if (state is BillSplittingLoading) {
          // Optional: Show loading indicator on save button or elsewhere
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditingMode ? 'Edit Bill' : 'Review Bill'),
          actions: [
            // Show progress indicator instead of button while loading
            if (context.watch<BillSplittingBloc>().state
                is BillSplittingLoading)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else
              IconButton(
                icon: Icon(
                    _isEditingMode ? Icons.save_outlined : Icons.edit_outlined),
                tooltip: _isEditingMode ? 'Save Bill Data' : 'Edit Bill Data',
                onPressed: _isEditingMode ? _saveBillInternal : _toggleEditMode,
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
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                )
              else ...[
                // --- Main Bill Info ---
                _buildEditableRow(
                  context: context,
                  icon: Icons.store_mall_directory_outlined,
                  label: 'Description / Store',
                  value: _descriptionController.text,
                  onTap: _showEditDescriptionDialog,
                ),
                const Divider(height: 1),
                _buildEditableRow(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: _dateController.text,
                  onTap: () => _selectDate(context), // Use direct call
                ),
                const Divider(height: 1),
                _buildEditableRow(
                  context: context,
                  textPrefix: "Total Amount:",
                  label: 'Total Amount',
                  value: _formatCurrencyValue(_parseNum(
                      _totalAmountController.text)), // Format for display
                  isBold: true,
                  onTap: _showEditTotalAmountDialog,
                ),
                const Divider(height: 1),

                // --- Conditionally Display Optional Fields ---
                if (_showTax) ...[
                  _buildEditableRow(
                    context: context,
                    textPrefix: "Tax:", // Use text prefix
                    label: 'Tax',
                    value: _taxController.text, // Raw value from controller
                    valueSuffix: "%", // Add suffix
                    onTap: _showEditTaxDialog,
                  ),
                  const Divider(height: 1),
                ],
                if (_showTip) ...[
                  _buildEditableRow(
                    context: context,
                    textPrefix: "Tip:", // Use text prefix
                    label: 'Tip',
                    value: _tipController.text, // Raw value from controller
                    valueSuffix: "%", // Add suffix
                    onTap: _showEditTipDialog,
                  ),
                  const Divider(height: 1),
                ],
                if (_showDiscount) ...[
                  _buildEditableRow(
                    context: context,
                    textPrefix: "Discount:", // Use text prefix
                    label: 'Discount',
                    value:
                        _discountController.text, // Raw value from controller
                    valueSuffix: "%", // Add suffix
                    onTap: _showEditDiscountDialog,
                  ),
                  const Divider(height: 1),
                ],
                if (_showCurrency) ...[
                  _buildCurrencyDropdownRow(),
                  const Divider(height: 1),
                ],

                // --- Add Optional Fields Button ---
                // Positioned below the optional fields
                if (_isEditingMode) // Only show button in edit mode
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0), // Add space above
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Add Tax, Tip, Discount, Currency',
                          onPressed: _showAddFieldDialog,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),

                // Add space before the main divider if optional fields are shown or button is present
                if (_showTax ||
                    _showTip ||
                    _showDiscount ||
                    _showCurrency ||
                    _isEditingMode)
                  const SizedBox(height: 16),

                const Divider(), // Divider before Items section

                // --- Items Section ---
                BillItemsSection(
                  key: ValueKey('items_${_items.hashCode}_$_isEditingMode'),
                  initialItems: _items,
                  enabled: _isEditingMode,
                  onItemsChanged: (updatedItems) {
                    if (_isEditingMode) {
                      setState(() {
                        _items = updatedItems;
                      }); // Update state
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
                      'participants_${_participants.hashCode}_$_isEditingMode'),
                  initialParticipants: _participants,
                  enabled: _isEditingMode,
                  onParticipantsChanged: (updatedParticipants) {
                    if (_isEditingMode) {
                      setState(() {
                        _participants = updatedParticipants;
                      }); // Update state
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),

                // --- Final Bill JSON Data (Show only when not editing) ---
                if (!_isEditingMode && _finalBillJsonString != null) ...[
                  ExpansionTile(
                    initiallyExpanded: true,
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
                  initiallyExpanded: false, // Default to collapsed
                  title: Text('Raw OCR/JSON Data (Initial)',
                      style: Theme.of(context).textTheme.titleSmall),
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
                          _ocrTextController.text,
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
                const SizedBox(height: 16), // Add some space at the bottom
              ],
            ],
          ),
        ),
      ),
    );
  }
}
