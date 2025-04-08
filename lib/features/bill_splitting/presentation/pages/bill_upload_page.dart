import 'dart:io'; // Will be needed for File type
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Will be needed for Bloc
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:hyper_split_bill/features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart';
import 'package:hyper_split_bill/injection_container.dart'; // For sl
import 'package:hyper_split_bill/core/router/app_router.dart'; // Import AppRoutes
import 'package:go_router/go_router.dart'; // Import go_router for context.push

// Wrap the page with BlocProvider to provide the Bloc instance
class BillUploadPage extends StatelessWidget {
  const BillUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocProvider is now handled by the router for this page and subsequent pages
    return const _BillUploadView();
  }
}

// Private widget containing the actual UI and state logic
class _BillUploadView extends StatefulWidget {
  const _BillUploadView();

  @override
  State<_BillUploadView> createState() => _BillUploadViewState();
}

class _BillUploadViewState extends State<_BillUploadView> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage; // To hold the selected image file
  // Removed _isLoading state variable, will use BlocBuilder instead

  // Function to pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      // Navigate to crop page and wait for result
      if (mounted) {
        final croppedFile = await GoRouter.of(context).push<File?>(
          AppRoutes.cropImage,
          extra: _selectedImage!.path,
        );

        // If a cropped file is returned, dispatch the OCR event
        if (croppedFile != null && mounted) {
          print("Cropped file received: ${croppedFile.path}");
          context.read<BillSplittingBloc>().add(
                ProcessOcrEvent(imageFile: croppedFile),
              );
        } else {
          print("Cropping cancelled or failed.");
          // Optionally clear the selected image if cropping is cancelled
          // setState(() { _selectedImage = null; });
        }
      }
    } else {
      print('No image selected.');
    }
  }

  // Function to take photo with camera
  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      // Navigate to crop page and wait for result
      if (mounted) {
        final croppedFile = await GoRouter.of(context).push<File?>(
          AppRoutes.cropImage,
          extra: _selectedImage!.path,
        );

        // If a cropped file is returned, dispatch the OCR event
        if (croppedFile != null && mounted) {
          print("Cropped file received: ${croppedFile.path}");
          context.read<BillSplittingBloc>().add(
                ProcessOcrEvent(imageFile: croppedFile),
              );
        } else {
          print("Cropping cancelled or failed.");
          // Optionally clear the selected image if cropping is cancelled
          // setState(() { _selectedImage = null; });
        }
      }
    } else {
      print('No image taken.');
    }
  }

  // Removed _navigateToNextStep as logic is now handled by dispatching events to Bloc

  @override
  Widget build(BuildContext context) {
    // Wrap the Scaffold with BlocListener to react to state changes
    return BlocListener<BillSplittingBloc, BillSplittingState>(
      listener: (context, state) {
        // No longer need to manage _isLoading here

        if (state is BillSplittingOcrSuccess) {
          // OCR Success: Navigate to the edit page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'OCR & Structuring Success! JSON length: ${state.structuredJson.length}. Navigating to edit...')), // Use structuredJson
          );
          // Navigate to BillEditPage, passing the extracted text
          context.push(AppRoutes.editBill,
              extra: state.structuredJson); // Use structuredJson
          // Clear the selected image after navigating (optional)
          // setState(() {
          //   _selectedImage = null;
          // });
        } else if (state is BillSplittingOcrFailure) {
          // OCR Failure: Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OCR Failed: ${state.message}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        // The actual UI remains inside the listener's child
        appBar: AppBar(
          title: const Text('Upload Bill'),
          // Remove loading indicator from AppBar actions
          actions: [], // Define an empty actions list
        ),
        // Use BlocBuilder to conditionally add a loading overlay using Stack
        body: BlocBuilder<BillSplittingBloc, BillSplittingState>(
          builder: (context, state) {
            final isLoading = state is BillSplittingOcrProcessing ||
                state is BillSplittingStructuring;

            return Stack(
              children: [
                // Main content (always present)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Display selected image preview (optional)
                        if (_selectedImage != null) ...[
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Placeholder
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Select an image or take a photo of your bill.',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],

                        // Buttons (still disable based on isLoading)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Choose from Gallery'),
                          onPressed: isLoading ? null : _pickImageFromGallery,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Take Photo'),
                          onPressed: isLoading ? null : _pickImageFromCamera,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading Overlay (conditionally shown)
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black
                          .withOpacity(0.5), // Semi-transparent background
                      child: Center(
                        child: Column(
                          // Added Column for text
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              state is BillSplittingStructuring
                                  ? 'Structuring data...' // Specific text for structuring
                                  : 'Processing image...', // Generic text for OCR
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
