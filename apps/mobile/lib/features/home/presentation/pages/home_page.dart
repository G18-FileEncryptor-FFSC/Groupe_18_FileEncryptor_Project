import 'package:flutter/material.dart';
import '../../../../screens/encryption_screen.dart';
import '../../../../screens/decryption_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FileEncryptor')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EncryptionScreen(),
                  ),
                );
              },
              child: const Text('Aller à l\'Encryption'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DecryptionScreen(),
                  ),
                );
              },
              child: const Text('Aller au Déchiffrement'),
            ),
          ],
        ),
      ),
    );
  }
}
