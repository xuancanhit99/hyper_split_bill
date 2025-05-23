import 'dart:io'; // Will be needed for File type
import 'dart:convert'; // Import for jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Will be needed for Bloc
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:image_cropper/image_cropper.dart'; // For cropping images
import 'package:hyper_split_bill/features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart';
import 'package:hyper_split_bill/injection_container.dart'; // For sl
import 'package:hyper_split_bill/core/router/app_router.dart'; // Import AppRoutes
import 'package:go_router/go_router.dart'; // Import go_router for context.push
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'dart:typed_data'; // Import for Uint8List
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/process_bill_ocr_usecase.dart';

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
  File? _selectedImage;
  Uint8List? _webImage;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
  }

  // Function to pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        try {
          setState(() {
            _imagePath = pickedFile.path;
            _selectedImage = null;
            _webImage =
                null; // Clear previous web image before starting new crop
          });

          final CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: _imagePath!,
            uiSettings: [
              WebUiSettings(
                context: context,
                presentStyle: WebPresentStyle.dialog,
                size: const CropperSize(width: 500, height: 500),
                // viewwMode parameter does not exist in WebUiSettings for version 9.1.0
                dragMode: WebDragMode.crop,
                movable: true,
                rotatable: true,
                scalable: true,
                zoomable: true,
                cropBoxMovable: true,
                cropBoxResizable: true,
                checkOrientation: true,
                // Adding translations for buttons if needed
                // translations: WebTranslations(
                //   title: AppLocalizations.of(context).cropperTitle ?? 'Crop Image',
                //   btnConfirm: AppLocalizations.of(context).cropperBtnConfirm ?? 'Confirm',
                //   btnCancel: AppLocalizations.of(context).cropperBtnCancel ?? 'Cancel',
                // ),
              ),
            ],
          );

          if (croppedFile != null) {
            final Uint8List croppedBytes = await croppedFile.readAsBytes();
            setState(() {
              _webImage = croppedBytes;
            });
            context.read<BillSplittingBloc>().add(
                  ProcessOcrEvent(imageFile: null, webImageBytes: _webImage),
                );
          } else {
            // _webImage is already null from above
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)
                      .billUploadPageCropFailedOrCancelledSnackbar)), // Using the new key
            );
          }
        } catch (e) {
          print("Error during web image picking/cropping from gallery: $e");
          setState(() {
            // Ensure _webImage is null on error too
            _webImage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)
                  .billUploadPageOcrFailedSnackbar(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } else {
        // For native platforms, continue with existing flow
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        // Navigate to crop page and wait for result
        if (mounted) {
          final croppedFile = await GoRouter.of(context).push<File?>(
            AppRoutes.cropImage,
            extra: _selectedImage!.path,
          );

          if (croppedFile != null && mounted) {
            setState(() {
              _selectedImage = croppedFile;
              _webImage = null; // Clear web image reference
            });
            // Dispatch the OCR event with the cropped file
            context.read<BillSplittingBloc>().add(
                  ProcessOcrEvent(imageFile: croppedFile),
                );
          }
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
      if (kIsWeb) {
        try {
          setState(() {
            _imagePath = pickedFile.path;
            _selectedImage = null;
            _webImage = null; // Clear previous web image
          });

          final CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: _imagePath!,
            uiSettings: [
              WebUiSettings(
                context: context,
                presentStyle: WebPresentStyle.dialog,
                size: const CropperSize(width: 500, height: 500),
                // viewwMode parameter does not exist in WebUiSettings for version 9.1.0
                dragMode: WebDragMode.crop,
                movable: true,
                rotatable: true,
                scalable: true,
                zoomable: true,
                cropBoxMovable: true,
                cropBoxResizable: true,
                checkOrientation: true,
                // translations: WebTranslations(
                //   title: AppLocalizations.of(context).cropperTitle ?? 'Crop Image',
                //   btnConfirm: AppLocalizations.of(context).cropperBtnConfirm ?? 'Confirm',
                //   btnCancel: AppLocalizations.of(context).cropperBtnCancel ?? 'Cancel',
                // ),
              ),
            ],
          );

          if (croppedFile != null) {
            final Uint8List croppedBytes = await croppedFile.readAsBytes();
            setState(() {
              _webImage = croppedBytes;
            });
            context.read<BillSplittingBloc>().add(
                  ProcessOcrEvent(imageFile: null, webImageBytes: _webImage),
                );
          } else {
            // _webImage is already null
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)
                      .billUploadPageCropFailedOrCancelledSnackbar)), // Using the new key
            );
          }
        } catch (e) {
          print("Error during web image picking/cropping from camera: $e");
          setState(() {
            // Ensure _webImage is null on error too
            _webImage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)
                  .billUploadPageOcrFailedSnackbar(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } else {
        // For native platforms, continue with existing flow
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        // Navigate to crop page and wait for result
        if (mounted) {
          final croppedFile = await GoRouter.of(context).push<File?>(
            AppRoutes.cropImage,
            extra: _selectedImage!.path,
          );

          if (croppedFile != null && mounted) {
            setState(() {
              _selectedImage = croppedFile;
              _webImage = null;
            });
            context.read<BillSplittingBloc>().add(
                  ProcessOcrEvent(imageFile: croppedFile),
                );
          }
        }
      }
    } else {
      print('No image taken.');
    }
  }

  // Function to retry OCR with the existing image
  Future<void> _retryOcr() async {
    // For web platform
    if (kIsWeb && _imagePath != null) {
      setState(() {
        _webImage = null; // Clear previous web image before retrying crop
      });
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: _imagePath!,
        uiSettings: [
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 500, height: 500),
            // viewwMode parameter does not exist in WebUiSettings for version 9.1.0
            dragMode: WebDragMode.crop,
            movable: true,
            rotatable: true,
            scalable: true,
            zoomable: true,
            cropBoxMovable: true,
            cropBoxResizable: true,
            checkOrientation: true,
            // translations: WebTranslations(
            //   title: AppLocalizations.of(context).cropperTitle ?? 'Crop Image',
            //   btnConfirm: AppLocalizations.of(context).cropperBtnConfirm ?? 'Confirm',
            //   btnCancel: AppLocalizations.of(context).cropperBtnCancel ?? 'Cancel',
            // ),
          ),
        ],
      );

      if (croppedFile != null) {
        final Uint8List croppedBytes = await croppedFile.readAsBytes();
        setState(() {
          _webImage = croppedBytes;
        });
        context.read<BillSplittingBloc>().add(
              ProcessOcrEvent(imageFile: null, webImageBytes: _webImage),
            );
      } else {
        // _webImage is already null
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .billUploadPageCropFailedOrCancelledSnackbar)), // Using the new key
        );
      }
    }
    // For native platforms
    else if (!kIsWeb && _selectedImage != null) {
      print("Retrying OCR: Navigating to crop page for existing image.");
      final croppedFile = await GoRouter.of(context).push<File?>(
        AppRoutes.cropImage,
        extra: _selectedImage!.path,
      );

      if (croppedFile != null && mounted) {
        setState(() {
          _selectedImage = croppedFile;
        });
        context.read<BillSplittingBloc>().add(
              ProcessOcrEvent(imageFile: croppedFile),
            );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .billUploadPageCropCancelledSnackbar),
          ),
        );
      }
    } else {
      print("Retry OCR called but no image is selected.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)
              .billUploadPageNoImageToRetrySnackbar),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<BillSplittingBloc, BillSplittingState>(
      listener: (context, state) {
        if (state is BillSplittingOcrSuccess) {
          bool isReceipt = false;
          String errorMessage = l10n.billUploadPageProcessingErrorDefault;
          String imageCategory = l10n.billUploadPageUnknownCategory;

          try {
            final data =
                jsonDecode(state.structuredJson) as Map<String, dynamic>;

            if (data.containsKey('is_receipt') && data['is_receipt'] is bool) {
              isReceipt = data['is_receipt'] as bool;

              if (!isReceipt) {
                imageCategory = data['image_category'] as String? ??
                    l10n.billUploadPageUnknownCategory;
                errorMessage =
                    imageCategory == l10n.billUploadPageUnknownCategory
                        ? l10n.billUploadPageNotAReceiptError
                        : l10n.billUploadPageNotAReceiptButCategoryError(
                            imageCategory);
              }
            } else {
              print(
                  "'is_receipt' field missing or not boolean in JSON response.");
              errorMessage = l10n.billUploadPageCannotDetermineReceiptError;
              isReceipt = false;
            }
          } catch (e) {
            print("Error decoding structured JSON: $e");
            errorMessage = l10n.billUploadPageJsonProcessingError;
            isReceipt = false;
          }

          if (isReceipt) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.billUploadPageOcrSuccessSnackbar)),
            );
            context.push(AppRoutes.editBill, extra: state.structuredJson);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        } else if (state is BillSplittingOcrFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(l10n.billUploadPageOcrFailedSnackbar(state.message)),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.billUploadPageTitle),
        ),
        body: SafeArea(
          child: BlocBuilder<BillSplittingBloc, BillSplittingState>(
            builder: (context, state) {
              final isLoading = state is BillSplittingOcrProcessing ||
                  state is BillSplittingStructuring;

              return Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (_webImage != null && kIsWeb) ...[
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Image.memory(
                                  _webImage!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ] else if (_selectedImage != null && !kIsWeb) ...[
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
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  'assets/images/Two-Cat-Scan-Bill.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                          if ((_selectedImage != null && !kIsWeb) ||
                              (_webImage != null && kIsWeb)) ...[
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label:
                                  Text(l10n.billUploadPageRetryOcrButtonLabel),
                              onPressed: isLoading ? null : _retryOcr,
                            ),
                            const SizedBox(height: 16),
                          ],
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(l10n.billUploadPageGalleryButtonLabel),
                            onPressed: isLoading ? null : _pickImageFromGallery,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(l10n.billUploadPageCameraButtonLabel),
                            onPressed: isLoading ? null : _pickImageFromCamera,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                state is BillSplittingStructuring
                                    ? l10n.billUploadPageLoadingStructuring
                                    : l10n.billUploadPageLoadingProcessing,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
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
