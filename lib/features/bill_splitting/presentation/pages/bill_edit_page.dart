import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert'; // For jsonDecode, utf8, JsonEncoder
import 'package:intl/intl.dart'; // For date formatting
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/calculate_split_bill_usecase.dart'; // Import Usecase
import 'package:hyper_split_bill/features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart'; // Import Bloc, Event, State
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart'; // Import BillEntity
import 'package:go_router/go_router.dart'; // Import go_router for pop and push
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_items_section.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/bill_participants_section.dart';
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart'; // Import AuthBloc for user ID
import 'package:hyper_split_bill/core/router/app_router.dart'; // Import AppRoutes for navigation
import 'package:hyper_split_bill/core/constants/currencies.dart'; // Import the new currency constants file
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

// Import newly created widgets
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/edit_dialog_content.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/edit_bill_info_section.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/json_expansion_tile.dart';

// Enum for input type
enum AmountType { percentage, fixed }

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

  // State for input types of tax, tip, discount
  AmountType _taxInputType = AmountType.percentage;
  AmountType _tipInputType = AmountType.percentage;
  AmountType _discountInputType = AmountType.percentage;

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

    // Initial calculation (can run before parsing if needed, or moved)
    // _recalculateAndCompareTotal(); // Moved to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Parse JSON here, as context is available and it runs after initState
    // Use a flag to ensure it only runs once during initialization
    if (_isInitializing) {
      _parseStructuredJson(widget.structuredJsonString);
      // Perform initial calculation *after* parsing is complete
      _recalculateAndCompareTotal();
      // Set the flag to false after the first run
      // Note: _parseStructuredJson already sets _isInitializing = false internally
      // If it didn't, we would set it here: _isInitializing = false;
    }
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
                description: itemMap['description'] as String? ??
                    AppLocalizations.of(context)!
                        .billEditPageDefaultItemDescription, // Use localized default
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

      // Initialize participants list as empty. User will add them manually.
      _participants = [];

      setState(() {}); // Update UI after successful parsing
    } catch (e, s) {
      print("Error parsing structured JSON: $e\nStackTrace: $s");
      setState(() {
        _parsingError = AppLocalizations.of(context)!
            .billEditPageErrorParsingJson(e.toString());
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

  // Helper to get actual tax, tip, discount amounts
  Map<String, double> _getActualAdditionalCosts() {
    final itemsSubtotal =
        _items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final taxValue = _showTax ? (_parseNum(_taxController.text) ?? 0.0) : 0.0;
    final tipValue = _showTip ? (_parseNum(_tipController.text) ?? 0.0) : 0.0;
    final discountValue =
        _showDiscount ? (_parseNum(_discountController.text) ?? 0.0) : 0.0;

    final actualTaxAmount = _taxInputType == AmountType.percentage
        ? itemsSubtotal * (taxValue / 100.0)
        : taxValue;
    final actualTipAmount = _tipInputType == AmountType.percentage
        ? itemsSubtotal * (tipValue / 100.0)
        : tipValue;
    final actualDiscountAmount = _discountInputType == AmountType.percentage
        ? itemsSubtotal * (discountValue / 100.0)
        : discountValue;
    return {
      'tax': actualTaxAmount.toDouble(),
      'tip': actualTipAmount.toDouble(),
      'discount': actualDiscountAmount.toDouble(),
    };
  }

  void _saveBillInternal() {
    final l10n = AppLocalizations.of(context)!; // For localization
    final totalAmountFromController = _parseNum(_totalAmountController.text);
    final currencyCode = _currencyController.text.trim().toUpperCase();

    // Validate Total Amount
    if (totalAmountFromController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.billEditPageValidationErrorTotalAmount)));
      return;
    }

    // Validate if all items have at least one participant
    final unassignedItems =
        _items.where((item) => item.participantIds.isEmpty).toList();
    if (unassignedItems.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.billEditPageErrorUnassignedItems(
            unassignedItems.length, unassignedItems.first.description)),
        // Example: "2 items are unassigned, starting with 'Pizza'."
        // You might want a more generic message or list all unassigned items.
      ));
      return;
    }

    // Validate if there are any participants
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.billEditPageErrorNoParticipants),
      ));
      return;
    }

    // --- Participant Percentage Handling (for display/external JSON, not for owed amount calculation) ---
    // This section related to percentages can be removed or simplified as percentages are no longer central.
    // If _participants.first.percentage is still used anywhere for display in JSON, it might need adjustment.
    // For now, let's comment it out as the core logic relies on item assignment.
    /*
    if (_participants.length == 1 && _participants.first.percentage == null) {
      _participants[0] = _participants[0].copyWith(
        percentage: 100.0,
        isPercentageLocked: false,
        setPercentageToNull: false,
      );
    }
    double totalPercentage =
        _participants.fold(0.0, (sum, p) => sum + (p.percentage ?? 0.0));
    if ((totalPercentage - 100.0).abs() > 0.01 && _participants.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.billEditPageValidationErrorPercentages(
              totalPercentage.toStringAsFixed(2)))));
      return;
    }
    */

    // Validate and Parse Date
    DateTime? parsedBillDate;
    try {
      parsedBillDate = _displayDateFormat.parseStrict(_dateController.text);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context)!.billEditPageValidationErrorDate)));
      return;
    }

    // Validate Currency
    if (!_dropdownCurrencies.contains(currencyCode)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .billEditPageValidationErrorCurrency)));
      return;
    }

    // Get User ID
    final authState = context.read<AuthBloc>().state;
    String? currentUserId;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context)!.billEditPageValidationErrorAuth)));
      return;
    }

    // --- Calculate Owed Amounts ---
    final additionalCosts = _getActualAdditionalCosts();
    final billEntityForCalc = BillEntity(
      id: '', // Not needed for calculation logic itself
      totalAmount:
          totalAmountFromController.toDouble(), // Main total from input
      date: parsedBillDate,
      description: _descriptionController.text.trim(),
      payerUserId: currentUserId!,
      currencyCode: currencyCode,
      items: _items,
      participants: _participants, // Current participants, will be updated
    );

    final calculateSplitBillUsecase = CalculateSplitBillUsecase();
    final updatedParticipantsWithOwedAmount = calculateSplitBillUsecase.call(
      bill: billEntityForCalc,
      actualTaxAmount: additionalCosts['tax']!,
      actualTipAmount: additionalCosts['tip']!,
      actualDiscountAmount: additionalCosts['discount']!,
    );

    // Update participants in state with owed amounts
    // This needs to happen before creating currentBillData for Firebase
    // and before setState for UI update.
    // Create a new list to ensure state update.
    final List<ParticipantEntity> finalParticipantsForStateAndFirebase =
        List.from(updatedParticipantsWithOwedAmount);

    // Create Bill Entity for saving to Firebase (includes owed amounts)
    final currentBillData = BillEntity(
      id: '', // ID will be generated by backend/storage
      totalAmount: totalAmountFromController.toDouble(),
      date: parsedBillDate,
      description: _descriptionController.text.trim(),
      payerUserId: currentUserId!,
      currencyCode: currencyCode,
      items: _items,
      participants:
          finalParticipantsForStateAndFirebase, // Use participants with owed amounts
    );

    // Create JSON Map for DISPLAY and CHATBOT
    final billMapForExternalUse = {
      'bill_date': _isoDateFormat.format(currentBillData.date),
      'description': currentBillData.description,
      'currency_code': currentBillData.currencyCode,
      'total_amount': currentBillData.totalAmount,
      'tax_amount': additionalCosts['tax']!,
      'tip_amount': additionalCosts['tip']!,
      'discount_amount': additionalCosts['discount']!,
      'items':
          currentBillData.items?.map((item) => item.toJson()).toList() ?? [],
      'participants': currentBillData.participants?.map((p) {
            return {
              'name': p.name,
              // 'percentage': p.percentage, // Percentage might be less relevant now
              'amount_owed': p.amountOwed, // Include amount_owed
            };
          }).toList() ??
          [],
    };
    const jsonEncoder = JsonEncoder.withIndent('  ');
    final generatedJson = jsonEncoder.convert(billMapForExternalUse);

    setState(() {
      _participants =
          finalParticipantsForStateAndFirebase; // Update UI with owed amounts
      _finalBillJsonString = generatedJson;
      _isEditingMode = false;
      _showSplitDetails = false;
    });

    print("Internal save complete. Dispatching save event...");
    _dispatchSaveEvent(currentBillData);
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
    final taxValue = _showTax ? (_parseNum(_taxController.text) ?? 0.0) : 0.0;
    final tipValue = _showTip ? (_parseNum(_tipController.text) ?? 0.0) : 0.0;
    final discountValue =
        _showDiscount ? (_parseNum(_discountController.text) ?? 0.0) : 0.0;

    // Calculate actual amounts based on input type
    final actualTaxAmount = _taxInputType == AmountType.percentage
        ? itemsSubtotal * (taxValue / 100.0)
        : taxValue;
    final actualTipAmount = _tipInputType == AmountType.percentage
        ? itemsSubtotal * (tipValue / 100.0)
        : tipValue;
    final actualDiscountAmount = _discountInputType == AmountType.percentage
        ? itemsSubtotal * (discountValue / 100.0)
        : discountValue;

    final newCalculatedTotal = itemsSubtotal +
        actualTaxAmount +
        actualTipAmount -
        actualDiscountAmount;
    // Update the state variable directly
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
        title: Text(AppLocalizations.of(context)!.dialogEditDescriptionTitle),
        // Use the imported widget
        content: DescriptionDialogContent(
          key: contentKey, // Assign key
          initialValue: _descriptionController.text,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(), // Return null on cancel
            child: Text(AppLocalizations.of(context)!.buttonCancel),
          ),
          TextButton(
            onPressed: () {
              // Access value via key and pop
              final value = contentKey.currentState?.currentValue;
              Navigator.of(context).pop(value);
            },
            child: Text(AppLocalizations.of(context)!.buttonSave),
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
            child: Text(AppLocalizations.of(context)!.buttonCancel),
          ),
          TextButton(
            onPressed: () {
              // Access state via key to validate and get value
              final contentState = contentKey.currentState;
              if (contentState != null && contentState.validate()) {
                Navigator.of(context).pop(contentState.currentValue);
              }
            },
            child: Text(AppLocalizations.of(context)!.buttonSave),
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
      title: AppLocalizations.of(context)!.dialogEditTotalAmountTitle,
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
      title: AppLocalizations.of(context)!.dialogEditTaxTitle,
      initialValue: _taxController.text,
      valueSuffix: _taxInputType == AmountType.percentage
          ? '%'
          : _currencyController.text, // Dynamic suffix
      allowNegative: false,
    );
    if (newValue != null && newValue != _taxController.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _taxController.text = newValue;
          });
          _recalculateAndCompareTotal();
        }
      });
    }
  }

  Future<void> _showEditTipDialog() async {
    final String? newValue = await _showEditNumericDialog(
      title: AppLocalizations.of(context)!.dialogEditTipTitle,
      initialValue: _tipController.text,
      valueSuffix: _tipInputType == AmountType.percentage
          ? '%'
          : _currencyController.text, // Dynamic suffix
      allowNegative: false,
    );
    if (newValue != null && newValue != _tipController.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _tipController.text = newValue;
          });
          _recalculateAndCompareTotal();
        }
      });
    }
  }

  Future<void> _showEditDiscountDialog() async {
    final String? newValue = await _showEditNumericDialog(
      title: AppLocalizations.of(context)!.dialogEditDiscountTitle,
      initialValue: _discountController.text,
      valueSuffix: _discountInputType == AmountType.percentage
          ? '%'
          : _currencyController.text, // Dynamic suffix
      allowNegative: false,
    );
    if (newValue != null && newValue != _discountController.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _discountController.text = newValue;
          });
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
              title: Text(
                  AppLocalizations.of(context)!.dialogAddOptionalFieldsTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CheckboxListTile(
                      title:
                          Text(AppLocalizations.of(context)!.checkboxTaxLabel),
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
                      title:
                          Text(AppLocalizations.of(context)!.checkboxTipLabel),
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
                      title: Text(
                          AppLocalizations.of(context)!.checkboxDiscountLabel),
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
                      title: Text(
                          AppLocalizations.of(context)!.checkboxCurrencyLabel),
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
                  child: Text(AppLocalizations.of(context)!.buttonDone),
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

  // --- Handlers to change input type ---
  void _setTaxInputType(AmountType type) {
    if (!_isEditingMode) return;
    setState(() {
      _taxInputType = type;
      // Potentially clear or convert the value in _taxController if switching types,
      // or let _recalculateAndCompareTotal handle the interpretation.
      // For now, just recalculate.
    });
    _recalculateAndCompareTotal();
  }

  void _setTipInputType(AmountType type) {
    if (!_isEditingMode) return;
    setState(() {
      _tipInputType = type;
    });
    _recalculateAndCompareTotal();
  }

  void _setDiscountInputType(AmountType type) {
    if (!_isEditingMode) return;
    setState(() {
      _discountInputType = type;
    });
    _recalculateAndCompareTotal();
  }

  @override
  Widget build(BuildContext context) {
    // Get the localization instance
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<BillSplittingBloc, BillSplittingState>(
      listener: (context, state) {
        if (state is BillSplittingSuccess && !_isEditingMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.billEditPageSuccessSnackbar(state.message)),
                backgroundColor: Colors.green),
          );
          // Optionally navigate away or disable further editing
        } else if (state is BillSplittingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(l10n.billEditPageSaveErrorSnackbar(state.message)),
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
          title: Text(_isEditingMode
              ? l10n.billEditPageEditTitle
              : l10n.billEditPageReviewTitle),
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
                tooltip: _isEditingMode
                    ? l10n.billEditPageSaveTooltip
                    : l10n.billEditPageEditTooltip,
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
                      child: Text(
                          l10n.billEditPageErrorParsingOcr(
                              _parsingError ?? 'Unknown error'),
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
                  // Pass input types and handlers
                  taxInputType: _taxInputType,
                  tipInputType: _tipInputType,
                  discountInputType: _discountInputType,
                  onTaxInputTypeChanged: _setTaxInputType,
                  onTipInputTypeChanged: _setTipInputType,
                  onDiscountInputTypeChanged: _setDiscountInputType,
                ),

                const Divider(), // Divider before Items section

                // --- Items Section ---
                // DEBUG PRINT STATEMENTS
                Builder(builder: (context) {
                  // Use Builder to ensure context is available for print
                  print('BillEditPage _isEditingMode: $_isEditingMode');
                  print(
                      'BillEditPage _participants: ${_participants.map((p) => 'Name: ${p.name}, ID: ${p.id}, Owed: ${p.amountOwed}').toList()}');
                  return const SizedBox.shrink(); // Does not render anything
                }),
                BillItemsSection(
                  key: ValueKey('items_${_items.hashCode}_$_isEditingMode'),
                  initialItems: _items,
                  enabled: _isEditingMode,
                  onItemsChanged: _handleItemsChanged,
                  showItemDetails:
                      _showItemDetails, // Pass the visibility state
                  allParticipants: _participants, // Pass the participants list
                ),
                const SizedBox(height: 24),
                const Divider(),

                // --- Participants Section ---
                Text(l10n.billEditPageParticipantsSectionTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                BillParticipantsSection(
                  // Use a ValueKey that primarily depends on whether the section is in editing mode.
                  // This prevents unnecessary state recreation when only the participant list content changes.
                  // The BillParticipantsSection itself will handle updates to its list via didUpdateWidget.
                  key: ValueKey('bill_participants_section_${_isEditingMode}'),
                  initialParticipants: _participants,
                  enabled: _isEditingMode,
                  currencyCode: _currencyController.text,
                  billTotalAmount: _parseNum(_totalAmountController.text)
                      ?.toDouble(), // Pass bill total for warning
                  onParticipantsChanged: (updatedParticipants) {
                    // No need to check _isEditingMode here, the callback should only be called when enabled
                    setState(() {
                      _participants = updatedParticipants;
                    });
                  },
                ),
                // const SizedBox(height: 24), // Adjusted spacing after removing split equally button
                // const Divider(), // Adjusted divider placement
                // "Split Equally" button removed as percentage logic is gone from BillParticipantsSection
                const SizedBox(height: 24), // Keep this SizedBox
                const Divider(), // Keep this Divider

                // --- Final Bill JSON Data (Show only when not editing) ---
                if (!_isEditingMode && _finalBillJsonString != null) ...[
                  JsonExpansionTile(
                    title: l10n.billEditPageFinalJsonTileTitle,
                    jsonString: _finalBillJsonString!,
                    initiallyExpanded: false,
                  ),
                  const SizedBox(height: 16),
                ],

                // --- Bill Bot Button (Show only when not editing) ---
                if (!_isEditingMode && _finalBillJsonString != null) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(l10n.billEditPageAskBillBotButtonLabel),
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
                  title: l10n.billEditPageRawJsonTileTitle,
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
