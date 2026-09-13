import 'package:flutter/material.dart';

class FileDecryptorApp extends StatelessWidget {
  const FileDecryptorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Decryptor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Decryptionscreen(),
    );
  }
}

class Decryptionscreen extends StatelessWidget {
  const Decryptionscreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
