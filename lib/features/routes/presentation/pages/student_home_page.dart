import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_drawer.dart';

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Genera coordenadas mock aleatorias dentro de un radio de la UPC para simulación
  void _randomizeStudentLocation() {
    final campus = _campusData[_selectedCampus]!;
    final double baseLat = campus['lat'];
    final double baseLng = campus['lng'];
    
    // Generamos una desviación de aproximadamente 300 a 800 metros (0.003 a 0.008 en lat/lng)
    final random = Random();
    final double offsetLat = (random.nextDouble() - 0.5) * 0.012;
    final double offsetLng = (random.nextDouble() - 0.5) * 0.012;

    setState(() {
      _mockLat = baseLat + offsetLat;
      _mockLng = baseLng + offsetLng;
      _mockAddress = 'Simulado: Paradero a ${(offsetLat * 111000).abs().round()}m de la UPC';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          // 1. MAPA DE SIMULACIÓN HIGH-FIDELITY
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _VectorMapPainter(
                    pulseValue: _pulseController.value,
                    studentLat: _mockLat,
                    studentLng: _mockLng,
                    campusLat: _campusData[_selectedCampus]!['lat'],
                    campusLng: _campusData[_selectedCampus]!['lng'],
                    campusName: _selectedCampus,
                  ),
                );
              },
            ),
          ),

          // 2. GRADIENT OVERLAYS PARA MEJOR CONTRASTE Y ESTÉTICA PREMIUM
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
                            'UPC Destino',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // Dropdown de Campus
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
                              // Actualizar también ubicación del estudiante relativamente cerca
                              _randomizeStudentLocation();
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
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: AppColors.primary, size: 18),
                        onPressed: _randomizeStudentLocation,
                        tooltip: 'Cambiar ubicación',
                      )
                    ],
                  )
                ],
              ),
            ),
          ),

          // 4. PANEL DE CONTROL INFERIOR (CARD FLOTANTE)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info rápida sobre el algoritmo de 500 metros
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

                // Card principal
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
                          // Botón para Seguidor (Buscar Viajes)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/nearby-bookings',
                                  arguments: {
                                    'campus': _selectedCampus,
                                    'lat': _mockLat,
                                    'lng': _mockLng,
                                  },
                                );
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
                          // Botón para Líder (Crear Anuncio)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/create-announcement');
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
            ),
          ),
        ],
      ),
    );
  }
}

// Pintor de mapa premium personalizado que simula un mapa oscuro de alta tecnología
class _VectorMapPainter extends CustomPainter {
  final double pulseValue;
  final double studentLat;
  final double studentLng;
  final double campusLat;
  final double campusLng;
  final String campusName;

  _VectorMapPainter({
    required this.pulseValue,
    required this.studentLat,
    required this.studentLng,
    required this.campusLat,
    required this.campusLng,
    required this.campusName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0;

    final Paint roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final Paint mainHighwayPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.15)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    // 1. Pintar fondo de mapa oscuro
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0F0F12),
    );

    // 2. Dibujar cuadrícula (Grid Lines)
    const double gridSpace = 40.0;
    for (double i = 0; i < size.width; i += gridSpace) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += gridSpace) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 3. Dibujar Caminos Mock (Vías del mapa)
    final Path roads = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.45)
      ..moveTo(size.width * 0.2, 0)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.5, size.width * 0.8, size.height)
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.65)
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..lineTo(size.width * 0.9, size.height * 0.8);
    canvas.drawPath(roads, roadPaint);

    // Calcular centros relativos en la pantalla para simulación
    // Mapeamos el espacio de lat/lng al espacio en píxeles de la pantalla
    // Centro de la pantalla será el punto medio entre estudiante y campus
    final Offset campusOffset = Offset(size.width * 0.5, size.height * 0.4);
    
    // El estudiante estará desplazado según la diferencia de coordenadas
    final double scale = 15000.0; // Factor de escala para que se vea el desplazamiento
    final double dLat = studentLat - campusLat;
    final double dLng = studentLng - campusLng;
    
    // En coordenadas de mapa, +lat es arriba (-y), +lng es derecha (+x)
    final Offset studentOffset = Offset(
      campusOffset.dx + (dLng * scale),
      campusOffset.dy - (dLat * scale),
    );

    // 4. Dibujar ruta del estudiante al campus (línea dorada semi-transparente)
    final Path routePath = Path()
      ..moveTo(studentOffset.dx, studentOffset.dy)
      ..quadraticBezierTo(
        (studentOffset.dx + campusOffset.dx) / 2 + 30,
        (studentOffset.dy + campusOffset.dy) / 2 - 40,
        campusOffset.dx,
        campusOffset.dy,
      );
    canvas.drawPath(routePath, mainHighwayPaint);

    // Dibujar polyline animada de flujo
    final Paint pulseLinePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, pulseLinePaint);

    // 5. Dibujar área de escaneo de 500 metros del estudiante (Radar)
    // 500 metros a la escala usada equivale a un radio de unos 80 píxeles
    const double radius500m = 90.0;
    
    final Paint radarFillPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(studentOffset, radius500m, radarFillPaint);

    final Paint radarBorderPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.4 * (1 - pulseValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(studentOffset, radius500m * pulseValue, radarBorderPaint);
    canvas.drawCircle(studentOffset, radius500m, Paint()
      ..color = Colors.blueAccent.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);

    // 6. Dibujar pin de ubicación del estudiante (Azul)
    final Paint studentPointPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;
    final Paint studentGlowPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.3)
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(studentOffset, 14, studentGlowPaint);
    canvas.drawCircle(studentOffset, 6, studentPointPaint);
    canvas.drawCircle(studentOffset, 3, Paint()..color = Colors.white);

    // 7. Dibujar pin de ubicación de la Universidad UPC (Amarillo)
    final Paint campusPointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final Paint campusGlowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(campusOffset, 16, campusGlowPaint);
    canvas.drawCircle(campusOffset, 8, campusPointPaint);
    
    // Dibujar la "U" o corona en el pin de la UPC
    canvas.drawCircle(campusOffset, 4, Paint()..color = Colors.black);

    // Texto del campus
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: 'UPC $campusName',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(campusOffset.dx - textPainter.width / 2, campusOffset.dy - 30),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
