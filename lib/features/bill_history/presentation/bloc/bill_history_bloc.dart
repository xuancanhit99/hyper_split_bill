import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hyper_split_bill/core/usecases/usecase.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart'; // Ensure this is imported
import 'package:hyper_split_bill/features/bill_history/domain/usecases/delete_bill_from_history_usecase.dart';
import 'package:hyper_split_bill/features/bill_history/domain/usecases/get_bill_details_from_history_usecase.dart';
import 'package:hyper_split_bill/features/bill_history/domain/usecases/get_bill_history_usecase.dart';
import 'package:hyper_split_bill/features/bill_history/domain/usecases/save_bill_to_history_usecase.dart';
import 'package:hyper_split_bill/features/bill_history/domain/usecases/update_bill_in_history_usecase.dart';
import 'package:injectable/injectable.dart';

part 'bill_history_event.dart';
part 'bill_history_state.dart';

@injectable
class BillHistoryBloc extends Bloc<BillHistoryEvent, BillHistoryState> {
  final GetBillHistoryUseCase getBillHistoryUseCase;
  final GetBillDetailsFromHistoryUseCase getBillDetailsFromHistoryUseCase;
  final SaveBillToHistoryUseCase saveBillToHistoryUseCase;
  final UpdateBillInHistoryUseCase updateBillInHistoryUseCase;
  final DeleteBillFromHistoryUseCase deleteBillFromHistoryUseCase;

  BillHistoryBloc({
    required this.getBillHistoryUseCase,
    required this.getBillDetailsFromHistoryUseCase,
    required this.saveBillToHistoryUseCase,
    required this.updateBillInHistoryUseCase,
    required this.deleteBillFromHistoryUseCase,
  }) : super(BillHistoryInitial()) {
    on<LoadBillHistoryEvent>(_onLoadBillHistory);
    on<LoadBillDetailsEvent>(_onLoadBillDetails);
    on<SaveBillToHistoryEvent>(_onSaveBillToHistory);
    on<UpdateBillInHistoryEvent>(_onUpdateBillInHistory);
    on<DeleteBillFromHistoryEvent>(_onDeleteBillFromHistory);
  }

  Future<void> _onLoadBillHistory(
      LoadBillHistoryEvent event, Emitter<BillHistoryState> emit) async {
    emit(BillHistoryLoading());
    final failureOrHistory = await getBillHistoryUseCase(NoParams());
    emit(failureOrHistory.fold(
      (failure) => BillHistoryError(failure.message),
      (history) => BillHistoryLoaded(history),
    ));
  }

  Future<void> _onLoadBillDetails(
      LoadBillDetailsEvent event, Emitter<BillHistoryState> emit) async {
    emit(BillDetailsLoading());
    final failureOrBill = await getBillDetailsFromHistoryUseCase(event.billId);
    emit(failureOrBill.fold(
      (failure) => BillHistoryError(failure.message),
      (bill) => BillDetailsLoaded(bill),
    ));
  }

  Future<void> _onSaveBillToHistory(
      SaveBillToHistoryEvent event, Emitter<BillHistoryState> emit) async {
    // emit(BillHistoryLoading()); // Or a specific loading state for this action
    final failureOrSavedBill = await saveBillToHistoryUseCase(event.bill);
    emit(failureOrSavedBill.fold(
      (failure) => BillHistoryError(failure.message),
      (bill) {
        // Optionally, reload the entire history or just emit success
        add(LoadBillHistoryEvent()); // Reload history after saving
        return BillHistoryActionSuccess(message: 'Bill saved successfully!');
      },
    ));
  }

  Future<void> _onUpdateBillInHistory(
      UpdateBillInHistoryEvent event, Emitter<BillHistoryState> emit) async {
    // emit(BillHistoryLoading()); // Or a specific loading state for this action
    final failureOrUpdatedBill = await updateBillInHistoryUseCase(event.bill);
    emit(failureOrUpdatedBill.fold(
      (failure) => BillHistoryError(failure.message),
      (bill) {
        add(LoadBillHistoryEvent()); // Reload history after updating
        return BillHistoryActionSuccess(message: 'Bill updated successfully!');
      },
    ));
  }

  Future<void> _onDeleteBillFromHistory(
      DeleteBillFromHistoryEvent event, Emitter<BillHistoryState> emit) async {
    // emit(BillHistoryLoading()); // Or a specific loading state for this action
    final failureOrVoid = await deleteBillFromHistoryUseCase(event.billId);
    emit(failureOrVoid.fold(
      (failure) => BillHistoryError(failure.message),
      (_) {
        add(LoadBillHistoryEvent()); // Reload history after deleting
        return BillHistoryActionSuccess(message: 'Bill deleted successfully!');
      },
    ));
  }
}
