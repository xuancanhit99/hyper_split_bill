import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import AppLocalizations
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart';

class SplitByPercentageDialog extends StatefulWidget {
  final List<ParticipantEntity> participants;
  final Function(Map<ParticipantEntity, double>) onSplit;

  const SplitByPercentageDialog({
    super.key,
    required this.participants,
    required this.onSplit,
  });

  @override
  State<SplitByPercentageDialog> createState() =>
      _SplitByPercentageDialogState();
}

class _SplitByPercentageDialogState extends State<SplitByPercentageDialog> {
  late Map<ParticipantEntity, TextEditingController> _percentageControllers;
  late Map<ParticipantEntity, FocusNode> _focusNodes;
  double _totalPercentage = 0;

  @override
  void initState() {
    super.initState();
    _percentageControllers = {
      for (var p in widget.participants)
        p: TextEditingController(text: '0') // Default to '0'
    };
    _focusNodes = {for (var p in widget.participants) p: FocusNode()};

    _percentageControllers.forEach((_, controller) {
      controller.addListener(_updateTotalPercentage);
    });
    _updateTotalPercentage(); // Initial calculation
  }

  void _updateTotalPercentage() {
    double currentTotal = 0;
    _percentageControllers.forEach((_, controller) {
      currentTotal += double.tryParse(controller.text) ?? 0;
    });
    if (mounted) {
      setState(() {
        _totalPercentage = currentTotal;
      });
    }
  }

  @override
  void dispose() {
    _percentageControllers.forEach((_, controller) => controller.dispose());
    _focusNodes.forEach((_, node) => node.dispose());
    super.dispose();
  }

  void _handleSplit() {
    final Map<ParticipantEntity, double> percentages = {};
    double sum = 0;

    _percentageControllers.forEach((participant, controller) {
      final percentageValue =
          double.tryParse(controller.text) ?? 0; // Treat empty/invalid as 0
      if (percentageValue < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .splitByPercentageDialogErrorNegativePercentage(
                      participant.name))),
        );
        return; // Exit if any percentage is negative
      }
      percentages[participant] = percentageValue;
      sum += percentageValue;
    });

    // Check if any negative percentage caused an early return
    if (ScaffoldMessenger.of(context).mounted && sum != _totalPercentage) {
      // This implies a negative value was found and message shown, so we stop.
      // This check is a bit indirect, ideally the return from forEach would be better.
      // However, forEach does not support early exit from the outer function directly.
      // A simple flag or checking the sum against the calculated _totalPercentage can work.
      // If a negative value was entered, sum would not match _totalPercentage if it was updated *after* the SnackBar.
      // Let's ensure _totalPercentage reflects the sum of non-negative values for this check.

      // Re-calculate sum for accurate comparison in case of negative input that was skipped.
      double validSum = 0;
      percentages.forEach((key, value) {
        validSum += value;
      });
      if (validSum.toStringAsFixed(2) != _totalPercentage.toStringAsFixed(2)) {
        // A negative value was entered and a message was shown.
        return;
      }
    }

    if (sum.toStringAsFixed(2) != '100.00') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .splitByPercentageDialogErrorTotalNot100(
                    sum.toStringAsFixed(2)))),
      );
      return;
    }
    widget.onSplit(percentages);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chia theo phần trăm'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tổng: ${_totalPercentage.toStringAsFixed(2)}% / 100%',
                style: TextStyle(
                    color: _totalPercentage > 100
                        ? Colors.red
                        : (_totalPercentage == 100
                            ? Colors.green
                            : Theme.of(context).textTheme.bodyLarge?.color))),
            const SizedBox(height: 16),
            ...widget.participants.map((participant) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(child: Text(participant.name)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: _percentageControllers[participant],
                        focusNode: _focusNodes[participant],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                        textAlign: TextAlign.right,
                        onTap: () {
                          // Select all text when focused
                          _percentageControllers[participant]?.selection =
                              TextSelection(
                            baseOffset: 0,
                            extentOffset: _percentageControllers[participant]!
                                .text
                                .length,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!
              .buttonCancel), // Use AppLocalizations
        ),
        ElevatedButton(
          onPressed: _handleSplit,
          child: Text(
              AppLocalizations.of(context)!.buttonSave), // Use AppLocalizations
        ),
      ],
    );
  }
}
