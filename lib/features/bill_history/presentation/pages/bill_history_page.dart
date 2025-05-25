import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Import go_router for navigation
import 'package:hyper_split_bill/core/router/app_router.dart'; // Import AppRoutes
import 'package:hyper_split_bill/features/bill_history/presentation/bloc/bill_history_bloc.dart';
import 'package:hyper_split_bill/injection_container.dart'; // For sl()
import 'package:intl/intl.dart'; // For date formatting

class BillHistoryPage extends StatelessWidget {
  const BillHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BillHistoryBloc>()..add(LoadBillHistoryEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bill History'),
        ),
        body: BlocBuilder<BillHistoryBloc, BillHistoryState>(
          builder: (context, state) {
            if (state is BillHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is BillHistoryLoaded) {
              if (state.bills.isEmpty) {
                return const Center(child: Text('No bills in history yet.'));
              }
              return ListView.builder(
                itemCount: state.bills.length,
                itemBuilder: (context, index) {
                  final bill = state.bills[index];
                  return ListTile(
                    title: Text(bill.description ?? 'Unnamed Bill'),
                    subtitle: Text(
                        'Bill Date: ${DateFormat.yMd().format(bill.billDate)}\nSaved: ${DateFormat.yMd().add_jm().format(bill.createdAt)}\nTotal: ${NumberFormat('#,##0.00').format(bill.totalAmount)} ${bill.currencyCode}'), // Format number and append currency code
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        // Show confirmation dialog before deleting
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Bill'),
                            content: const Text(
                                'Are you sure you want to delete this bill from history?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                child: const Text('Delete'),
                                onPressed: () {
                                  context
                                      .read<BillHistoryBloc>()
                                      .add(DeleteBillFromHistoryEvent(bill.id));
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      // Navigate to BillEditPage using go_router with bill ID as a path parameter
                      context.push('${AppRoutes.editBill}/${bill.id}');
                    },
                  );
                },
              );
            } else if (state is BillHistoryError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is BillHistoryActionSuccess) {
              // This state might be better handled by a BlocListener to show a SnackBar
              // and then the BlocBuilder would show the updated list (due to LoadBillHistoryEvent being added)
              // For simplicity here, we just show a text, but ideally, UI should reflect the list.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message!)),
                  );
                }
                // Optionally, trigger a reload if not already handled by the event that led to this state
                // context.read<BillHistoryBloc>().add(LoadBillHistoryEvent());
              });
              return const Center(
                  child: Text(
                      'Action successful. Loading history...')); // Placeholder
            }
            return const Center(child: Text('Press button to load history.'));
          },
        ),
      ),
    );
  }
}
