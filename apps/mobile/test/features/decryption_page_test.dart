// test/features/decryption_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/decryption_screen.dart';

void main() {
  testWidgets('DecryptionScreen displays step indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DecryptionScreen(),
      ),
    );

    expect(find.text('Déchiffrement'), findsOneWidget);
  });
}
