import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../state/encryption_state.dart';
import '../services/encryption_service.dart';

class EncryptionScreen extends StatefulWidget {
  const EncryptionScreen({super.key});

  @override
  State<EncryptionScreen> createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> {
  late final EncryptionService _service;
  final _passwordController = TextEditingController();
  EncryptionState _state = const EncryptionState();

  @override
  void initState() {
    super.initState();
    _service = EncryptionService();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _state = _state.copyWith(
          selectedFilePath: result.files.single.path,
          status: EncryptionStatus.idle,
          errorMessage: null,
        );
      });
    }
  }

  Future<void> _startEncryption() async {
    final path = _state.selectedFilePath;
    final pwd = _passwordController.text;

    if (path == null) {
      _showSnack('Veuillez sélectionner un fichier');
      return;
    }
    if (pwd.isEmpty) {
      _showSnack('Veuillez renseigner un mot de passe');
      return;
    }

    setState(() {
      _state = _state.copyWith(status: EncryptionStatus.loading, progress: 0.0);
    });

    try {
      final res = await _service.encrypt(
        filePath: path,
        password: pwd,
        onProgress: (p) => setState(() => _state = _state.copyWith(progress: p)),
      );

      _passwordController.clear();

      if (res.isSuccess) {
        setState(() {
          _state = _state.copyWith(
            status: EncryptionStatus.success,
            outputPath: res.outputPath,
          );
        });
      } else {
        setState(() {
          _state = _state.copyWith(
            status: EncryptionStatus.error,
            errorMessage: res.errorMessage ?? 'Échec du chiffrement',
          );
        });
      }
    } catch (e) {
      _passwordController.clear();
      setState(() {
        _state = _state.copyWith(
          status: EncryptionStatus.error,
          errorMessage: e.toString(),
        );
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chiffrement de fichier')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _state.status == EncryptionStatus.loading ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(_state.selectedFilePath ?? 'Sélectionner un fichier'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe de chiffrement',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (_state.status == EncryptionStatus.loading) ...[
              LinearProgressIndicator(value: _state.progress),
              const SizedBox(height: 8),
              Text('${(_state.progress * 100).toStringAsFixed(0)} %', textAlign: TextAlign.center),
            ],
            if (_state.status == EncryptionStatus.success)
              Text('Fichier chiffré : ${_state.outputPath}', style: const TextStyle(color: Colors.green)),
            if (_state.status == EncryptionStatus.error)
              Text('Erreur : ${_state.errorMessage}', style: const TextStyle(color: Colors.red)),
            const Spacer(),
            ElevatedButton(
              onPressed: _state.status == EncryptionStatus.loading ? null : _startEncryption,
              child: const Text('Chiffrer le fichier'),
            ),
          ],
        ),
      ),
    );
  }
}