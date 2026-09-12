import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/encryption_screen.dart';
import 'package:mobile/state/encryption_state.dart';

void main() {
  group('EncryptionState Unit Tests', () {
    test('Initial state should be idle with progress at 0.0', () {
      const state = EncryptionState();
      expect(state.status, EncryptionStatus.idle);
      expect(state.progress, 0.0);
      expect(state.selectedFilePath, isNull);
      expect(state.outputPath, isNull);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates fields correctly for loading and success', () {
      const state = EncryptionState();

      final loadingState = state.copyWith(
        status: EncryptionStatus.loading,
        selectedFilePath: '/path/test.txt',
        progress: 0.5,
      );
      expect(loadingState.status, EncryptionStatus.loading);
      expect(loadingState.selectedFilePath, '/path/test.txt');
      expect(loadingState.progress, 0.5);

      final successState = loadingState.copyWith(
        status: EncryptionStatus.success,
        outputPath: '/path/test.txt.enc',
        progress: 1.0,
      );
      expect(successState.status, EncryptionStatus.success);
      expect(successState.outputPath, '/path/test.txt.enc');
      expect(successState.progress, 1.0);
    });

    test('copyWith updates fields correctly for error state', () {
      const state = EncryptionState();
      final errorState = state.copyWith(
        status: EncryptionStatus.error,
        errorMessage: 'Invalid key',
      );
      expect(errorState.status, EncryptionStatus.error);
      expect(errorState.errorMessage, 'Invalid key');
    });
  });

  group('EncryptionScreen Widget Tests', () {
    testWidgets('Displays all essential UI elements initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EncryptionScreen(),
        ),
      );

      expect(find.text('Chiffrer un fichier'), findsOneWidget);
      expect(find.text('Sélectionnez un fichier'), findsOneWidget);
      expect(find.text('Mot de passe de chiffrement'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('Disables encryption button when no file is selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EncryptionScreen(),
        ),
      );

        final buttonFinder =
          find.byWidgetPredicate((widget) => widget is ElevatedButton);

      // Scroller dans le ListView jusqu'à faire apparaître le bouton
      await tester.scrollUntilVisible(
        buttonFinder,
        150.0,
        scrollable: find.byWidgetPredicate((widget) => widget is Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(buttonFinder, findsOneWidget);

      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });
  });
}