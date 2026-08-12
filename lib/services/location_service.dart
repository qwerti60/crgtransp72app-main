import 'package:geolocator/geolocator.dart';

/// Геолокация для поиска «рядом со мной».
class LocationService {
  static Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Включите геолокацию в настройках устройства.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Нет доступа к геолокации.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Доступ к геолокации запрещён. Разрешите его в настройках приложения.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  }
}
