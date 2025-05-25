import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_split_bill/features/bill_history/presentation/bloc/bill_history_bloc.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/pages/bill_edit_page.dart';

/// A widget that fetches a bill from history and shows the BillEditPage
/// when the data is loaded.
class BillHistoryFetcher extends StatefulWidget {
  final String billId;
  final String? structuredJsonString;

  const BillHistoryFetcher({
    super.key,
    required this.billId,
    this.structuredJsonString,
  });

  @override
  State<BillHistoryFetcher> createState() => _BillHistoryFetcherState();
}

class _BillHistoryFetcherState extends State<BillHistoryFetcher> {
  @override
  void initState() {
    super.initState();
    // Trigger loading of bill details when widget initializes
    context.read<BillHistoryBloc>().add(LoadBillDetailsEvent(widget.billId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillHistoryBloc, BillHistoryState>(
      builder: (context, state) {
        if (state is BillHistoryLoading || state is BillDetailsLoading || state is BillHistoryInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is BillDetailsLoaded) {
          return BillEditPage(
            historicalBillToEdit: state.bill,
            structuredJsonString: widget.structuredJsonString,
          );
        } else if (state is BillHistoryError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading bill: ${state.message}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<BillHistoryBloc>().add(LoadBillDetailsEvent(widget.billId));
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }
        // Default loading state
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
