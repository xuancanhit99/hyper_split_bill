part of 'bill_history_bloc.dart';

// Imports moved to bill_history_bloc.dart

abstract class BillHistoryState extends Equatable {
  const BillHistoryState();

  @override
  List<Object?> get props => [];
}

class BillHistoryInitial extends BillHistoryState {}

class BillHistoryLoading extends BillHistoryState {}

class BillHistoryLoaded extends BillHistoryState {
  final List<HistoricalBillEntity> bills;

  const BillHistoryLoaded(this.bills);

  @override
  List<Object?> get props => [bills];
}

class BillDetailsLoading extends BillHistoryState {}

class BillDetailsLoaded extends BillHistoryState {
  final HistoricalBillEntity bill;

  const BillDetailsLoaded(this.bill);

  @override
  List<Object?> get props => [bill];
}

class BillHistoryActionSuccess extends BillHistoryState {
  final String? message; // Optional success message
  const BillHistoryActionSuccess({this.message});

  @override
  List<Object?> get props => [message];
}

class BillHistoryError extends BillHistoryState {
  final String message;

  const BillHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
