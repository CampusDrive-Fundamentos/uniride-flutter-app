import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


// Configuración Core
import 'core/constants/app_colors.dart';
import 'core/di/service_locator.dart' as di;
import 'core/router/app_router.dart';

// BLoCs
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'features/profile/presentation/blocs/profile_bloc.dart';
import 'features/routes/presentation/blocs/routes_bloc.dart';

void main() async {
  // 1. Asegurar que los bindings de Flutter estén listos 
  // (Necesario para inicializar paquetes nativos como flutter_secure_storage)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar Service Locator (GetIt) para inyectar todas las dependencias
  // (Esto instancia Dio, Repositorios, UseCases y BLoCs)
  await di.init(); 

  // 3. Arrancar la aplicación
  runApp(const UniRideApp());
}

class UniRideApp extends StatelessWidget {
  const UniRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiBlocProvider inyecta los BLoCs en la raíz de la app 
    // para que estén disponibles globalmente en cualquier pantalla.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>(),
        ),
        BlocProvider<OnboardingBloc>(
          create: (_) => di.sl<OnboardingBloc>(),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => di.sl<ProfileBloc>(),
        ),
        BlocProvider<RoutesBloc>(
          create: (_) => di.sl<RoutesBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'UniRide - CampusDrive',
        debugShowCheckedModeBanner: false, // Ocultar la cinta roja de "DEBUG"

        // Configuración Global del Tema (Basado en tus diseños de Figma)
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
            error: AppColors.error,
          ),
          
          // Estilo global del AppBar
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.primary),
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Estilo global de los Botones (Amarillo con texto negro)
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 50), // Botones anchos por defecto
            ),
          ),
          
          // Estilo global de los Inputs (Fondo gris oscuro, bordes invisibles)
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          
          // Color del cursor al escribir
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: AppColors.primary,
            selectionColor: AppColors.primary,
            selectionHandleColor: AppColors.primary,
          ),
        ),
        
        // Enrutamiento: Le decimos a Flutter que arranque en el Splash Screen
        initialRoute: '/', 
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}