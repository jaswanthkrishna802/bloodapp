import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {

  static Future<Map<String, dynamic>> getUserLocation() async {

    /// 🔐 PERMISSION
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      throw Exception("Location permission denied");
    }

    /// 📍 GET POSITION
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    /// 🌍 GET ADDRESS
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks.first;

    String location =
        "${place.locality}, ${place.administrativeArea}";

    return {
      "latitude": position.latitude,
      "longitude": position.longitude,
      "location": location,
    };
  }
}
