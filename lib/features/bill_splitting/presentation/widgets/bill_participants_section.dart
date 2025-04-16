import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';
import 'package:intl/intl.dart'; // For number formatting

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
        const SnackBar(
            content: Text(
                'Please enter a valid percentage (0-100) before locking.')),
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
          title: const Text('Add Participant'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'Enter participant name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Add'),
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
                          content: Text('Participant "$name" already exists.')),
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
        const SnackBar(content: Text('Cannot remove the last participant.')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row (Optional)
        if (_participants.isNotEmpty && !widget.enabled)
          Padding(
            padding: const EdgeInsets.only(
                bottom: 4.0, left: 40.0), // Align with checkboxes
            child: Row(
              children: [
                Expanded(
                    child: Text('Name',
                        style: Theme.of(context).textTheme.labelSmall)),
                SizedBox(
                    width: 60,
                    child: Text('Percent',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelSmall)),
                SizedBox(
                    width: 90,
                    child: Text('Amount',
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
                  ? 'No participants added yet.'
                  : 'No participants.',
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
              return _buildParticipantRow(participant);
            },
          ),
        const SizedBox(height: 8),
        if (widget.enabled)
          TextButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Participant'),
            onPressed: _addParticipantDialog,
          ),
      ],
    );
  }

  Widget _buildParticipantRow(ParticipantEntity participant) {
    final percentageController = _percentageControllers[participant.name];
    final bool isLocked = participant.isPercentageLocked;
    final bool canRemove = widget.enabled && _participants.length > 1;

    // Calculate amount for review mode
    String displayAmount = '';
    if (!widget.enabled &&
        widget.totalAmount != null &&
        widget.totalAmount! > 0 &&
        participant.percentage != null) {
      final amount = widget.totalAmount! * (participant.percentage! / 100.0);
      displayAmount =
          '${_formatCurrencyValue(amount)} ${widget.currencyCode ?? ''}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          // Checkbox (Lock) - Only in edit mode
          if (widget.enabled)
            SizedBox(
              width: 40,
              child: Checkbox(
                value: isLocked,
                onChanged: (bool? value) {
                  if (value != null) {
                    _handleLockChange(participant, value);
                  }
                },
                visualDensity: VisualDensity.compact, // Make checkbox smaller
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
          else // Placeholder for alignment in review mode
            const SizedBox(width: 40),

          // Name
          Expanded(
            child: Text(
              participant.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // Percentage Input / Text
          SizedBox(
            width: 60, // Fixed width for percentage input/text
            child: widget.enabled
                ? IntrinsicWidth(
                    // Make TextField only as wide as needed
                    child: TextField(
                      controller: percentageController,
                      enabled: !isLocked, // Disable if locked
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(
                            r'^\d*\.?\d{0,2}')), // Allow numbers and up to 2 decimal places
                      ],
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: '...',
                        isDense: true, // Reduce padding
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        suffixText: '%',
                        border: isLocked
                            ? InputBorder.none
                            : const UnderlineInputBorder(), // No border if locked
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
                      // Consider adding onSubmitted or FocusNode listener for validation if needed
                    ),
                  )
                : Text(
                    '${_formatCurrencyValue(participant.percentage)}%', // Display formatted percentage
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: isLocked
                          ? FontWeight.bold
                          : FontWeight.normal, // Bold if it was locked
                    ),
                  ),
          ),
          const SizedBox(width: 8),

          // Calculated Amount (Review Mode Only)
          SizedBox(
            width: 90, // Fixed width for amount
            child: !widget.enabled
                ? Text(
                    displayAmount,
                    textAlign: TextAlign.right,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall, // Smaller text for amount
                  )
                : const SizedBox.shrink(), // Empty space in edit mode
          ),

          // Remove Button (Edit Mode Only)
          if (widget.enabled)
            SizedBox(
              width: 40, // Width for the remove button
              child: canRemove
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      color: Colors.red[300],
                      tooltip: 'Remove ${participant.name}',
                      onPressed: () => _removeParticipant(participant),
                      padding: EdgeInsets.zero, // Remove extra padding
                      constraints:
                          const BoxConstraints(), // Remove constraints to allow smaller size
                    )
                  : const SizedBox(width: 40), // Placeholder if cannot remove
            )
          else // Placeholder for alignment in review mode
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}
