import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class DriverRegistrationPage extends StatefulWidget {
  const DriverRegistrationPage({super.key});

  @override
  State<DriverRegistrationPage> createState() => _DriverRegistrationPageState();
}

class _DriverRegistrationPageState extends State<DriverRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _culCtrl = TextEditingController(); // Código CUL

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Registro de Conductor', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushReplacementNamed(context, '/register-vehicle');
          } else if (state is AuthError) {
            // US17 Escenario 2: Fallo -> Notificación
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(_nameCtrl, 'Nombres', false),
                  const SizedBox(height: 16),
                  _buildTextField(_lastNameCtrl, 'Apellidos', false),
                  const SizedBox(height: 16),
                  _buildTextField(_emailCtrl, 'Correo Personal', false),
                  const SizedBox(height: 16),
                  _buildTextField(_passwordCtrl, 'Contraseña', true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_dniCtrl, 'DNI (8 dígitos)', false, isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_phoneCtrl, 'Teléfono', false, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_licenseCtrl, 'N° Licencia de Conducir', false),
                  const SizedBox(height: 16),
                  _buildTextField(_culCtrl, 'Código Certificado Único Laboral (CUL)', false),
                  
                  const SizedBox(height: 32),
                  if (state is AuthLoading)
                    const CircularProgressIndicator(color: AppColors.primary)
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<AuthBloc>().add(RegisterDriverEvent(
                            username: _emailCtrl.text.split('@')[0],
                            firstName: _nameCtrl.text, lastName: _lastNameCtrl.text,
                            email: _emailCtrl.text, password: _passwordCtrl.text,
                            phoneNumber: _phoneCtrl.text, dni: _dniCtrl.text,
                            licenseNumber: _licenseCtrl.text, culCertificate: _culCtrl.text,
                          ));
                        }
                      },
                      child: const Text('Continuar a Vehículo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool obscure, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: (v) => v!.isEmpty ? 'Requerido' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}