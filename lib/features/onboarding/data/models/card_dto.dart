class CardDto {
  final String cardNumber;
  final String expiryDate;
  final String cvv;

  CardDto({required this.cardNumber, required this.expiryDate, required this.cvv});

  Map<String, dynamic> toJson() => {
    "cardNumber": cardNumber,
    "expiryDate": expiryDate,
    "cvv": cvv,
  };
}