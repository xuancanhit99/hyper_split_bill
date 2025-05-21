import 'package:flutter/material.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart'; // Import ParticipantEntity
import 'package:hyper_split_bill/features/bill_splitting/presentation/widgets/select_item_participants_dialog.dart'; // Import dialog
import 'package:intl/intl.dart'; // For number formatting

// A widget to display a single bill item within the BillItemsSection list.
class BillItemWidget extends StatelessWidget {
  final BillItemEntity item;
  final VoidCallback onEdit; // Callback when edit button is pressed
  final bool showItemDetails; // New: Control Qty/Unit Price visibility
  final List<ParticipantEntity> allParticipants; // All participants in the bill
  final Function(List<String> selectedParticipantIds)
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

    String getParticipantNames(List<String> ids) {
      if (ids.isEmpty) return 'Chưa chọn';
      return allParticipants
          .where((p) => ids.contains(p.id))
          .map((p) => p.name)
          .join(', ');
    }

    return InkWell(
      onTap: isEditingEnabled // Check if editing is enabled
          ? () async {
              // DEBUG PRINT STATEMENT
              print(
                  'BillItemWidget onTap - Item: ${item.description}, isEditingEnabled: $isEditingEnabled, All Participants: ${allParticipants.map((p) => 'Name: ${p.name}, ID: ${p.id}').toList()}');
              final List<String>? selectedIds = await showDialog<List<String>>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return SelectItemParticipantsDialog(
                    allParticipants: allParticipants,
                    initiallySelectedParticipantIds: item.participantIds,
                    item: item,
                  );
                },
              );
              if (selectedIds != null) {
                onParticipantsSelected(selectedIds);
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
                  tooltip: 'Tùy chọn món',
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
                  child: Text(
                    getParticipantNames(item.participantIds),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
