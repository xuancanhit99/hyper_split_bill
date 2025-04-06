// part of 'ocr_bloc.dart'; // Link to the Bloc file
//
// abstract class OcrEvent extends Equatable {
//   const OcrEvent();
//
//   @override
//   List<Object?> get props => [];
// }
//
// // Event triggered when user wants to start OCR process
// class OcrRequested extends OcrEvent {
//   final File imageFile;
//   final String? prompt; // Optional custom prompt
//
//   const OcrRequested(this.imageFile, {this.prompt});
//
//   @override
//   List<Object?> get props => [imageFile, prompt];
// }
//
// // Optional: Event to reset the OCR state back to initial
// class OcrReset extends OcrEvent {}