import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';

class CalculateSplitBillUsecase {
  // Consider making this a callable class if you prefer: call(Params params)
  // For now, a static method or instance method is fine.
  List<ParticipantEntity> call({
    required BillEntity bill,
    required double actualTaxAmount,
    required double actualTipAmount,
    required double actualDiscountAmount,
  }) {
    final Map<String, double> participantItemSubtotals = {};
    double grandItemSubtotal = 0.0;    // 1. Calculate item subtotals for each participant and the grand item subtotal
    for (final item in bill.items ?? <BillItemEntity>[]) {
      // Check if we have weighted participants
      if (item.participants.isNotEmpty) {
        // Use weighted participants
        grandItemSubtotal += item.totalPrice;
        final int totalWeight = item.totalWeight;
        
        if (totalWeight > 0) {
          for (final participant in item.participants) {
            // Calculate share based on weight proportion
            final double weightedShare = item.totalPrice * participant.weight / totalWeight;
            participantItemSubtotals[participant.participantId] =
                (participantItemSubtotals[participant.participantId] ?? 0) + weightedShare;
          }
        }
      }
      // Fall back to old participantIds for backward compatibility
      else if (item.participantIds.isNotEmpty) {
        final double sharePerParticipantForItem =
            item.totalPrice / item.participantIds.length;
        grandItemSubtotal += item.totalPrice;
        for (final participantId in item.participantIds) {
          // Ensure participantId from item exists in the bill's participant list for safety, though ideally it always should.
          // For this calculation, we assume participantId is valid and corresponds to an existing participant.
          participantItemSubtotals[participantId] =
              (participantItemSubtotals[participantId] ?? 0) +
                  sharePerParticipantForItem;
        }
      }
      // else: Item not assigned to anyone, currently ignored in this calculation.
      // Could be assigned to payer or split equally among all if needed.
    }

    // 2. Calculate net additional cost
    final double netAdditionalCost =
        actualTaxAmount + actualTipAmount - actualDiscountAmount;

    // 3. Prepare the list of participants to be updated
    final List<ParticipantEntity> updatedParticipants = [];

    // 4. Distribute additional costs and calculate final owed amounts
    for (final participant in bill.participants ?? <ParticipantEntity>[]) {
      if (participant.id == null) continue; // Skip if participant has no ID

      final double currentParticipantItemSubtotal =
          participantItemSubtotals[participant.id!] ?? 0.0;
      double participantShareOfNetCost = 0.0;

      if (grandItemSubtotal > 0) {
        final double proportion =
            currentParticipantItemSubtotal / grandItemSubtotal;
        participantShareOfNetCost = netAdditionalCost * proportion;
      } else if ((bill.participants?.length ?? 0) > 0) {
        // If no items are shared (e.g., bill is only tax/tip), split additional costs equally
        participantShareOfNetCost =
            netAdditionalCost / bill.participants!.length;
      }
      // If grandItemSubtotal is 0 and no participants, participantShareOfNetCost remains 0.

      final double amountOwed =
          currentParticipantItemSubtotal + participantShareOfNetCost;

      updatedParticipants.add(
        participant.copyWith(
          amountOwed: amountOwed,
          setAmountOwedToNull: false, // Ensure it's not nulled if already null
        ),
      );
    }

    // Precision handling: It might be good to round final amounts to 2 decimal places
    // depending on currency requirements. For now, returning raw doubles.
    // Example rounding: double.parse(amountOwed.toStringAsFixed(2))

    return updatedParticipants;
  }
}
