library bill_splitting_bloc; // Define the library

import 'dart:convert'; // For jsonDecode
import 'dart:io'; // Import File
import 'dart:typed_data'; // Import for Uint8List
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart'; // Import Entity
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/get_bills_usecase.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/process_bill_ocr_usecase.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/create_bill_usecase.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/update_bill_usecase.dart'; // Import UpdateBillUseCase
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/delete_bill_usecase.dart'; // Import DeleteBillUseCase
import 'package:injectable/injectable.dart';

part 'bill_splitting_event.dart'; // Include the event file
part 'bill_splitting_state.dart'; // Include the state file

@lazySingleton // Make Bloc a singleton accessible via GetIt
class BillSplittingBloc extends Bloc<BillSplittingEvent, BillSplittingState> {
  final GetBillsUseCase _getBillsUseCase;
  final ProcessBillOcrUseCase _processBillOcrUseCase;
  final CreateBillUseCase _createBillUseCase;
  final UpdateBillUseCase _updateBillUseCase; // Add UpdateBillUseCase
  final DeleteBillUseCase _deleteBillUseCase; // Add DeleteBillUseCase

  BillSplittingBloc(
    this._getBillsUseCase,
    this._processBillOcrUseCase,
    this._createBillUseCase,
    this._updateBillUseCase, // Inject UpdateBillUseCase
    this._deleteBillUseCase, // Inject DeleteBillUseCase
  ) : super(BillSplittingInitial()) {
    // Register event handlers
    on<FetchBillsEvent>(_onFetchBills);
    on<ProcessOcrEvent>(_onProcessOcr);
    on<SaveBillEvent>(
        _onSaveBill); // This handles both create and update based on bill.id
    on<DeleteBillEvent>(_onDeleteBill); // Register DeleteBillEvent handler
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

    // Use appropriate parameter based on platform (native file or web bytes)
    final ocrResult = await _processBillOcrUseCase(
      imageFile: event.imageFile,
      webImageBytes: event.webImageBytes,
    );

    await ocrResult.fold(
      // OCR failed directly
      (failure) async => emit(BillSplittingOcrFailure(failure.message)),
      // OCR succeeded, resultString might be structured JSON or raw text
      (resultString) async {
        // OCR returns direct JSON
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

    // If the bill has an ID, it's an update operation. Otherwise, it's a create operation.
    if (event.bill.id != null && event.bill.id!.isNotEmpty) {
      final failureOrUpdatedBill =
          await _updateBillUseCase(UpdateBillParams(bill: event.bill));
      failureOrUpdatedBill.fold(
        (failure) => emit(BillSplittingError(failure.message)),
        (updatedBill) {
          emit(BillSplittingSuccess('Bill updated successfully!',
              billEntity: updatedBill));
        },
      );
    } else {
      final failureOrCreatedBill = await _createBillUseCase(event.bill);
      failureOrCreatedBill.fold(
        (failure) => emit(BillSplittingError(failure.message)),
        (createdBill) {
          emit(BillSplittingSuccess('Bill created successfully!',
              billEntity: createdBill));
        },
      );
    }
  }

  Future<void> _onDeleteBill(
    DeleteBillEvent event,
    Emitter<BillSplittingState> emit,
  ) async {
    emit(BillSplittingLoading());
    final failureOrDeleted =
        await _deleteBillUseCase(DeleteBillParams(billId: event.billId));

    failureOrDeleted.fold(
      (failure) => emit(BillSplittingError(failure.message)),
      (_) => emit(BillSplittingSuccess(
          'Bill deleted successfully!')), // No specific entity to return on delete
    );
  }
}
