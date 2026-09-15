import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/decryption_service.dart';
import '../state/decryption_state.dart';

class DecryptionScreen extends StatefulWidget {
  const DecryptionScreen({super.key});

  @override
  State<DecryptionScreen> createState() => _DecryptionScreenState();
}

class _DecryptionScreenState extends State<DecryptionScreen> {
  final _passwordController = TextEditingController();
  final _decryptionService = DecryptionService();
  DecryptionState _state = const DecryptionState();
  int _step = 0;
  bool _obscurePassword = true;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final size = await File(path).length();
    setState(() {
      _state = DecryptionState(
        selectedFilePath: path,
        fileName: result!.files.single.name,
        fileSizeBytes: size,
      );
      _step = 0;
    });
  }

  Future<void> _decrypt() async {
    final path = _state.selectedFilePath;
    final password = _passwordController.text;
    if (path == null || password.isEmpty) return;

    setState(() {
      _state = DecryptionState(
        status: DecryptionStatus.loading,
        selectedFilePath: path,
        fileName: _state.fileName,
        fileSizeBytes: _state.fileSizeBytes,
      );
    });

    final result = await _decryptionService.decrypt(
      inputPath: path,
      password: password,
    );
    if (!mounted) return;
    setState(() {
      _state = result.copyWith(
        selectedFilePath: path,
        fileName: _state.fileName,
        fileSizeBytes: _state.fileSizeBytes,
      );
    });
  }

  void _reset() {
    setState(() {
      _state = const DecryptionState();
      _passwordController.clear();
      _step = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Déchiffrement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProgress(),
            const SizedBox(height: 24),
            Expanded(child: _buildStep()),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < 3; index++) ...[
          CircleAvatar(
            radius: 20,
            backgroundColor: index <= _step
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: index <= _step ? Colors.white : Colors.black54,
              ),
            ),
          ),
          if (index < 2)
            Container(width: 40, height: 2, color: Colors.grey.shade300),
        ],
      ],
    );
  }

  Widget _buildStep() {
    if (_step == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Choisir un fichier chiffré',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _state.isLoading ? null : _pickFile,
            icon: const Icon(Icons.folder_open),
            label: Text(_state.fileName ?? 'Sélectionner un fichier'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _state.selectedFilePath == null
                ? null
                : () => setState(() => _step = 1),
            child: const Text('Continuer'),
          ),
        ],
      );
    }

    if (_step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Mot de passe',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _passwordController.text.isEmpty
                      ? null
                      : () => setState(() => _step = 2),
                  child: const Text('Continuer'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _state.isSuccess
              ? 'Déchiffrement réussi'
              : _state.isError
                  ? 'Échec du déchiffrement'
                  : 'Prêt pour le déchiffrement',
        ),
        if (_state.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _state.errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ],
        if (_state.outputPath != null) ...[
          const SizedBox(height: 16),
          Text('Fichier restauré : ${_state.outputPath}'),
        ],
        const Spacer(),
        if (_state.isSuccess)
          ElevatedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('Déchiffrer un autre fichier'),
          )
        else
          ElevatedButton(
            onPressed: _state.isLoading ? null : _decrypt,
            child: Text(_state.isLoading
                ? 'Déchiffrement en cours...'
                : 'Déchiffrer maintenant'),
          ),
        TextButton(
          onPressed: _state.isLoading ? null : () => setState(() => _step = 1),
          child: const Text('Modifier'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
