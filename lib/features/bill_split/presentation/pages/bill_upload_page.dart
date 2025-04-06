// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
// import 'package:go_router/go_router.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:hyper_split_bill/core/router/app_router.dart';
// import 'package:hyper_split_bill/features/bill_split/presentation/bloc/ocr/ocr_bloc.dart'; // Import the Bloc
// import 'package:hyper_split_bill/injection_container.dart'; // Import GetIt instance
//
// class BillUploadPage extends StatelessWidget {
//   const BillUploadPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // Provide the OcrBloc instance scoped to this page
//     return BlocProvider(
//       create: (context) => sl<OcrBloc>(), // Get instance from GetIt/Injectable
//       child: const BillUploadView(), // Separate the view logic
//     );
//   }
// }
//
//
// // --- Separate View Widget ---
// class BillUploadView extends StatefulWidget {
//   const BillUploadView({super.key});
//
//   @override
//   State<BillUploadView> createState() => _BillUploadViewState();
// }
//
// class _BillUploadViewState extends State<BillUploadView> {
//   File? _selectedImage;
//   final ImagePicker _picker = ImagePicker();
//
//   // Methods _pickImage and _cropImage remain the same as before...
//   Future<void> _pickImage(ImageSource source) async {
//     // Reset OCR state when picking a new image
//     context.read<OcrBloc>().add(OcrReset());
//     final pickedFile = await _picker.pickImage(source: source);
//     if (pickedFile != null) {
//       _cropImage(File(pickedFile.path));
//     } else {
//       setState(() { _selectedImage = null; }); // Clear selection if picker cancelled
//     }
//   }
//
//   Future<void> _cropImage(File imageFile) async {
//     final croppedFile = await ImageCropper().cropImage(
//       // ... (cropping settings remain the same)
//       sourcePath: imageFile.path,
//       aspectRatioPresets: [ /* ... */ ],
//       uiSettings: [ /* ... */ ],
//     );
//
//     if (croppedFile != null) {
//       setState(() {
//         _selectedImage = File(croppedFile.path);
//       });
//     } else {
//       // If cropping is cancelled, revert to the original picked file?
//       // Or just clear the selection? Let's clear it for simplicity.
//       setState(() { _selectedImage = null; });
//       context.read<OcrBloc>().add(OcrReset()); // Also reset Bloc state
//     }
//   }
//
//
//   // --- Updated _proceedToOcr ---
//   void _proceedToOcr() {
//     if (_selectedImage != null) {
//       // Dispatch the event to the Bloc
//       context.read<OcrBloc>().add(OcrRequested(_selectedImage!));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select and crop an image first')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Use BlocListener to react to state changes (navigation, errors)
//     return BlocListener<OcrBloc, OcrState>(
//       listener: (context, state) {
//         if (state is OcrSuccess) {
//           // Navigate to Edit Page on Success
//           // Pass the structured data to the next screen
//           context.push(AppRouter.editPath, extra: state.extractedData);
//         } else if (state is OcrFailure) {
//           // Show error message on Failure
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('OCR Failed: ${state.error}'),
//               backgroundColor: Theme.of(context).colorScheme.error,
//             ),
//           );
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(title: const Text('Upload & Analyze Bill')),
//         body: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: <Widget>[
//                 // --- Image Preview ---
//                 if (_selectedImage != null)
//                   Container( /* ... Image preview same as before ... */
//                     constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
//                     margin: const EdgeInsets.only(bottom: 20),
//                     decoration: BoxDecoration(border: Border.all(color: Theme.of(context).primaryColor)),
//                     child: Image.file(_selectedImage!),
//                   )
//                 else
//                   Container( /* ... Placeholder same as before ... */
//                     height: 200,
//                     width: double.infinity,
//                     color: Colors.grey[300],
//                     margin: const EdgeInsets.only(bottom: 20),
//                     child: const Center(child: Text('Select or Capture an Image')),
//                   ),
//
//                 // --- Action Buttons ---
//                 Row( /* ... Gallery/Camera buttons same as before ... */ ),
//                 const SizedBox(height: 30),
//
//                 // --- Analyze Button with Loading Indicator ---
//                 BlocBuilder<OcrBloc, OcrState>( // Use BlocBuilder to show loading
//                   builder: (context, state) {
//                     // Show loading indicator inside the button or disable it
//                     bool isLoading = state is OcrLoading;
//
//                     return ElevatedButton.icon(
//                       icon: isLoading
//                           ? Container( // Replace icon with spinner
//                         width: 24,
//                         height: 24,
//                         padding: const EdgeInsets.all(2.0),
//                         child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
//                       )
//                           : const Icon(Icons.receipt_long),
//                       label: Text(isLoading ? 'Analyzing...' : 'Analyze Receipt'),
//                       style: ElevatedButton.styleFrom(
//                         minimumSize: const Size(double.infinity, 50),
//                         // Optionally change color when loading
//                         backgroundColor: isLoading ? Colors.grey : null,
//                       ),
//                       // Disable button when loading or if no image selected
//                       onPressed: (isLoading || _selectedImage == null) ? null : _proceedToOcr,
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }