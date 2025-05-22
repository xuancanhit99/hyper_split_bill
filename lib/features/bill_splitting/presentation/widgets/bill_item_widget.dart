import 'package:flutter/material.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart'; // Import ParticipantEntity
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_participant.dart'; // Import BillItemParticipant
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/select_item_participants_dialog.dart'; // Import dialog
import 'package:intl/intl.dart'; // For number formatting
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

// A widget to display a single bill item within the BillItemsSection list.
class BillItemWidget extends StatelessWidget {
  final BillItemEntity item;
  final VoidCallback onEdit; // Callback when edit button is pressed
  final bool showItemDetails; // New: Control Qty/Unit Price visibility
  final List<ParticipantEntity> allParticipants; // All participants in the bill
  final Function(List<String> selectedParticipantIds,
          List<BillItemParticipant>? participants)
      onParticipantsSelected; // Callback for when participants are selected
  final bool isEditingEnabled; // To control tap interaction

  const BillItemWidget({
    super.key,
    required this.item,
    required this.onEdit,
    required this.showItemDetails,
    required this.allParticipants,
    required this.onParticipantsSelected,
    required this.isEditingEnabled, // Add to constructor
  });

  // --- Formatting Helper ---
  String _formatCurrencyValue(num? value) {
    if (value == null) return '';
    // Use NumberFormat for flexible formatting
    // '0.##' pattern removes trailing zeros and '.00'
    final format = NumberFormat('0.##');
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    // Formatter for quantity display
    final quantityFormat = NumberFormat.decimalPattern();

    // String getParticipantNames(List<String> ids) {
    //   if (ids.isEmpty) return 'Chưa chọn';
    //   return allParticipants
    //       .where((p) => ids.contains(p.id))
    //       .map((p) => p.name)
    //       .join(', ');
    // }

    // New method to build participant chips
    Widget _buildParticipantChips(List<String> participantIds) {
      if (participantIds.isEmpty) {
        return Text(
          AppLocalizations.of(context)!.billItemWidgetNoParticipantSelected,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]),
        );
      }
      List<Widget> chips = participantIds.map((id) {
        final participant =
            allParticipants.firstWhere((p) => p.id == id, orElse: () {
          // This should ideally not happen if data is consistent
          print("Error: Participant with ID $id not found in allParticipants.");
          return ParticipantEntity(
              id: id, name: 'Unknown', color: Colors.grey.shade400);
        });

        // Get participant weight if available
        int weight = 1;
        if (item.participants.isNotEmpty) {
          final participantEntry = item.participants.firstWhere(
            (p) => p.participantId == id,
            orElse: () =>
                const BillItemParticipant(participantId: '', weight: 1),
          );
          if (participantEntry.participantId.isNotEmpty) {
            weight = participantEntry.weight;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(right: 4.0, top: 2.0, bottom: 2.0),
          child: Chip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(participant.name,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black87)),
                if (weight > 1) ...[
                  const SizedBox(width: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'x$weight',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: participant.color ?? Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: const EdgeInsets.only(left: 2.0, right: 2.0),
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList();

      return Wrap(
        spacing: 0.0, // Horizontal spacing between chips
        runSpacing: 0.0, // Vertical spacing between lines of chips
        children: chips,
      );
    }

    return InkWell(
      onTap: isEditingEnabled // Check if editing is enabled
          ? () async {
              // DEBUG PRINT STATEMENT
              print(
                  'BillItemWidget onTap - Item: ${item.description}, isEditingEnabled: $isEditingEnabled, All Participants: ${allParticipants.map((p) => 'Name: ${p.name}, ID: ${p.id}').toList()}');
              final Map<String, dynamic>? result =
                  await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return SelectItemParticipantsDialog(
                    allParticipants: allParticipants,
                    initiallySelectedParticipantIds: item.participantIds,
                    item: item,
                  );
                },
              );

              if (result != null) {
                // Extract the selected participant IDs
                final List<String> selectedIds =
                    result['selectedIds'] as List<String>;
                // Extract the participants with weights
                final List<BillItemParticipant> participants =
                    (result['participants'] as List)
                        .cast<BillItemParticipant>();

                // Pass both the selected IDs and weighted participants
                onParticipantsSelected(selectedIds, participants);
              }
            }
          : null, // Disable tap if not editing
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    item.description,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Conditionally show Qty
                if (showItemDetails) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Text(
                      quantityFormat.format(item.quantity),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                // Conditionally show Unit Price
                if (showItemDetails) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatCurrencyValue(item.unitPrice),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatCurrencyValue(item.totalPrice),
                    textAlign: TextAlign.right,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  iconSize: 20.0,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: AppLocalizations.of(context)!
                      .billItemWidgetOptionsTooltip,
                  onPressed:
                      onEdit, // This can open a menu for "Edit Details", "Delete", etc.
                  // Or, we can remove this if the main tap is for selecting participants
                  // and editing is done via another way. For now, let's keep it.
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people_alt_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                    child: _buildParticipantChips(item.participants.isNotEmpty
                        ? item.participants.map((p) => p.participantId).toList()
                        : item.participantIds)),
                // Optional: Add a small edit icon here too for participants if needed
                // IconButton(
                //   icon: const Icon(Icons.edit_outlined, size: 16),
                //   onPressed: () { /* Same as InkWell onTap */ },
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
