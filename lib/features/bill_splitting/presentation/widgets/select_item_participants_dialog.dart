import 'package:flutter/material.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart'; // Added import for BillItemEntity

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
  late Set<String> _selectedParticipantIds;

  @override
  void initState() {
    super.initState();
    _selectedParticipantIds =
        Set<String>.from(widget.initiallySelectedParticipantIds);
  }

  void _onParticipantSelected(String participantId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedParticipantIds.add(participantId);
      } else {
        _selectedParticipantIds.remove(participantId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Chọn người chia sẻ cho "${widget.item.description}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.allParticipants.length,
          itemBuilder: (context, index) {
            final participant = widget.allParticipants[index];
            // Ensure participant.id is not null before using it
            final participantId = participant.id;
            if (participantId == null) {
              // Optionally, handle or log this case, though ideally IDs should always be present
              return const SizedBox
                  .shrink(); // Or some other placeholder/error widget
            }
            final bool isSelected =
                _selectedParticipantIds.contains(participantId);
            return CheckboxListTile(
              title: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: participant.color ?? Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    margin: const EdgeInsets.only(right: 10),
                  ),
                  Expanded(child: Text(participant.name)),
                ],
              ),
              value: isSelected,
              onChanged: (bool? value) {
                if (value != null) {
                  _onParticipantSelected(participantId, value);
                }
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Hủy'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Lưu'),
          onPressed: () {
            Navigator.of(context).pop(_selectedParticipantIds.toList());
          },
        ),
      ],
    );
  }
}
