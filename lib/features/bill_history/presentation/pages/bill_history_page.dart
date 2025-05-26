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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load bill history when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });

    // Listen to search input changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _loadHistory() {
    context.read<BillHistoryBloc>().add(LoadBillHistoryEvent());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload history when page becomes visible again
    final currentState = context.read<BillHistoryBloc>().state;
    if (currentState is! BillHistoryLoaded &&
        currentState is! BillHistoryLoading) {
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          // Auto-reload if state is reset to initial
          if (state is BillHistoryInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<BillHistoryBloc>().add(LoadBillHistoryEvent());
            });
          }
        },
        builder: (context, state) {
          if (state is BillHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BillHistoryLoaded) {
            // Filter bills based on search query
            final filteredBills = state.bills.where((bill) {
              final description =
                  (bill.description ?? 'Unnamed Bill').toLowerCase();
              final totalAmount = bill.totalAmount.toString();
              final currencyCode = bill.currencyCode.toLowerCase();
              final billDate = DateFormat.yMd().format(bill.billDate);

              return description.contains(_searchQuery) ||
                  totalAmount.contains(_searchQuery) ||
                  currencyCode.contains(_searchQuery) ||
                  billDate.contains(_searchQuery);
            }).toList();

            return Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search bills...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                // Bills List
                Expanded(
                  child: filteredBills.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? 'No bills found matching "$_searchQuery"'
                                : 'No bills in history yet.',
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            context
                                .read<BillHistoryBloc>()
                                .add(LoadBillHistoryEvent());
                          },
                          child: ListView.builder(
                            itemCount: filteredBills.length,
                            itemBuilder: (context, index) {
                              final bill = filteredBills[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 4.0,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16.0),
                                  title: Text(
                                    bill.description ?? 'Unnamed Bill',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Bill Date: ${DateFormat.yMd().format(bill.billDate)}',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.save,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Saved: ${DateFormat.yMd().add_jm().format(bill.createdAt)}',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Total: ${NumberFormat('#,##0.00').format(bill.totalAmount)} ${bill.currencyCode}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
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
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                            TextButton(
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                              onPressed: () {
                                                context
                                                    .read<BillHistoryBloc>()
                                                    .add(
                                                        DeleteBillFromHistoryEvent(
                                                            bill.id));
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    context.push(
                                        '${AppRoutes.editBill}/${bill.id}');
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
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

          // For any other state (like BillHistoryInitial), auto-load and show loading
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<BillHistoryBloc>().add(LoadBillHistoryEvent());
            }
          });

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
