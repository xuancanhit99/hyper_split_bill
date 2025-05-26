import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_split_bill/core/router/app_router.dart';
import 'package:hyper_split_bill/features/bill_history/presentation/bloc/bill_history_bloc.dart';
import 'package:intl/intl.dart';

class BillHistoryPage extends StatefulWidget {
  const BillHistoryPage({super.key});

  @override
  State<BillHistoryPage> createState() => _BillHistoryPageState();
}

class _BillHistoryPageState extends State<BillHistoryPage> {
  @override
  void initState() {
    super.initState();
    // Load bill history when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillHistoryBloc>().add(LoadBillHistoryEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go(AppRoutes.home);
          },
          tooltip: 'Back to Home',
        ),
      ),
      body: BlocConsumer<BillHistoryBloc, BillHistoryState>(
        listener: (context, state) {
          // Handle any side effects here if needed
        },
        builder: (context, state) {
          if (state is BillHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BillHistoryLoaded) {
            if (state.bills.isEmpty) {
              return const Center(child: Text('No bills in history yet.'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<BillHistoryBloc>().add(LoadBillHistoryEvent());
              },
              child: ListView.builder(
                itemCount: state.bills.length,
                itemBuilder: (context, index) {
                  final bill = state.bills[index];
                  return ListTile(
                    title: Text(bill.description ?? 'Unnamed Bill'),
                    subtitle: Text(
                        'Bill Date: ${DateFormat.yMd().format(bill.billDate)}\n'
                        'Saved: ${DateFormat.yMd().add_jm().format(bill.createdAt)}\n'
                        'Total: ${NumberFormat('#,##0.00').format(bill.totalAmount)} ${bill.currencyCode}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
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
                      context.push('${AppRoutes.editBill}/${bill.id}');
                    },
                  );
                },
              ),
            );
          } else if (state is BillHistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<BillHistoryBloc>()
                          .add(LoadBillHistoryEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Press button to load history.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<BillHistoryBloc>().add(LoadBillHistoryEvent());
                  },
                  child: const Text('Load History'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
