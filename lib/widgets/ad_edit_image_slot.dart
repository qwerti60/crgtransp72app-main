import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Circular photo slot for ad edit forms with optional delete button.
class AdEditImageSlot extends StatelessWidget {
  const AdEditImageSlot({
    super.key,
    required this.size,
    required this.displayFile,
    required this.fallbackFile,
    required this.onTap,
    this.onDelete,
  });

  final double size;
  final XFile? displayFile;
  final XFile? fallbackFile;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  bool get _hasPhoto => displayFile != null || fallbackFile != null;

  ImageProvider _imageProvider() {
    if (displayFile != null) {
      return FileImage(File(displayFile!.path));
    }
    if (fallbackFile != null) {
      return FileImage(File(fallbackFile!.path));
    }
    return const AssetImage('assets/images/fotouser.png');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: _imageProvider(),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (_hasPhoto && onDelete != null)
          Positioned(
            top: -4,
            right: -4,
            child: Material(
              color: Colors.red,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onDelete,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
