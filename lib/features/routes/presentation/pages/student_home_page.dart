import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_drawer.dart';
import '../../../../core/di/service_locator.dart' as di;
import '../../../../core/utils/polyline_decoder.dart';
import '../../../profile/presentation/blocs/profile_bloc.dart';
import '../../data/models/route_model.dart';
import '../blocs/routes_bloc.dart';
import '../blocs/routes_event.dart';
import '../blocs/routes_state.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/passenger_entity.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String _selectedCampus = 'MONTERRICO';
  late AnimationController _pulseController;
  
  // Coordenadas mock para la ubicación del estudiante (dragable en la simulación)
  double _mockLat = -12.1042;
  double _mockLng = -76.9629;
  String _mockAddress = 'Av. Primavera 2390, Surco';

  // Active booking variables
  BookingEntity? _currentBooking;
  RouteEntity? _currentRoute;
  Map<String, dynamic>? _currentTrip;
  List<LatLng> _routePoints = [];
  bool _isActionLoading = false;
  int? _cachedUserId;
  String? _sessionPin; // Cache para mantener el PIN original durante la sesión
  Timer? _tripPollingTimer; // Polling para detectar llegadas de otros pasajeros
  final Set<String> _locallyArrivedIds = {}; // IDs que han marcado llegada localmente para feedback instantáneo

  // Opciones de campus con sus coordenadas reales aproximadas
  final Map<String, Map<String, dynamic>> _campusData = {
    'MONTERRICO': {
      'lat': -12.1042,
      'lng': -76.9629,
      'address': 'Prolongación Primavera 2390, Monterrico, Surco',
    },
    'SAN ISIDRO': {
      'lat': -12.0875,
      'lng': -77.0501,
      'address': 'Av. Salaverry 2255, San Isidro',
    },
    'VILLA': {
      'lat': -12.2036,
      'lng': -77.0125,
      'address': 'Av. Alameda San Marcos, Chorrillos',
    },
    'SAN MIGUEL': {
      'lat': -12.0772,
      'lng': -77.0937,
      'address': 'Av. La Marina 2810, San Miguel',
    },
    'UNMSM': {
      'lat': -12.0559,
      'lng': -77.0817,
      'address': 'Av. Universitaria / Av. Venezuela, Lima',
    },
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPersistedCampus();
      if (mounted) {
        context.read<RoutesBloc>().add(const LoadCurrentBookingEvent());
      }
    });
  }

  Future<void> _loadPersistedCampus() async {
    try {
      final savedCampus = await _secureStorage.read(key: 'selected_campus');
      if (savedCampus != null && _campusData.containsKey(savedCampus)) {
        _updateSelectedCampus(savedCampus, persist: false);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stopTripPolling();
    super.dispose();
  }

  void _startTripPolling() {
    _tripPollingTimer?.cancel();
    _tripPollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _currentBooking != null) {
        // Refrescamos tanto el viaje como la reserva principal para detectar el cierre del conductor
        _checkActiveTrip();
        context.read<RoutesBloc>().add(const LoadCurrentBookingEvent());
      } else {
        _stopTripPolling();
      }
    });
  }

  void _stopTripPolling() {
    _tripPollingTimer?.cancel();
    _tripPollingTimer = null;
  }

  void _clearActiveTripSession() {
    _stopTripPolling();
    setState(() {
      _currentTrip = null;
      _currentBooking = null;
      _currentRoute = null;
      _routePoints = [];
      _sessionPin = null;
      _locallyArrivedIds.clear();
    });
  }

  Future<void> _loadRouteDetails(int routeId) async {
    try {
      final dio = di.sl<Dio>();
      final response = await dio.get('/api/v1/routes/$routeId');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null) {
          final parsedMap = data is Map ? Map<String, dynamic>.from(data) : jsonDecode(data) as Map<String, dynamic>;
          final route = RouteModel.fromJson(parsedMap);
          setState(() {
            _currentRoute = route;
            if (route.encodedPolyline != null) {
              _routePoints = PolylineDecoder.decode(route.encodedPolyline!);
            } else {
              _routePoints = [];
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _checkActiveTrip() async {
    try {
      final dio = di.sl<Dio>();
      final response = await dio.get('/api/v1/trips/current');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic rawData = response.data;
        Map<String, dynamic> tripData = rawData is Map ? Map<String, dynamic>.from(rawData) : jsonDecode(rawData as String) as Map<String, dynamic>;
        
        // Sincronización agresiva: El líder necesita el detalle completo para ver llegadas
        if (tripData['id'] != null) {
          try {
            final detailResp = await dio.get('/api/v1/trips/${tripData['id']}');
            if (detailResp.statusCode == 200 && detailResp.data != null) {
              final dynamic detailRaw = detailResp.data;
              final fullDetail = detailRaw is Map ? Map<String, dynamic>.from(detailRaw) : jsonDecode(detailRaw as String) as Map<String, dynamic>;
              tripData = fullDetail;
            }
          } catch (_) {}
        }

        setState(() {
          _currentTrip = tripData;
        });
        
        // Si el viaje terminó, limpiamos todo para volver a la pantalla de búsqueda
        if (_currentTrip!['status'] == 'COMPLETED' || _currentTrip!['status'] == 'CANCELLED') {
          _clearActiveTripSession();
          _showSnackBar('El viaje ha finalizado. ¡Gracias por usar Uniride!');
        } else {
          // Si el viaje está en cualquier otro estado activo (ACCEPTED, STARTED, ACTIVE, etc.)
          // nos aseguramos de que el polling esté funcionando para detectar el fin.
          if (_tripPollingTimer == null) _startTripPolling();
        }
      } else {
        // Si no hay viaje actual en el endpoint, pero teníamos uno activo, 
        // significa que el conductor lo terminó o se canceló.
        if (_currentTrip != null) {
          _clearActiveTripSession();
          _showSnackBar('El viaje ha finalizado.');
        }
      }
    } catch (_) {
      // En caso de error (ej. 404), si teníamos un viaje, asumimos que terminó
      if (_currentTrip != null) {
        _clearActiveTripSession();
      }
    }
  }

  Future<void> _loadActiveBookingDetails(BookingEntity booking) async {
    // CACHÉ DE PIN: Si el ID del booking es el mismo, mantenemos el primer PIN que vimos
    // para evitar que los cambios del backend al cerrar el grupo confundan al usuario.
    if (_currentBooking?.id == booking.id) {
      if (_sessionPin == null && booking.securityPin != null) {
        _sessionPin = booking.securityPin;
      }
    } else {
      _sessionPin = booking.securityPin;
    }

    setState(() {
      _currentBooking = booking;
    });
    await _loadRouteDetails(booking.routeId);
    if (booking.status != 'OPEN') {
      await _checkActiveTrip();
    } else {
      setState(() {
        _currentTrip = null;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }

  void _showPaymentMethodSelector(int bookingId, int passengerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Método de Pago', style: TextStyle(color: Colors.white)),
        content: const Text('Selecciona el método de pago usado por el estudiante:', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RoutesBloc>().add(UpdatePassengerPaymentEvent(
                bookingId: bookingId,
                passengerId: passengerId,
                method: 'YAPE',
              ));
            },
            child: const Text('YAPE', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RoutesBloc>().add(UpdatePassengerPaymentEvent(
                bookingId: bookingId,
                passengerId: passengerId,
                method: 'PLIN',
              ));
            },
            child: const Text('PLIN', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RoutesBloc>().add(UpdatePassengerPaymentEvent(
                bookingId: bookingId,
                passengerId: passengerId,
                method: 'CASH',
              ));
            },
            child: const Text('EFECTIVO', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMapMarkers(Map<String, dynamic> campus) {
    List<Marker> markers = [];

    // 1. Origen (Campus)
    markers.add(
      Marker(
        point: LatLng(campus['lat'], campus['lng']),
        width: 80.0,
        height: 80.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school, color: AppColors.primary, size: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _selectedCampus,
                style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    // 2. Destino Final
    if (_currentRoute != null) {
      markers.add(
        Marker(
          point: LatLng(_currentRoute!.destination.latitude, _currentRoute!.destination.longitude),
          width: 40.0,
          height: 40.0,
          child: const Icon(Icons.flag, color: Colors.redAccent, size: 32),
        ),
      );

      // 3. Waypoints (Paradas)
      for (var wp in _currentRoute!.waypoints) {
        markers.add(
          Marker(
            point: LatLng(wp.latitude, wp.longitude),
            width: 40.0,
            height: 40.0,
            child: const Icon(Icons.pin_drop, color: Colors.blueAccent, size: 28),
          ),
        );
      }
    } else {
      markers.add(
        Marker(
          point: LatLng(_mockLat, _mockLng),
          width: 40.0,
          height: 40.0,
          child: const Icon(Icons.location_on, color: Colors.blueAccent, size: 30),
        ),
      );
    }

    return markers;
  }

  Map<int, double> _calculateFairPrices(BookingEntity booking) {
    final Map<int, double> prices = {};
    final route = _currentRoute;
    if (route == null || booking.passengers.isEmpty) return prices;

    final int totalStudents = booking.passengers.length;
    final double baseShare = 10.0 / totalStudents;

    // 1. Obtener la distancia de cada pasajero
    final List<MapEntry<PassengerEntity, double>> passengersWithDistance = [];
    for (var p in booking.passengers) {
      double dist = 0.0;
      if (p.role.toUpperCase() == 'LEADER') {
        dist = route.totalDistanceKm;
      } else {
        for (var wp in route.waypoints) {
          if (wp.passengerId == p.studentId) {
            dist = wp.distanceFromStartKm ?? 0.0;
            break;
          }
        }
      }
      passengersWithDistance.add(MapEntry(p, dist));
    }

    // 2. Ordenar por distancia ascendente
    passengersWithDistance.sort((a, b) => a.value.compareTo(b.value));

    // Inicializar precios con el costo base
    for (var p in booking.passengers) {
      prices[p.studentId] = baseShare;
    }

    // 3. Calcular costo por segmentos
    double prevDistance = 0.0;
    for (int i = 0; i < passengersWithDistance.length; i++) {
      final double currentDistance = passengersWithDistance[i].value;
      final double segmentLength = currentDistance - prevDistance;
      
      if (segmentLength > 0.001) {
        final int passengersInSegment = passengersWithDistance.length - i;
        final double segmentCost = segmentLength * 1.5;
        final double sharePerPassenger = segmentCost / passengersInSegment;

        for (int j = i; j < passengersWithDistance.length; j++) {
          final int studentId = passengersWithDistance[j].key.studentId;
          prices[studentId] = (prices[studentId] ?? 0.0) + sharePerPassenger;
        }
      }
      prevDistance = currentDistance;
    }

    return prices;
  }

  void _updateSelectedCampus(String newCampus, {bool persist = true}) async {
    if (_campusData.containsKey(newCampus)) {
      final data = _campusData[newCampus]!;
      setState(() {
        _selectedCampus = newCampus;
        _mockLat = data['lat'];
        _mockLng = data['lng'];
        _mockAddress = data['address'];
      });
      _mapController.move(
        LatLng(data['lat'], data['lng']),
        14.0,
      );

      if (persist) {
        await _secureStorage.write(key: 'selected_campus', value: newCampus);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      _cachedUserId = profileState.userData.id;
    } else if (profileState is ProfileUpdateSuccess) {
      _cachedUserId = profileState.userData.id;
    }
    final currentUserId = _cachedUserId ?? 1;

    return BlocConsumer<RoutesBloc, RoutesState>(
      listener: (context, state) {
        if (state is RoutesLoading) {
          setState(() {
            _isActionLoading = true;
          });
        } else if (state is RoutesError) {
          setState(() {
            _isActionLoading = false;
          });
          _showSnackBar(state.message);
        } else if (state is NearbyBookingsLoaded || state is RoutesInitial) {
          setState(() {
            _isActionLoading = false;
          });
        } else if (state is CurrentBookingLoaded) {
          setState(() {
            _isActionLoading = false;
          });
          _loadActiveBookingDetails(state.booking);
        } else if (state is CurrentBookingEmpty) {
          setState(() {
            _isActionLoading = false;
            _currentBooking = null;
            _currentRoute = null;
            _currentTrip = null;
            _routePoints = [];
            _sessionPin = null;
            _locallyArrivedIds.clear();
          });
        } else if (state is RouteAndBookingCreated) {
          setState(() {
            _isActionLoading = false;
            _locallyArrivedIds.clear();
          });
          // Cargamos los detalles directamente desde la entidad creada para evitar saltos de PIN
          _loadActiveBookingDetails(state.booking);
        } else if (state is JoinedBookingSuccess) {
          setState(() {
            _isActionLoading = false;
            _locallyArrivedIds.clear();
          });
          _loadActiveBookingDetails(state.booking);
        } else if (state is LockAndPublishSuccess) {
          setState(() {
            _isActionLoading = false;
          });
          _showSnackBar('¡Anuncio publicado! Buscando conductor...');
          // USAMOS EL BOOKING QUE VIENE EN EL ÉXITO (que tiene el PIN original preservado)
          _loadActiveBookingDetails(state.booking);
        } else if (state is LeaveBookingSuccess || state is CancelBookingSuccess) {
          setState(() {
            _isActionLoading = false;
          });
          _clearActiveTripSession();
          _showSnackBar(state is LeaveBookingSuccess 
              ? 'Saliste del grupo de viaje.' 
              : 'Grupo de viaje cancelado exitosamente.');
        } else if (state is ConfirmArrivalSuccess) {
          setState(() {
            _isActionLoading = false;
            _locallyArrivedIds.add(currentUserId.toString());
          });
          _showSnackBar('¡Llegada confirmada! Esperando al conductor para finalizar.');
          _checkActiveTrip();
        } else if (state is UpdatePaymentSuccess) {
          setState(() {
            _isActionLoading = false;
          });
          _showSnackBar('Checklist de pago actualizado.');
          _loadActiveBookingDetails(state.booking);
        }
      },
      builder: (context, state) {
        final campus = _campusData[_selectedCampus]!;
        final hasActiveBooking = _currentBooking != null;

        return Scaffold(
          drawer: const CustomDrawer(),
          body: Stack(
            children: [
              // 1. MAPA DE INTERACCIÓN REAL (FLUTTER MAP)
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _routePoints.isNotEmpty
                        ? _routePoints.first
                        : LatLng(campus['lat'], campus['lng']),
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.uniride.app',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: AppColors.primary,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: _buildMapMarkers(campus),
                    ),
                  ],
                ),
              ),

              // 2. GRADIENT OVERLAYS
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),

              // 3. BARRA SUPERIOR: SELECTOR DE CAMPUS Y DIRECCIÓN
              if (!hasActiveBooking)
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Builder(
                                  builder: (context) => IconButton(
                                    icon: const Icon(Icons.menu, color: AppColors.primary),
                                    onPressed: () => Scaffold.of(context).openDrawer(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Punto de Salida',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            DropdownButton<String>(
                              value: _selectedCampus,
                              dropdownColor: AppColors.surface,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              items: _campusData.keys.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text('Campus $value'),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  _updateSelectedCampus(newValue);
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(color: Colors.grey, height: 16),
                        Row(
                          children: [
                            const Icon(Icons.my_location, color: Colors.blueAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _mockAddress,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(Icons.menu, color: AppColors.primary),
                                onPressed: () => Scaffold.of(context).openDrawer(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Mi Viaje Activo',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.primary),
                          onPressed: () {
                            context.read<RoutesBloc>().add(const LoadCurrentBookingEvent());
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. PANEL INFERIOR DINÁMICO
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: hasActiveBooking 
                    ? _buildActiveBookingDashboard(currentUserId)
                    : _buildDefaultControlPanel(),
              ),

              // Loading overlay
              if (_isActionLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultControlPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.radar, color: Colors.blueAccent, size: 16),
              SizedBox(width: 6),
              Text(
                'Escaneo de rutas dentro de 500 metros activado',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Listo para tu viaje diario?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Viaja seguro, comparte gastos y reduce la huella de carbono.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/nearby-bookings',
                          arguments: {
                            'campus': _selectedCampus,
                            'lat': _mockLat,
                            'lng': _mockLng,
                          },
                        );
                        
                        if (result != null && result is String) {
                          _updateSelectedCampus(result);
                        }
                        
                        // Al volver, refrescar el estado del dashboard
                        if (mounted) {
                          context.read<RoutesBloc>().add(const LoadCurrentBookingEvent());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.search, color: Colors.black),
                      label: const Text(
                        'Buscar Rutas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/create-announcement',
                          arguments: {
                            'campus': _selectedCampus,
                            'lat': _mockLat,
                            'lng': _mockLng,
                          },
                        );

                        if (result != null && result is String) {
                          _updateSelectedCampus(result);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add_road_rounded),
                      label: const Text(
                        'Crear Anuncio',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveBookingDashboard(int currentUserId) {
    final booking = _currentBooking!;
    final route = _currentRoute;

    bool isLeader = booking.leaderId == currentUserId;
    if (!isLeader && booking.passengers.isNotEmpty) {
      try {
        final me = booking.passengers.firstWhere((p) => p.studentId == currentUserId);
        isLeader = (me.role.toUpperCase() == 'LEADER');
      } catch (e) {
        // Fallback: Si acabas de crear el viaje, eres el único pasajero, asume que eres el líder
        if (booking.passengers.length == 1 && booking.passengers.first.role.toUpperCase() == 'LEADER') {
          isLeader = true;
        }
      }
    }
    
    String statusText = 'Grupo Abierto';
    Color statusColor = Colors.greenAccent;
    IconData statusIcon = Icons.lock_open;
    
    if (booking.status == 'LOCKED') {
      statusText = 'Buscando Conductor';
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.radar;
    }
    
    if (_currentTrip != null) {
      final tripStatus = _currentTrip!['status'];
      if (tripStatus == 'ACCEPTED') {
        statusText = 'Conductor en Camino';
        statusColor = Colors.blueAccent;
        statusIcon = Icons.directions_car;
      } else if (tripStatus == 'ACTIVE') {
        statusText = 'En Viaje';
        statusColor = AppColors.primary;
        statusIcon = Icons.navigation;
      } else if (tripStatus == 'COMPLETED') {
        statusText = 'Viaje Terminado';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Grupo #${booking.id}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              )
            ],
          ),
          const Divider(color: Colors.white12, height: 20),

          if (route != null) ...[
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.destination.address,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.straighten, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Distancia total: ${route.totalDistanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.payments_outlined, color: AppColors.primary, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Costo total: S/ ${(10.0 + route.totalDistanceKm * 1.5).toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                 Builder(builder: (context) {
                  if (booking.passengers.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  PassengerEntity? me;
                  for (var p in booking.passengers) {
                    if (p.studentId == currentUserId) {
                      me = p;
                      break;
                    }
                  }
                  me ??= booking.passengers.first;

                  final prices = _calculateFairPrices(booking);
                  final double price = prices[me.studentId] ?? 0.0;
                  double distance = me.role.toUpperCase() == 'LEADER'
                      ? route.totalDistanceKm
                      : 0.0;
                  if (me.role.toUpperCase() != 'LEADER') {
                    for (var wp in route.waypoints) {
                      if (wp.passengerId == currentUserId) {
                        distance = wp.distanceFromStartKm ?? 0.0;
                        break;
                      }
                    }
                  }
                  return Text(
                    'Tu precio justo: S/ ${price.toStringAsFixed(2)} (${distance.toStringAsFixed(1)} km recorridos)',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (booking.securityPin != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PIN de Seguridad', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Muéstralo al conductor al subir', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                  Text(
                    _sessionPin ?? _currentTrip?['securityCode'] ?? booking.securityPin!,
                    style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Text('Pasajeros en el Grupo:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Builder(builder: (context) {
            final r = route;
            if (r == null) {
              return const SizedBox.shrink();
            }
            final prices = _calculateFairPrices(booking);
            return Column(
              children: booking.passengers.map((p) {
                final isSelf = p.studentId == currentUserId || (isLeader && p.role.toUpperCase() == 'LEADER');
                final isL = p.role.toUpperCase() == 'LEADER';
                final double price = prices[p.studentId] ?? 0.0;
                double distance = isL
                    ? r.totalDistanceKm
                    : 0.0;
                if (!isL) {
                  for (var wp in r.waypoints) {
                    if (wp.passengerId == p.studentId) {
                      distance = wp.distanceFromStartKm ?? 0.0;
                      break;
                    }
                  }
                }
                // Detección de llegada del pasajero desde el objeto del viaje activo
                bool pArrived = false;
                if (_currentTrip != null && _currentTrip!['passengers'] != null) {
                  final tPass = (_currentTrip!['passengers'] as List).firstWhere(
                    (tp) => (tp['passengerId'] ?? tp['studentId'] ?? tp['id'] ?? '').toString() == p.studentId.toString(),
                    orElse: () => null,
                  );
                  if (tPass != null) {
                    final dynamic rawA = tPass['hasArrived'] ?? tPass['arrived'] ?? false;
                    pArrived = rawA == true || rawA == 'true' || tPass['status'] == 'ARRIVED' || tPass['status'] == 'COMPLETED';
                  }
                }
                
                // Si el polling o el backend fallan, revisamos caché local para el usuario actual
                if (!pArrived && isSelf) {
                  pArrived = _locallyArrivedIds.contains(p.studentId.toString());
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: pArrived ? Colors.green.withOpacity(0.05) : Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: pArrived ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            pArrived ? Icons.check_circle : (isL ? Icons.star : Icons.person), 
                            color: pArrived ? Colors.green : (isL ? AppColors.primary : Colors.white70), 
                            size: 16
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estudiante #${p.studentId} ${isSelf ? "(Tú)" : ""}',
                                style: TextStyle(
                                  color: pArrived ? Colors.greenAccent : (isSelf ? AppColors.primary : Colors.white70), 
                                  fontSize: 12, 
                                  fontWeight: isSelf || pArrived ? FontWeight.bold : FontWeight.normal
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pArrived ? 'Llegó a salvo' : 'Precio justo: S/ ${price.toStringAsFixed(2)} (${distance.toStringAsFixed(1)} km)',
                                style: TextStyle(color: pArrived ? Colors.green.withOpacity(0.7) : Colors.grey, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isLeader && !isSelf && _currentTrip != null) 
                        GestureDetector(
                          onTap: () => _showPaymentMethodSelector(booking.id, p.studentId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.paymentStatus == 'PAID' ? Colors.green.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: p.paymentStatus == 'PAID' ? Colors.green : Colors.orangeAccent),
                            ),
                            child: Text(
                              p.paymentStatus == 'PAID' ? 'PAGADO (${p.paymentMethod})' : 'MARCAR PAGO',
                              style: TextStyle(color: p.paymentStatus == 'PAID' ? Colors.green : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      else
                        Text(
                          p.paymentStatus == 'PAID' ? '✓ Pagado' : 'Pendiente',
                          style: TextStyle(color: p.paymentStatus == 'PAID' ? Colors.green : Colors.orangeAccent, fontSize: 11),
                        )
                    ],
                  ),
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 16),

          // PRIORIDAD 1: Si el viaje ya inició, mostrar confirmación de llegada
          if (_currentTrip != null && (_currentTrip!['status'] == 'STARTED' || _currentTrip!['status'] == 'ACTIVE')) ...[
            _buildConfirmArrivalButton(currentUserId, isLeader),
          ] 
          // PRIORIDAD 2: Si el grupo está en fases previas, mostrar controles de gestión
          else if (booking.status == 'OPEN' || booking.status == 'LOCKED' || booking.status == 'FULL') ...[
            if (booking.status == 'OPEN' && isLeader) ...[
              ElevatedButton.icon(
                onPressed: _isActionLoading ? null : () {
                  context.read<RoutesBloc>().add(LockAndPublishBookingEvent(
                    bookingId: booking.id,
                    routeId: booking.routeId,
                    campus: _selectedCampus,
                    securityCode: _sessionPin ?? booking.securityPin ?? '1234',
                    totalDistanceKm: _currentRoute?.totalDistanceKm ?? 5.0,
                    passengerIds: booking.passengers.map((p) => p.studentId).toList(),
                  ));
                },
                icon: const Icon(Icons.publish, color: Colors.black),
                label: const Text('Cerrar Grupo y Buscar Conductor', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
            ],
            if (isLeader)
              // BOTÓN CORRECTO PARA EL LÍDER: LLama al Endpoint de Cancelar (/api/v1/bookings/{id})
              OutlinedButton.icon(
                onPressed: _isActionLoading ? null : () {
                  context.read<RoutesBloc>().add(CancelBookingEvent(
                    bookingId: booking.id,
                    tripId: _currentTrip != null ? _currentTrip!['id'] : null,
                  ));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar Grupo', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else
              // BOTÓN PARA SEGUIDORES: Llama al Endpoint de Salir (/leave)
              OutlinedButton.icon(
                onPressed: _isActionLoading ? null : () {
                  // Obtener las coordenadas de la parada del usuario para enviarlas al backend
                  double lat = _mockLat;
                  double lng = _mockLng;
                  bool waypointFound = false;

                  if (_currentRoute != null) {
                    for (var wp in _currentRoute!.waypoints) {
                      if (wp.passengerId == currentUserId) {
                        lat = wp.latitude;
                        lng = wp.longitude;
                        waypointFound = true;
                        break;
                      }
                    }
                  }

                  print('DEBUG: Intentando salir del grupo. UserID: $currentUserId, BookingId: ${booking.id}');
                  print('DEBUG: Coordenadas enviadas: lat=$lat, lng=$lng. Parada encontrada: $waypointFound');

                  context.read<RoutesBloc>().add(LeaveBookingEvent(
                    bookingId: booking.id,
                    lat: lat,
                    lng: lng,
                  ));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Salir del Grupo', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmArrivalButton(int currentUserId, bool isLeader) {
    if (_currentTrip == null) return const SizedBox.shrink();
    
    // Intentar obtener la lista de pasajeros del viaje o de la reserva
    final List? tripPassengers = _currentTrip!['passengers'] as List?;
    final bookingPassengers = _currentBooking?.passengers ?? [];

    // 1. Determinar si YO ya llegué (Check local + Backend)
    final String myIdStr = currentUserId.toString();
    bool arrived = _locallyArrivedIds.contains(myIdStr);
    
    if (tripPassengers != null) {
      for (var p in tripPassengers) {
        final pId = (p['passengerId'] ?? p['studentId'] ?? p['id'] ?? p['student_id'] ?? '').toString();
        if (pId == myIdStr) {
          final dynamic rawArr = p['hasArrived'] ?? p['arrived'] ?? false;
          if (rawArr == true || rawArr == 'true' || p['status'] == 'ARRIVED' || p['status'] == 'COMPLETED') {
            arrived = true;
            _locallyArrivedIds.add(myIdStr); // Sincronizamos caché local
          }
          break;
        }
      }
    }

    // ESTADO DESHABILITADO (Ya marcó pero espera al conductor)
    if (arrived) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: null, // DESHABILITADO
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              disabledBackgroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.green, width: 1)),
            ),
            icon: const Icon(Icons.check_circle, color: Colors.green),
            label: Text(
              isLeader ? 'Viaje Finalizado (Esperando Conductor)' : 'Llegada Confirmada',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLeader 
              ? 'Has notificado la llegada del grupo. El conductor debe cerrar el viaje.' 
              : 'Has notificado tu llegada. El conductor cerrará el viaje al finalizar el recorrido.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      );
    }

    // ESTADO ACTIVO
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isActionLoading ? null : () async {
            // Buscamos el ID específico que el backend usa para esta relación (pasajero-viaje)
            dynamic finalPassengerId = currentUserId;
            if (tripPassengers != null) {
              final meInTrip = tripPassengers.firstWhere(
                (p) => (p['passengerId'] ?? p['studentId'] ?? p['id'] ?? '').toString() == currentUserId.toString(),
                orElse: () => null,
              );
              // Prioridad: 1. ID de la relación (PK), 2. passengerId, 3. studentId
              if (meInTrip != null) {
                finalPassengerId = meInTrip['id'] ?? meInTrip['passengerId'] ?? meInTrip['studentId'] ?? currentUserId;
              }
            }

            print('DEBUG: Senior Audit - Enviando confirmación. Trip: ${_currentTrip!['id']}, PassengerID Detectado: $finalPassengerId');
            
            context.read<RoutesBloc>().add(ConfirmArrivalEvent(
              tripId: _currentTrip!['id'],
              passengerId: finalPassengerId is int ? finalPassengerId : int.tryParse(finalPassengerId.toString()) ?? currentUserId,
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(isLeader ? Icons.flag : Icons.home, color: Colors.black),
          label: Text(
            isLeader ? 'Finalizar Viaje del Grupo' : 'Confirmar mi Llegada',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

