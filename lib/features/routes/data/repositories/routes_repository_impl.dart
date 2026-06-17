import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/routes_repository.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../models/route_model.dart';
import '../models/booking_model.dart';
import '../services/routes_api_service.dart';

class RoutesRepositoryImpl implements RoutesRepository {
  final RoutesApiService apiService;

  RoutesRepositoryImpl({required this.apiService});

  Map<String, dynamic> _parseMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else if (data is String) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    throw Exception('Formato de datos no válido');
  }

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) {
      return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } else if (data is String) {
      final parsed = jsonDecode(data);
      if (parsed is List) {
        return parsed.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    }
    throw Exception('Formato de lista no válido');
  }

  @override
  Future<Either<Failure, RouteEntity>> createRoute({
    required String campus,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      final response = await apiService.createRoute(
        campus: campus,
        destinationAddress: destinationAddress,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final parsedMap = _parseMap(response.data);
          final routeModel = RouteModel.fromJson(parsedMap);
          return Right(routeModel);
        } catch (e) {
          return const Left(ServerFailure('Error procesando la respuesta del servidor.'));
        }
      }
      return const Left(ServerFailure('No se pudo crear la ruta.'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        return const Left(ServerFailure('Sesión expirada. Por favor inicia sesión nuevamente.'));
      }
      return Left(ServerFailure(
        e.response?.data is Map 
            ? (e.response?.data['message'] ?? 'Error de red al crear la ruta.')
            : 'Error de red al crear la ruta.',
      ));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado.'));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    required int routeId,
  }) async {
    try {
      final response = await apiService.createBooking(routeId: routeId);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final parsedMap = _parseMap(response.data);
        final bookingModel = BookingModel.fromJson(parsedMap);
        return Right(bookingModel);
      }
      return const Left(ServerFailure('No se pudo crear el grupo de viaje.'));
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.response?.data is Map 
            ? (e.response?.data['message'] ?? 'Error de red al crear el grupo de viaje.')
            : 'Error de red al crear el grupo de viaje.',
      ));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado al crear el grupo.'));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> searchNearbyBookings({
    required String campus,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await apiService.searchNearbyBookings(
        campus: campus,
        lat: lat,
        lng: lng,
      );
      if (response.statusCode == 200) {
        final parsedList = _parseList(response.data);
        final list = parsedList
            .map((b) => BookingModel.fromJson(b))
            .toList();
        return Right(list);
      }
      return const Left(ServerFailure('Error al buscar viajes cercanos.'));
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.response?.data is Map 
            ? (e.response?.data['message'] ?? 'Error de red al buscar viajes.')
            : 'Error de red al buscar viajes.',
      ));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado al buscar viajes.'));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> joinBooking({
    required int bookingId,
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      final response = await apiService.joinBooking(
        bookingId: bookingId,
        lat: lat,
        lng: lng,
        address: address,
      );
      if (response.statusCode == 200) {
        final parsedMap = _parseMap(response.data);
        final bookingModel = BookingModel.fromJson(parsedMap);
        return Right(bookingModel);
      }
      return const Left(ServerFailure('No se pudo unir al grupo de viaje.'));
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.response?.data is Map 
            ? (e.response?.data['message'] ?? 'Error de red al unirse al viaje.')
            : 'Error de red al unirse al viaje.',
      ));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado al unirse al viaje.'));
    }
  }

  @override
  Future<Either<Failure, List<RouteEntity>>> getRoutesByCampus({
    required String campus,
  }) async {
    try {
      final response = await apiService.getRoutesByCampus(campus: campus);
      if (response.statusCode == 200) {
        final parsedList = _parseList(response.data);
        final list = parsedList
            .map((r) => RouteModel.fromJson(r))
            .toList();
        return Right(list);
      }
      return const Left(ServerFailure('Error al obtener rutas del campus.'));
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.response?.data is Map 
            ? (e.response?.data['message'] ?? 'Error de red al obtener rutas.')
            : 'Error de red al obtener rutas.',
      ));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado al obtener rutas.'));
    }
  }

  @override
  Future<Either<Failure, void>> createTrip({
    required int bookingId,
    required int routeId,
    required String campus,
    required String securityCode,
    required double totalAmount,
    required List<int> passengerIds,
  }) async {
    try {
      final response = await apiService.createTrip(
        bookingId: bookingId,
        routeId: routeId,
        campus: campus,
        securityCode: securityCode,
        totalAmount: totalAmount,
        passengerIds: passengerIds,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return const Right(null);
      }
      return const Left(ServerFailure('No se pudo registrar la solicitud de viaje.'));
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.response?.data is Map 
            ? (e.response?.data['message'] ?? 'Error de red al registrar viaje.')
            : 'Error de red al registrar viaje.',
      ));
    } catch (e) {
      return const Left(ServerFailure('Error inesperado al registrar el viaje.'));
    }
  }
}
