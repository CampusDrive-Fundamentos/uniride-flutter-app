import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../blocs/onboarding_bloc.dart';
import '../blocs/onboarding_event.dart';
import '../blocs/onboarding_state.dart';

class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({super.key});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();

  @override
  void dispose() {
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registra tu Vehículo', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is VehicleRegisteredSuccess) {
            // US18 completada: vamos a vincular la tarjeta (US27)
            Navigator.pushReplacementNamed(context, '/link-card');
          } else if (state is OnboardingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Por tu seguridad y la de los estudiantes, necesitamos verificar los datos de tu vehículo.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _modelController,
                    label: 'Modelo del Vehículo (Ej. Toyota Yaris)',
                    validator: (v) => Validators.validateRequired(v, 'Modelo'),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _colorController,
                    label: 'Color',
                    validator: (v) => Validators.validateRequired(v, 'Color'),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _plateController,
                    label: 'Placa (Ej. ABC-123)',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (!RegExp(r'^[A-Z0-9]{3}-[A-Z0-9]{3}$').hasMatch(v)) {
                        return 'Formato inválido. Use el guión (Ej: ABC-123)';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const Spacer(),
                  if (state is OnboardingLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<OnboardingBloc>().add(
                            SubmitVehicleEvent(
                              model: _modelController.text,
                              color: _colorController.text,
                              plate: _plateController.text,
                            ),
                          );
                        }
                      },
                      child: const Text('Continuar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}