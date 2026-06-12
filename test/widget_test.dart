import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniride_flutter_app/main.dart'; // Ajusta este import si tu nombre de proyecto es distinto

void main() {
  testWidgets('Test de inicialización', (WidgetTester tester) async {
    // CORRECCIÓN: Cambiado MyApp por UniRideApp
    await tester.pumpWidget(const UniRideApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}