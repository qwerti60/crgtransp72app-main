import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AdEditImageMultipart {
  static Future<void> appendPhotos(
    http.MultipartRequest request, {
    required List<XFile?> originals,
    required List<bool> deleted,
    required String fieldPrefix,
  }) async {
    for (var i = 0; i < originals.length; i++) {
      final field = '$fieldPrefix${i + 1}';
      if (deleted[i]) {
        request.fields['delete_$field'] = '1';
      } else if (originals[i] != null) {
        request.files.add(
          await http.MultipartFile.fromPath(field, originals[i]!.path),
        );
      }
    }
  }
}
