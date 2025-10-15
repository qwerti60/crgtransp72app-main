import 'package:flutter/foundation.dart';

class MyImageProvider with ChangeNotifier {
  final List _images = [];

  List get images => _images;

  void addImage(Uint8List image) {
    _images.add(image);
    notifyListeners();
  }

  void removeImage(Uint8List image) {
    _images.remove(image);
    notifyListeners();
  }

  void addImages(List images) {
    _images.addAll(images);
    notifyListeners();
  }
}
