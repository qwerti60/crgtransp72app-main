import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crgtransp72app/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Общая логика выбора, предпросмотра и загрузки аватара (как в «Личные данные»).
class AvatarImageUpload {
  AvatarImageUpload._();

  static Future<ImageSource?> pickImageSource(BuildContext context) {
    return showDialog<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Выбор изображения'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(ImageSource.gallery),
                  child: const Text('Загрузить из фотогалереи'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(ImageSource.camera),
                  child: const Text('Сделать фото'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Полный цикл: источник → выбор файла → предпросмотр → отправка.
  static Future<bool?> runPickPreviewUploadFlow(
    BuildContext context, {
    required String email,
    void Function(Uint8List uploadedBytes)? onUploaded,
  }) async {
    final source = await pickImageSource(context);
    if (source == null || !context.mounted) return null;

    return pickTransformPreviewAndUpload(
      context,
      source: source,
      email: email,
      onUploaded: onUploaded,
    );
  }

  static Future<Uint8List?> prepareRoundedAvatar(XFile image) async {
    try {
      final originalImageFile = File(image.path);
      final rawBytes = await originalImageFile.readAsBytes();
      final originalImage = img.decodeImage(rawBytes);
      if (originalImage == null) return null;

      final resizedImg =
          img.copyResize(originalImage, width: 100, height: 100);
      final roundedImage = await _convertToRoundedImage(resizedImg);
      final byteData =
          await roundedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> showPreviewAndUpload(
    BuildContext context, {
    required Uint8List previewBytes,
    required String email,
    void Function(Uint8List uploadedBytes)? onUploaded,
  }) async {
    if (!context.mounted) return null;

    final shouldUpload = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (previewContext) => AlertDialog(
        title: const Text('Предпросмотр'),
        content: SizedBox(
          width: 120,
          height: 120,
          child: Image.memory(previewBytes, fit: BoxFit.contain),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(previewContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(previewContext).pop(true),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );

    if (shouldUpload != true || !context.mounted) return null;

    final ok = await uploadAvatar(previewBytes, email);
    if (ok && onUploaded != null) {
      onUploaded(previewBytes);
    }
    return ok;
  }

  /// `true` — загружено, `false` — ошибка, `null` — отмена или не выбрано фото.
  static Future<bool?> pickTransformPreviewAndUpload(
    BuildContext context, {
    required ImageSource source,
    required String email,
    void Function(Uint8List uploadedBytes)? onUploaded,
  }) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null || !context.mounted) return null;

    final prepared = await prepareRoundedAvatar(image);
    if (!context.mounted) return null;
    if (prepared == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось обработать изображение')),
      );
      return false;
    }

    return showPreviewAndUpload(
      context,
      previewBytes: prepared,
      email: email,
      onUploaded: onUploaded,
    );
  }

  static Future<bool> uploadAvatar(Uint8List imageBytes, String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBase}/upload.php'),
        body: {
          'image': base64Encode(imageBytes),
          'email': email,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<ui.Image> _convertToRoundedImage(img.Image inputImage) async {
    final imageBytes = Uint8List.fromList(img.encodePng(inputImage));

    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(imageBytes, completer.complete);
    final image = await completer.future;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final imgWidth = image.width.toDouble();
    final imgHeight = image.height.toDouble();
    final oval = Rect.fromLTWH(0, 0, imgWidth, imgHeight);

    final clipOvalPath = Path()..addOval(oval);
    canvas.clipPath(clipOvalPath);

    _paintImage(
      canvas: canvas,
      rect: oval,
      image: image,
      fit: BoxFit.fill,
    );

    final picture = recorder.endRecording();
    return picture.toImage(image.width, image.height);
  }

  static void _paintImage({
    required Canvas canvas,
    required Rect rect,
    required ui.Image image,
    required BoxFit fit,
  }) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final sizes = applyBoxFit(fit, imageSize, rect.size);
    final inputSubrect =
        Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);
    final outputSubrect =
        Alignment.center.inscribe(sizes.destination, rect);
    canvas.drawImageRect(image, inputSubrect, outputSubrect, Paint());
  }
}
