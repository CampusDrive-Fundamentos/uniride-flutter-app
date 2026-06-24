import 'package:latlong2/latlong.dart';

class PolylineDecoder {
  /// Decodes an encoded polyline string from Google/OSRM/OpenRouteService into a list of LatLng coordinates.
  static List<LatLng> decode(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    try {
      while (index < len) {
        int b, shift = 0, result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        result = result.toSigned(32);
        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1)).toSigned(32);
        lat += dlat;

        shift = 0;
        result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        result = result.toSigned(32);
        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1)).toSigned(32);
        lng += dlng;

        points.add(LatLng(lat / 1e5, lng / 1e5));
      }
    } catch (_) {
      // Return whatever points we managed to parse if string is truncated
    }
    return points;
  }
}
