import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart';
import 'package:hyper_split_bill/core/constants/app_colors.dart'; // For theme colors if needed

class ImageCropPage extends StatefulWidget {
  final String imagePath; // Receive the path of the image to crop

  const ImageCropPage({super.key, required this.imagePath});

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  CroppedFile? _croppedFile;

  @override
  void initState() {
    super.initState();
    // Start cropping after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Ensure the widget is still mounted
        _cropImage();
      }
    });
  }

  Future<void> _cropImage() async {
    CroppedFile? croppedFile; // Declare outside try
    try {
      croppedFile = await ImageCropper().cropImage(
        // Assign to the existing variable, remove 'final'
        sourcePath: widget.imagePath,
        // aspectRatioPresets parameter removed, handled within uiSettings if needed
        uiSettings: [
          // Customize the cropper UI
          AndroidUiSettings(
              toolbarTitle: 'Crop Bill Image',
              toolbarColor: Theme.of(context).appBarTheme.backgroundColor ??
                  AppColors.facebookBlue, // Use theme color
              toolbarWidgetColor:
                  Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Crop Bill Image',
            // Add iOS specific settings if needed
          ),
          // WebUiSettings( // Add Web settings if needed
          //   context: context,
          // ),
        ],
      );
    } catch (e) {
      print("Error during image cropping: $e");
      // Optionally show a SnackBar error message before popping
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e')),
        );
      }
    } finally {
      // Ensure we always try to pop, regardless of success, failure, or cancellation
      if (mounted) {
        // Pop and return the result (null if cancelled or error)
        Navigator.of(context)
            .pop(croppedFile == null ? null : File(croppedFile.path));
      }
    }
    // _processCroppedImage is no longer needed here as we return the result via pop

    // Logic moved to finally block
  }

  // Removed _processCroppedImage function

  @override
  Widget build(BuildContext context) {
    // This page's primary purpose is to launch the native cropper UI.
    // We don't need to show much in the Flutter UI itself.
    return const Scaffold(
      // Optional: Keep AppBar for context, or remove entirely for cleaner transition
      // appBar: AppBar(
      //   title: const Text('Cropping Image...'),
      //   automaticallyImplyLeading: false,
      // ),
      body: SafeArea(
        // Added SafeArea
        child: Center(
            child:
                CircularProgressIndicator()), // Keep indicator for visual feedback
      ),
    );
    // Alternatively, return const SizedBox.shrink(); for a completely blank Flutter UI.
  }
}
