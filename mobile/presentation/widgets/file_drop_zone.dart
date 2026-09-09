import 'package:flutter/material.dart';

class FileDropZone extends StatelessWidget {
  final String? selectedFilePath;
  final VoidCallback onTap;

  const FileDropZone({super.key, required this.onTap, this.selectedFilePath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue.withValues(alpha: 0.05),
        ),
        child: Center(
          child: selectedFilePath == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_open, size: 40, color: Colors.blueAccent),
                    SizedBox(height: 8),
                    Text(
                      "Appuyez pour choisir un fichier chiffré",
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      size: 40,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedFilePath!.split('/').last,
                      style: const TextStyle(color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
