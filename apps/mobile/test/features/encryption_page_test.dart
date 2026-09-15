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

  group('EncryptionScreen Widget Tests (Wizard Flow)', () {
    testWidgets('Displays Step 1 (File Selection) elements initially',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: EncryptionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifie la présence des éléments de l'étape 1
      expect(find.text('Choisir un fichier'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Zero upload cloud'), findsOneWidget);
      expect(find.textContaining('Continuer'), findsOneWidget);

      // Vérifie que les éléments de l'étape 2 sont absents
      expect(find.text('Mot de passe'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Disables "Continuer" button when no file is selected',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: EncryptionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Trouve le bouton ElevatedButton englobant le texte 'Continuer'
      final buttonFinder = find.ancestor(
        of: find.textContaining('Continuer'),
        matching: find.byWidgetPredicate((w) => w is ElevatedButton),
      );

      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<ElevatedButton>(buttonFinder);
      // Le bouton doit être grisé sans fichier sélectionné
      expect(button.onPressed, isNull);
    });
  });
}