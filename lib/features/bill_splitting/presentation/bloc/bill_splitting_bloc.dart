library bill_splitting_bloc; // Define the library

import 'dart:convert'; // For jsonDecode
import 'dart:io'; // Import File
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart'; // Import Entity
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/get_bills_usecase.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/process_bill_ocr_usecase.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/create_bill_usecase.dart';
// TODO: Import other use cases (DeleteBill, etc.) when needed
import 'package:injectable/injectable.dart';

part 'bill_splitting_event.dart'; // Include the event file
part 'bill_splitting_state.dart'; // Include the state file

@lazySingleton // Make Bloc a singleton accessible via GetIt
class BillSplittingBloc extends Bloc<BillSplittingEvent, BillSplittingState> {
  final GetBillsUseCase _getBillsUseCase;
  final ProcessBillOcrUseCase _processBillOcrUseCase;
  final CreateBillUseCase _createBillUseCase;
  // TODO: Inject other use cases

  BillSplittingBloc(
    this._getBillsUseCase,
    this._processBillOcrUseCase,
    this._createBillUseCase,
    // TODO: Add other use cases (Update, Delete) to constructor
  ) : super(BillSplittingInitial()) {
    // Register event handlers
    on<FetchBillsEvent>(_onFetchBills);
    on<ProcessOcrEvent>(_onProcessOcr);
    on<SaveBillEvent>(_onSaveBill);
    // TODO: Register handlers for other events (SaveBill, DeleteBill, etc.)
  }

  // --- Event Handlers ---

  Future<void> _onFetchBills(
    FetchBillsEvent event,
    Emitter<BillSplittingState> emit,
  ) async {
    emit(BillSplittingLoading());
    final failureOrBills = await _getBillsUseCase();
    failureOrBills.fold(
      (failure) => emit(BillSplittingError(failure.message)),
      (bills) {
        // TODO: Decide how to emit loaded bills (maybe a specific state?)
        // For now, just logging or emitting a generic success/loaded state
        print('Fetched ${bills.length} bills');
        // emit(BillSplittingBillsLoaded(bills)); // Example state
        emit(BillSplittingInitial()); // Go back to initial for now
      },
    );
  }

  Future<void> _onProcessOcr(
    ProcessOcrEvent event,
    Emitter<BillSplittingState> emit,
  ) async {
    emit(BillSplittingOcrProcessing());
    final ocrResult = await _processBillOcrUseCase(imageFile: event.imageFile);

    await ocrResult.fold(
      // OCR failed directly
      (failure) async => emit(BillSplittingOcrFailure(failure.message)),
      // OCR succeeded, resultString might be structured JSON or raw text
      (resultString) async {
        // OCR trả về JSON trực tiếp
        print("Bloc: Received structured JSON from OCR.");
        emit(BillSplittingOcrSuccess(structuredJson: resultString));
      },
    );
  }

  Future<void> _onSaveBill(
    SaveBillEvent event,
    Emitter<BillSplittingState> emit,
  ) async {
    emit(BillSplittingLoading()); // Indicate saving process

    // TODO: Add logic here to also save associated items and participants
    // This might involve multiple repository calls or a dedicated use case/transaction.
    // For now, just save the main bill entity.

    final failureOrSavedBill = await _createBillUseCase(event.bill);

    failureOrSavedBill.fold(
        (failure) => emit(
            BillSplittingError(failure.message)), // Pass the raw error message
        (savedBill) {
      // TODO: Maybe update state with the saved bill (which now has an ID)
      // or navigate back/show success message.
      emit(const BillSplittingSuccess('Bill saved successfully!'));
      // Consider resetting state or navigating after success
      // emit(BillSplittingInitial());
    });
  }

// TODO: Implement handlers for DeleteBillEvent, UpdateBillEvent etc.
}
