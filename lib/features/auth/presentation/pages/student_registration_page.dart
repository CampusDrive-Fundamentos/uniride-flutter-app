import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class StudentRegistrationPage extends StatefulWidget {
  const StudentRegistrationPage({super.key});

  @override
  State<StudentRegistrationPage> createState() => _StudentRegistrationPageState();
}

class _StudentRegistrationPageState extends State<StudentRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _universityController = TextEditingController();
  File? _tiuImage;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _tiuImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Registro de Estudiante', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (state is AuthRegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          } else if (state is AuthError) {
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(_nameController, 'Nombres', false, (v) => Validators.validateRequired(v, 'Nombres')),
                  const SizedBox(height: 16),
                  _buildTextField(_lastNameController, 'Apellidos', false, (v) => Validators.validateRequired(v, 'Apellidos')),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, 'Correo Institucional', false, Validators.validateEmail),
                  const SizedBox(height: 16),
                  _buildTextField(_passwordController, 'Contraseña', true, Validators.validatePassword),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, 'Teléfono', false, (v) => Validators.validateRequired(v, 'Teléfono')),
                  const SizedBox(height: 16),
                  _buildTextField(_universityController, 'Universidad (Ej. UPC)', false, (v) => Validators.validateRequired(v, 'Universidad')),
                  const SizedBox(height: 24),
                  
                  // Subida de TIU (US01)
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                    label: Text(_tiuImage == null ? 'Subir foto del TIU' : 'TIU Seleccionado', style: const TextStyle(color: AppColors.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (state is AuthLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  else
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_tiuImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Debe adjuntar la foto de su TIU'), backgroundColor: AppColors.error),
                            );
                            return;
                          }
                          context.read<AuthBloc>().add(RegisterStudentEvent(
                            username: _emailController.text.split('@')[0], // Generar username del email
                            firstName: _nameController.text,
                            lastName: _lastNameController.text,
                            email: _emailController.text,
                            password: _passwordController.text,
                            phoneNumber: _phoneController.text,
                            universityName: _universityController.text,
                            tiuPhoto: _tiuImage!,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Crear Cuenta', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget reutilizable para inputs oscuros
  Widget _buildTextField(TextEditingController controller, String label, bool isPassword, String? Function(String?)? validator) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }
}