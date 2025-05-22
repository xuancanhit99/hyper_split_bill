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
        '[BPS] _initializeState: Received initialParticipantsFromWidget: ${initialParticipantsFromWidget.map((p) => '${p.name}:${p.id}:${p.color}').toList()}');

    Set<Color> colorsCurrentlyInUse = initialParticipantsFromWidget
        .where((p) => p.color != null)
        .map((p) => p.color!)
        .toSet();

    int localNextColorAssignIndex = 0;
    if (colorsCurrentlyInUse.isNotEmpty) {
      int highestUsedIndexInAvailableColors = -1;
      for (int i = 0; i < _availableColors.length; i++) {
        if (colorsCurrentlyInUse.contains(_availableColors[i])) {
          if (i > highestUsedIndexInAvailableColors) {
            highestUsedIndexInAvailableColors = i;
          }
        }
      }
      localNextColorAssignIndex = (highestUsedIndexInAvailableColors + 1);
    }
    print(
        '[BPS] _initializeState: Initial localNextColorAssignIndex set to $localNextColorAssignIndex.');

    Map<String, Color> existingColorsMapFromOldState = {};
    if (!isInitialCall && mounted && _participants.isNotEmpty) {
      for (var p_old in _participants) {
        if (p_old.id != null && p_old.color != null) {
          bool newHasColorForThisId = initialParticipantsFromWidget
              .any((p_new) => p_new.id == p_old.id && p_new.color != null);
          if (!newHasColorForThisId) {
            existingColorsMapFromOldState[p_old.id!] = p_old.color!;
          }
        }
      }
      print(
          '[BPS] _initializeState: Populated existingColorsMapFromOldState: $existingColorsMapFromOldState');
    }

    List<ParticipantEntity> newParticipantList = [];
    Set<Color> colorsAssignedOrKeptInThisRun =
        Set<Color>.from(colorsCurrentlyInUse);

    for (var p_new in initialParticipantsFromWidget) {
      final participantId = (p_new.id == null || p_new.id!.isEmpty)
          ? _generateUniqueParticipantId()
          : p_new.id!;

      Color? determinedColor;
      if (p_new.color != null) {
        determinedColor = p_new.color;
        print(
            '[BPS] _initializeState mapping: Kept p_new.color for ${p_new.name} (ID: $participantId): $determinedColor');
      } else if (existingColorsMapFromOldState.containsKey(participantId)) {
        determinedColor = existingColorsMapFromOldState[participantId];
        colorsAssignedOrKeptInThisRun.add(determinedColor!);
        print(
            '[BPS] _initializeState mapping: Used existingColorFromOldState for ${p_new.name} (ID: $participantId): $determinedColor');
      } else {
        int attempts = 0;
        Color candidateColor;
        do {
          candidateColor = _availableColors[
              localNextColorAssignIndex % _availableColors.length];
          localNextColorAssignIndex++;
          attempts++;
        } while (colorsAssignedOrKeptInThisRun.contains(candidateColor) &&
            attempts < _availableColors.length);

        if (colorsAssignedOrKeptInThisRun.contains(candidateColor) &&
            attempts >= _availableColors.length) {
          print(
              "[BPS] Warning: Could not find a unique color for ${p_new.name} after $attempts attempts. Assigning potentially duplicate color $candidateColor.");
        }
        determinedColor = candidateColor;
        colorsAssignedOrKeptInThisRun.add(determinedColor);
        print(
            '[BPS] _initializeState mapping: Assigned new color for ${p_new.name} (ID: $participantId): $determinedColor. localNextColorAssignIndex advanced.');
      }
      newParticipantList
          .add(p_new.copyWith(id: participantId, color: determinedColor));
    }
    _participants = newParticipantList;
    _nextColorIndex =
        localNextColorAssignIndex; // Update global _nextColorIndex

    print(
        '[BPS] _initializeState: Final _participants: ${_participants.map((p) => '${p.name}:${p.id}:${p.color}').toList()}');
    print(
        '[BPS] _initializeState: Global _nextColorIndex updated to $_nextColorIndex at end.');
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

                    Set<Color> currentlyUsedColorsByParticipants = _participants
                        .where((p) => p.color != null)
                        .map((p) => p.color!)
                        .toSet();

                    Color newParticipantColor;
                    int attempts = 0;
                    do {
                      newParticipantColor = _availableColors[
                          _nextColorIndex % _availableColors.length];
                      _nextColorIndex++;
                      attempts++;
                    } while (currentlyUsedColorsByParticipants
                            .contains(newParticipantColor) &&
                        attempts < _availableColors.length);

                    if (currentlyUsedColorsByParticipants
                            .contains(newParticipantColor) &&
                        attempts >= _availableColors.length) {
                      print(
                          "[BPS] _addParticipantDialog: Warning! Could not find a unique color. Assigning potentially duplicate color $newParticipantColor.");
                    }

                    print(
                        '[BPS] _addParticipantDialog: Adding ${name} with ID $newParticipantId and color $newParticipantColor. Global _nextColorIndex is now $_nextColorIndex');

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
                left: 8.0,
                bottom: 4.0,
                right:
                    48.0), // Added left 8.0, right is 8.0 (for padding) + 40.0 (for alignment)
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text(l10n.participantSectionHeaderName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall)), // Increased font size
                Expanded(
                    flex: 2,
                    child: Text(l10n.participantSectionHeaderAmount,
                        textAlign: TextAlign.right,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall)), // Increased font size
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
          Padding(
            // Added Padding widget
            padding: const EdgeInsets.symmetric(
                horizontal: 8.0), // Added horizontal padding
            child: ListView.builder(
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
                  width: 22, // Increased size
                  height: 22, // Increased size
                  decoration: BoxDecoration(
                    color: participant.color ?? Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    participant.name,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16), // Use theme color
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
                  width: 16, // Increased size
                  height: 16, // Increased size
                  decoration: BoxDecoration(
                    color: participant.color ?? Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    participant.name,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16), // Use theme color
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
      return Card(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        elevation: 0, // Tùy chọn: loại bỏ bóng đổ nếu muốn giao diện phẳng hơn
        margin: const EdgeInsets.only(
            bottom: 8.0, top: 4.0, left: 8.0, right: 8.0), // Thêm margin
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Thêm padding bên trong card
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.billEditPageWarningUnallocatedCost(
                    _formatCurrencyValue(totalOwedByParticipants),
                    _formatCurrencyValue(billTotal),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        // Văn bản hơi lớn hơn
                        color: Theme.of(context)
                            .colorScheme
                            .onErrorContainer, // Đảm bảo văn bản hiển thị rõ trên nền errorContainer
                      ),
                  textAlign: TextAlign.left, // Căn trái văn bản
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink(); // No warning needed
  }
}
