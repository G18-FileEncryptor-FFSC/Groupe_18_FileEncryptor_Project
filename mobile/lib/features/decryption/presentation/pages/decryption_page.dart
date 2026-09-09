import 'package:flutter/material.dart';
import '../../../../../presentation/controllers/decryption_controller.dart';
import '../../../../../presentation/states/decryption_state.dart';
import '../../../../../presentation/widgets/file_drop_zone.dart';
import '../../../../../presentation/widgets/password_field.dart';
import '../../../../../presentation/widgets/decryption_progress.dart';

class DecryptionPage extends StatefulWidget {
  const DecryptionPage({super.key});

  @override
  State<DecryptionPage> createState() => _DecryptionPageState();
}

class _DecryptionPageState extends State<DecryptionPage> {
  final DecryptionController _controller = DecryptionController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Déchiffrement"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FileDropZone(
              selectedFilePath: state.selectedFilePath,
              onTap: () {
                _controller.selectFile("/storage/mon_fichier.enc");
              },
            ),

            const SizedBox(height: 20),

            PasswordField(controller: _passwordController),

            const SizedBox(height: 20),

            if (state.status == DecryptionStatus.loading)
              DecryptionProgress(progress: state.progress),

            if (state.status == DecryptionStatus.success)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Fichier déchiffré avec succès !",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      state.outputFilePath ?? "",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

            if (state.status == DecryptionStatus.failure)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage ?? "Erreur inconnue",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            ElevatedButton(
              onPressed: state.status == DecryptionStatus.loading
                  ? null
                  : () => _controller.decryptFile(_passwordController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.status == DecryptionStatus.loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Déchiffrer", style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 12),

            if (state.status == DecryptionStatus.success ||
                state.status == DecryptionStatus.failure)
              TextButton(
                onPressed: () {
                  _controller.reset();
                  _passwordController.clear();
                },
                child: const Text("Recommencer"),
              ),
          ],
        ),
      ),
    );
  }
}
