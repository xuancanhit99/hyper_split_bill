import 'dart:io'; // Will be needed for File type
import 'dart:convert'; // Import for jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

          final screenSize = MediaQuery.of(context).size;
          final cropperWidth = (screenSize.width * 0.9).clamp(0.0, 500.0);
          final cropperHeight = (screenSize.height * 0.8).clamp(0.0, 500.0);

          final CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: _imagePath!,
            uiSettings: [
              WebUiSettings(
                context: context,
                presentStyle: WebPresentStyle.dialog,
                size: CropperSize(
                    width: cropperWidth.toInt(), height: cropperHeight.toInt()),
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

          final screenSize = MediaQuery.of(context).size;
          final cropperWidth = (screenSize.width * 0.9).clamp(0.0, 500.0);
          final cropperHeight = (screenSize.height * 0.8).clamp(0.0, 500.0);

          final CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: _imagePath!,
            uiSettings: [
              WebUiSettings(
                context: context,
                presentStyle: WebPresentStyle.dialog,
                size: CropperSize(
                    width: cropperWidth.toInt(), height: cropperHeight.toInt()),
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

      final screenSize = MediaQuery.of(context).size;
      final cropperWidth = (screenSize.width * 0.9).clamp(0.0, 500.0);
      final cropperHeight = (screenSize.height * 0.8).clamp(0.0, 500.0);

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: _imagePath!,
        uiSettings: [
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: CropperSize(
                width: cropperWidth.toInt(), height: cropperHeight.toInt()),
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

  // Helper method to build image preview card
  Widget _buildImagePreviewCard({required Widget child}) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  // Helper method to build action cards
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required Color color,
    bool isOutlined = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: isOutlined ? Border.all(color: color, width: 2) : null,
        boxShadow: isOutlined
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOutlined
                        ? color.withOpacity(0.1)
                        : color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: onTap == null ? Colors.grey : null,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onTap == null
                                  ? Colors.grey
                                  : Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: onTap == null ? Colors.grey : color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(l10n.billUploadPageTitle),
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                Theme.of(context).brightness == Brightness.light
                    ? Brightness.dark
                    : Brightness.light,
            statusBarBrightness: Theme.of(context).brightness,
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<BillSplittingBloc, BillSplittingState>(
            builder: (context, state) {
              final isLoading = state is BillSplittingOcrProcessing ||
                  state is BillSplittingStructuring;

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.receipt_long,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Upload Your Bill',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Take a photo or select from gallery to get started',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Image Preview Section
                        if (_webImage != null && kIsWeb) ...[
                          _buildImagePreviewCard(
                            child:
                                Image.memory(_webImage!, fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 24),
                        ] else if (_selectedImage != null && !kIsWeb) ...[
                          _buildImagePreviewCard(
                            child: Image.file(_selectedImage!,
                                fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Action Buttons Section
                        Text(
                          'Choose Upload Method',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),

                        // Retry Button (appears first when image is selected)
                        if ((_selectedImage != null && !kIsWeb) ||
                            (_webImage != null && kIsWeb)) ...[
                          _buildActionCard(
                            context,
                            icon: Icons.refresh,
                            title: l10n.billUploadPageRetryOcrButtonLabel,
                            subtitle: 'Process the image again',
                            onTap: isLoading ? null : _retryOcr,
                            color: Colors.orange,
                            isOutlined: true,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Gallery Button
                        _buildActionCard(
                          context,
                          icon: Icons.photo_library_outlined,
                          title: l10n.billUploadPageGalleryButtonLabel,
                          subtitle: 'Select from your photo gallery',
                          onTap: isLoading ? null : _pickImageFromGallery,
                          color: Theme.of(context).colorScheme.primary,
                        ),

                        const SizedBox(height: 16),

                        // Camera Button
                        _buildActionCard(
                          context,
                          icon: Icons.camera_alt_outlined,
                          title: l10n.billUploadPageCameraButtonLabel,
                          subtitle: 'Take a new photo with camera',
                          onTap: isLoading ? null : _pickImageFromCamera,
                          color: Theme.of(context).colorScheme.secondary,
                        ),

                        const SizedBox(height: 32),
                      ],
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
