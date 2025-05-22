import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'dart:math'; // Import for Random

// Helper to format currency
String _formatCurrencyValue(num? value) {
  if (value == null) return '';
  final format = NumberFormat('0.##'); // Removes trailing zeros
  return format.format(value);
}

class BillParticipantsSection extends StatefulWidget {
  final List<ParticipantEntity> initialParticipants;
  final bool enabled; // Controls edit vs review mode
  final Function(List<ParticipantEntity>) onParticipantsChanged;
  final String?
      currencyCode; // Still needed for review mode display of amountOwed
  final double?
      billTotalAmount; // For review mode, to check if all costs are allocated

  const BillParticipantsSection({
    super.key,
    required this.initialParticipants,
    required this.onParticipantsChanged,
    this.enabled = true,
    this.currencyCode,
    this.billTotalAmount, // Added for warning display
  });

  @override
  State<BillParticipantsSection> createState() =>
      _BillParticipantsSectionState();
}

class _BillParticipantsSectionState extends State<BillParticipantsSection> {
  late List<ParticipantEntity> _participants;
  final Random _random = Random(); // For generating unique IDs

  // Define a list of colors for participants
  final List<Color> _availableColors = [
    Colors.blue.shade300,
    Colors.green.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.red.shade300,
    Colors.teal.shade300,
    Colors.pink.shade300,
    Colors.amber.shade300,
    Colors.indigo.shade300,
    Colors.cyan.shade300,
    Colors.lime.shade300,
    Colors.brown.shade300,
  ];
  int _nextColorIndex = 0;

  Color _getNextColor() {
    print('[BPS] _getNextColor: current _nextColorIndex = $_nextColorIndex');
    final color = _availableColors[_nextColorIndex % _availableColors.length];
    _nextColorIndex++;
    print(
        '[BPS] _getNextColor: assigned color $color, new _nextColorIndex = $_nextColorIndex');
    return color;
  }

  @override
  void initState() {
    super.initState();
    print('[BPS] initState: initial _nextColorIndex = $_nextColorIndex');
    _initializeState(widget.initialParticipants, isInitialCall: true);
    print(
        '[BPS] initState: _participants after init: ${_participants.map((p) => '${p.name}:${p.color}').toList()}');
  }

  @override
  void didUpdateWidget(covariant BillParticipantsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('[BPS] didUpdateWidget called.');
    print(
        '[BPS] didUpdateWidget: oldParticipants: ${oldWidget.initialParticipants.map((p) => '${p.name}:${p.id}:${p.color}').toList()}');
    print(
        '[BPS] didUpdateWidget: newParticipants from widget: ${widget.initialParticipants.map((p) => '${p.name}:${p.id}:${p.color}').toList()}');
    print(
        '[BPS] didUpdateWidget: current _participants state before potential init: ${_participants.map((p) => '${p.name}:${p.id}:${p.color}').toList()}');

    if (widget.initialParticipants != oldWidget.initialParticipants ||
        widget.enabled != oldWidget.enabled ||
        widget.billTotalAmount != oldWidget.billTotalAmount ||
        widget.currencyCode != oldWidget.currencyCode) {
      print('[BPS] didUpdateWidget: Conditions met, calling _initializeState.');
      _initializeState(widget.initialParticipants, isInitialCall: false);
      print(
          '[BPS] didUpdateWidget: _participants after init: ${_participants.map((p) => '${p.name}:${p.id}:${p.color}').toList()}');
    } else {
      print(
          '[BPS] didUpdateWidget: Conditions NOT met, _initializeState not called.');
    }
  }

  void _initializeState(List<ParticipantEntity> initialParticipantsFromWidget,
      {bool isInitialCall = false}) {
    print('[BPS] _initializeState: Called with isInitialCall = $isInitialCall');
    print(
        '[BPS] _initializeState: _nextColorIndex at start = $_nextColorIndex');
    print(
        '[BPS] _initializeState: Received initialParticipantsFromWidget: ${initialParticipantsFromWidget.map((p) => '${p.name}:${p.id}:${p.color}').toList()}');

    if (isInitialCall) {
      _nextColorIndex = 0;
      print(
          '[BPS] _initializeState: Reset _nextColorIndex to 0 due to isInitialCall=true');
    }

    Map<String, Color> existingColorsMap = {};
    // Only try to preserve if not the initial call AND _participants is already initialized and not empty.
    if (!isInitialCall && mounted && _participants.isNotEmpty) {
      for (var p_old in _participants) {
        if (p_old.id != null && p_old.color != null) {
          existingColorsMap[p_old.id!] = p_old.color!;
        }
      }
      print(
          '[BPS] _initializeState: Populated existingColorsMap: $existingColorsMap');
    } else {
      print(
          '[BPS] _initializeState: Not populating existingColorsMap (isInitialCall=$isInitialCall or _participants was empty/not mounted)');
    }

    _participants = initialParticipantsFromWidget.map((p_new) {
      print(
          '[BPS] _initializeState mapping: Processing p_new = ${p_new.name}:${p_new.id}:${p_new.color}');
      final participantId = (p_new.id == null || p_new.id!.isEmpty)
          ? _generateUniqueParticipantId()
          : p_new
              .id!; // Assert non-null as it's either generated or from p_new.id

      Color? determinedColor;
      if (p_new.color != null) {
        determinedColor = p_new.color;
        print(
            '[BPS] _initializeState mapping: Using p_new.color for ${p_new.name}: $determinedColor');
      } else if (existingColorsMap.containsKey(participantId)) {
        determinedColor = existingColorsMap[participantId];
        print(
            '[BPS] _initializeState mapping: Using existingColor for ${p_new.name} (ID: $participantId): $determinedColor');
      } else {
        determinedColor = _getNextColor();
        print(
            '[BPS] _initializeState mapping: Called _getNextColor for ${p_new.name}: $determinedColor');
      }

      return p_new.copyWith(id: participantId, color: determinedColor);
    }).toList();
    print(
        '[BPS] _initializeState: Final _participants: ${_participants.map((p) => '${p.name}:${p.id}:${p.color}').toList()}');
    print('[BPS] _initializeState: _nextColorIndex at end = $_nextColorIndex');
  }

  // Removed _updateControllerTexts, _distributePercentages, _listEquals,
  // _handlePercentageChange, _handleLockChange

  String _generateUniqueParticipantId() {
    return 'p_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
  }

  Future<void> _addParticipantDialog() async {
    final nameController = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
              AppLocalizations.of(context)!.participantSectionAddDialogTitle),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!
                    .participantSectionAddDialogHint),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.buttonCancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!
                  .participantSectionAddDialogButton),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  if (!_participants
                      .any((p) => p.name.toLowerCase() == name.toLowerCase())) {
                    final newParticipantId = _generateUniqueParticipantId();
                    // _getNextColor() will use and increment the persistent _nextColorIndex
                    final newParticipantColor = _getNextColor();
                    print(
                        '[BPS] _addParticipantDialog: Adding ${name} with ID $newParticipantId and color $newParticipantColor. Current _nextColorIndex: $_nextColorIndex');
                    final newParticipant = ParticipantEntity(
                      id: newParticipantId,
                      name: name,
                      color: newParticipantColor,
                    );
                    setState(() {
                      _participants.add(newParticipant);
                    });
                    widget.onParticipantsChanged(List.from(
                        _participants)); // Inform parent about the change
                    print(
                        '[BPS] _addParticipantDialog: _participants after adding: ${_participants.map((p) => '${p.name}:${p.id}:${p.color}').toList()}');
                    Navigator.of(dialogContext).pop();
                  } else {
                    Navigator.of(dialogContext).pop(); // Close dialog first
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .participantSectionExistsSnackbar(name))),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _removeParticipant(ParticipantEntity participant) {
    if (_participants.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .participantSectionCannotRemoveLastSnackbar)),
      );
      return;
    }
    if (participant.id == null) return;

    setState(() {
      _participants.removeWhere((p) => p.id == participant.id);
    });
    widget.onParticipantsChanged(List.from(_participants));
  }

  @override
  void dispose() {
    // No controllers to dispose anymore
    super.dispose();
  }

  // Removed _disposeControllers

  @override
  Widget build(BuildContext context) {
    // Get the localization instance
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row (Only for Review Mode, if participants exist)
        if (_participants.isNotEmpty && !widget.enabled)
          Padding(
            padding: const EdgeInsets.only(
                bottom: 4.0, right: 40.0), // Align with remove button space
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text(l10n.participantSectionHeaderName,
                        style: Theme.of(context).textTheme.labelSmall)),
                Expanded(
                    flex: 2,
                    child: Text(l10n.participantSectionHeaderAmount,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelSmall)),
              ],
            ),
          ),
        // Warning for unallocated costs in review mode
        if (!widget.enabled &&
            widget.billTotalAmount != null &&
            _participants.isNotEmpty)
          _buildUnallocatedCostWarning(l10n),
        if (_participants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              widget.enabled
                  ? l10n.participantSectionEmptyListEdit
                  : l10n.participantSectionEmptyListReview,
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true, // Important for Column/ListView nesting
            physics:
                const NeverScrollableScrollPhysics(), // Disable scrolling within the list
            itemCount: _participants.length,
            itemBuilder: (context, index) {
              final participant = _participants[index];
              return widget.enabled
                  ? _buildEditModeRow(l10n, participant)
                  : _buildReviewModeRow(participant);
            },
          ),
        const SizedBox(height: 8),
        if (widget.enabled)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: Text(l10n.participantSectionAddButtonLabel),
              onPressed: _addParticipantDialog,
            ),
          ),
      ],
    );
  }

  // Builds a row for Edit Mode (Simplified)
  Widget _buildEditModeRow(
      AppLocalizations l10n, ParticipantEntity participant) {
    final bool canRemove = _participants.length >
        0; // Allow removing even if it's the last one, BillEditPage will validate on save.

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: participant.color ?? Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    participant.name,
                    style: const TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40, // Keep consistent width for alignment
            child: canRemove
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                    color: Colors.red[400],
                    tooltip:
                        l10n.participantSectionRemoveTooltip(participant.name),
                    onPressed: () => _removeParticipant(participant),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : const SizedBox(
                    width:
                        40), // Placeholder if not removable (though now always removable from UI here)
          ),
        ],
      ),
    );
  }

  // Builds a row for Review Mode (Simplified - amountOwed is primary)
  Widget _buildReviewModeRow(ParticipantEntity participant) {
    String displayAmount = '';
    if (participant.amountOwed != null) {
      displayAmount =
          '${_formatCurrencyValue(participant.amountOwed)} ${widget.currencyCode ?? ''}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: participant.color ?? Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    participant.name,
                    style: const TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8), // Spacer
          Expanded(
            flex: 2,
            child: Text(
              displayAmount,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Placeholder for remove button alignment (if header has one, or for consistency)
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildUnallocatedCostWarning(AppLocalizations l10n) {
    final double totalOwedByParticipants =
        _participants.fold(0.0, (sum, p) => sum + (p.amountOwed ?? 0.0));
    final double billTotal = widget.billTotalAmount ?? 0.0;

    // Using a small epsilon for floating point comparison
    if ((billTotal - totalOwedByParticipants).abs() > 0.01 && billTotal > 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
        child: Text(
          l10n.billEditPageWarningUnallocatedCost(
            _formatCurrencyValue(totalOwedByParticipants),
            _formatCurrencyValue(billTotal),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink(); // No warning needed
  }
}
