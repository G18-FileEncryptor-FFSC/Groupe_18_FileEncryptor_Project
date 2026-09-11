
import 'package:flutter/material.dart';
import 'screens/encryption_screen.dart';

class FileEncryptorApp extends StatelessWidget {
  const FileEncryptorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Encryptor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const EncryptionScreen(),
    );
  }
}