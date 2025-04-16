import 'package:flutter/material.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';

// Widget to manage the list of participants (display chips, add, remove)
class BillParticipantsSection extends StatefulWidget {
  final List<ParticipantEntity> initialParticipants;
  final bool enabled;
  final Function(List<ParticipantEntity>) onParticipantsChanged;

  const BillParticipantsSection({
    super.key,
    required this.initialParticipants,
    required this.onParticipantsChanged,
    this.enabled = true,
  });

  @override
  State<BillParticipantsSection> createState() =>
      _BillParticipantsSectionState();
}

class _BillParticipantsSectionState extends State<BillParticipantsSection> {
  late List<ParticipantEntity> _participants;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy to manage within this widget's state
    _participants = List.from(widget.initialParticipants);
  }

  // Update internal state if the initial list changes from parent
  // This is important if the parent re-parses or loads data
  @override
  void didUpdateWidget(covariant BillParticipantsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialParticipants != oldWidget.initialParticipants) {
      setState(() {
        _participants = List.from(widget.initialParticipants);
      });
    }
  }

  // --- Dialog for Adding Participant ---
  Future<void> _addParticipantDialog() async {
    final nameController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
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
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    // Avoid adding duplicate names (case-insensitive check)
                    if (!_participants.any(
                        (p) => p.name.toLowerCase() == name.toLowerCase())) {
                      // ID will be null for newly added participants
                      final newParticipant = ParticipantEntity(name: name);
                      _participants.add(newParticipant);
                      widget.onParticipantsChanged(List.from(
                          _participants)); // Notify parent with a new list instance
                    } else {
                      // Show feedback if name exists
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Participant "$name" already exists.')),
                        );
                      }
                    }
                  });
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _removeParticipant(ParticipantEntity participant) {
    // Prevent removing the last participant if needed (e.g., the owner 'Me')
    if (_participants.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove the last participant.')),
      );
      return;
    }
    setState(() {
      _participants.remove(participant);
      widget.onParticipantsChanged(
          List.from(_participants)); // Notify parent with a new list instance
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_participants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No participants added yet.',
                style: TextStyle(color: Colors.grey[600])),
          )
        else
          Wrap(
            // Use Wrap for chips that can flow to the next line
            spacing: 8.0,
            runSpacing: 4.0,
            children: _participants.map((participant) {
              return Chip(
                label: Text(participant.name),
                // Disable delete if not enabled or if it's the last participant
                onDeleted: (widget.enabled && _participants.length > 1)
                    ? () => _removeParticipant(participant)
                    : null,
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        // Conditionally show the button
        if (widget.enabled)
          TextButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Participant'),
            onPressed:
                _addParticipantDialog, // No need for ternary here anymore
          ),
      ],
    );
  }
}
