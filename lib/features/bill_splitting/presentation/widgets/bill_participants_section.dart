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
  // late Map<String, TextEditingController> _percentageControllers; // Removed
  // bool _isDistributing = false; // Removed
  final Random _random = Random(); // For generating unique IDs

  @override
  void initState() {
    super.initState();
    _initializeState(widget.initialParticipants);
  }

  @override
  void didUpdateWidget(covariant BillParticipantsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialParticipants != oldWidget.initialParticipants ||
        widget.enabled != oldWidget.enabled) {
      _initializeState(widget.initialParticipants);
    }
  }

  void _initializeState(List<ParticipantEntity> initialParticipants) {
    _participants = initialParticipants.map((p) {
      return p.id == null || p.id!.isEmpty
          ? p.copyWith(id: _generateUniqueParticipantId())
          : p;
    }).toList();
    // No percentage logic needed here anymore
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
                    final newParticipant = ParticipantEntity(
                      id: newParticipantId,
                      name: name,
                      // No percentage, isPercentageLocked needed
                    );
                    setState(() {
                      _participants.add(newParticipant);
                    });
                    widget.onParticipantsChanged(List.from(_participants));
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
    final bool canRemove = _participants.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              participant.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40, // Keep consistent width for alignment
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
                : const SizedBox(width: 40),
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
    // Removed fallback to percentage calculation as it's no longer part of this widget's direct responsibility

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // No placeholder needed for checkbox if it's removed from review header
          Expanded(
            flex: 3,
            child: Text(
              participant.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
