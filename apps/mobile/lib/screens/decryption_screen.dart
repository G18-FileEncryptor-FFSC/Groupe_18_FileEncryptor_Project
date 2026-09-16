import 'dart:io';

import 'package:file_encryptor_core/file_encryptor_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
  int _currentStep = 0; // 0: Fichier .enc, 1: Mot de passe, 2: Résultat
  bool _obscurePassword = true;
  String? _detectedOriginalName;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() => setState(() {});

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.any,
    );
    if (file == null) return;
    final path = file.path;
    if (path == null || !mounted) return;

    final size = await File(path).length();
    String? originalName;

    // Tentative d'inspection rapide du conteneur .enc pour extraire le nom original
    try {
      final fileService = LocalFileService();
      final container = await fileService.readEncryptedContainer(path);
      originalName = container.originalFileName;
    } catch (_) {
      originalName = null;
    }

    setState(() {
      _detectedOriginalName = originalName;
      _state = DecryptionState(
        selectedFilePath: path,
        fileName: file.name,
        fileSizeBytes: size,
      );
      _currentStep = 1; // Passage automatique à l'étape du mot de passe
    });
  }

  Future<void> _decrypt() async {
    final path = _state.selectedFilePath;
    final password = _passwordController.text;
    if (path == null || password.isEmpty) return;

    setState(() {
      _currentStep = 2;
      _state = _state.copyWith(
        status: DecryptionStatus.loading,
        errorMessage: null,
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
        fileName: result.fileName ?? _detectedOriginalName ?? _state.fileName,
        fileSizeBytes: _state.fileSizeBytes,
      );
    });
  }

  void _reset() {
    setState(() {
      _state = const DecryptionState();
      _passwordController.clear();
      _detectedOriginalName = null;
      _currentStep = 0;
    });
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 Mo';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} Mo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (_currentStep > 0 && !_state.isLoading) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0B57D0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Color(0xFF0B57D0), size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'FILEENCRYPTOR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Accueil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0B57D0),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Déchiffrer un fichier',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 20),

            // Stepper : 1. Fichier .enc -> 2. Mot de passe -> 3. Résultat
            _buildStepper(),
            const SizedBox(height: 24),

            // Step Content
            if (_currentStep == 0)
              _buildFilePickStep()
            else if (_currentStep == 1)
              _buildPasswordStep()
            else
              _buildResultStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Step 1
          _stepNode(
            index: 0,
            label: '1. Fichier .enc',
            isDone: _state.selectedFilePath != null,
            isActive: _currentStep == 0,
          ),
          Expanded(
            child: Container(
              height: 2,
              color: _state.selectedFilePath != null
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          // Step 2
          _stepNode(
            index: 1,
            label: '2. Mot de passe',
            isDone: _currentStep > 1,
            isActive: _currentStep == 1,
          ),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 2
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          // Step 3
          _stepNode(
            index: 2,
            label: '3. Résultat',
            isDone: _state.isSuccess,
            isActive: _currentStep == 2,
          ),
        ],
      ),
    );
  }

  Widget _stepNode({
    required int index,
    required String label,
    required bool isDone,
    required bool isActive,
  }) {
    Color circleColor;
    Widget circleContent;

    if (isDone && !isActive) {
      circleColor = const Color(0xFF16A34A);
      circleContent = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (isActive) {
      circleColor = const Color(0xFF2563EB);
      circleContent = Text(
        '${index + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    } else {
      circleColor = const Color(0xFFE2E8F0);
      circleContent = Text(
        '${index + 1}',
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    return Column(
      children: [
        CircleAvatar(radius: 14, backgroundColor: circleColor, child: circleContent),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
            color: isActive
                ? const Color(0xFF2563EB)
                : isDone
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // --- Étape 0 : Sélection du fichier .enc ---
  Widget _buildFilePickStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.file_upload_outlined,
                    color: Color(0xFF2563EB),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sélectionner un fichier chiffré (.enc)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Touchez pour parcourir vos dossiers et récupérer votre fichier',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open),
          label: const Text('Parcourir les fichiers'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  // --- Étape 1 : Saisie du mot de passe (Conforme au screenshot Figma) ---
  Widget _buildPasswordStep() {
    final fileName = _state.fileName ?? 'fichier.enc';
    final sizeStr = _formatSize(_state.fileSizeBytes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // File Card Preview (comme dans la capture Figma)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AES-GCM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sizeStr • Scellé en local',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Intègre',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section Title: Mot de passe de déchiffrement + "Obligatoire"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Mot de passe de déchiffrement',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Obligatoire',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Input Password Field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Saisissez votre clé secrète',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: const Icon(
                Icons.key_outlined,
                color: Color(0xFF64748B),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        const Text(
          'Saisissez la clé ou phrase secrète utilisée lors du scellement.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        // Checkbox: Afficher le mot de passe
        InkWell(
          onTap: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: !_obscurePassword,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) {
                    setState(() => _obscurePassword = !(val ?? false));
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Afficher le mot de passe',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Protection matérielle active card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Protection matérielle active',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Protection contre les attaques par force brute active (délai d\'itération mémoire PBKDF2/Argon2). Vos clés ne transitent jamais sur le réseau.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Specs: Mémoire allouée & threads
        Row(
          children: const [
            Icon(Icons.memory, size: 16, color: Color(0xFF64748B)),
            SizedBox(width: 6),
            Text(
              'Mémoire allouée: 64 Mo',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            Spacer(),
            Icon(Icons.speed, size: 16, color: Color(0xFF64748B)),
            SizedBox(width: 6),
            Text(
              '4 threads',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Action Button: Déchiffrer le fichier
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _passwordController.text.trim().isEmpty ? null : _decrypt,
            icon: const Icon(Icons.lock_open, size: 20),
            label: const Text(
              'Déchiffrer le fichier',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF93C5FD),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Étape 2 : Résultat & Partage ---
  Widget _buildResultStep() {
    if (_state.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: const [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Color(0xFF2563EB),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Déchiffrement en cours...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Vérification cryptographique du conteneur et du tag MAC...',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    if (_state.isError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline, color: Colors.red.shade600, size: 30),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Échec du déchiffrement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _state.errorMessage ??
                      'Le mot de passe fourni est incorrect ou le conteneur a été altéré.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _currentStep = 1);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer le mot de passe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _reset,
            child: const Text('Choisir un autre fichier'),
          ),
        ],
      );
    }

    // Success State
    final restoredFileName = _state.fileName ?? 'fichier_restaure';
    final outPath = _state.outputPath ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF16A34A),
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Déchiffrement réussi !',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Le fichier d\'origine a été restauré sans aucune perte d\'intégrité.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const Divider(height: 28),
              Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      restoredFileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatSize(_state.fileSizeBytes),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (outPath.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Emplacement : $outPath',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (outPath.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(files: [XFile(outPath)]),
              );
            },
            icon: const Icon(Icons.ios_share),
            label: const Text('Partager le fichier restauré'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.refresh),
          label: const Text('Déchiffrer un autre fichier'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
