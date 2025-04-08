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
    return BlocProvider(
      create: (context) => sl<BillSplittingBloc>(),
      child:
          const _BillUploadView(), // Use a private widget for the view content
    );
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
  bool _isLoading = false; // To track loading state for OCR

  // Function to pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      // Navigate to crop page
      if (mounted) {
        // Use go_router to push the crop page, passing the path
        GoRouter.of(context).push(AppRoutes.cropImage,
            extra: _selectedImage!.path); // Correct way to push
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
      // Navigate to crop page
      if (mounted) {
        // Use go_router to push the crop page, passing the path
        GoRouter.of(context).push(AppRoutes.cropImage,
            extra: _selectedImage!.path); // Correct way to push
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
        setState(() {
          // Update loading state based on Bloc state
          _isLoading = state is BillSplittingOcrProcessing;
        });

        if (state is BillSplittingOcrSuccess) {
          // OCR Success: Navigate to the edit page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'OCR Success! Text length: ${state.extractedText.length}. Navigating to edit...')),
          );
          // Navigate to BillEditPage, passing the extracted text
          context.push(AppRoutes.editBill, extra: state.extractedText);
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
          actions: [
            // Show loading indicator in AppBar
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))),
              ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Display selected image preview (optional)
                if (_selectedImage != null) ...[
                  Expanded(
                    // Use Expanded to allow image to take available space
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.contain, // Adjust fit as needed
                      ),
                    ),
                  ),
                ] else ...[
                  // Placeholder or instruction text when no image is selected
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Select an image or take a photo of your bill.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ],

                // Buttons at the bottom
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from Gallery'),
                  // Disable button while loading
                  onPressed: _isLoading ? null : _pickImageFromGallery,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take Photo'),
                  // Disable button while loading
                  onPressed: _isLoading ? null : _pickImageFromCamera,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // TODO: Wrap with BlocListener to handle state changes (loading, success, error)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Bill'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Display selected image preview (optional)
              if (_selectedImage != null) ...[
                Expanded(
                  // Use Expanded to allow image to take available space
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.contain, // Adjust fit as needed
                    ),
                  ),
                ),
              ] else ...[
                // Placeholder or instruction text when no image is selected
                const Expanded(
                  child: Center(
                    child: Text(
                      'Select an image or take a photo of your bill.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              ],

              // Buttons at the bottom
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from Gallery'),
                onPressed: _pickImageFromGallery,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take Photo'),
                onPressed: _pickImageFromCamera,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
