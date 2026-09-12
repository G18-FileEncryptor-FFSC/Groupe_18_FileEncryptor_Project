import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../state/encryption_state.dart';
import '../services/encryption_service.dart';

class EncryptionScreen extends StatefulWidget {
  const EncryptionScreen({super.key});

  @override
  State<EncryptionScreen> createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> {
  static const _primaryColor = Color(0xFF6366F1);

  late final EncryptionService _service;
  final _passwordController = TextEditingController();
  EncryptionState _state = const EncryptionState();
  String? _selectedFileName;
  int _selectedFileSize = 0;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _service = EncryptionService();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      setState(() {
        _state = _state.copyWith(
          selectedFilePath: file.path,
          status: EncryptionStatus.idle,
          errorMessage: null,
        );
        _selectedFileName = file.name;
        _selectedFileSize = file.size;
      });
    }
  }

  void _clearFile() {
    if (_state.status == EncryptionStatus.loading) return;
    setState(() {
      _state = const EncryptionState();
      _selectedFileName = null;
      _selectedFileSize = 0;
    });
  }

  Future<void> _startEncryption() async {
    final path = _state.selectedFilePath;
    final pwd = _passwordController.text;

    if (path == null) {
      _showSnack('Veuillez sélectionner un fichier');
      return;
    }
    if (pwd.isEmpty) {
      _showSnack('Veuillez renseigner un mot de passe');
      return;
    }

    setState(() {
      _state = _state.copyWith(status: EncryptionStatus.loading, progress: 0.0);
    });

    try {
      final res = await _service.encrypt(
        filePath: path,
        password: pwd,
        onProgress: (p) =>
            setState(() => _state = _state.copyWith(progress: p)),
      );

      _passwordController.clear();

      if (res.isSuccess) {
        setState(() {
          _state = _state.copyWith(
            status: EncryptionStatus.success,
            outputPath: res.outputPath,
          );
        });
      } else {
        setState(() {
          _state = _state.copyWith(
            status: EncryptionStatus.error,
            errorMessage: res.errorMessage ?? 'Échec du chiffrement',
          );
        });
      }
    } catch (e) {
      _passwordController.clear();
      setState(() {
        _state = _state.copyWith(
          status: EncryptionStatus.error,
          errorMessage: e.toString(),
        );
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _shareFile() async {
    final outputPath = _state.outputPath;
    if (outputPath == null || outputPath.isEmpty) return;
    await Share.shareXFiles([XFile(outputPath)]);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _outputName(String path) => path.split(RegExp(r'[/\\]')).last;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _state.status == EncryptionStatus.loading;
    final hasFile = _state.selectedFilePath != null;
    final canEncrypt =
        hasFile && _passwordController.text.isNotEmpty && !isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text('FileEncryptor',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline, color: _primaryColor),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chiffrer un fichier',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Sécurisé par AES-GCM 256 bits côté client',
                          style:
                              TextStyle(color: Colors.blueGrey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _FileDropzone(
              fileName: _selectedFileName,
              fileSize: _selectedFileSize,
              onTap: isLoading ? null : _pickFile,
              onClear: isLoading ? null : _clearFile,
              formatSize: _formatFileSize,
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Mot de passe de chiffrement',
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: IconButton(
                  tooltip: _isPasswordVisible
                      ? 'Masquer le mot de passe'
                      : 'Afficher le mot de passe',
                  icon: Icon(_isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: _primaryColor, width: 1.5)),
              ),
            ),
            const SizedBox(height: 22),
            if (isLoading) ...[
              LinearProgressIndicator(
                  value: _state.progress,
                  color: _primaryColor,
                  backgroundColor: const Color(0xFFE2E8F0)),
              const SizedBox(height: 8),
              Text('${(_state.progress * 100).toStringAsFixed(0)} %',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.blueGrey)),
              const SizedBox(height: 14),
            ],
            if (_state.status == EncryptionStatus.success) ...[
              _SuccessCard(
                  outputName: _outputName(_state.outputPath ?? 'fichier.enc'),
                  onShare: _shareFile),
              const SizedBox(height: 16),
            ],
            if (_state.status == EncryptionStatus.error) ...[
              _ErrorCard(
                  message: _state.errorMessage ?? 'Échec du chiffrement'),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: canEncrypt ? _startEncryption : null,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_outline),
              label: Text(isLoading
                  ? 'Chiffrement en cours...'
                  : 'Chiffrer le fichier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                disabledForegroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileDropzone extends StatelessWidget {
  final String? fileName;
  final int fileSize;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final String Function(int) formatSize;

  const _FileDropzone(
      {required this.fileName,
      required this.fileSize,
      required this.onTap,
      required this.onClear,
      required this.formatSize});

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;
    return GestureDetector(
      onTap: hasFile ? null : onTap,
      child: CustomPaint(
        painter: hasFile
            ? null
            : _DashedBorderPainter(color: const Color(0xFFCBD5E1)),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: hasFile ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: hasFile ? Border.all(color: const Color(0xFFE2E8F0)) : null,
          ),
          child: hasFile
              ? Row(children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      color: Color(0xFF6366F1), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(fileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(formatSize(fileSize),
                            style: const TextStyle(
                                color: Colors.blueGrey, fontSize: 12)),
                      ])),
                  IconButton(
                      tooltip: 'Retirer le fichier',
                      onPressed: onClear,
                      icon: const Icon(Icons.close)),
                ])
              : const Column(children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: Color(0xFF6366F1), size: 38),
                  SizedBox(height: 10),
                  Text('Sélectionnez un fichier',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Tous formats acceptés',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                ]),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final String outputName;
  final VoidCallback onShare;

  const _SuccessCard({required this.outputName, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(Icons.check_circle, color: Colors.green.shade700, size: 36),
        const SizedBox(height: 8),
        Text('Fichier chiffré avec succès !',
            style: TextStyle(
                color: Colors.green.shade800, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(outputName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.green.shade900, fontSize: 12)),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.ios_share),
                label: const Text('Partager ou exporter le fichier'))),
      ]),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(Icons.error_outline, color: Colors.red.shade700),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade800)))
      ]),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(12)));
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 10) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}