class SignUpResponseDto {
  final String message;

  SignUpResponseDto({required this.message});

  factory SignUpResponseDto.fromJson(Map<String, dynamic> json) {
    return SignUpResponseDto(
      message: json['message'] ?? '',
    );
  }
}
