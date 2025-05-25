part of 'bill_history_bloc.dart';

// Imports moved to bill_history_bloc.dart

abstract class BillHistoryEvent extends Equatable {
  const BillHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadBillHistoryEvent extends BillHistoryEvent {}

class LoadBillDetailsEvent extends BillHistoryEvent {
  final String billId;

  const LoadBillDetailsEvent(this.billId);

  @override
  List<Object?> get props => [billId];
}

class SaveBillToHistoryEvent extends BillHistoryEvent {
  final HistoricalBillEntity bill;

  const SaveBillToHistoryEvent(this.bill);

  @override
  List<Object?> get props => [bill];
}

class UpdateBillInHistoryEvent extends BillHistoryEvent {
  final HistoricalBillEntity bill;

  const UpdateBillInHistoryEvent(this.bill);

  @override
  List<Object?> get props => [bill];
}

class DeleteBillFromHistoryEvent extends BillHistoryEvent {
  final String billId;

  const DeleteBillFromHistoryEvent(this.billId);

  @override
  List<Object?> get props => [billId];
}
