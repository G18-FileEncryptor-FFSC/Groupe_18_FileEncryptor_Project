// lib/screens/decryption_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_encryptor_core/file_encryptor_core.dart';
import '../state/decryption_state.dart';
import '../services/decryption_service.dart';

class DecryptionScreen extends StatefulWidget {
  const DecryptionScreen({super.key});

  @override
  State<DecryptionScreen> createState() => _DecryptionScreenState();
}

class _DecryptionScreenState extends State<DecryptionScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  DecryptionState _state = const DecryptionState();

  // Initialisation correcte avec late final
  late final _decryptionService = DecryptionService(
    decryptFileUseCase: DecryptFileUseCase(
      cryptoRepository: CryptoRepositoryImpl(),
      fileRepository: FileRepositoryImpl(),
    ),
  );

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickFile() async {
    final pickedFile = await FilePicker.pickFile(
      type: FileType.any,
    );

    if (pickedFile != null && pickedFile.path != null) {
      final path = pickedFile.path!;
      final file = File(path);
      final size = await file.length();
      final name = pickedFile.name;

      setState(() {
        _state = _state.copyWith(
          selectedFilePath: path,
          fileName: name,
          fileSizeBytes: size,
        );
      });
    }
  }

  Future<void> _startDecryption() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le mot de passe')),
      );
      return;
    }

    setState(() {
      _state = _state.copyWith(
        status: DecryptionStatus.loading,
        password: _passwordController.text,
      );
    });

    final result = await _decryptionService.decrypt(
      inputPath: _state.selectedFilePath!,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _state = result);
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      _passwordController.clear();
      _state = const DecryptionState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Déchiffrement'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 24),
            Expanded(
              child: _buildCurrentStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepCircle(1),
        _stepLine(),
        _stepCircle(2),
        _stepLine(),
        _stepCircle(3),
      ],
    );
  }

  Widget _stepCircle(int stepNumber) {
    final isActive = stepNumber == _currentStep + 1;
    final isCompleted = stepNumber < _currentStep + 1;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : isCompleted
                ? Colors.green
                : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                '$stepNumber',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _stepLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1File();
      case 1:
        return _buildStep2Password();
      case 2:
        return _buildStep3Summary();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1File() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Choisir un fichier chiffré',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _state.status == DecryptionStatus.loading ? null : _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 48,
                  color: _state.selectedFilePath != null
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _state.fileName ?? 'Choisir un fichier',
                  style: TextStyle(
                    fontSize: 16,
                    color: _state.selectedFilePath != null
                        ? Colors.black87
                        : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Zéro upload cloud · 100% sur l'appareil",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _state.selectedFilePath != null &&
                    _state.status != DecryptionStatus.loading
                ? _nextStep
                : null,
            child: const Text('Continuer →'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Password() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Mot de passe',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir le mot de passe';
              }
              return null;
            },
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevStep,
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _nextStep();
                    }
                  },
                  child: const Text('Continuer →'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Summary() {
    final isProcessing = _state.status == DecryptionStatus.loading;
    final isSuccess = _state.status == DecryptionStatus.success;
    final isError = _state.status == DecryptionStatus.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSuccess
                ? Colors.green.shade50
                : isError
                    ? Colors.red.shade50
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSuccess
                  ? Colors.green
                  : isError
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
            ),
          ),
          child: Text(
            isSuccess
                ? 'Déchiffrement réussi'
                : isError
                    ? 'Échec du déchiffrement'
                    : 'Prêt pour le déchiffrement',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSuccess
                  ? Colors.green.shade700
                  : isError
                      ? Colors.red.shade700
                      : Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow('Fichier source', _state.fileName ?? '—'),
                _summaryRow(
                  'Taille originale',
                  _state.fileSizeBytes != null
                      ? '${(_state.fileSizeBytes! / 1024).toStringAsFixed(2)} Ko'
                      : '—',
                ),
                if (_state.outputPath != null)
                  _summaryRow(
                    'Fichier restauré',
                    _state.outputPath!.split(Platform.pathSeparator).last,
                  ),
              ],
            ),
          ),
        ),
        if (isError && _state.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _state.errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
        const Spacer(),
        if (isSuccess)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Déchiffrer un autre fichier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : _startDecryption,
                  child: isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Déchiffrer maintenant'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isProcessing ? null : _prevStep,
                child: const Text('← Modifier'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
