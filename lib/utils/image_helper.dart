import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndSaveImage(ImageSource source) async {
    // Compress aggressively to avoid Firestore 1MB limits
    final XFile? image = await _picker.pickImage(
      source: source, 
      imageQuality: 50, 
      maxWidth: 600, 
      maxHeight: 600,
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    final base64String = base64Encode(bytes);
    
    return 'base64,$base64String';
  }
}
