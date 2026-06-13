class LoginRequestDto {
  final String email;
  final String password;

  LoginRequestDto({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    String actualUsername = email.contains('@') ? email.split('@')[0] : email;

    return {
      "username": actualUsername,
      "password": password,
    };
  }
}