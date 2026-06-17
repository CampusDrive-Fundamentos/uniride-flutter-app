import 'package:dio/dio.dart';

class RoutesApiService {
  final Dio _dio;

  RoutesApiService(this._dio);

  String _mapAppCampusToBackend(String campus) {
    switch (campus.toUpperCase().replaceAll(' ', '_')) {
      case 'MONTERRICO':
        return 'UPC_MONTERRICO';
      case 'SAN_ISIDRO':
        return 'UPC_SAN_ISIDRO';
      case 'SAN_MIGUEL':
        return 'UPC_SAN_MIGUEL';
      case 'VILLA':
        return 'UPC_VILLA';
      default:
        return campus;
    }
  }

  Future<Response> createRoute({
    required String campus,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
  }) async {
    return await _dio.post(
      '/api/v1/routes',
      data: {
        'campus': _mapAppCampusToBackend(campus),
        'destinationAddress': destinationAddress,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
      },
    );
  }

  Future<Response> createBooking({required int routeId}) async {
    return await _dio.post(
      '/api/v1/bookings',
      queryParameters: {'routeId': routeId},
    );
  }

  Future<Response> searchNearbyBookings({
    required String campus,
    required double lat,
    required double lng,
  }) async {
    return await _dio.get(
      '/api/v1/bookings/search',
      queryParameters: {
        'campus': _mapAppCampusToBackend(campus),
        'lat': lat,
        'lng': lng,
      },
    );
  }

  Future<Response> joinBooking({
    required int bookingId,
    required double lat,
    required double lng,
    required String address,
  }) async {
    return await _dio.post(
      '/api/v1/bookings/$bookingId/join',
      data: {
        'lat': lat,
        'lng': lng,
        'address': address,
      },
    );
  }

  Future<Response> getRoutesByCampus({required String campus}) async {
    return await _dio.get('/api/v1/routes/campus/${_mapAppCampusToBackend(campus)}');
  }

  Future<Response> createTrip({
    required int bookingId,
    required int routeId,
    required String campus,
    required String securityCode,
    required double totalAmount,
    required List<int> passengerIds,
  }) async {
    return await _dio.post(
      '/api/v1/trips',
      data: {
        'bookingId': bookingId,
        'routeId': routeId,
        'campus': _mapAppCampusToBackend(campus),
        'securityCode': securityCode,
        'totalAmount': totalAmount,
        'paymentMethod': 'CARD',
        'passengerIds': passengerIds,
      },
    );
  }
}
