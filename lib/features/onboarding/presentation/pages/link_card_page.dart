import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../blocs/onboarding_bloc.dart';
import '../blocs/onboarding_event.dart';
import '../blocs/onboarding_state.dart';

class LinkCardPage extends StatefulWidget {
  const LinkCardPage({super.key});

  @override
  State<LinkCardPage> createState() => _LinkCardPageState();
}

class _LinkCardPageState extends State<LinkCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Método de Pago', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is CardLinkedSuccess) {
            Navigator.pushReplacementNamed(context, '/home');
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
                    'Añade una tarjeta para el cobro automático de la comisión de la plataforma (10%).',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _cardNumberController,
                    label: 'Número de Tarjeta',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.length < 16) return 'Debe tener 16 dígitos';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _expiryDateController,
                          label: 'MM/AA',
                          keyboardType: TextInputType.datetime,
                          validator: (v) => Validators.validateRequired(v, 'Fecha'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          controller: _cvvController,
                          label: 'CVV',
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.length < 3) return 'Inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
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
                            SubmitCardEvent(
                              cardNumber: _cardNumberController.text,
                              expiry: _expiryDateController.text,
                              cvv: _cvvController.text,
                            ),
                          );
                        }
                      },
                      child: const Text('Finalizar Registro', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
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