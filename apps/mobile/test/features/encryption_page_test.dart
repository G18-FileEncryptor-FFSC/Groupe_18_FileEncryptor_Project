import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/encryption_screen.dart';
import 'package:mobile/state/encryption_state.dart';

void main() {
  group('EncryptionState Unit Tests', () {
    test('état initial correct', () {
      const state = EncryptionState();

      expect(state.status, EncryptionStatus.idle);
      expect(state.progress, 0.0);
      expect(state.selectedFilePath, isNull);
      expect(state.outputPath, isNull);
      expect(state.errorMessage, isNull);
    });

    test('copyWith modifie correctement les valeurs', () {
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
      expect(successState.selectedFilePath, '/path/test.txt');
      expect(successState.errorMessage, isNull);
    });

    test('copyWith gère correctement une erreur', () {
      const state = EncryptionState();

      final errorState = state.copyWith(
        status: EncryptionStatus.error,
        errorMessage: 'Invalid key',
      );

      expect(errorState.status, EncryptionStatus.error);
      expect(errorState.errorMessage, 'Invalid key');
      expect(errorState.progress, 0.0);
      expect(errorState.selectedFilePath, isNull);
      expect(errorState.outputPath, isNull);
    });

    test('copyWith conserve les valeurs existantes', () {
      const state = EncryptionState(
        status: EncryptionStatus.loading,
        selectedFilePath: '/documents/test.txt',
        progress: 0.75,
        outputPath: '/documents/test.txt.enc',
      );

      final copiedState = state.copyWith();

      expect(copiedState.status, EncryptionStatus.loading);
      expect(copiedState.selectedFilePath, '/documents/test.txt');
      expect(copiedState.progress, 0.75);
      expect(copiedState.outputPath, '/documents/test.txt.enc');
    });
  });

  group('EncryptionScreen Widget Tests', () {
    Future<void> pumpEncryptionScreen(
      WidgetTester tester,
    ) async {
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
    }

    testWidgets(
      'affiche correctement la première étape',
      (WidgetTester tester) async {
        await pumpEncryptionScreen(tester);

        expect(
          find.text('Chiffrer un fichier'),
          findsOneWidget,
        );

        expect(
          find.text('Choisir un fichier'),
          findsAtLeastNWidgets(1),
        );

        expect(
          find.textContaining('Continuer'),
          findsOneWidget,
        );

        expect(
          find.text('Mot de passe'),
          findsNothing,
        );

        expect(
          find.byType(TextField),
          findsNothing,
        );
      },
    );

    testWidgets(
      'désactive Continuer lorsqu aucun fichier n est sélectionné',
      (WidgetTester tester) async {
        await pumpEncryptionScreen(tester);

        final continueText = find.textContaining('Continuer');

        final buttonFinder = find.ancestor(
          of: continueText,
          matching: find.byType(ElevatedButton),
        );

        expect(buttonFinder, findsOneWidget);

        final button = tester.widget<ElevatedButton>(
          buttonFinder,
        );

        expect(button.onPressed, isNull);
      },
    );
  });
}