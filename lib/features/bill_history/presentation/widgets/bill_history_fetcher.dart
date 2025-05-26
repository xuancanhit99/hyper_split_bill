import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_split_bill/features/bill_history/presentation/bloc/bill_history_bloc.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';
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

class _BillHistoryFetcherState extends State<BillHistoryFetcher> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _isInitialized = false;
  HistoricalBillEntity? _cachedBill;
  late String _currentBillId;

  @override
  void initState() {
    super.initState();
    _currentBillId = widget.billId;
    _loadBillDetailsIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBillDetailsIfNeeded();
  }

  @override
  void didUpdateWidget(BillHistoryFetcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.billId != widget.billId) {
      _currentBillId = widget.billId;
      _cachedBill = null; // Clear cache when bill ID changes
      _loadBillDetailsIfNeeded();
    }
  }

  void _loadBillDetailsIfNeeded() {
    // Skip loading if we're already initialized with the correct bill
    if (_isInitialized && _cachedBill != null && _cachedBill!.id == _currentBillId) {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // Check current bloc state first
    final currentState = context.read<BillHistoryBloc>().state;

    if (currentState is BillDetailsLoaded && currentState.bill.id == _currentBillId) {
      // Bill already loaded in the bloc
      setState(() {
        _cachedBill = currentState.bill;
        _isLoading = false;
        _isInitialized = true;
      });
    } else if (!_isInitialized || currentState is BillHistoryError) {
      // Need to load bill from repository
      setState(() {
        _isLoading = true;
      });
      context.read<BillHistoryBloc>().add(LoadBillDetailsEvent(_currentBillId));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);  // Required for AutomaticKeepAliveClientMixin

    // If we already have a cached bill, use it directly to avoid flickering
    if (_cachedBill != null && _cachedBill!.id == _currentBillId) {
      return BillEditPage(
        historicalBillToEdit: _cachedBill!,
        structuredJsonString: widget.structuredJsonString,
      );
    }

    return BlocConsumer<BillHistoryBloc, BillHistoryState>(
      listener: (context, state) {
        if (state is BillDetailsLoaded && state.bill.id == _currentBillId) {
          setState(() {
            _cachedBill = state.bill;
            _isLoading = false;
            _isInitialized = true;
          });
        } else if (state is BillHistoryError) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      builder: (context, state) {
        // If we have a cached bill, use it even if the bloc state is different
        if (_cachedBill != null && _cachedBill!.id == _currentBillId) {
          return BillEditPage(
            historicalBillToEdit: _cachedBill!,
            structuredJsonString: widget.structuredJsonString,
          );
        }

        if (state is BillDetailsLoaded && state.bill.id == _currentBillId) {
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
                      setState(() {
                        _isLoading = true;
                      });
                      context.read<BillHistoryBloc>().add(LoadBillDetailsEvent(_currentBillId));
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        // Loading state with a timeout
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('Loading bill $_currentBillId...'),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
