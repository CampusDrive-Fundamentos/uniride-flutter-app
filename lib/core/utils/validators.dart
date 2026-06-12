class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'El correo es requerido';
    if (!value.endsWith('.edu.pe') && !value.endsWith('.edu')) {
      return 'Debe ser un correo institucional (.edu o .edu.pe)';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName es requerido';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}