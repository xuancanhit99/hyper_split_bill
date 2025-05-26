import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hyper_split_bill/core/usecases/usecase.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';
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
    print('BillHistoryBloc: Loading bill history...');
    emit(BillHistoryLoading());
    final failureOrHistory = await getBillHistoryUseCase(NoParams());
    failureOrHistory.fold(
      (failure) {
        print('BillHistoryBloc: Failed to load history: ${failure.message}');
        emit(BillHistoryError(failure.message));
      },
      (history) {
        print('BillHistoryBloc: Loaded ${history.length} bills successfully');
        emit(BillHistoryLoaded(history));
      },
    );
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
    print('BillHistoryBloc: Saving bill to history with ID: ${event.bill.id}');
    final failureOrSavedBill = await saveBillToHistoryUseCase(event.bill);

    await failureOrSavedBill.fold(
      (failure) async {
        print('BillHistoryBloc: Save failed with error: ${failure.message}');
        emit(BillHistoryError(failure.message));
      },
      (bill) async {
        print('BillHistoryBloc: Save successful, reloading history...');
        // Reload history after saving successfully
        emit(BillHistoryLoading());
        final failureOrHistory = await getBillHistoryUseCase(NoParams());
        failureOrHistory.fold(
          (failure) {
            print(
                'BillHistoryBloc: Failed to reload history after save: ${failure.message}');
            if (!emit.isDone) emit(BillHistoryError(failure.message));
          },
          (history) {
            print(
                'BillHistoryBloc: History reloaded after save with ${history.length} bills');
            if (!emit.isDone) emit(BillHistoryLoaded(history));
          },
        );
      },
    );
  }

  Future<void> _onUpdateBillInHistory(
      UpdateBillInHistoryEvent event, Emitter<BillHistoryState> emit) async {
    print(
        'BillHistoryBloc: Updating bill in history with ID: ${event.bill.id}');
    final failureOrUpdatedBill = await updateBillInHistoryUseCase(event.bill);

    await failureOrUpdatedBill.fold(
      (failure) async {
        print('BillHistoryBloc: Update failed with error: ${failure.message}');
        emit(BillHistoryError(failure.message));
      },
      (bill) async {
        print('BillHistoryBloc: Update successful, reloading history...');
        // Reload history after updating successfully
        emit(BillHistoryLoading());
        final failureOrHistory = await getBillHistoryUseCase(NoParams());
        failureOrHistory.fold(
          (failure) {
            print(
                'BillHistoryBloc: Failed to reload history: ${failure.message}');
            if (!emit.isDone) emit(BillHistoryError(failure.message));
          },
          (history) {
            print(
                'BillHistoryBloc: History reloaded successfully with ${history.length} bills');
            if (!emit.isDone) emit(BillHistoryLoaded(history));
          },
        );
      },
    );
  }

  Future<void> _onDeleteBillFromHistory(
      DeleteBillFromHistoryEvent event, Emitter<BillHistoryState> emit) async {
    print(
        'BillHistoryBloc: Deleting bill from history with ID: ${event.billId}');
    final failureOrVoid = await deleteBillFromHistoryUseCase(event.billId);

    await failureOrVoid.fold(
      (failure) async {
        print('BillHistoryBloc: Delete failed with error: ${failure.message}');
        emit(BillHistoryError(failure.message));
      },
      (_) async {
        print('BillHistoryBloc: Delete successful, reloading history...');
        // Reload history after deleting successfully
        emit(BillHistoryLoading());
        final failureOrHistory = await getBillHistoryUseCase(NoParams());
        failureOrHistory.fold(
          (failure) {
            print(
                'BillHistoryBloc: Failed to reload history after delete: ${failure.message}');
            if (!emit.isDone) emit(BillHistoryError(failure.message));
          },
          (history) {
            print(
                'BillHistoryBloc: History reloaded after delete with ${history.length} bills');
            if (!emit.isDone) emit(BillHistoryLoaded(history));
          },
        );
      },
    );
  }
}
