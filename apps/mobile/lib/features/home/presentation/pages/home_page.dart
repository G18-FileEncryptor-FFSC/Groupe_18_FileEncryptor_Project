import 'package:flutter/material.dart';

/// Page d'accueil du tableau de bord.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FileEncryptor')),
      body: const Center(child: Text('Tableau de bord')),
    );
  }
}
