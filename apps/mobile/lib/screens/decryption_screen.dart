import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/decryption_service.dart';

class DecryptionScreen extends StatefulWidget {
  const DecryptionScreen({super.key});

  @override
  State<DecryptionScreen> createState() => _DecryptionScreenState();
}

class _DecryptionScreenState extends State<DecryptionScreen> {
  final _passwordController = TextEditingController();
  final _decryptionService = DecryptionService();

  String? _selectedFilePath;
  bool _isDecrypting = false;
  double _progress = 0.0;
  String? _statusMessage;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _statusMessage = null;
      });
    }
  }

  Future<void> _startDecryption() async {
    if (_selectedFilePath == null) {
      setState(
        () => _statusMessage = "Veuillez sélectionner un fichier à déchiffrer.",
      );
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _statusMessage = "Veuillez entrer le mot de passe.");
      return;
    }

    setState(() {
      _isDecrypting = true;
      _progress = 0.0;
      _statusMessage = "Déchiffrement en cours...";
    });

    try {
      await _decryptionService.decrypt(
        filePath: _selectedFilePath!,
        password: _passwordController.text,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      setState(() {
        _statusMessage = "Déchiffrement réussi avec succès !";
        _isDecrypting = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Erreur : ${e.toString()}";
        _isDecrypting = false;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Déchiffrement de Fichier')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isDecrypting ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(
                _selectedFilePath == null
                    ? 'Sélectionner le fichier'
                    : 'Fichier : ${_selectedFilePath!.split('/').last}',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
              enabled: !_isDecrypting,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isDecrypting ? null : _startDecryption,
              child: const Text('Lancer le déchiffrement'),
            ),
            const SizedBox(height: 20),
            if (_isDecrypting) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 10),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
              ),
            ],
            if (_statusMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusMessage!.startsWith('Erreur')
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
