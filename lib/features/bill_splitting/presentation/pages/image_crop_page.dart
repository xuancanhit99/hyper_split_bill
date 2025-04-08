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
    final croppedFile = await ImageCropper().cropImage(
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

    if (croppedFile != null) {
      setState(() {
        _croppedFile = croppedFile;
      });
      // If cropping is successful, proceed to OCR
      _processCroppedImage(File(croppedFile.path));
    } else {
      // If user cancels cropping, go back to the previous screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _processCroppedImage(File croppedImageFile) {
    if (mounted) {
      // Dispatch event to Bloc with the cropped image
      context.read<BillSplittingBloc>().add(
            ProcessOcrEvent(imageFile: croppedImageFile),
          );
      // TODO: Add BlocListener here or on the previous page to handle navigation
      // after OCR processing starts/completes/fails.
      // For now, pop back after dispatching. Consider a loading indicator.
      Navigator.of(context)
          .pop(); // Pop back to upload page (or handle navigation via Bloc state)
    }
  }

  @override
  Widget build(BuildContext context) {
    // This page primarily shows the native cropper UI.
    // We can show a loading indicator while the cropper is initializing or processing.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cropping Image...'), // Temporary title
        automaticallyImplyLeading: false, // Hide back button as flow is handled
      ),
      body: const Center(
        // Show a loading indicator while the cropper UI is presented
        child: CircularProgressIndicator(),
      ),
    );
  }
}
