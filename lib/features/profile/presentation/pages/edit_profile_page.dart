import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import '../blocs/profile_bloc.dart';

class EditProfilePage extends StatefulWidget {
  final User user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  
  // Driver only fields
  late TextEditingController _cardCtrl;
  late TextEditingController _vTypeCtrl;
  late TextEditingController _vNameCtrl;
  late TextEditingController _vPlateCtrl;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _firstNameCtrl = TextEditingController(text: widget.user.firstName);
    _lastNameCtrl = TextEditingController(text: widget.user.lastName);
    _phoneCtrl = TextEditingController(text: widget.user.phoneNumber);
    
    _cardCtrl = TextEditingController(text: widget.user.cardNumber ?? '');
    _vTypeCtrl = TextEditingController(text: widget.user.vehicle?.type ?? '');
    _vNameCtrl = TextEditingController(text: widget.user.vehicle?.name ?? '');
    _vPlateCtrl = TextEditingController(text: widget.user.vehicle?.licenseNumber ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cardCtrl.dispose();
    _vTypeCtrl.dispose();
    _vNameCtrl.dispose();
    _vPlateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = widget.user.role == 'DRIVER';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perfil actualizado con éxito'), backgroundColor: Colors.green),
            );
            Navigator.pop(context, true);
          } else if (state is ProfileError) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Datos Personales', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  _buildTextField(_firstNameCtrl, 'Nombres'),
                  const SizedBox(height: 16),
                  _buildTextField(_lastNameCtrl, 'Apellidos'),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneCtrl, 'Teléfono', isNumber: true),

                  if (isDriver) ...[
                    const SizedBox(height: 32),
                    const Text('Datos de Conducción', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    _buildTextField(_cardCtrl, 'N° de Tarjeta Bancaria', isNumber: true),
                    const SizedBox(height: 16),
                    _buildTextField(_vTypeCtrl, 'Tipo de Vehículo'),
                    const SizedBox(height: 16),
                    _buildTextField(_vNameCtrl, 'Marca / Modelo'),
                    const SizedBox(height: 16),
                    _buildTextField(_vPlateCtrl, 'Placa (Ej: ABC-123)', 
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        final regex = RegExp(r'^[A-Za-z]{3}-?[A-Za-z0-9]{3}$');
                        if (!regex.hasMatch(v)) return 'Formato sugerido: XXX-000';
                        return null;
                      }
                    ),
                  ],

                  const SizedBox(height: 40),
                  if (state is ProfileUpdating)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (isDriver) {
                            context.read<ProfileBloc>().add(UpdateDriverProfileEvent(
                              firstName: _firstNameCtrl.text,
                              lastName: _lastNameCtrl.text,
                              phoneNumber: _phoneCtrl.text,
                              cardNumber: _cardCtrl.text,
                              vehicleType: _vTypeCtrl.text,
                              vehicleName: _vNameCtrl.text,
                              vehiclePlate: _vPlateCtrl.text,
                            ));
                          } else {
                            context.read<ProfileBloc>().add(UpdateStudentProfileEvent(
                              firstName: _firstNameCtrl.text,
                              lastName: _lastNameCtrl.text,
                              phoneNumber: _phoneCtrl.text,
                            ));
                          }
                        }
                      },
                      child: const Text('Guardar Cambios', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: validator ?? (v) => v!.isEmpty ? 'Requerido' : null,
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
