import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

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
  final double? totalAmount; // Needed for review mode calculation
  final String? currencyCode; // Needed for review mode display

  const BillParticipantsSection({
    super.key,
    required this.initialParticipants,
    required this.onParticipantsChanged,
    this.enabled = true,
    this.totalAmount, // Make optional
    this.currencyCode, // Make optional
  });

  @override
  State<BillParticipantsSection> createState() =>
      _BillParticipantsSectionState();
}

class _BillParticipantsSectionState extends State<BillParticipantsSection> {
  late List<ParticipantEntity> _participants;
  // Map to hold controllers, using participant name as key for simplicity here
  // In a real app, using a unique ID (even temporary) would be more robust
  late Map<String, TextEditingController> _percentageControllers;
  bool _isDistributing = false; // Flag to prevent recursive updates

  @override
  void initState() {
    super.initState();
    _initializeState(widget.initialParticipants);
  }

  @override
  void didUpdateWidget(covariant BillParticipantsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize if the initial list or enabled status changes significantly
    if (widget.initialParticipants != oldWidget.initialParticipants ||
        widget.enabled != oldWidget.enabled) {
      // Dispose old controllers before creating new ones
      _disposeControllers();
      _initializeState(widget.initialParticipants);
    } else {
      // If only totalAmount or currencyCode changes (e.g., parent updates), just rebuild
      // No need to re-initialize controllers or participants list
    }
  }

  void _initializeState(List<ParticipantEntity> initialParticipants) {
    _participants = List.from(initialParticipants);
    _percentageControllers = {};
    for (var p in _participants) {
      _percentageControllers[p.name] = TextEditingController();
    }
    // Set initial percentages (distribute equally or use existing)
    _distributePercentages(
        notifyParent: false); // Don't notify on initial setup
    _updateControllerTexts(); // Set initial text based on distributed percentages
  }

  void _updateControllerTexts() {
    for (var p in _participants) {
      final controller = _percentageControllers[p.name];
      final percentageString =
          _formatCurrencyValue(p.percentage); // Use formatter
      if (controller != null && controller.text != percentageString) {
        controller.text = percentageString;
      }
    }
  }

  // Distributes 100% among participants, respecting locked percentages
  void _distributePercentages({bool notifyParent = true}) {
    if (_isDistributing || _participants.isEmpty)
      return; // Prevent recursion and handle empty list
    _isDistributing = true;

    double totalLockedPercentage = 0;
    int unlockedCount = 0;
    List<ParticipantEntity> updatedParticipants =
        List.from(_participants); // Work on a copy

    // Calculate total locked percentage and count unlocked participants
    for (var p in updatedParticipants) {
      if (p.isPercentageLocked) {
        totalLockedPercentage += p.percentage ?? 0;
      } else {
        unlockedCount++;
      }
    }

    // Ensure locked percentage doesn't exceed 100
    totalLockedPercentage = totalLockedPercentage.clamp(0.0, 100.0);

    double remainingPercentage = 100.0 - totalLockedPercentage;
    double percentagePerUnlocked =
        unlockedCount > 0 ? (remainingPercentage / unlockedCount) : 0;
    // Ensure non-negative percentage
    percentagePerUnlocked =
        percentagePerUnlocked < 0 ? 0 : percentagePerUnlocked;

    // Assign percentages
    double assignedTotal =
        0; // Track assigned percentage to handle rounding errors
    for (int i = 0; i < updatedParticipants.length; i++) {
      ParticipantEntity p = updatedParticipants[i];
      if (!p.isPercentageLocked) {
        // Assign calculated percentage, handle potential rounding on the last one
        double assigned =
            (i == updatedParticipants.length - 1 && unlockedCount > 0)
                ? (100.0 -
                    assignedTotal -
                    totalLockedPercentage) // Assign remaining to last unlocked
                : percentagePerUnlocked;
        assigned = assigned.clamp(0.0, 100.0); // Clamp individual assignment

        updatedParticipants[i] = p.copyWith(percentage: assigned);
        assignedTotal += assigned; // Add the actually assigned value
      } else {
        // Keep locked percentage, ensure it's part of the tracked total
        assignedTotal += p.percentage ?? 0;
      }
    }

    // Final check due to potential floating point inaccuracies
    double finalTotal =
        updatedParticipants.fold(0.0, (sum, p) => sum + (p.percentage ?? 0.0));
    if ((finalTotal - 100.0).abs() > 0.01 && updatedParticipants.isNotEmpty) {
      // If there's a noticeable discrepancy, adjust the last participant (or first if last is locked)
      int adjustIndex =
          updatedParticipants.lastIndexWhere((p) => !p.isPercentageLocked);
      if (adjustIndex == -1)
        adjustIndex = 0; // Adjust first if all are locked (edge case)

      double adjustment = 100.0 - finalTotal;
      double currentPerc = updatedParticipants[adjustIndex].percentage ?? 0.0;
      updatedParticipants[adjustIndex] = updatedParticipants[adjustIndex]
          .copyWith(
              percentage: (currentPerc + adjustment)
                  .clamp(0.0, 100.0) // Clamp adjustment
              );
      print(
          "Percentage adjustment applied: $adjustment to participant at index $adjustIndex");
    }

    // Update state and notify parent if changes occurred
    bool changed = !_listEquals(_participants, updatedParticipants);
    if (changed) {
      setState(() {
        _participants = updatedParticipants;
        _updateControllerTexts(); // Update text fields after calculation
      });
      if (notifyParent) {
        widget.onParticipantsChanged(List.from(_participants));
      }
    }
    _isDistributing = false;
  }

  // Helper to compare lists of participants
  bool _listEquals(List<ParticipantEntity> a, List<ParticipantEntity> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _handlePercentageChange(ParticipantEntity participant, String value) {
    if (_isDistributing) return; // Prevent updates during distribution

    final controller = _percentageControllers[participant.name];
    if (controller == null) return;

    double? newPercentage = double.tryParse(value);
    // Basic validation: allow empty string or valid number up to 100
    if (value.isEmpty ||
        (newPercentage != null && newPercentage >= 0 && newPercentage <= 100)) {
      // Update the participant entity immediately if the value is valid and locked
      // The actual distribution happens on lock/unlock or add/remove
      // If not locked, just update the controller text, distribution handles the rest
      // controller.text = value; // Keep controller in sync, even if not locked yet
    } else {
      // Revert to the last valid percentage if input is invalid
      final currentPercentageString =
          _formatCurrencyValue(participant.percentage);
      controller.text = currentPercentageString;
      controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length)); // Move cursor to end
    }
  }

  void _handleLockChange(ParticipantEntity participant, bool isLocked) {
    if (_isDistributing) return;

    final controller = _percentageControllers[participant.name];
    if (controller == null) return;

    double? currentPercentage = double.tryParse(controller.text);

    // If locking, ensure the value is valid before locking
    if (isLocked &&
        (currentPercentage == null ||
            currentPercentage < 0 ||
            currentPercentage > 100)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            // Remove const
            content: Text(AppLocalizations.of(context)!
                .participantSectionInvalidPercentageLock)),
      );
      // Don't proceed with locking if value is invalid
      // We need to trigger a rebuild to uncheck the checkbox visually
      setState(() {});
      return;
    }

    // Find the index and update the participant in the list
    int index = _participants.indexWhere((p) => p.name == participant.name);
    if (index != -1) {
      final updatedParticipant = _participants[index].copyWith(
          isPercentageLocked: isLocked,
          // If locking, use the validated percentage from the controller
          // If unlocking, percentage will be recalculated by _distributePercentages
          percentage:
              isLocked ? currentPercentage : _participants[index].percentage,
          setPercentageToNull:
              !isLocked // Allow distribution to overwrite if unlocking
          );

      // Create a new list with the updated participant
      List<ParticipantEntity> tempList = List.from(_participants);
      tempList[index] = updatedParticipant;

      // Update the state immediately for visual feedback
      setState(() {
        _participants = tempList;
        // If locking, ensure controller reflects the locked value accurately
        if (isLocked) {
          controller.text = _formatCurrencyValue(currentPercentage);
        }
      });

      // Recalculate and distribute percentages for everyone
      _distributePercentages();
    }
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
                    final newParticipant = ParticipantEntity(
                        name: name); // Percentage will be set by distribution
                    // Add controller for the new participant
                    _percentageControllers[name] = TextEditingController();
                    // Add to list and redistribute
                    setState(() {
                      _participants.add(newParticipant);
                    });
                    _distributePercentages(); // This will handle percentage and notify parent
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
            // Remove const
            content: Text(AppLocalizations.of(context)!
                .participantSectionCannotRemoveLastSnackbar)),
      );
      return;
    }
    // Remove controller and participant, then redistribute
    final controller = _percentageControllers.remove(participant.name);
    controller?.dispose(); // Dispose the controller

    setState(() {
      _participants.removeWhere((p) => p.name == participant.name);
    });
    _distributePercentages(); // Redistribute percentages and notify parent
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _percentageControllers.values.forEach((controller) => controller.dispose());
    _percentageControllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Get the localization instance
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row (Review Mode Only)
        if (_participants.isNotEmpty && !widget.enabled)
          Padding(
            padding: const EdgeInsets.only(
                bottom: 4.0,
                left: 40.0, // Align with checkbox space
                right: 40.0), // Align with remove button space
            child: Row(
              children: [
                Expanded(
                    flex: 2, // Name takes 2 parts
                    child: Text(l10n.participantSectionHeaderName,
                        style: Theme.of(context).textTheme.labelSmall)),
                Expanded(
                    flex: 1, // Percent takes 1 part
                    child: Text(l10n.participantSectionHeaderPercent,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelSmall)),
                Expanded(
                    flex: 1, // Amount takes 1 part
                    child: Text(l10n.participantSectionHeaderAmount,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelSmall)),
              ],
            ),
          ),
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
              // Call the appropriate row builder based on mode
              return widget.enabled
                  ? _buildEditModeRow(l10n, participant) // Pass l10n instance
                  : _buildReviewModeRow(participant);
            },
          ),
        const SizedBox(height: 8),
        if (widget.enabled)
          TextButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.participantSectionAddButtonLabel),
            onPressed: _addParticipantDialog,
          ),
      ],
    );
  }

  // Builds a row for Edit Mode
  Widget _buildEditModeRow(
      AppLocalizations l10n, ParticipantEntity participant) {
    // Add l10n parameter
    final percentageController = _percentageControllers[participant.name];
    final bool isLocked = participant.isPercentageLocked;
    final bool canRemove = _participants.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          // Checkbox (Lock)
          SizedBox(
            width: 40,
            child: Checkbox(
              value: isLocked,
              onChanged: (bool? value) {
                if (value != null) {
                  _handleLockChange(participant, value);
                }
              },
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          // Name
          Expanded(
            child: Text(
              participant.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // Percentage Input
          SizedBox(
            width: 70, // Increased width
            child: IntrinsicWidth(
              child: TextField(
                controller: percentageController,
                enabled: !isLocked,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: '...',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  suffixText: '%',
                  border: isLocked
                      ? InputBorder.none
                      : const UnderlineInputBorder(),
                  enabledBorder: isLocked
                      ? InputBorder.none
                      : const UnderlineInputBorder(),
                  focusedBorder: isLocked
                      ? InputBorder.none
                      : const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue)),
                ),
                onChanged: (value) =>
                    _handlePercentageChange(participant, value),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Placeholder for Amount column alignment
          const SizedBox(width: 90),

          // Remove Button
          SizedBox(
            width: 40,
            child: canRemove
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: Colors.red[300],
                    tooltip:
                        l10n.participantSectionRemoveTooltip(participant.name),
                    onPressed: () => _removeParticipant(participant),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : const SizedBox(width: 40), // Keep space if cannot remove
          ),
        ],
      ),
    );
  }

  // Builds a row for Review Mode
  Widget _buildReviewModeRow(ParticipantEntity participant) {
    final bool isLocked =
        participant.isPercentageLocked; // To show bold if it was locked

    // Calculate amount
    String displayAmount = '';
    if (widget.totalAmount != null &&
        widget.totalAmount! > 0 &&
        participant.percentage != null) {
      final amount = widget.totalAmount! * (participant.percentage! / 100.0);
      displayAmount =
          '${_formatCurrencyValue(amount)} ${widget.currencyCode ?? ''}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 4.0), // Add some vertical padding
      child: Row(
        children: [
          // Placeholder for Checkbox alignment
          const SizedBox(width: 40),

          // Name (Flex 2)
          Expanded(
            flex: 2,
            child: Text(
              participant.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // const SizedBox(width: 8), // No extra space needed with Expanded

          // Percentage Text (Flex 1)
          Expanded(
            flex: 1,
            child: Text(
              '${_formatCurrencyValue(participant.percentage)}%',
              textAlign: TextAlign.right,
              // Removed conditional bold style:
              // style: TextStyle(
              //   fontWeight: isLocked ? FontWeight.bold : FontWeight.normal,
              // ),
            ),
          ),
          // const SizedBox(width: 8), // No extra space needed with Expanded

          // Calculated Amount (Flex 1)
          Expanded(
            flex: 1,
            child: Text(
              displayAmount,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          // Placeholder for Remove button alignment
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
