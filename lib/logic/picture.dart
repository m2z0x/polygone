import 'dart:io';
import 'dart:async'; // Add this import for Future handling
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oreon/providers/providers.dart';
import 'package:provider/provider.dart';

class PicturePicker extends StatefulWidget {
  const PicturePicker({super.key});

  @override
  State<PicturePicker> createState() => _PicturePickerState();
}

class _PicturePickerState extends State<PicturePicker> {
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _buildNavigationTile(
                    icon: LucideIcons.camera,
                    title: "Take Photo",
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 8),
                  _buildNavigationTile(
                    icon: LucideIcons.image,
                    title: 'Choose from Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // Close the bottom sheet immediately
    if (mounted) {
      Navigator.pop(context);
    }

    try {
      // Pick the image directly
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85, // Optional: set image quality
        maxWidth: 1024, // Optional: set max width
        maxHeight: 1024, // Optional: set max height
      );

      if (pickedFile != null && mounted) {
        setState(() => _selectedImage = File(pickedFile.path));
        // Uncomment and adjust based on your provider implementation
        context.read<UserProvider>().updateAvatarPicture(pickedFile.path);
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImagePicker,
      child: Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.tealAccent,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.camera,
            size: 20,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required VoidCallback onTap,
    IconData? icon,
    Widget? iconWidget,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.tealAccent.withOpacity(0.1),
        highlightColor: Colors.tealAccent.withOpacity(0.05),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: iconWidget ?? Icon(
              icon,
              color: Colors.white70,
              size: 24,
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: icon == LucideIcons.x
                ? null
                : Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.4),
                  ),
          ),
        ),
      ),
    );
  }
}