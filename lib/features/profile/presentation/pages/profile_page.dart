import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_drawer.dart';
import '../blocs/profile_bloc.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileEvent());
  }

  Future<void> _logout(BuildContext context) async {
    const secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: 'jwt_token'); 

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoaded) {
                return IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(user: state.userData),
                      ),
                    );
                    if (updated == true && context.mounted) {
                      context.read<ProfileBloc>().add(LoadProfileEvent());
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () => _logout(context), child: const Text('Volver al Login'))
                ],
              ),
            );
          } else if (state is ProfileLoaded) {
            final user = state.userData;
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person, size: 60, color: Colors.black),
                          ),
                          const SizedBox(height: 16),
                          Text('${user.firstName} ${user.lastName}', 
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(user.email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(user.role, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    const Text('Información de Contacto', 
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    _buildInfoTile(Icons.phone, 'Teléfono', user.phoneNumber),
                    _buildInfoTile(Icons.email, 'Email', user.email),
                    
                    if (user.cardNumber != null || user.vehicle != null) ...[
                      const SizedBox(height: 32),
                      const Text('Detalles de Conducción', 
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      if (user.cardNumber != null)
                        _buildInfoTile(Icons.credit_card, 'Tarjeta de Cobro', '**** **** **** ${user.cardNumber!.substring(user.cardNumber!.length > 4 ? user.cardNumber!.length - 4 : 0)}'),
                      
                      if (user.vehicle != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoTile(Icons.directions_car, 'Vehículo', '${user.vehicle!.name} (${user.vehicle!.type})'),
                        _buildInfoTile(Icons.badge, 'Placa', user.vehicle!.licenseNumber),
                      ],
                    ],
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Cerrar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
