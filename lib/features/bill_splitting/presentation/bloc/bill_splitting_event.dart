part of 'bill_splitting_bloc.dart'; // Use 'part of' for multi-file Bloc setup

abstract class BillSplittingEvent extends Equatable {
  const BillSplittingEvent();

  @override
  List<Object?> get props => [];
}

// Event to trigger fetching the list of existing bills
class FetchBillsEvent extends BillSplittingEvent {}

// Event to trigger fetching details of a specific bill
class FetchBillDetailsEvent extends BillSplittingEvent {
  final String billId;
  const FetchBillDetailsEvent(this.billId);
  @override
  List<Object?> get props => [billId];
}

// Event triggered when an image is selected/captured
class ImageSelectedEvent extends BillSplittingEvent {
  final File imageFile;
  const ImageSelectedEvent(this.imageFile);
  @override
  List<Object?> get props => [imageFile];
}

// Event to trigger OCR processing on the selected image
class ProcessOcrEvent extends BillSplittingEvent {
  final File? imageFile; // File for native platforms
  final Uint8List? webImageBytes; // Image bytes for web platform
  final String? prompt; // Optional prompt for OCR
  const ProcessOcrEvent({this.imageFile, this.webImageBytes, this.prompt});
  @override
  List<Object?> get props => [imageFile, webImageBytes, prompt];
}

// Event to save the current bill data (new or updated)
class SaveBillEvent extends BillSplittingEvent {
  final BillEntity bill;
  // TODO: Potentially pass items and participants lists as well, or handle them via Bloc state
  const SaveBillEvent(this.bill);
  @override
  List<Object?> get props => [bill];
}

// Event to delete a bill
class DeleteBillEvent extends BillSplittingEvent {
  final String billId;
  const DeleteBillEvent(this.billId);
  @override
  List<Object?> get props => [billId];
}

// TODO: Add events for adding/removing participants, assigning items, chat interactions etc.
// class AddParticipantEvent extends BillSplittingEvent { ... }
// class AssignItemEvent extends BillSplittingEvent { ... }
// class SendChatMessageEvent extends BillSplittingEvent { ... }
