import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../blocs/routes_bloc.dart';
import '../blocs/routes_event.dart';
import '../blocs/routes_state.dart';
import '../../domain/entities/booking_entity.dart';

class NearbyBookingsPage extends StatefulWidget {
  final String campus;
  final double lat;
  final double lng;

  const NearbyBookingsPage({
    super.key,
    required this.campus,
    required this.lat,
    required this.lng,
  });

  @override
  State<NearbyBookingsPage> createState() => _NearbyBookingsPageState();
}

class _NearbyBookingsPageState extends State<NearbyBookingsPage> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  final _pickupAddressController = TextEditingController(text: 'Mi ubicación actual');

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Disparar la búsqueda de rutas al iniciar la pantalla
    _fetchNearbyBookings();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _pickupAddressController.dispose();
    super.dispose();
  }

  void _fetchNearbyBookings() {
    context.read<RoutesBloc>().add(
          SearchNearbyBookingsEvent(
            campus: widget.campus,
            lat: widget.lat,
            lng: widget.lng,
          ),
        );
  }

  void _showJoinModal(BuildContext context, BookingEntity booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirmar Parada de Encuentro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Indica la dirección exacta donde te recogerá el conductor. Debe estar en el camino establecido.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _pickupAddressController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Dirección de Recogida',
                  prefixIcon: Icon(Icons.pin_drop, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar bottom sheet
                  
                  // Lanzar evento para unirse
                  this.context.read<RoutesBloc>().add(
                        JoinBookingEvent(
                          bookingId: booking.id,
                          lat: widget.lat,
                          lng: widget.lng,
                          address: _pickupAddressController.text,
                        ),
                      );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Confirmar y Unirse',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessScreen(BookingEntity booking) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  // Icono animado de exito
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.greenAccent,
                      child: Icon(Icons.check, size: 50, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¡Te has unido con éxito!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu parada ha sido registrada. El conductor recalculará la ruta óptima para recogerte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Detalles del grupo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Código de Viaje:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Text('#${booking.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(color: Colors.grey, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Líder del Grupo:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Text('Usuario #${booking.leaderId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(color: Colors.grey, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Parada Confirmada:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Expanded(
                              child: Text(
                                _pickupAddressController.text,
                                textAlign: TextAlign.end,
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cerrar dialogo de exito
                      Navigator.pop(context); // Volver al home
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Volver al Inicio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rutas Cercanas (500m)', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<RoutesBloc, RoutesState>(
        listener: (context, state) {
          if (state is JoinedBookingSuccess) {
            _showSuccessScreen(state.booking);
          }
        },
        builder: (context, state) {
          if (state is RoutesLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _scannerController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(180, 180),
                        painter: _RadarScannerPainter(
                          value: _scannerController.value,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Escaneando rutas activas...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Buscando conductores a menos de 500m de tu ubicación.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          } else if (state is RoutesError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchNearbyBookings,
                      child: const Text('Reintentar Buscar'),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is NearbyBookingsLoaded) {
            final bookings = state.bookings;

            if (bookings.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.radar_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 20),
                      const Text(
                        'No se encontraron rutas cercanas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Actualmente no hay conductores que pasen a menos de 500 metros de tu posición con destino a la universidad.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _fetchNearbyBookings,
                        child: const Text('Escanear de Nuevo', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Se encontraron ${bookings.length} grupos activos cerca de ti:',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: bookings.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      // Simular una distancia mock basada en el index para presentación
                      final distance = (index + 1) * 120 + 35; 
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
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
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.primary,
                                      child: Icon(Icons.person, color: Colors.black, size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Conductor #${booking.leaderId}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Ruta #${booking.routeId}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.navigation, color: Colors.blueAccent, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'A ${distance}m de ti',
                                        style: const TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.grey, height: 24),
                            
                            // Destino
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Destino Final:',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                      Text(
                                        'Ruta hacia Campus ${widget.campus}',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Pasajeros y estado
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.people_outline, color: AppColors.textSecondary, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${booking.passengers.length}/4 Pasajeros',
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    booking.status,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Botón para unirse
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _showJoinModal(context, booking),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Unirse al Viaje',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// Pintor de radar animado futurista
class _RadarScannerPainter extends CustomPainter {
  final double value;

  _RadarScannerPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    final Paint circlePaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.blueAccent.withOpacity(0.0),
          Colors.blueAccent.withOpacity(0.4),
        ],
        stops: const [0.0, 1.0],
        transform: GradientRotation(value * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // Pintar circulos concentricos
    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius * 0.66, circlePaint);
    canvas.drawCircle(center, radius * 0.33, circlePaint);

    // Pintar barrido de radar
    canvas.drawCircle(center, radius, sweepPaint);

    // Pintar cruz central
    final Paint linePaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.2)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, radius), Offset(size.width, radius), linePaint);
    canvas.drawLine(Offset(radius, 0), Offset(radius, size.height), linePaint);

    // Pequeño pin en el centro
    canvas.drawCircle(center, 4, Paint()..color = Colors.blueAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
