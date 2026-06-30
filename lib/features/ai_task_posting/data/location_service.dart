import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  const LocationResult({required this.latitude, required this.longitude});
}

class LocationUnavailable implements Exception {
  final String message;
  const LocationUnavailable(this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around geolocator's permission dance — spec Step 6 just
/// needs current coordinates, no continuous tracking.
class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable("Location services are turned off. Please enable them and try again.");
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable("Location permission was denied. Please allow it to set your task location.");
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LocationResult(latitude: position.latitude, longitude: position.longitude);
  }
}
