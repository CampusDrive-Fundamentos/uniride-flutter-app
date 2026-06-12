class AuthResponseDto {
  final String token;
  
  AuthResponseDto({required this.token});

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      token: json['token'] ?? '',
    );
  }
}