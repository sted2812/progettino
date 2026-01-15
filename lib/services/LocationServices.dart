import 'package:geolocator/geolocator.dart';

class LocationService {
  // Verifica i permessi e lo stato del GPS
  static Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    return permission != LocationPermission.deniedForever;
  }

  // Stream costante della posizione per monitoraggio live
  static Stream<Position> get positionStream => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 30, // Notifica ogni 30 metri per risparmiare batteria
    ),
  );

  // Recupera la posizione corrente
  static Future<Position?> getCurrentPosition() async {
    try {
      if (await checkPermissions()) {
        return await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 5),
        );
      }
    } catch (e) {
    }
    return null;
  }
}