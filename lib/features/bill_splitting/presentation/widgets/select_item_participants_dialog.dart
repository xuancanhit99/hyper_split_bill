import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Added import for AppLocalizations
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart'; // Added import for BillItemEntity
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_participant.dart'; // Added import for BillItemParticipant

class SelectItemParticipantsDialog extends StatefulWidget {
  final List<ParticipantEntity> allParticipants;
  final List<String> initiallySelectedParticipantIds;
  final BillItemEntity item;

  const SelectItemParticipantsDialog({
    super.key,
    required this.allParticipants,
    required this.initiallySelectedParticipantIds,
    required this.item,
  });

  @override
  State<SelectItemParticipantsDialog> createState() =>
      _SelectItemParticipantsDialogState();
}

class _SelectItemParticipantsDialogState
    extends State<SelectItemParticipantsDialog> {
  late Map<String, int> _participantWeights; // Map: participantId -> weight
  late Set<String> _selectedParticipantIds;
  @override
  void initState() {
    super.initState();
    _selectedParticipantIds =
        Set<String>.from(widget.initiallySelectedParticipantIds);

    // Initialize participant weights
    _participantWeights = {};

    // First, try to get weights from the item.participants list
    if (widget.item.participants.isNotEmpty) {
      for (final participant in widget.item.participants) {
        _participantWeights[participant.participantId] = participant.weight;
      }
    }
    // If participants list is empty but we have participantIds, create default weights
    else if (widget.initiallySelectedParticipantIds.isNotEmpty) {
      for (final id in widget.initiallySelectedParticipantIds) {
        _participantWeights[id] = 1;
      }
    }

    // For any selected participants that don't have a weight yet, set default weight of 1
    for (final id in _selectedParticipantIds) {
      _participantWeights.putIfAbsent(id, () => 1);
    }
  }

  void _onParticipantSelected(String participantId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedParticipantIds.add(participantId);
        // Set default weight of 1 for newly selected participants
        _participantWeights.putIfAbsent(participantId, () => 1);
      } else {
        _selectedParticipantIds.remove(participantId);
        // Optionally, we could remove the weight when unselected
        // _participantWeights.remove(participantId);
      }
    });
  }

  // Update participant weight
  void _updateWeight(String participantId, int newWeight) {
    if (newWeight >= 1) {
      setState(() {
        _participantWeights[participantId] = newWeight;
      });
    }
  }

  // Increment participant weight
  void _incrementWeight(String participantId) {
    final currentWeight = _participantWeights[participantId] ?? 1;
    _updateWeight(participantId, currentWeight + 1);
  }

  // Decrement participant weight
  void _decrementWeight(String participantId) {
    final currentWeight = _participantWeights[participantId] ?? 1;
    if (currentWeight > 1) {
      _updateWeight(participantId, currentWeight - 1);
    }
  }

  // Method to show weight editing dialog
  void _showEditWeightDialog(
      BuildContext context, String participantId, int currentWeight) async {
    final TextEditingController controller =
        TextEditingController(text: currentWeight.toString());

    final int? result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        final localizations =
            AppLocalizations.of(dialogContext)!; // Get localizations here
        return AlertDialog(
          title: Text(localizations.dialogEditWeightTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(localizations.dialogEditWeightInputLabel),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: localizations.dialogEditWeightInputHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(localizations.buttonCancel),
            ),
            TextButton(
              onPressed: () {
                final newValue = int.tryParse(controller.text);
                if (newValue != null && newValue >= 1) {
                  Navigator.pop(dialogContext, newValue);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                        content: Text(
                            localizations.dialogEditWeightValidationError)),
                  );
                }
              },
              child: Text(localizations.buttonSave),
            ),
          ],
        );
      },
    );

    // Clean up
    controller.dispose();

    if (result != null) {
      _updateWeight(participantId, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title:
          Text(localizations.dialogParticipantsTitle(widget.item.description)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Name takes most space
                  Expanded(
                    child: Text(localizations.dialogParticipantsHeaderName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Weight ratio header on the right
                  SizedBox(
                    // Removed const
                    width: 120,
                    child: Center(
                      // Removed const
                      child: Text(localizations.dialogParticipantsHeaderWeight,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.allParticipants.length,
                itemBuilder: (context, index) {
                  final participant = widget.allParticipants[index];
                  // Ensure participant.id is not null before using it
                  final participantId = participant.id;
                  if (participantId == null) {
                    return const SizedBox.shrink();
                  }

                  final bool isSelected =
                      _selectedParticipantIds.contains(participantId);
                  final int weight = isSelected
                      ? (_participantWeights[participantId] ?? 1)
                      : 1;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        // Left side: Checkbox and participant name
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                if (value != null) {
                                  _onParticipantSelected(participantId, value);
                                }
                              },
                            ),
                            title: Row(
                              children: [
                                // Color indicator
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: participant.color ??
                                        Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  margin: const EdgeInsets.only(right: 10),
                                ),
                                // Name
                                Expanded(
                                  child: Text(participant.name),
                                ),
                              ],
                            ),
                            onTap: () {
                              _onParticipantSelected(
                                  participantId, !isSelected);
                            },
                          ),
                        ),

                        // Right side: Weight controls (if selected)
                        if (isSelected)
                          SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Decrement button
                                InkWell(
                                  onTap: weight > 1
                                      ? () => _decrementWeight(participantId)
                                      : null,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: weight > 1
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.remove, size: 16),
                                  ),
                                ),
                                // Weight display - clickable to edit
                                GestureDetector(
                                  onTap: () => _showEditWeightDialog(
                                      context,
                                      participantId,
                                      weight), // Removed localizations here
                                  child: Container(
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    height: 28,
                                    width: 28,
                                    child: Text(
                                      '$weight',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                // Increment button
                                InkWell(
                                  onTap: () => _incrementWeight(participantId),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.add, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(
                              width: 120), // Empty placeholder for alignment
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(localizations.buttonCancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(localizations.buttonSave),
          onPressed: () {
            // Create a list of BillItemParticipant objects from the selected IDs and weights
            final List<String> selectedIds = _selectedParticipantIds.toList();
            final List<BillItemParticipant> participants =
                selectedIds.map((id) {
              return BillItemParticipant(
                participantId: id,
                weight: _participantWeights[id] ?? 1,
              );
            }).toList();

            // Return both the selected IDs and the weighted participants
            Navigator.of(context).pop({
              'selectedIds': selectedIds,
              'participants': participants,
            });
          },
        ),
      ],
    );
  }
}
