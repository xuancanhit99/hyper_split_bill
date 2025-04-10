import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Import compressor
import 'package:path_provider/path_provider.dart'; // Import path_provider
import 'package:hyper_split_bill/features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart';
import 'package:hyper_split_bill/core/constants/app_colors.dart'; // For theme colors if needed

class ImageCropPage extends StatefulWidget {
  final String imagePath; // Receive the path of the image to crop

  const ImageCropPage({super.key, required this.imagePath});

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  @override
  void initState() {
    super.initState();
    // Start cropping after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Ensure the widget is still mounted
        _cropAndCompressImage(); // Call the combined function
      }
    });
  }

  // Combined function for cropping and compressing
  Future<void> _cropAndCompressImage() async {
    CroppedFile? croppedFile;
    File? finalResultFile; // To store the potentially compressed file

    try {
      // 1. Crop the image
      croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.imagePath,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop Bill Image',
              toolbarColor: Theme.of(context).appBarTheme.backgroundColor ??
                  AppColors.facebookBlue,
              toolbarWidgetColor:
                  Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Crop Bill Image',
          ),
        ],
      );

      // 2. Process if cropping was successful
      if (croppedFile != null) {
        print('Image cropped successfully: ${croppedFile.path}');
        final File originalCroppedFile = File(croppedFile.path);

        // 3. Attempt to compress the cropped image (nested try-catch)
        try {
          final targetPath = await _getTargetPath(originalCroppedFile.path);
          print(
              'Compressing image from ${originalCroppedFile.path} to $targetPath');

          final XFile? compressedXFile =
              await FlutterImageCompress.compressAndGetFile(
            originalCroppedFile.absolute.path,
            targetPath,
            quality: 80, // Adjust quality (0-100)
          );

          if (compressedXFile != null) {
            finalResultFile = File(compressedXFile.path);
            final originalSize = await originalCroppedFile.length();
            final compressedSize = await finalResultFile.length();
            print('Compression successful:');
            print(
                '  Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
            print(
                '  Compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
          } // <<< Closing brace for if (compressedXFile != null)
          else {
            print('Compression returned null, using original cropped file.');
            finalResultFile = originalCroppedFile; // Fallback
          }
        } catch (compressError) {
          print("Error during image compression: $compressError");
          print("Using original cropped file due to compression error.");
          finalResultFile =
              originalCroppedFile; // Fallback on compression error
        }
      } else {
        print('Image cropping cancelled by user.');
        finalResultFile = null; // No file to return
      }
    } catch (cropError) {
      print("Error during image cropping: $cropError");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $cropError')),
        );
      }
      finalResultFile = null; // Error during cropping
    } finally {
      // 4. Pop and return the final result (compressed, original cropped, or null)
      if (mounted) {
        print('Popping ImageCropPage with result: ${finalResultFile?.path}');
        Navigator.of(context).pop(finalResultFile);
      }
    }
  }

  // Helper function to get a target path in the temporary directory
  Future<String> _getTargetPath(String originalPath) async {
    final Directory tempDir = await getTemporaryDirectory();
    // Try to determine original extension, default to jpg if unknown
    String fileExtension =
        originalPath.contains('.') ? originalPath.split('.').last : 'jpg';
    // Ensure valid image extension for compression if needed, or handle based on library support
    if (!['jpg', 'jpeg', 'png', 'heic', 'webp']
        .contains(fileExtension.toLowerCase())) {
      print(
          "Warning: Original file extension '$fileExtension' might not be directly supported for compression output format. Defaulting target to '.jpg'");
      fileExtension = 'jpg'; // Defaulting to jpg for target
    }
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String targetFileName = 'compressed_${timestamp}.$fileExtension';
    return '${tempDir.path}/$targetFileName';
  }

  @override
  Widget build(BuildContext context) {
    // This page's primary purpose is to launch the native cropper UI.
    // We show a loading indicator while the process is ongoing.
    return const Scaffold(
      body: SafeArea(
        child: Center(
            child:
                CircularProgressIndicator()), // Keep indicator for visual feedback
      ),
    );
  }
}
