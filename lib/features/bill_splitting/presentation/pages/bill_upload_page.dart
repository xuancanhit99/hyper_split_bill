import 'dart:io'; // Will be needed for File type
import 'dart:convert'; // Import for jsonDecode
import 'package:hyper_split_bill/core/constants/app_colors.dart'; // Import AppColors
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Will be needed for Bloc
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:hyper_split_bill/features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart';
import 'package:hyper_split_bill/injection_container.dart'; // For sl
import 'package:hyper_split_bill/core/router/app_router.dart'; // Import AppRoutes
import 'package:go_router/go_router.dart'; // Import go_router for context.push
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

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

        // If a cropped file is returned, update the UI and dispatch the OCR event
        if (croppedFile != null && mounted) {
          print("Cropped file received: ${croppedFile.path}");
          // Update the displayed image to the cropped one
          setState(() {
            _selectedImage = croppedFile;
          });
          // Dispatch the OCR event with the cropped file
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

        // If a cropped file is returned, update the UI and dispatch the OCR event
        if (croppedFile != null && mounted) {
          print("Cropped file received: ${croppedFile.path}");
          // Update the displayed image to the cropped one
          setState(() {
            _selectedImage = croppedFile;
          });
          // Dispatch the OCR event with the cropped file
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

  // Function to retry OCR with the existing selected image
  void _retryOcr() {
    if (_selectedImage != null) {
      // Dispatch the OCR event with the existing cropped file
      context.read<BillSplittingBloc>().add(
            ProcessOcrEvent(imageFile: _selectedImage!),
          );
    } else {
      print("Retry OCR called but no image is selected.");
      // Optionally show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            // Remove const
            content: Text(AppLocalizations.of(context)!
                .billUploadPageNoImageToRetrySnackbar)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the localization instance
    final l10n = AppLocalizations.of(context)!;

    // Wrap the Scaffold with BlocListener to react to state changes
    return BlocListener<BillSplittingBloc, BillSplittingState>(
      listener: (context, state) {
        // No longer need to manage _isLoading here

        if (state is BillSplittingOcrSuccess) {
          // OCR Success: Validate JSON before navigating
          bool isReceipt = false; // Default to false
          // Use localized default error message
          String errorMessage = l10n.billUploadPageProcessingErrorDefault;
          String imageCategory = l10n
              .billUploadPageUnknownCategory; // Use localized default category

          try {
            final data =
                jsonDecode(state.structuredJson) as Map<String, dynamic>;

            // --- Validation using is_receipt and image_category ---

            // 1. Check if 'is_receipt' field exists and is a boolean
            if (data.containsKey('is_receipt') && data['is_receipt'] is bool) {
              isReceipt = data['is_receipt'] as bool;

              if (!isReceipt) {
                // 2. If it's not a receipt, try to get the category
                imageCategory = data['image_category'] as String? ??
                    l10n.billUploadPageUnknownCategory; // Use localized default
                // Construct specific error message
                if (imageCategory == l10n.billUploadPageUnknownCategory) {
                  errorMessage =
                      l10n.billUploadPageNotAReceiptError; // Use l10n
                } else {
                  errorMessage = l10n.billUploadPageNotAReceiptButCategoryError(
                      imageCategory); // Use l10n with placeholder
                }
              }
              // If isReceipt is true, we don't need to set an error message here.
            } else {
              // Handle case where 'is_receipt' is missing or has wrong type
              print(
                  "Warning: 'is_receipt' field missing or not a boolean in JSON response.");
              errorMessage =
                  l10n.billUploadPageCannotDetermineReceiptError; // Use l10n
              isReceipt = false; // Treat as invalid if field is missing/wrong
            }
            // --- End Validation ---
          } catch (e) {
            print("Error decoding structured JSON: $e");
            errorMessage = l10n.billUploadPageJsonProcessingError; // Use l10n
            isReceipt = false; // Treat as invalid on decoding error
          }

          if (isReceipt) {
            // Navigate only if it's confirmed to be a receipt
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  // Remove const
                  content:
                      Text(l10n.billUploadPageOcrSuccessSnackbar)), // Use l10n
            );
            context.push(AppRoutes.editBill, extra: state.structuredJson);
          } else {
            // Show the specific error message if it's not a receipt or if an error occurred
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage), // Use the determined error message
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          // Clear the selected image after processing (optional)
          // setState(() { _selectedImage = null; });
        } else if (state is BillSplittingOcrFailure) {
          // OCR Failure: Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.billUploadPageOcrFailedSnackbar(
                  state.message)), // Use l10n with placeholder
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        // The actual UI remains inside the listener's child
        appBar: AppBar(
          title: Text(l10n.billUploadPageTitle), // Use l10n
          // Remove loading indicator from AppBar actions
          actions: [], // Define an empty actions list
        ),
        // Use BlocBuilder to conditionally add a loading overlay using Stack
        body: SafeArea(
          // Added SafeArea
          child: BlocBuilder<BillSplittingBloc, BillSplittingState>(
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
                            // Placeholder Image
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    8.0), // Add some padding around the placeholder
                                child: Image.asset(
                                  'assets/images/Two-Cat-Scan-Bill.png', // Path to your default image
                                  fit: BoxFit.contain, // Adjust fit as needed
                                ),
                              ),
                            ),
                          ],

                          // Add the Retry OCR button conditionally first
                          if (_selectedImage != null) ...[
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n
                                  .billUploadPageRetryOcrButtonLabel), // Use l10n
                              onPressed: isLoading ? null : _retryOcr,
                              // style property can be removed to use the default OutlinedButtonTheme
                              // or customized if needed, e.g., OutlinedButton.styleFrom(...)
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Buttons (still disable based on isLoading)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(l10n
                                .billUploadPageGalleryButtonLabel), // Use l10n
                            onPressed: isLoading ? null : _pickImageFromGallery,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(l10n
                                .billUploadPageCameraButtonLabel), // Use l10n
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
                                    ? l10n
                                        .billUploadPageLoadingStructuring // Use l10n
                                    : l10n
                                        .billUploadPageLoadingProcessing, // Use l10n
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
      ),
    );
  }
}
