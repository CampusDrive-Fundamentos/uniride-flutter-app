import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../blocs/routes_bloc.dart';
import '../blocs/routes_event.dart';
import '../blocs/routes_state.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  
  String _selectedCampus = 'MONTERRICO';
  String _selectedExitGate = 'Puerta 1 (Primavera)';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 13, minute: 0);

  // Puertas de salida correspondientes por Campus
  final Map<String, List<String>> _gatesByCampus = {
    'MONTERRICO': ['Puerta 1 (Primavera)', 'Puerta 3 (El Polo)', 'Puerta 4'],
    'SAN ISIDRO': ['Puerta Principal (Salaverry)', 'Puerta Posterior (Huascar)'],
    'VILLA': ['Puerta Principal (Al. San Marcos)', 'Puerta 2'],
    'SAN MIGUEL': ['Puerta Principal (La Marina)', 'Puerta 2 (Parque de las Leyendas)'],
  };

  // Coordenadas simuladas para el destino
  double _destinationLat = -12.1210;
  final double _destinationLng = -77.0290;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Simular coordenadas aproximadas basadas en el texto (o valores fijos para el mockup)
      if (_destinationController.text.toLowerCase().contains('miraflores')) {
        _destinationLat = -12.1210;
      } else if (_destinationController.text.toLowerCase().contains('surco')) {
        _destinationLat = -12.1280;
      } else if (_destinationController.text.toLowerCase().contains('san miguel')) {
        _destinationLat = -12.0772;
      } else {
        _destinationLat = -12.1000; // Valor por defecto
      }

      final timeFormatted = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      context.read<RoutesBloc>().add(
            CreateRouteAndBookingEvent(
              campus: _selectedCampus,
              destinationAddress: _destinationController.text,
              destinationLat: _destinationLat,
              destinationLng: _destinationLng,
              exitGate: _selectedExitGate,
              departureTime: timeFormatted,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crear Anuncio de Ruta', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<RoutesBloc, RoutesState>(
        listener: (context, state) {
          if (state is RoutesLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          } else if (state is RoutesError) {
            Navigator.pop(context); // Cerrar loader
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          } else if (state is RouteAndBookingCreated) {
            Navigator.pop(context); // Cerrar loader
            
            // Mostrar diálogo de éxito de creación de anuncio con PIN
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent),
                    SizedBox(width: 10),
                    Text('¡Anuncio Creado!', style: TextStyle(color: Colors.white)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu ruta ha sido registrada y publicada en el sistema.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Código PIN de Seguridad:',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            state.booking.securityPin ?? 'Generando...',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Cerrar diálogo
                      Navigator.pop(context); // Volver al Home
                    },
                    child: const Text('Aceptar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Publica tu ruta hacia la universidad para recibir solicitudes de seguidores (pasajeros) dentro de un radio de 500m de tu camino.',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Selector de Campus
                const Text(
                  'Campus de Origen (UPC)',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCampus,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.school, color: AppColors.primary),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: _gatesByCampus.keys.map((String campus) {
                    return DropdownMenuItem<String>(
                      value: campus,
                      child: Text('Campus $campus'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCampus = value;
                        // Reiniciar a la primera puerta del campus seleccionado
                        _selectedExitGate = _gatesByCampus[value]!.first;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Selector de Puerta de Salida
                const Text(
                  'Puerta de Salida',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedExitGate,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.exit_to_app, color: AppColors.primary),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: _gatesByCampus[_selectedCampus]!.map((String gate) {
                    return DropdownMenuItem<String>(
                      value: gate,
                      child: Text(gate),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedExitGate = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Dirección de Destino
                const Text(
                  'Dirección de Destino',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _destinationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Ej. Parque Kennedy, Miraflores',
                    prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la dirección de destino';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Selector de Hora de Salida
                const Text(
                  'Hora de Salida',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit, color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Botón de Enviar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Publicar Anuncio',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
