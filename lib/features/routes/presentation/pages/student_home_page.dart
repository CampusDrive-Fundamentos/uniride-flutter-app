import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> with SingleTickerProviderStateMixin {
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

  // Opciones de campus de la UPC con sus coordenadas reales aproximadas
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
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutesBloc>().add(const LoadCurrentBookingEvent());
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
        setState(() {
          _currentTrip = Map<String, dynamic>.from(response.data);
        });
      } else {
        setState(() {
          _currentTrip = null;
        });
      }
    } catch (_) {
      setState(() {
        _currentTrip = null;
      });
    }
  }

  Future<void> _loadActiveBookingDetails(BookingEntity booking) async {
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
          });
        } else if (state is RouteAndBookingCreated) {
          setState(() {
            _isActionLoading = false;
          });
          context.read<RoutesBloc>().add(const LoadCurrentBookingEvent());
        } else if (state is JoinedBookingSuccess) {
          setState(() {
            _isActionLoading = false;
          });
          context.read<RoutesBloc>().add(const LoadCurrentBookingEvent());
        } else if (state is LockAndPublishSuccess) {
          setState(() {
            _isActionLoading = false;
          });
          _showSnackBar('¡Anuncio publicado! Buscando conductor...');
          context.read<RoutesBloc>().add(const LoadCurrentBookingEvent());
        } else if (state is LeaveBookingSuccess) {
          setState(() {
            _isActionLoading = false;
          });
          _showSnackBar('Saliste del grupo de viaje.');
          context.read<RoutesBloc>().add(const LoadCurrentBookingEvent());
        } else if (state is CancelBookingSuccess) {
          setState(() {
            _isActionLoading = false;
          });
          _showSnackBar('Grupo de viaje cancelado exitosamente.');
          context.read<RoutesBloc>().add(const LoadCurrentBookingEvent());
        } else if (state is ConfirmArrivalSuccess) {
          setState(() {
            _isActionLoading = false;
          });
          _showSnackBar('¡Llegada confirmada a salvo!');
          context.read<RoutesBloc>().add(const LoadCurrentBookingEvent());
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
                                  setState(() {
                                    _selectedCampus = newValue;
                                    final data = _campusData[newValue]!;
                                    _mockLat = data['lat'];
                                    _mockLng = data['lng'];
                                    _mockAddress = data['address'];
                                  });
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
                        await Navigator.pushNamed(
                          context,
                          '/nearby-bookings',
                          arguments: {
                            'campus': _selectedCampus,
                            'lat': _mockLat,
                            'lng': _mockLng,
                          },
                        );
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
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/create-announcement',
                          arguments: {
                            'campus': _selectedCampus,
                            'lat': _mockLat,
                            'lng': _mockLng,
                          },
                        );
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
    
    // LÓGICA REFORZADA PARA DETERMINAR SI ERES EL LÍDER
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

          if (_currentRoute != null) ...[
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentRoute!.destination.address,
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
                  'Distancia: ${_currentRoute!.totalDistanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.payments_outlined, color: AppColors.primary, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Costo total: S/ ${(10.0 + _currentRoute!.totalDistanceKm * 1.5).toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
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
                    booking.securityPin!,
                    style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Text('Pasajeros en el Grupo:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...booking.passengers.map((p) {
            final isSelf = p.studentId == currentUserId || (isLeader && p.role.toUpperCase() == 'LEADER');
            final isL = p.role.toUpperCase() == 'LEADER';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(isL ? Icons.star : Icons.person, color: isL ? AppColors.primary : Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Estudiante #${p.studentId} ${isSelf ? "(Tú)" : ""}',
                        style: TextStyle(color: isSelf ? AppColors.primary : Colors.white70, fontSize: 12, fontWeight: isSelf ? FontWeight.bold : FontWeight.normal),
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
          }),

          const SizedBox(height: 16),

          if (booking.status == 'OPEN' || booking.status == 'LOCKED' || booking.status == 'FULL') ...[
            if (booking.status == 'OPEN' && isLeader) ...[
              ElevatedButton.icon(
                onPressed: _isActionLoading ? null : () {
                  context.read<RoutesBloc>().add(LockAndPublishBookingEvent(
                    bookingId: booking.id,
                    routeId: booking.routeId,
                    campus: _selectedCampus,
                    securityCode: booking.securityPin ?? '1234',
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
                  context.read<RoutesBloc>().add(LeaveBookingEvent(
                    bookingId: booking.id,
                    lat: _mockLat,
                    lng: _mockLng,
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
          ] else if (_currentTrip != null && _currentTrip!['status'] == 'ACTIVE') ...[
            if (!isLeader)
              _buildConfirmArrivalButton(currentUserId),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmArrivalButton(int currentUserId) {
    if (_currentTrip == null || _currentTrip!['passengers'] == null) return const SizedBox.shrink();
    final passengersList = _currentTrip!['passengers'] as List;
    final selfPass = passengersList.firstWhere(
      (p) => p['passengerId'] == currentUserId,
      orElse: () => null,
    );
    if (selfPass == null) return const SizedBox.shrink();
    final bool arrived = selfPass['hasArrived'] ?? false;
    
    if (arrived) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Llegaste a salvo a casa',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: _isActionLoading ? null : () {
          context.read<RoutesBloc>().add(ConfirmArrivalEvent(
            tripId: _currentTrip!['id'],
            passengerId: currentUserId,
          ));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.home, color: Colors.black),
        label: const Text('Confirmar Llegada a Salvo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      );
    }
  }
}