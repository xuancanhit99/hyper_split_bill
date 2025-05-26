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
import 'package:hyper_split_bill/features/bill_history/presentation/bloc/bill_history_bloc.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs for history entries

// Import newly created widgets
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/edit_dialog_content.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/edit_bill_info_section.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/json_expansion_tile.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_participant.dart'; // Import BillItemParticipant

// Enum for input type
enum AmountType { percentage, fixed }

class BillEditPage extends StatefulWidget {
  final String?
      structuredJsonString; // Receive the structured JSON string (nullable for editing history)
  final HistoricalBillEntity?
      historicalBillToEdit; // For editing an existing bill from history

  const BillEditPage({
    super.key,
    this.structuredJsonString,
    this.historicalBillToEdit,
  }) : assert(structuredJsonString != null || historicalBillToEdit != null,
            'Either structuredJsonString or historicalBillToEdit must be provided');

  @override
  State<BillEditPage> createState() => _BillEditPageState();
}

class _BillEditPageState extends State<BillEditPage> {
  // Helper class for _calculateBillDetails return type
  _BillCalculationResult? _currentCalculationResult;

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
  bool _showSplitDetails = false; // State to control split detail visibility
  String? _editingHistoricalBillId; // ID of the historical bill being edited
  String?
      _currentSupabaseBillId; // ID of the bill in Supabase (if editing an existing one or after a save)

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
      if (widget.historicalBillToEdit != null) {
        _loadDataFromHistoricalBill(widget.historicalBillToEdit!);
      } else if (widget.structuredJsonString != null) {
        _parseStructuredJson(widget.structuredJsonString!);
      } else {
        // This case should not happen due to the assert in the constructor
        setState(() {
          _parsingError =
              AppLocalizations.of(context)!.billEditPageErrorNoDataSource;
          _isInitializing = false;
        });
      }
      // Perform initial calculation *after* parsing/loading is complete
      _recalculateAndCompareTotal();
      // _isInitializing is set to false within _parseStructuredJson or _loadDataFromHistoricalBill
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

  void _loadDataFromHistoricalBill(HistoricalBillEntity historicalBill) {
    _items = [];
    _participants = [];
    _parsingError = null;
    _isInitializing = false;
    _isEditingMode = true; // Start in editing mode
    _finalBillJsonString = null;
    _editingHistoricalBillId = historicalBill
        .id; // Attempt to get firebaseBillId from the historical data.
    // This assumes finalBillDataJson might contain the original Firebase bill's ID.
    // A more robust solution would be a dedicated field in HistoricalBillEntity.
    _currentSupabaseBillId =
        historicalBill.finalBillDataJson['supabase_bill_id'] as String?;
    if (_currentSupabaseBillId == null) {
      // Fallback to 'id' if 'supabase_bill_id' is not present (for older records or other conventions)
      _currentSupabaseBillId =
          historicalBill.finalBillDataJson['id'] as String?;
      if (_currentSupabaseBillId != null) {
        print(
            "Warning: 'supabase_bill_id' not found in historical JSON, using 'id' as fallback for Supabase ID: $_currentSupabaseBillId");
      }
    }

    print(
        "Attempting to load data from HistoricalBillEntity: ${historicalBill.id}. Current Supabase Bill ID: $_currentSupabaseBillId");

    try {
      final data = historicalBill.finalBillDataJson;
      if (data == null) {
        throw Exception("finalBillDataJson is null in HistoricalBillEntity");
      }
      print("Historical bill data map: $data");

      _descriptionController.text = data['description'] as String? ??
          historicalBill.description ??
          ''; // Provide default empty string
      _totalAmountController.text =
          (data['total_amount'] as num?)?.toString() ??
              historicalBill.totalAmount.toString();

      final taxAmount = _parseNum(data['tax_amount']);
      _taxController.text = taxAmount?.toString() ?? '0.0';
      _showTax = taxAmount != null && taxAmount != 0;

      final tipAmount = _parseNum(data['tip_amount']);
      _tipController.text = tipAmount?.toString() ?? '0.0';
      _showTip = tipAmount != null && tipAmount != 0;

      final discountAmount = _parseNum(data['discount_amount']);
      _discountController.text = discountAmount?.toString() ?? '0.0';
      _showDiscount = discountAmount != null && discountAmount != 0;

      final parsedCurrency =
          data['currency_code'] as String? ?? historicalBill.currencyCode;
      String effectiveCurrency = 'USD';
      if (parsedCurrency.isNotEmpty) {
        final upperCaseCurrency = parsedCurrency.toUpperCase();
        if (upperCaseCurrency.length == 3) {
          effectiveCurrency = upperCaseCurrency;
          if (!_dropdownCurrencies.contains(effectiveCurrency)) {
            _dropdownCurrencies.add(effectiveCurrency);
            _dropdownCurrencies.sort();
          }
        }
      }
      _currencyController.text = effectiveCurrency;

      final dateString = data['bill_date'] as String? ??
          _isoDateFormat.format(historicalBill.billDate);
      if (dateString.isNotEmpty) {
        DateTime? parsedDate;
        try {
          parsedDate = _isoDateFormat.parseStrict(dateString);
        } catch (_) {
          try {
            parsedDate = DateFormat('MM/dd/yyyy').parseStrict(dateString);
          } catch (_) {
            try {
              parsedDate = DateFormat('dd/MM/yyyy').parseStrict(dateString);
            } catch (_) {
              try {
                parsedDate = _displayDateFormat.parseStrict(dateString);
              } catch (_) {
                print(
                    "Warning: Could not parse date string '$dateString' from historical bill. Using original from entity.");
                parsedDate = historicalBill.billDate;
              }
            }
          }
        }
        _dateController.text = _displayDateFormat.format(parsedDate);
      } else {
        _dateController.text =
            _displayDateFormat.format(historicalBill.billDate);
      }

      if (data['items'] is List) {
        int itemIndex = 0;
        for (var itemMap in (data['items'] as List)) {
          if (itemMap is Map<String, dynamic>) {
            try {
              List<BillItemParticipant> itemParticipants = [];
              List<String> itemParticipantIds = [];

              if (itemMap['participants'] != null &&
                  (itemMap['participants'] as List).isNotEmpty) {
                // Ưu tiên trường 'participants' nếu có
                itemParticipants = (itemMap['participants'] as List<dynamic>)
                    .map((pMap) {
                      if (pMap is Map<String, dynamic>) {
                        return BillItemParticipant.fromJson(pMap);
                      }
                      return null;
                    })
                    .whereType<BillItemParticipant>()
                    .toList();
                itemParticipantIds =
                    itemParticipants.map((p) => p.participantId).toList();
              } else if (itemMap['participant_ids'] != null &&
                  (itemMap['participant_ids'] as List).isNotEmpty) {
                // Nếu không, sử dụng 'participant_ids' và tạo BillItemParticipant với trọng số mặc định
                itemParticipantIds =
                    (itemMap['participant_ids'] as List<dynamic>)
                        .cast<String>()
                        .toList();
                itemParticipants = itemParticipantIds
                    .map((id) =>
                        BillItemParticipant(participantId: id, weight: 1))
                    .toList();
              }

              _items.add(BillItemEntity(
                id: itemMap['id'] as String? ?? 'temp_hist_item_${itemIndex++}',
                description: itemMap['description'] as String? ??
                    AppLocalizations.of(context)!
                        .billEditPageDefaultItemDescription,
                quantity: _parseNum(itemMap['quantity'], allowNegative: false)
                        ?.toInt() ??
                    1,
                unitPrice: _parseNum(itemMap['unit_price'])?.toDouble() ?? 0.0,
                totalPrice:
                    _parseNum(itemMap['total_price'])?.toDouble() ?? 0.0,
                participantIds:
                    itemParticipantIds, // Sử dụng ID đã lấy hoặc tạo
                participants:
                    itemParticipants, // Sử dụng người tham gia đã phân tích cú pháp hoặc tạo
              ));
            } catch (e, s) {
              print(
                  "Error parsing item map from historical bill: $itemMap. Error: $e\nStackTrace: $s");
            }
          }
        }
      }

      if (data['participants'] is List) {
        for (var pMap in (data['participants'] as List)) {
          if (pMap is Map<String, dynamic>) {
            try {
              final String participantId = pMap['id'] as String? ??
                  'temp_hist_p_${_participants.length}';
              _participants.add(ParticipantEntity(
                id: participantId,
                name: pMap['name'] as String? ??
                    AppLocalizations.of(context)!
                        .billEditPageDefaultParticipantName,
                amountOwed: _parseNum(pMap['amount_owed'])?.toDouble(),
              ));
            } catch (e, s) {
              print(
                  "Error parsing participant map from historical bill: $pMap. Error: $e\nStackTrace: $s");
            }
          }
        }
      }

      if (historicalBill.rawOcrJson != null) {
        try {
          _ocrTextController.text = const JsonEncoder.withIndent('  ')
              .convert(historicalBill.rawOcrJson);
        } catch (e) {
          _ocrTextController.text = "Error displaying raw OCR JSON: $e";
        }
      } else {
        _ocrTextController.text = AppLocalizations.of(context)!
            .billEditPageNoRawOcrData; // Placeholder, add to .arb
      }

      setState(() {});
    } catch (e, s) {
      print("Error loading data from HistoricalBillEntity: $e\nStackTrace: $s");
      setState(() {
        _parsingError = AppLocalizations.of(context)!
            .billEditPageErrorLoadingHistorical(e.toString()); // Placeholder
      });
    }
    _recalculateAndCompareTotal();
    _isInitializing = false; // Ensure this is set
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
    // BillSplittingBloc._onSaveBill will determine create vs update
    // based on whether billToSave.id is populated.
    print(
        "Dispatching SaveBillEvent. Bill ID to send: '${billToSave.id}', User ID: ${billToSave.payerUserId}");
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

  _BillCalculationResult? _calculateBillDetails() {
    final l10n = AppLocalizations.of(context)!;
    final totalAmountFromController = _parseNum(_totalAmountController.text);
    final currencyCode = _currencyController.text.trim().toUpperCase();

    if (totalAmountFromController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.billEditPageValidationErrorTotalAmount)));
      return null;
    }

    // Removed validation for unassignedItems as per user request
    // final unassignedItems =
    //     _items.where((item) => item.participantIds.isEmpty).toList();
    // if (unassignedItems.isNotEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     content: Text(l10n.billEditPageErrorUnassignedItems(
    //         unassignedItems.length, unassignedItems.first.description)),
    //   ));
    //   return null;
    // }

    // Removed validation for empty participants list as per user request
    // if (_participants.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     content: Text(l10n.billEditPageErrorNoParticipants),
    //   ));
    //   return null;
    // }

    DateTime? parsedBillDate;
    try {
      parsedBillDate = _displayDateFormat.parseStrict(_dateController.text);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context)!.billEditPageValidationErrorDate)));
      return null;
    }

    if (!_dropdownCurrencies.contains(currencyCode)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .billEditPageValidationErrorCurrency)));
      return null;
    }

    final authState = context.read<AuthBloc>().state;
    String? currentUserId;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context)!.billEditPageValidationErrorAuth)));
      return null;
    }

    final additionalCosts = _getActualAdditionalCosts();
    final billEntityForCalc = BillEntity(
      id: '', // Not needed for calculation logic itself
      totalAmount: totalAmountFromController.toDouble(),
      date: parsedBillDate,
      description: _descriptionController.text.trim(),
      payerUserId: currentUserId!,
      currencyCode: currencyCode,
      items: _items,
      participants: _participants,
    );

    final calculateSplitBillUsecase = CalculateSplitBillUsecase();
    final updatedParticipantsWithOwedAmount = calculateSplitBillUsecase.call(
      bill: billEntityForCalc,
      actualTaxAmount: additionalCosts['tax']!,
      actualTipAmount: additionalCosts['tip']!,
      actualDiscountAmount: additionalCosts['discount']!,
    );

    // Merge updated owed amounts with original participant data to preserve color, etc.
    final List<ParticipantEntity> finalParticipantsForState =
        _participants.map((originalParticipant) {
      final updatedInfo = updatedParticipantsWithOwedAmount.firstWhere(
        (updatedP) => updatedP.id == originalParticipant.id,
        // If an original participant is somehow not in the updated list (should not happen),
        // return the original one. This case needs to be reviewed if it occurs.
        orElse: () {
          print(
              "Warning: Original participant ID ${originalParticipant.id} not found in updated list from usecase.");
          return originalParticipant;
        },
      );
      return originalParticipant.copyWith(
        amountOwed: updatedInfo.amountOwed,
        // If CalculateSplitBillUsecase also modifies other fields like 'percentage',
        // ensure they are copied here too. For now, it primarily sets 'amountOwed'.
      );
    }).toList();

    final String billIdForSave;
    if (_currentSupabaseBillId != null && _currentSupabaseBillId!.isNotEmpty) {
      billIdForSave = _currentSupabaseBillId!;
    } else {
      billIdForSave = '';
    }

    final billDataForSavingOrEvent = BillEntity(
      id: billIdForSave,
      totalAmount: totalAmountFromController.toDouble(),
      date: parsedBillDate,
      description: _descriptionController.text.trim(),
      payerUserId: currentUserId!,
      currencyCode: currencyCode,
      items: _items,
      participants: finalParticipantsForState,
    );

    final billMapForExternalUse = {
      'bill_date': _isoDateFormat.format(billDataForSavingOrEvent.date),
      'description': billDataForSavingOrEvent.description,
      'currency_code': billDataForSavingOrEvent.currencyCode,
      'total_amount': billDataForSavingOrEvent.totalAmount,
      'tax_amount': additionalCosts['tax']!,
      'tip_amount': additionalCosts['tip']!,
      'discount_amount': additionalCosts['discount']!,
      'items': billDataForSavingOrEvent.items
              ?.map((item) => item.toJson())
              .toList() ??
          [],
      'participants': billDataForSavingOrEvent.participants?.map((p) {
            return {
              'id': p.id, // Ensure ID is included for item assignment linking
              'name': p.name,
              'amount_owed': p.amountOwed,
            };
          }).toList() ??
          [],
      // Include Supabase ID if available, for consistency in JSON output
      if (billDataForSavingOrEvent.id.isNotEmpty)
        'supabase_bill_id': billDataForSavingOrEvent.id,
    };
    const jsonEncoder = JsonEncoder.withIndent('  ');
    final generatedJson = jsonEncoder.convert(billMapForExternalUse);

    return _BillCalculationResult(
      billEntity: billDataForSavingOrEvent,
      finalBillJson: generatedJson,
      updatedParticipants: finalParticipantsForState,
    );
  }

  void _handleShowResultButton() {
    final calculationResult = _calculateBillDetails();
    if (calculationResult != null) {
      setState(() {
        _participants = calculationResult.updatedParticipants;
        _finalBillJsonString = calculationResult.finalBillJson;
        _isEditingMode = false;
        _showSplitDetails = false; // Reset this as well
        _currentCalculationResult =
            calculationResult; // Store for potential save later
      });
      // DO NOT dispatch save event here
    }
  }

  void _handleSaveAppBarButton() {
    final calculationResult = _currentCalculationResult ??
        _calculateBillDetails(); // Recalculate if not already done or if changes were made after review

    if (calculationResult != null) {
      // Update state with potentially recalculated participants before saving
      // This ensures that if user edited something after review and hit save directly,
      // the latest calculations are used.
      setState(() {
        _participants = calculationResult.updatedParticipants;
        _finalBillJsonString = calculationResult.finalBillJson;
        // DO NOT change _isEditingMode here
      });
      print(
          "Save AppBar button pressed. Dispatching save event to BillSplittingBloc...");
      _dispatchSaveEvent(calculationResult.billEntity);
      // SnackBar for "Saved" will be handled by BlocListener on BillSplittingSuccess
    }
  }

  // --- Split Equally Logic ---
  void _splitEqually() {
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(AppLocalizations.of(context)!.billEditPageErrorNoParticipants),
      ));
      return;
    }

    // Filter participants to include only those with non-null IDs
    final validParticipants = _participants.where((p) => p.id != null).toList();

    if (validParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!
            .billEditPageErrorNoParticipants), // Re-use the no participants message
      ));
      return;
    }

    // Create updated items with all valid participants assigned with weight 1
    final updatedItems = _items.map((item) {
      final itemParticipants = validParticipants
          .map((p) => BillItemParticipant(
              participantId: p.id!, weight: 1)) // Use non-null id!
          .toList();
      final participantIds =
          validParticipants.map((p) => p.id!).toList(); // Use non-null id!

      return item.copyWith(
        participants: itemParticipants,
        participantIds: participantIds,
      );
    }).toList();

    setState(() {
      _items = updatedItems;
    });

    // Immediately trigger calculation and show result
    setState(() {
      _items = updatedItems;
    });
    _handleShowResultButton(); // This will calculate and switch to review mode
  }

  void _toggleEditMode() {
    setState(() {
      _isEditingMode = !_isEditingMode;
      if (_isEditingMode) {
        _finalBillJsonString = null;
        _showSplitDetails = false;
        _currentCalculationResult =
            null; // Clear stored result when going back to edit
      } else {
        // If switching to review mode (e.g. from an external trigger, though not current flow)
        // ensure calculation is fresh if _currentCalculationResult is null.
        if (_currentCalculationResult == null) {
          final calculationResult = _calculateBillDetails();
          if (calculationResult != null) {
            _participants = calculationResult.updatedParticipants;
            _finalBillJsonString = calculationResult.finalBillJson;
            _currentCalculationResult = calculationResult;
          } else {
            _isEditingMode = true; // Stay in edit mode if calculation fails
          }
        } else {
          // Use existing stored calculation
          _participants = _currentCalculationResult!.updatedParticipants;
          _finalBillJsonString = _currentCalculationResult!.finalBillJson;
        }
      }
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
        if (state is BillSplittingSuccess) {
          // This listener handles successful saves triggered by _handleSaveAppBarButton
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.billEditPageSuccessSnackbar(state.message)),
                backgroundColor: Colors.green),
          );

          if (state.billEntity?.id != null &&
              state.billEntity!.id!.isNotEmpty) {
            _currentSupabaseBillId = state.billEntity!.id;
            print(
                "Updated _currentSupabaseBillId from BLoC success: $_currentSupabaseBillId");
          }

          final authState = context.read<AuthBloc>().state;
          String? currentUserId;
          if (authState is AuthAuthenticated) {
            currentUserId = authState.user.id;
          }

          if (currentUserId != null && state.billEntity != null) {
            final billToSaveInHistory = state.billEntity!;
            final additionalCosts = _getActualAdditionalCosts();
            final billMapForHistoryJson = {
              'bill_date': _isoDateFormat.format(billToSaveInHistory.date),
              'description': billToSaveInHistory.description,
              'currency_code': billToSaveInHistory.currencyCode,
              'total_amount': billToSaveInHistory.totalAmount,
              'tax_amount': additionalCosts['tax']!,
              'tip_amount': additionalCosts['tip']!,
              'discount_amount': additionalCosts['discount']!,
              'items': billToSaveInHistory.items
                      ?.map((item) => item.toJson())
                      .toList() ??
                  [],
              'participants': (billToSaveInHistory.participants ?? []).map((p) {
                // Ensure participants is always a list
                return {
                  'id': p.id,
                  'name': p.name,
                  'amount_owed': p.amountOwed,
                };
              }).toList(), // .toList() handles empty list correctly
              'supabase_bill_id': billToSaveInHistory.id,
            };
            print(
                "Saving to history with Supabase Bill ID: ${billToSaveInHistory.id}");

            HistoricalBillEntity historicalBill;
            if (_editingHistoricalBillId != null) {
              historicalBill = HistoricalBillEntity(
                id: _editingHistoricalBillId!,
                userId: currentUserId,
                description: billToSaveInHistory.description,
                totalAmount: billToSaveInHistory.totalAmount,
                currencyCode: billToSaveInHistory.currencyCode ?? 'USD',
                billDate: billToSaveInHistory.date,
                rawOcrJson: (() {
                  try {
                    return jsonDecode(_ocrTextController.text)
                        as Map<String, dynamic>?;
                  } catch (e) {
                    print("Error decoding rawOcrJson for history: $e");
                    return null;
                  }
                })(),
                finalBillDataJson: billMapForHistoryJson,
                createdAt: widget.historicalBillToEdit?.createdAt ??
                    DateTime.now(), // Preserve original if possible
                updatedAt: DateTime.now(),
              );
              context
                  .read<BillHistoryBloc>()
                  .add(UpdateBillInHistoryEvent(historicalBill));
              print(
                  "Updating existing historical bill: $_editingHistoricalBillId");
            } else {
              historicalBill = HistoricalBillEntity(
                id: const Uuid().v4(),
                userId: currentUserId,
                description: billToSaveInHistory.description,
                totalAmount: billToSaveInHistory.totalAmount,
                currencyCode: billToSaveInHistory.currencyCode ?? 'USD',
                billDate: billToSaveInHistory.date,
                rawOcrJson: (() {
                  try {
                    return jsonDecode(_ocrTextController.text)
                        as Map<String, dynamic>?;
                  } catch (e) {
                    print("Error decoding rawOcrJson for history: $e");
                    return null;
                  }
                })(),
                finalBillDataJson: billMapForHistoryJson,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              context
                  .read<BillHistoryBloc>()
                  .add(SaveBillToHistoryEvent(historicalBill));
              print("Creating new historical bill");
            }
            print(
                "Dispatched BillHistoryEvent for bill ID (original): ${billToSaveInHistory.id}, History ID: ${historicalBill.id}");

            // Navigate to Bill History page immediately after successful save
            if (mounted) {
              context.go(AppRoutes.history);
            }
          } else {
            print(
                "Could not save to history: User ID or BillEntity is null after BillSplittingSuccess.");
          }
        } else if (state is BillSplittingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(l10n.billEditPageSaveErrorSnackbar(state.message)),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
          // If save fails, user remains in edit mode.
          // If they were in review mode and somehow triggered a save that failed (not standard flow now),
          // they should arguably be returned to edit mode.
          if (!_isEditingMode) {
            setState(() {
              _isEditingMode = true;
            });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditingMode
              ? l10n.billEditPageEditTitle
              : l10n.billEditPageReviewTitle),
          actions: [
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
            // Always show Save button on AppBar, regardless of mode.
            // Tooltip might change based on whether it's a new save or update.
            else
              IconButton(
                icon: const Icon(Icons.save_outlined),
                tooltip: (_currentSupabaseBillId != null &&
                            _currentSupabaseBillId!.isNotEmpty) ||
                        (_editingHistoricalBillId != null)
                    ? l10n.billEditPageUpdateTooltip // "Update Bill"
                    : l10n.billEditPageSaveTooltip, // "Save Bill"
                onPressed:
                    _handleSaveAppBarButton, // Always calls save function
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
                          _parsingError ??
                              AppLocalizations.of(context)!
                                  .billEditPageErrorUnknown, // Placeholder
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                )
              else ...[
                // Show different content based on editing mode
                if (_isEditingMode) ...[
                  // EDITING MODE - Show interactive components
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
                    allParticipants:
                        _participants, // Pass the participants list
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
                    key:
                        ValueKey('bill_participants_section_${_isEditingMode}'),
                    initialParticipants: _participants,
                    enabled: _isEditingMode,
                    currencyCode: _currencyController.text,
                    billTotalAmount: _parseNum(_totalAmountController.text)
                        ?.toDouble(), // Pass bill total for warning
                    onParticipantsChanged: (updatedParticipants) {
                      // This callback is for when names are edited, or participants are added/removed.
                      // The list structure might change.
                      if (!mounted) return;
                      setState(() {
                        _participants = List.from(updatedParticipants);

                        // After participants are updated, filter out removed participants from items
                        final updatedItems = _items.map((item) {
                          final validItemParticipants = item.participants
                              .where((itemParticipant) =>
                                  updatedParticipants.any((p) =>
                                      p.id == itemParticipant.participantId))
                              .toList();
                          final validParticipantIds = validItemParticipants
                              .map((p) => p.participantId)
                              .toList();

                          return item.copyWith(
                            participants: validItemParticipants,
                            participantIds: validParticipantIds,
                          );
                        }).toList();
                        _items = updatedItems;
                        _recalculateAndCompareTotal();
                      });
                    },
                    onParticipantsUpdated: (updatedParticipantsWithColors) {
                      // This callback is specifically for when BPS updates colors or other internal
                      // states that BillEditPage needs to be aware of for its children (like BillItemsSection).
                      if (!mounted) return;

                      // Check if there's an actual change to avoid unnecessary rebuilds
                      bool changed = false;
                      if (_participants.length !=
                          updatedParticipantsWithColors.length) {
                        changed = true;
                      } else {
                        for (int i = 0; i < _participants.length; i++) {
                          if (_participants[i].id !=
                                  updatedParticipantsWithColors[i].id ||
                              _participants[i].name !=
                                  updatedParticipantsWithColors[i].name ||
                              _participants[i].color !=
                                  updatedParticipantsWithColors[i].color ||
                              _participants[i].amountOwed !=
                                  updatedParticipantsWithColors[i].amountOwed) {
                            changed = true;
                            break;
                          }
                        }
                      }

                      if (changed) {
                        print(
                            "[BillEditPage] onParticipantsUpdated from BPS. Updating _participants and rebuilding.");
                        setState(() {
                          // Crucially update _participants here so BillItemsSection gets the colored list
                          _participants =
                              List.from(updatedParticipantsWithColors);
                        });
                      } else {
                        print(
                            "[BillEditPage] onParticipantsUpdated from BPS. No effective change detected in _participants list content, not forcing setState.");
                      }
                    },
                  ),
                  const SizedBox(
                      height: 24), // Add spacing after participants section

                  // Action Buttons Section - Only in editing mode
                  OutlinedButton(
                    onPressed: _splitEqually,
                    child: Text(l10n.billEditPageSplitEquallyButtonLabel(
                        _participants.length)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleShowResultButton,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(l10n.billEditPageResultButtonLabel),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  // REVIEW MODE - Show clean, read-only bill receipt
                  // Summary Section - Bill interface at the top
                  if (_finalBillJsonString != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bill Header
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _descriptionController.text.isNotEmpty
                                          ? _descriptionController.text
                                          : 'Bill Receipt',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _dateController.text,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _currencyController.text,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Divider(),

                          // Items Summary
                          if (_items.isNotEmpty) ...[
                            Text(
                              'Items',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ...(_items.map((item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.quantity}x ${item.description}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatCurrencyValue(
                                                item.totalPrice),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                      // Hiển thị các chấm tròn màu sắc cho người tham gia
                                      if (item.participantIds.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const SizedBox(
                                                width: 8), // Indent nhẹ
                                            ...item.participantIds
                                                .map((participantId) {
                                              // Tìm participant tương ứng để lấy màu
                                              final participant =
                                                  _participants.firstWhere(
                                                (p) => p.id == participantId,
                                                orElse: () => ParticipantEntity(
                                                    id: participantId,
                                                    name: '',
                                                    color: Theme.of(context)
                                                        .primaryColor),
                                              );

                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    right: 6),
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: participant.color ??
                                                      Theme.of(context)
                                                          .primaryColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ))),
                            const SizedBox(height: 12),
                            const Divider(),
                          ],

                          // Additional costs
                          Builder(builder: (context) {
                            final additionalCosts = _getActualAdditionalCosts();
                            final itemsSubtotal = _items.fold(
                                0.0, (sum, item) => sum + item.totalPrice);

                            return Column(
                              children: [
                                // Subtotal
                                if (_items.isNotEmpty) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Subtotal',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        _formatCurrencyValue(itemsSubtotal),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                // Tax
                                if (_showTax &&
                                    additionalCosts['tax']! > 0) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Tax',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        _formatCurrencyValue(
                                            additionalCosts['tax']),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                // Tip
                                if (_showTip &&
                                    additionalCosts['tip']! > 0) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Tip',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        _formatCurrencyValue(
                                            additionalCosts['tip']),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                // Discount
                                if (_showDiscount &&
                                    additionalCosts['discount']! > 0) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Discount',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.green[600],
                                            ),
                                      ),
                                      Text(
                                        '-${_formatCurrencyValue(additionalCosts['discount'])}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.green[600],
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                const Divider(thickness: 2),
                                const SizedBox(height: 8),

                                // Total
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'TOTAL',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '${_currencyController.text} ${_formatCurrencyValue(_parseNum(_totalAmountController.text))}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }),

                          // Participants summary
                          if (_participants.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Divider(),
                            Text(
                              'Split Between',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),

                            // Show warnings only (before the styled participant cards)
                            BillParticipantsSection(
                              key: ValueKey(
                                  'bill_participants_section_warning_${_isEditingMode}'),
                              initialParticipants: _participants,
                              enabled: false, // Read-only in review mode
                              currencyCode: _currencyController.text,
                              billTotalAmount:
                                  _parseNum(_totalAmountController.text)
                                      ?.toDouble(),
                              onParticipantsChanged: (updatedParticipants) {
                                // No-op in review mode
                              },
                              onParticipantsUpdated:
                                  (updatedParticipantsWithColors) {
                                // No-op in review mode
                              },
                            ),

                            const SizedBox(height: 12),
                            ...(_participants.map((participant) => Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        participant.color?.withOpacity(0.1) ??
                                            Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          participant.color?.withOpacity(0.3) ??
                                              Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: participant.color ??
                                                  Theme.of(context)
                                                      .primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            participant.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${_currencyController.text} ${_formatCurrencyValue(participant.amountOwed)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: participant.color ??
                                                  Theme.of(context)
                                                      .primaryColor,
                                            ),
                                      ),
                                    ],
                                  ),
                                ))),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Buttons Section - At the bottom in review mode
                  // Edit Button - styled to match Ask Bill Bot
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: Text(
                        l10n.billEditPageEditButtonLabel,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      onPressed: _toggleEditMode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  // Ask Bill Bot Button
                  if (_finalBillJsonString != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        label: Text(
                          l10n.billEditPageAskBillBotButtonLabel,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        onPressed: () {
                          context.push(AppRoutes.chatbot,
                              extra: _finalBillJsonString);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Helper class for _calculateBillDetails return type
class _BillCalculationResult {
  final BillEntity billEntity;
  final String finalBillJson;
  final List<ParticipantEntity> updatedParticipants;

  _BillCalculationResult({
    required this.billEntity,
    required this.finalBillJson,
    required this.updatedParticipants,
  });
}
// Placeholder for localization strings to be added to .arb files:
// billEditPageErrorNoDataSource: "No data source provided to edit the bill."
// billEditPageNoRawOcrData: "No raw OCR data available for this historical bill."
// billEditPageErrorLoadingHistorical: "Error loading bill from history: {error}"
// billEditPageUpdateTooltip: "Update Bill"
// billEditPageSaveTooltip: "Save Bill" (New or ensure it exists)
// billEditPageEditTooltip: "Edit Bill" (Ensure it exists)
// billEditPageResultButtonLabel: "Show Result" (Ensure it exists or update)
// billEditPageUpdateButtonLabel: "Update Bill" // This might be redundant if AppBar tooltip covers "Update"
// billEditPageErrorUnknown: "An unknown error occurred."
