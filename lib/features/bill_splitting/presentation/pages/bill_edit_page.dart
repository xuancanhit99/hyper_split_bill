import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert'; // For jsonDecode, utf8, JsonEncoder
import 'package:intl/intl.dart'; // For date formatting
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart'; // Import Bloc, Event, State
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart'; // Import BillEntity
import 'package:go_router/go_router.dart'; // Import go_router for pop and push
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_items_section.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_participants_section.dart';
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart'; // Import AuthBloc for user ID
import 'package:hyper_split_bill/core/router/app_router.dart'; // Import AppRoutes for navigation
import 'package:hyper_split_bill/core/constants/currencies.dart'; // Import the new currency constants file

// Import newly created widgets
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/edit_dialog_content.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/edit_bill_info_section.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/json_expansion_tile.dart';

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
  bool _showSplitDetails =
      false; // State to control split detail visibility (kept for potential future use)

  // State for optional field visibility
  bool _showTax = false;
  bool _showTip = false;
  bool _showDiscount = false;
  bool _showCurrency = false; // Currency starts hidden as per requirement
  bool _showItemDetails = false; // State for Qty/Unit Price visibility

  // State for calculated total comparison
  double?
      _calculatedTotalAmount; // Holds the sum of items + tax + tip - discount

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
    // Initial calculation after parsing
    _recalculateAndCompareTotal();
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
      // Initialize with the first participant and set their percentage to 100%
      _participants = [
        ParticipantEntity(
          name: currentUserName,
          percentage: 100.0, // Explicitly set percentage
          isPercentageLocked: false, // Start unlocked
        )
      ];

      setState(() {}); // Update UI after successful parsing
    } catch (e, s) {
      print("Error parsing structured JSON: $e\nStackTrace: $s");
      setState(() {
        _parsingError = 'Failed to parse structured data: $e';
      });
      // Recalculate total after parsing is complete and state is set
      _recalculateAndCompareTotal();
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

    // --- Participant Percentage Handling ---
    // If only one participant exists, ensure their percentage is 100% before validation
    if (_participants.length == 1) {
      // Use copyWith to create a new instance with updated percentage
      _participants[0] = _participants[0].copyWith(
        percentage: 100.0,
        isPercentageLocked: false, // Ensure it's not locked if it was somehow
        setPercentageToNull: false, // Ensure percentage is not nullified
      );
      print("Auto-set single participant percentage to 100%");
    }

    // Validate Participant Percentages
    double totalPercentage =
        _participants.fold(0.0, (sum, p) => sum + (p.percentage ?? 0.0));
    if ((totalPercentage - 100.0).abs() > 0.01) {
      // Allow for small floating point inaccuracies
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Participant percentages must add up to 100%. Current total: ${totalPercentage.toStringAsFixed(2)}%')),
      );
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
      participants:
          _participants, // Pass the participants list with percentages
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
      _showSplitDetails = false; // Reset split details visibility
    });

    print("Internal save complete. Dispatching save event...");
    _dispatchSaveEvent(currentBillData); // Dispatch event with BillEntity
  }

  void _toggleEditMode() {
    setState(() {
      _isEditingMode = !_isEditingMode; // Toggle edit mode
      if (_isEditingMode) {
        _finalBillJsonString = null; // Clear final JSON when going back to edit
        _showSplitDetails = false; // Reset split details visibility
      }
      // When switching back to review mode, percentages might need redistribution
      // if they were edited but not saved (though save is required now).
      // However, the BillParticipantsSection handles its state based on `enabled`.
    });
    print("Switched to ${_isEditingMode ? 'editing' : 'review'} mode.");
  }

  // --- Total Amount Calculation and Update ---

  void _recalculateAndCompareTotal() {
    if (!mounted) return; // Ensure widget is still active

    final itemsSubtotal =
        _items.fold(0.0, (sum, item) => sum + item.totalPrice);

    // Use _parseNum which handles null/empty/invalid safely, default to 0
    final taxPercent = _showTax ? (_parseNum(_taxController.text) ?? 0.0) : 0.0;
    final tipPercent = _showTip ? (_parseNum(_tipController.text) ?? 0.0) : 0.0;
    // Discount is usually negative, but let's treat the input as positive %
    final discountPercent =
        _showDiscount ? (_parseNum(_discountController.text) ?? 0.0) : 0.0;

    // Calculate amounts based on itemsSubtotal
    final taxAmount = itemsSubtotal * (taxPercent / 100.0);
    final tipAmount = itemsSubtotal * (tipPercent / 100.0);
    final discountAmount = itemsSubtotal * (discountPercent / 100.0);

    final newCalculatedTotal =
        itemsSubtotal + taxAmount + tipAmount - discountAmount;
    // Update the state variable directly, as this method is now called
    // at appropriate times (e.g., within addPostFrameCallback elsewhere or directly)
    if (mounted) {
      setState(() {
        _calculatedTotalAmount = newCalculatedTotal;
      });
    }

    // Optional: Print comparison for debugging
    // final currentTotalInController = _parseNum(_totalAmountController.text) ?? 0.0;
    // print("Recalculated Total: $newCalculatedTotal, Current Total in Controller: $currentTotalInController");
  }

  void _updateTotalAmountFromCalculation() {
    // Update the controller and recalculate directly
    if (_calculatedTotalAmount != null && mounted) {
      setState(() {
        // Format before setting to controller
        _totalAmountController.text =
            _formatCurrencyValue(_calculatedTotalAmount);
      });
      // Recalculate again immediately to update the comparison state
      _recalculateAndCompareTotal();
    }
  }

  // --- Handle Item Changes ---
  void _handleItemsChanged(List<BillItemEntity> updatedItems) {
    if (!mounted) return;
    // Use addPostFrameCallback for safety
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _items = updatedItems;
        });
        _recalculateAndCompareTotal(); // Recalculate when items change
      }
    });
  }

  // --- Edit Dialog Methods ---
  Future<void> _showEditDescriptionDialog() async {
    // Key to access the state of the dialog content (use public state type)
    final GlobalKey<DescriptionDialogContentState> contentKey =
        GlobalKey<DescriptionDialogContentState>();

    final String? newDescription = await showDialog<String>(
      context: context,
      // Prevent dismissal by tapping outside - ensures proper flow
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Edit Description'),
        // Use the imported widget
        content: DescriptionDialogContent(
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
      // Recalculate total after description change (though it doesn't affect total)
      // _recalculateAndCompareTotal(); // Not strictly needed here
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
    // Key to access the state of the dialog content (use public state type)
    final GlobalKey<NumericDialogContentState> contentKey =
        GlobalKey<NumericDialogContentState>();

    final String? newValue = await showDialog<String>(
      context: context,
      // Prevent dismissal by tapping outside - ensures proper flow
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        // Use the imported widget
        content: NumericDialogContent(
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
      allowNegative: false, // Total amount usually shouldn't be negative
    );
    if (newValue != null && newValue != _totalAmountController.text) {
      // Delay setState until after the frame finishes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _totalAmountController.text = newValue;
          });
          // Recalculate *after* state is set inside the callback
          _recalculateAndCompareTotal();
        }
      });
    }
  }

  Future<void> _showEditTaxDialog() async {
    final String? newValue = await _showEditNumericDialog(
      title: 'Edit Tax',
      initialValue: _taxController.text,
      valueSuffix: '%',
      allowNegative: false, // Tax percentage usually non-negative
    );
    if (newValue != null && newValue != _taxController.text) {
      // Delay setState until after the frame finishes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _taxController.text = newValue;
          });
          // Recalculate *after* state is set inside the callback
          _recalculateAndCompareTotal();
        }
      });
    }
  }

  Future<void> _showEditTipDialog() async {
    final String? newValue = await _showEditNumericDialog(
      title: 'Edit Tip',
      initialValue: _tipController.text,
      valueSuffix: '%',
      allowNegative: false, // Tip percentage usually non-negative
    );
    if (newValue != null && newValue != _tipController.text) {
      // Delay setState until after the frame finishes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _tipController.text = newValue;
          });
          // Recalculate *after* state is set inside the callback
          _recalculateAndCompareTotal();
        }
      });
    }
  }

  Future<void> _showEditDiscountDialog() async {
    final String? newValue = await _showEditNumericDialog(
      title: 'Edit Discount',
      initialValue: _discountController.text,
      valueSuffix: '%',
      allowNegative: false, // Discount percentage usually non-negative
    );
    if (newValue != null && newValue != _discountController.text) {
      // Delay setState until after the frame finishes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _discountController.text = newValue;
          });
          // Recalculate *after* state is set inside the callback
          _recalculateAndCompareTotal();
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
                              setState(() {}); // Update main page UI
                              _recalculateAndCompareTotal(); // Recalculate
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
                              setState(() {}); // Update main page UI
                              _recalculateAndCompareTotal(); // Recalculate
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
                              setState(() {}); // Update main page UI
                              _recalculateAndCompareTotal(); // Recalculate
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
                              setState(() {}); // Update main page UI
                              // Currency change doesn't affect total calculation based on items/fees
                              // _recalculateAndCompareTotal(); // Not needed here
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

  // --- Currency Change Handler ---
  void _handleCurrencyChanged(String? newValue) {
    if (newValue != null && _dropdownCurrencies.contains(newValue)) {
      setState(() {
        _currencyController.text = newValue;
      });
    }
  }

  // --- Toggle Item Details Visibility ---
  void _toggleItemDetailsVisibility() {
    setState(() {
      _showItemDetails = !_showItemDetails;
    });
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
                // --- Use the new EditBillInfoSection ---
                EditBillInfoSection(
                  isEditingMode: _isEditingMode,
                  descriptionController: _descriptionController,
                  dateController: _dateController,
                  totalAmountController: _totalAmountController,
                  taxController: _taxController,
                  tipController: _tipController,
                  discountController: _discountController,
                  currencyController: _currencyController,
                  showTax: _showTax,
                  showTip: _showTip,
                  showDiscount: _showDiscount,
                  showCurrency: _showCurrency,
                  dropdownCurrencies: _dropdownCurrencies,
                  onEditDescription: _showEditDescriptionDialog,
                  onSelectDate: () => _selectDate(context),
                  onEditTotalAmount: _showEditTotalAmountDialog,
                  onEditTax: _showEditTaxDialog,
                  onEditTip: _showEditTipDialog,
                  onEditDiscount: _showEditDiscountDialog,
                  onCurrencyChanged: _handleCurrencyChanged,
                  onAddOptionalFields: _showAddFieldDialog,
                  onToggleItemDetails:
                      _toggleItemDetailsVisibility, // Pass the toggle function
                  showItemDetails:
                      _showItemDetails, // Pass the visibility state
                  formatCurrencyValue: _formatCurrencyValue,
                  // Pass calculation results and update callback
                  calculatedTotalAmount: _calculatedTotalAmount,
                  onUpdateTotalAmount: _updateTotalAmountFromCalculation,
                ),

                const Divider(), // Divider before Items section

                // --- Items Section ---
                BillItemsSection(
                  key: ValueKey('items_${_items.hashCode}_$_isEditingMode'),
                  initialItems: _items,
                  enabled: _isEditingMode,
                  // Use the dedicated handler
                  onItemsChanged: _handleItemsChanged,
                  showItemDetails:
                      _showItemDetails, // Pass the visibility state
                ),
                const SizedBox(height: 24),
                const Divider(),

                // --- Participants Section ---
                Text('Participants:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                BillParticipantsSection(
                  key: ValueKey(
                      'participants_${_participants.hashCode}_${_isEditingMode}_${_totalAmountController.text}_${_currencyController.text}'), // Add amounts to key to force rebuild on change
                  initialParticipants: _participants,
                  enabled: _isEditingMode,
                  totalAmount: _parseNum(_totalAmountController.text)
                      ?.toDouble(), // Pass total amount
                  currencyCode: _currencyController.text, // Pass currency code
                  onParticipantsChanged: (updatedParticipants) {
                    // No need to check _isEditingMode here, the callback should only be called when enabled
                    setState(() {
                      _participants = updatedParticipants;
                    });
                  },
                ),
                // Add "Split Equally" button for review mode
                if (!_isEditingMode && _participants.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton.icon(
                      icon: const Icon(Icons.pie_chart_outline, size: 18),
                      label:
                          Text('Split Equally Among ${_participants.length}'),
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontStyle: FontStyle.italic),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        if (_participants.isEmpty) return;
                        final double equalPercentage =
                            100.0 / _participants.length;
                        final List<ParticipantEntity> equallySplitParticipants =
                            [];
                        double assignedTotal = 0;

                        for (int i = 0; i < _participants.length; i++) {
                          double perc = (i == _participants.length - 1)
                              ? (100.0 -
                                  assignedTotal) // Assign remainder to last
                              : equalPercentage;
                          // Use toStringAsFixed for better control over rounding for display/comparison later
                          perc = double.parse(perc.toStringAsFixed(2));
                          assignedTotal += perc;

                          equallySplitParticipants.add(
                            _participants[i].copyWith(
                              percentage: perc,
                              isPercentageLocked: false, // Unlock all
                              setPercentageToNull: false,
                            ),
                          );
                        }

                        // Final check for 100% total due to potential rounding errors
                        double finalTotal = equallySplitParticipants.fold(
                            0.0, (sum, p) => sum + (p.percentage ?? 0.0));
                        if ((finalTotal - 100.0).abs() > 0.01 &&
                            equallySplitParticipants.isNotEmpty) {
                          double adjustment = 100.0 - finalTotal;
                          double lastPerc =
                              equallySplitParticipants.last.percentage ?? 0.0;
                          // Adjust the last participant's percentage
                          equallySplitParticipants[
                              equallySplitParticipants.length -
                                  1] = equallySplitParticipants.last.copyWith(
                              percentage: double.parse(
                                  (lastPerc + adjustment).toStringAsFixed(2)));
                        }

                        setState(() {
                          _participants = equallySplitParticipants;
                          // We don't need _showSplitDetails anymore as the display is handled within BillParticipantsSection
                          // _showSplitDetails = false;
                        });
                      },
                    ),
                  ),
                const SizedBox(height: 24), // Keep this SizedBox
                const Divider(), // Keep this Divider

                // --- Final Bill JSON Data (Show only when not editing) ---
                if (!_isEditingMode && _finalBillJsonString != null) ...[
                  JsonExpansionTile(
                    title: 'Final Bill JSON Data',
                    jsonString: _finalBillJsonString!,
                    initiallyExpanded: true,
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
                JsonExpansionTile(
                  title: 'Raw OCR/JSON Data (Initial)',
                  jsonString: _ocrTextController.text,
                  initiallyExpanded: false,
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
