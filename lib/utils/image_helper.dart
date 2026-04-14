import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndSaveImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${const Uuid().v4()}${path.extension(image.path)}';
    final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
    
    return savedImage.path;
  }
}
