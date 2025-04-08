part of 'bill_splitting_bloc.dart'; // Use 'part of' for multi-file Bloc setup

// Imports will be handled in bill_splitting_bloc.dart

abstract class BillSplittingState extends Equatable {
  // Use 'extends'
  const BillSplittingState();

  @override
  List<Object?> get props => [];
}

// Initial state before anything happens
class BillSplittingInitial extends BillSplittingState {}

// State when loading data (e.g., fetching bill details, saving)
class BillSplittingLoading extends BillSplittingState {}

// State when OCR processing is in progress
class BillSplittingOcrProcessing extends BillSplittingState {}

// State after OCR successfully extracts text
class BillSplittingOcrSuccess extends BillSplittingState {
  final String extractedText;
  // TODO: Potentially include parsed BillEntity/Items data here after initial parsing
  // final BillEntity initialParsedBill;

  const BillSplittingOcrSuccess({required this.extractedText});

  @override
  List<Object?> get props => [extractedText];
}

// State when OCR processing fails
class BillSplittingOcrFailure extends BillSplittingState {
  final String message;
  const BillSplittingOcrFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// State when bill data (including items, participants, assignments) is loaded for editing/viewing
class BillSplittingDataLoaded extends BillSplittingState {
  final BillEntity bill;
  // TODO: Add lists for items, participants, assignments
  // final List<BillItemEntity> items;
  // final List<ParticipantEntity> participants;

  const BillSplittingDataLoaded({required this.bill});

  @override
  List<Object?> get props => [bill]; // Add items, participants later
}

// State indicating the bill has been successfully saved/updated
class BillSplittingSuccess extends BillSplittingState {
  final String message; // e.g., "Bill saved successfully!"
  const BillSplittingSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// General error state for other operations (saving, loading details etc.)
class BillSplittingError extends BillSplittingState {
  final String message;
  const BillSplittingError(this.message);

  @override
  List<Object?> get props => [message];
}
