import 'package:flutter/material.dart';
import 'features/home/presentation/pages/home_page.dart';

class FileEncryptorApp extends StatelessWidget {
  const FileEncryptorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Encryptor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainNavigationWrapper(),
    );
  }
}
