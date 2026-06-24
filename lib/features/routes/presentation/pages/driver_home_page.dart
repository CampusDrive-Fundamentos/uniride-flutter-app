import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart' as di;
import '../../../../core/widgets/custom_drawer.dart';
import '../../../../core/utils/polyline_decoder.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> with SingleTickerProviderStateMixin {
  String _selectedCampus = 'MONTERRICO';
  List<Map<String, dynamic>> _availableTrips = [];
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _pulseController;

  // Active Trip State
  Map<String, dynamic>? _activeTrip;
  Map<String, dynamic>? _activeRoute;
  Map<String, dynamic>? _activeBooking;
  final TextEditingController _pinController = TextEditingController();
  bool _isActionLoading = false;
  List<LatLng> _routePoints = [];

  final Map<String, Map<String, dynamic>> _campusData = {
    'MONTERRICO': {
      'lat': -12.1042,
      'lng': -76.9629,
      'address': 'Prolongación Primavera 2390, Monterrico, Surco',
      'dbName': 'UPC_MONTERRICO',
    },
    'SAN ISIDRO': {
      'lat': -12.0875,
      'lng': -77.0501,
      'address': 'Av. Salaverry 2255, San Isidro',
      'dbName': 'UPC_SAN_ISIDRO',
    },
    'VILLA': {
      'lat': -12.2036,
      'lng': -77.0125,
      'address': 'Av. Alameda San Marcos, Chorrillos',
      'dbName': 'UPC_VILLA',
    },
    'SAN MIGUEL': {
      'lat': -12.0772,
      'lng': -77.0937,
      'address': 'Av. La Marina 2810, San Miguel',
      'dbName': 'UPC_SAN_MIGUEL',
    },
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadAvailableTrips();
    _checkActiveTrip();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveTrip() async {
    try {
      final dio = di.sl<Dio>();
      final response = await dio.get('/api/v1/trips/current');
      if (response.statusCode == 200 && response.data != null) {
        final trip = response.data;
        if (trip is Map && trip['status'] != 'COMPLETED' && trip['status'] != 'CANCELLED') {
          setState(() {
            _activeTrip = Map<String, dynamic>.from(trip);
          });
          await _loadActiveTripDetails();
        }
      }
    } catch (_) {
      // Ignorar si no hay viaje activo
    }
  }

  Future<void> _loadAvailableTrips() async {
    if (_activeTrip != null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final dbCampus = _campusData[_selectedCampus]!['dbName'];
      final dio = di.sl<Dio>();
      final response = await dio.get(
        '/api/v1/trips/available',
        queryParameters: {'campus': dbCampus},
      );

      if (response.statusCode == 200) {
        final List rawList = response.data is List ? response.data : [];
        final List<Map<String, dynamic>> tripsWithRoutes = [];

        for (var item in rawList) {
          final trip = Map<String, dynamic>.from(item as Map);
          try {
            final routeResp = await dio.get('/api/v1/routes/${trip['routeId']}');
            if (routeResp.statusCode == 200) {
              trip['route'] = routeResp.data;
            }
          } catch (e) {
            trip['route'] = null;
          }
          tripsWithRoutes.add(trip);
        }

        setState(() {
          _availableTrips = tripsWithRoutes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar viajes disponibles.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de red al conectar con el servidor.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActiveTripDetails() async {
    if (_activeTrip == null) return;
    setState(() {
      _isActionLoading = true;
    });

    try {
      final dio = di.sl<Dio>();
      
      // Cargar Ruta
      final routeId = _activeTrip!['routeId'];
      final routeResp = await dio.get('/api/v1/routes/$routeId');
      if (routeResp.statusCode == 200) {
        _activeRoute = Map<String, dynamic>.from(routeResp.data);
        if (_activeRoute != null && _activeRoute!['encodedPolyline'] != null) {
          _routePoints = PolylineDecoder.decode(_activeRoute!['encodedPolyline']);
        } else {
          _routePoints = [];
        }
      }

      // Cargar Reserva (Booking)
      final bookingId = _activeTrip!['bookingId'];
      final bookingResp = await dio.get('/api/v1/bookings/$bookingId');
      if (bookingResp.statusCode == 200) {
        _activeBooking = Map<String, dynamic>.from(bookingResp.data);
      }
    } catch (_) {
      // Manejar error de carga
    } finally {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  Future<void> _acceptTrip(int tripId) async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      final dio = di.sl<Dio>();
      final response = await dio.patch('/api/v1/trips/$tripId/accept');
      if (response.statusCode == 200) {
        setState(() {
          _activeTrip = Map<String, dynamic>.from(response.data);
          _availableTrips.clear();
        });
        await _loadActiveTripDetails();
        _showSnackBar('¡Viaje aceptado! Por favor recoge a los estudiantes.');
      }
    } catch (e) {
      _showSnackBar('Error al aceptar viaje. Inténtalo de nuevo.');
    } finally {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  Future<void> _startTrip() async {
    if (_pinController.text.length < 4) {
      _showSnackBar('Por favor ingresa el PIN de seguridad de 4 dígitos.');
      return;
    }

    setState(() {
      _isActionLoading = true;
    });

    try {
      final dio = di.sl<Dio>();
      final tripId = _activeTrip!['id'];
      final response = await dio.post(
        '/api/v1/trips/$tripId/start',
        data: {'securityCode': _pinController.text},
      );
      if (response.statusCode == 200) {
        setState(() {
          _activeTrip = Map<String, dynamic>.from(response.data);
          _pinController.clear();
        });
        _showSnackBar('¡Viaje Iniciado! Conduce con cuidado.');
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map 
          ? (e.response?.data['message'] ?? 'Código PIN incorrecto.') 
          : 'Código PIN incorrecto.';
      _showSnackBar(msg);
    } catch (_) {
      _showSnackBar('Error de conexión al iniciar viaje.');
    } finally {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  Future<void> _completeTrip() async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      final dio = di.sl<Dio>();
      final tripId = _activeTrip!['id'];
      final response = await dio.post('/api/v1/trips/$tripId/complete');
      if (response.statusCode == 200) {
        _showSnackBar('¡Viaje finalizado con éxito!');
        setState(() {
          _activeTrip = null;
          _activeRoute = null;
          _activeBooking = null;
          _routePoints.clear();
        });
        _loadAvailableTrips();
      }
    } catch (e) {
      final msg = e is DioException && e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Error al finalizar el viaje.')
          : 'Error al finalizar el viaje.';
      _showSnackBar(msg);
    } finally {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  Future<void> _cancelTrip() async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      final dio = di.sl<Dio>();
      final tripId = _activeTrip!['id'];
      final response = await dio.post(
        '/api/v1/trips/$tripId/cancel',
        data: {'reason': 'Conductor canceló desde la app'},
      );
      if (response.statusCode == 200) {
        _showSnackBar('Viaje cancelado.');
        setState(() {
          _activeTrip = null;
          _activeRoute = null;
          _activeBooking = null;
          _routePoints.clear();
        });
        _loadAvailableTrips();
      }
    } catch (_) {
      _showSnackBar('Error al cancelar el viaje.');
    } finally {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary, duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveTrip = _activeTrip != null;
    final campus = _campusData[_selectedCampus]!;

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
                  markers: [
                    // Campus UPC (Origen)
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
                    // Destino y Paradas del viaje activo
                    if (hasActiveTrip && _activeRoute != null) ...[
                      Marker(
                        point: LatLng(_activeRoute!['destination']['latitude'], _activeRoute!['destination']['longitude']),
                        width: 40.0,
                        height: 40.0,
                        child: const Icon(Icons.flag, color: Colors.redAccent, size: 32),
                      ),
                      if (_activeRoute!['waypoints'] != null)
                        ...((_activeRoute!['waypoints'] as List).map((wp) => Marker(
                              point: LatLng(wp['latitude'], wp['longitude']),
                              width: 40.0,
                              height: 40.0,
                              child: const Icon(Icons.pin_drop, color: Colors.blueAccent, size: 28),
                            )))
                    ]
                  ],
                ),
              ],
            ),
          ),

          // 2. GRADIENT OVERLAY
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

          // 3. BARRA SUPERIOR: SELECTOR DE CAMPUS / TÍTULO DE VIAJE
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.95),
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
                      Text(
                        hasActiveTrip ? 'Viaje en Progreso' : 'Bolsa de Viajes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (!hasActiveTrip)
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
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCampus = value;
                          });
                          _loadAvailableTrips();
                        }
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      onPressed: _loadActiveTripDetails,
                    ),
                ],
              ),
            ),
          ),

          // 4. PANEL INFERIOR (VIAJES DISPONIBLES O DETALLES DEL VIAJE ACTIVO)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: hasActiveTrip ? _buildActiveTripPanel() : _buildAvailableTripsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTripsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Solicitudes Cercanas',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary, size: 20),
                onPressed: _loadAvailableTrips,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            )
          else if (_availableTrips.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30.0),
              child: Text(
                'No hay solicitudes de viaje en este campus.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _availableTrips.length,
                itemBuilder: (context, index) {
                  final trip = _availableTrips[index];
                  final route = trip['route'];
                  final destAddress = route != null ? route['destination']['address'] : 'Destino desconocido';
                  final distance = route != null ? (route['totalDistanceKm'] as num).toDouble() : 0.0;
                  final amount = trip['totalAmount'] ?? (10.0 + distance * 1.5);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destAddress,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${distance.toStringAsFixed(1)} km  •  S/ ${amount.toStringAsFixed(2)}',
                                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isActionLoading ? null : () => _acceptTrip(trip['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Aceptar',
                            style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveTripPanel() {
    final status = _activeTrip!['status'];
    final route = _activeRoute;
    final booking = _activeBooking;
    final destAddress = route != null ? route['destination']['address'] : 'Cargando destino...';
    final amount = _activeTrip!['totalAmount'] ?? 15.0;
    
    final passengerCount = booking != null && booking['passengers'] != null 
        ? (booking['passengers'] as List).length 
        : 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VIAJE ACTUAL', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    status == 'ACCEPTED' ? 'Recogiendo Pasajeros' : 'En Ruta al Destino',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  'S/ ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          
          if (_isActionLoading && route == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else ...[
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    destAddress,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$passengerCount pasajeros listos',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            if (status == 'ACCEPTED') ...[
              const Text(
                'Solicita el PIN de seguridad del estudiante líder para iniciar el viaje:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 4),
                      decoration: const InputDecoration(
                        hintText: 'PIN',
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isActionLoading ? null : _startTrip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Iniciar Viaje', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isActionLoading ? null : _cancelTrip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancelar Viaje', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else if (status == 'ACTIVE') ...[
              ElevatedButton(
                onPressed: _isActionLoading ? null : _completeTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Finalizar Viaje', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
