import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/encryption_service.dart';
import '../state/encryption_state.dart';

class EncryptionScreen extends StatefulWidget {
  const EncryptionScreen({super.key});

  @override
  State<EncryptionScreen> createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> {
  late final EncryptionService _service;
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  EncryptionState _state = const EncryptionState();
  String? _fileName;
  int _fileSize = 0;
  int _currentStep = 0;
  bool _visible = false;
  bool _deleteOriginal = false;
  int _operationId = 0;

  @override
  void initState() {
    super.initState();
    _service = EncryptionService();
    _password.addListener(_onPasswordChanged);
    _confirmation.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() => setState(() {});

  bool _isPasswordValid(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'\d').hasMatch(password)) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'''[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`';]''').hasMatch(password) &&
        !RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) {
      return false;
    }
    return true;
  }

  Future<void> _pickFile() async {
    final result = await FilePickerPlatform.instance.pickFiles();
    if (!mounted || result.isEmpty) return;
    final file = result.first;
    final path = file.path;
    if (path == null) return;
    final size = await File(path).length();
    setState(() {
      _fileName = file.name;
      _fileSize = size;
      _state = _state.copyWith(
          selectedFilePath: path,
          status: EncryptionStatus.idle,
          errorMessage: null);
    });
  }

  void _clearFile() => setState(() {
        _fileName = null;
        _fileSize = 0;
        _currentStep = 0;
        _state = const EncryptionState();
      });

  Future<void> _startEncryption() async {
    final path = _state.selectedFilePath;
    if (path == null) {
      return _snack('Veuillez sélectionner un fichier');
    }
    if (_password.text.isEmpty) {
      setState(() => _currentStep = 1);
      return _snack('Veuillez renseigner un mot de passe');
    }
    final operation = ++_operationId;
    setState(() => _state =
        _state.copyWith(status: EncryptionStatus.loading, progress: 0));
    try {
      final result = await _service.encrypt(
        filePath: path,
        password: _password.text,
        onProgress: (value) {
          if (mounted && operation == _operationId) {
            setState(() => _state = _state.copyWith(progress: value));
          }
        },
      );
      if (!mounted || operation != _operationId) return;
      _password.clear();
      _confirmation.clear();
      setState(() => _state = _state.copyWith(
          status: result.isSuccess
              ? EncryptionStatus.success
              : EncryptionStatus.error,
          outputPath: result.outputPath,
          errorMessage: result.errorMessage ?? 'Échec du chiffrement'));
    } catch (error) {
      if (!mounted || operation != _operationId) return;
      setState(() => _state = _state.copyWith(
          status: EncryptionStatus.error, errorMessage: error.toString()));
    }
  }

  void _cancel() {
    _operationId++;
    setState(() =>
        _state = _state.copyWith(status: EncryptionStatus.idle, progress: 0));
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  String _size(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
          ? '${(bytes / 1024).toStringAsFixed(1)} KB'
          : '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';

  String _basename(String path) => path.split(RegExp(r'[/\\]')).last;

  Future<void> _share() async {
    final path = _state.outputPath;
    if (path != null && path.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    }
  }

  @override
  void dispose() {
    _password.removeListener(_onPasswordChanged);
    _confirmation.removeListener(_onPasswordChanged);
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = _state.status == EncryptionStatus.loading;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          centerTitle: true,
          title: const Text('FileEncryptor',
              style: TextStyle(fontWeight: FontWeight.w700))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            _Heading(loading ? 'Chiffrement en cours' : 'Chiffrer un fichier'),
            const SizedBox(height: 24),
            if (loading)
              _ProcessingView(
                  fileName: _fileName ?? 'votre fichier',
                  progress: _state.progress,
                  onCancel: _cancel)
            else ...[
              _Stepper(step: _currentStep),
              const SizedBox(height: 24),
              if (_currentStep == 0)
                _StepFileSelection(
                  fileName: _fileName,
                  filePath: _state.selectedFilePath,
                  fileSize: _size(_fileSize),
                  onPick: _pickFile,
                  onClear: _clearFile,
                  onContinue: _state.selectedFilePath == null
                      ? null
                      : () => setState(() => _currentStep = 1),
                )
              else if (_currentStep == 1)
                _StepSecurity(
                  password: _password,
                  confirmation: _confirmation,
                  visible: _visible,
                  onVisibility: () => setState(() => _visible = !_visible),
                  deleteOriginal: _deleteOriginal,
                  onDelete: (value) => setState(() => _deleteOriginal = value),
                  onBack: () => setState(() => _currentStep = 0),
                  onContinue: _isPasswordValid(_password.text) &&
                          _confirmation.text == _password.text &&
                          _confirmation.text.isNotEmpty
                      ? () {
                          if (_password.text.isEmpty) {
                            return _snack('Mot de passe requis');
                          }
                          if (!_isPasswordValid(_password.text)) {
                            return _snack(
                                'Le mot de passe ne respecte pas tous les critères');
                          }
                          if (_password.text != _confirmation.text) {
                            return _snack(
                                'Les mots de passe ne correspondent pas');
                          }
                          setState(() => _currentStep = 2);
                        }
                      : null,
                )
              else
                _StepSummary(
                  fileName: _fileName ?? 'Fichier sélectionné',
                  filePath: _state.selectedFilePath,
                  size: _size(_fileSize),
                  error: _state.status == EncryptionStatus.error
                      ? _state.errorMessage
                      : null,
                  output: _state.status == EncryptionStatus.success
                      ? _basename(_state.outputPath ?? 'fichier.enc')
                      : null,
                  onBack: () => setState(() => _currentStep = 1),
                  onEncrypt: _startEncryption,
                  onShare: _share,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String title;
  const _Heading(this.title);
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF0B57D0).withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.lock_outline, color: Color(0xFF0B57D0))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
            const Text('Protection renforcée, directement sur votre appareil',
              style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
        ])),
      ]);
}

class _Stepper extends StatelessWidget {
  final int step;
  const _Stepper({required this.step});
  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(5, (index) {
          if (index.isOdd) {
            return Expanded(
                child: Container(
                    height: 2,
                    color: index ~/ 2 < step
                        ? const Color(0xFF0B57D0)
                        : Colors.grey.shade300));
          }
          final number = index ~/ 2;
          final done = number < step;
          final active = number == step;
          return Column(children: [
            CircleAvatar(
                radius: 16,
                backgroundColor: done || active
                    ? const Color(0xFF0B57D0)
                    : Colors.grey.shade300,
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text('${number + 1}',
                        style: TextStyle(
                            color: active ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold))),
            const SizedBox(height: 6),
            Text(['Fichier', 'Sécurité', 'Résumé'][number],
                style: TextStyle(
                    fontSize: 12,
                    color:
                        active ? const Color(0xFF0B57D0) : Colors.grey.shade600,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ]);
        }),
      );
}

class _StepFileSelection extends StatelessWidget {
  final String? fileName;
  final String? filePath;
  final String fileSize;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final VoidCallback? onContinue;
  const _StepFileSelection(
      {required this.fileName,
      required this.filePath,
      required this.fileSize,
      required this.onPick,
      required this.onClear,
      required this.onContinue});
  @override
  Widget build(BuildContext context) {
    final selected = fileName != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(selected ? 'Fichier sélectionné' : 'Choisir un fichier',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      selected
            ? _FileCard(
              name: fileName!, path: filePath, size: fileSize, onClear: onClear)
          : _DashedCard(
              onTap: onPick,
              child: const Column(children: [
                Icon(Icons.insert_drive_file_outlined,
                    size: 44, color: Color(0xFF0B57D0)),
                SizedBox(height: 12),
                Text('Choisir un fichier',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                _Pill('Zero upload cloud · 100% sur l\'appareil',
                    Color(0xFF0B57D0)),
              ])),
      const SizedBox(height: 24),
      SizedBox(
          height: 52,
          child: ElevatedButton(
              onPressed: onContinue,
              style: _button(),
              child: const Text('Continuer →'))),
    ]);
  }
}

class _FileCard extends StatelessWidget {
  final String name, size;
  final String? path;
  final VoidCallback onClear;
  const _FileCard(
      {required this.name,
      required this.path,
      required this.size,
      required this.onClear});
  @override
  Widget build(BuildContext context) => Container(
      clipBehavior: Clip.antiAlias,
      decoration: _card(),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Row(children: [
              _FilePreview(path: path, name: name),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(size,
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 13))
                  ])),
              const _Pill('Valide', Color(0xFF188038)),
              IconButton(
                  onPressed: onClear, icon: const Icon(Icons.delete_outline)),
            ])),
        Container(
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.all(12),
            child: const Row(children: [
              Icon(Icons.verified_user_outlined,
                  color: Color(0xFF188038), size: 18),
              SizedBox(width: 8),
                Expanded(
                  child: Text('Prêt pour le chiffrement sécurisé',
                      style: TextStyle(fontSize: 12))),
            ]))
      ]));
}

class _FilePreview extends StatelessWidget {
  final String? path;
  final String name;
  const _FilePreview({required this.path, required this.name});

  @override
  Widget build(BuildContext context) {
    final extension = name.split('.').last.toLowerCase();
    final isImage = {'png', 'jpg', 'jpeg', 'webp'}.contains(extension);
    if (isImage && path != null && File(path!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(path!),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 38)),
      );
    }
    final icon = extension == 'pdf'
        ? Icons.picture_as_pdf
        : {'zip', 'rar', 'tar', '7z'}.contains(extension)
            ? Icons.folder_zip
            : {'mp4', 'mkv', 'mov'}.contains(extension)
                ? Icons.video_file
                : {'mp3', 'wav'}.contains(extension)
                    ? Icons.audio_file
                    : {'txt', 'doc', 'docx'}.contains(extension)
                        ? Icons.description
                        : isImage
                            ? Icons.image
                            : Icons.insert_drive_file;
    return Icon(icon,
        color: extension == 'pdf' ? Colors.red : const Color(0xFF0B57D0),
        size: 38);
  }
}

class _FileSummary extends StatelessWidget {
  final String? path;
  final String name;
  const _FileSummary({required this.path, required this.name});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          _FilePreview(path: path, name: name),
          const SizedBox(width: 10),
          const Text('Fichier source',
              style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
          const Spacer(),
          Flexible(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
      );
}

class _StepSecurity extends StatelessWidget {
  final TextEditingController password, confirmation;
  final bool visible, deleteOriginal;
  final VoidCallback onVisibility, onBack;
  final VoidCallback? onContinue;
  final ValueChanged<bool> onDelete;
  const _StepSecurity(
      {required this.password,
      required this.confirmation,
      required this.visible,
      required this.onVisibility,
      required this.deleteOriginal,
      required this.onDelete,
      required this.onBack,
      required this.onContinue});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: const [
          Text('Mot de passe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Spacer(),
          _Pill('Protection locale', Color(0xFF188038))
        ]),
        const SizedBox(height: 12),
        _Input(
            password,
            'Saisissez un mot de passe fort',
            Icons.key_outlined,
            visible,
            IconButton(
                onPressed: onVisibility,
                icon: Icon(visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined))),
        const SizedBox(height: 10),
        _Strength(password.text),
        const SizedBox(height: 14),
        _PasswordCriteriaList(password: password.text),
        const SizedBox(height: 18),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: confirmation.text.isNotEmpty &&
                confirmation.text != password.text
              ? Colors.red.shade700
              : null),
          child: const Text('Confirmer le mot de passe')),
        const SizedBox(height: 8),
        _Input(
          confirmation,
          'Répétez le mot de passe',
          Icons.lock_outline,
          visible,
          confirmation.text.isNotEmpty && confirmation.text != password.text
            ? const Icon(Icons.error_outline, color: Colors.red)
            : confirmation.text == password.text && confirmation.text.isNotEmpty
              ? const Icon(Icons.check_circle, color: Color(0xFF188038))
              : const SizedBox.shrink()),
        const SizedBox(height: 24),
        const Text('Options avancées',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _Option(
            Icons.delete_sweep_outlined,
            'Supprimer le fichier original',
            Switch(
                value: deleteOriginal,
                activeThumbColor: const Color(0xFF188038),
                onChanged: onDelete)),
        const SizedBox(height: 8),
        const _Option(Icons.tune, 'Niveau de protection',
          _Pill('Scellement sécurisé', Color(0xFF0B57D0))),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
              child: OutlinedButton(
                  onPressed: onBack, child: const Text('Retour'))),
          const SizedBox(width: 12),
          Expanded(
              flex: 2,
              child: ElevatedButton(
                  onPressed: onContinue,
                  style: _button(),
                  child: const Text('Continuer →')))
        ])
      ]);
}

class _StepSummary extends StatelessWidget {
  final String fileName, size;
  final String? filePath;
  final String? error, output;
  final VoidCallback onBack, onEncrypt, onShare;
  const _StepSummary(
      {required this.fileName,
      required this.filePath,
      required this.size,
      required this.error,
      required this.output,
      required this.onBack,
      required this.onEncrypt,
      required this.onShare});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(16)),
            child: const Row(children: [
              Icon(Icons.lock_clock, color: Color(0xFF0B57D0)),
              SizedBox(width: 12),
              Text('Prêt pour le scellement',
                  style: TextStyle(
                      color: Color(0xFF0B57D0), fontWeight: FontWeight.bold))
            ])),
        const SizedBox(height: 16),
        Container(
            decoration: _card(),
            child: Column(children: [
                _FileSummary(path: filePath, name: fileName),
              _Row(Icons.data_usage_outlined, 'Taille originale', size),
                const _Row(Icons.security, 'Protection', 'Scellement sécurisé',
                  color: Color(0xFF0B57D0)),
              _Row(Icons.lock_outline, 'Sortie générée', '$fileName.enc',
                  color: Color(0xFF0B57D0)),
                _Row(Icons.add_chart, 'Taille estimée', size),
                const _Row(Icons.verified_user_outlined, 'Coffre',
                  'Protection renforcée')
            ])),
        if (error != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _Message(error!, true)),
        if (output != null) ...[
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _Message('Fichier chiffré : $output', false)),
          OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.ios_share),
              label: const Text('Partager le fichier'))
        ],
        const SizedBox(height: 24),
        SizedBox(
            height: 52,
            child: ElevatedButton.icon(
                onPressed: output == null ? onEncrypt : null,
                icon: const Icon(Icons.lock),
                label: const Text('Chiffrer maintenant'),
                style: _button(color: const Color(0xFF188038)))),
        TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Modifier la sécurité'))
      ]);
}

class _ProcessingView extends StatelessWidget {
  final String fileName;
  final double progress;
  final VoidCallback onCancel;
  const _ProcessingView(
      {required this.fileName, required this.progress, required this.onCancel});
  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).toInt();
    return Column(children: [
      SizedBox(
          width: 190,
          height: 190,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
                width: 172,
                height: 172,
                child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    color: const Color(0xFF0B57D0),
                    backgroundColor: const Color(0xFFDCE6F8))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock, color: Color(0xFF0B57D0), size: 28),
              Text('$percent%',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold))
            ])
          ])),
      const SizedBox(height: 18),
      Text('Chiffrement de $fileName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Veuillez patienter...',
          style: TextStyle(color: Colors.blueGrey)),
      const SizedBox(height: 24),
      LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          color: const Color(0xFF0B57D0),
          backgroundColor: const Color(0xFFDCE6F8)),
      const SizedBox(height: 8),
      const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('18.2 MB/s'), Text('≈ 00:04')]),
      const SizedBox(height: 18),
      const Row(children: [
        Expanded(child: _Badge('Protection vérifiée')),
        SizedBox(width: 8),
        Expanded(child: _Badge('Zéro Fuite Réseau'))
      ]),
      const SizedBox(height: 24),
      OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.close),
          label: const Text('Annuler l’opération'))
    ]);
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget suffix;
  const _Input(
      this.controller, this.hint, this.icon, this.obscure, this.suffix);
  @override
  Widget build(BuildContext context) => TextField(
      controller: controller,
      obscureText: !obscure,
      decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200))));
}

class _Strength extends StatelessWidget {
  final String password;
  const _Strength(this.password);

  int get score {
    var result = 0;
    if (password.length >= 8) {
      result++;
    }
    if (RegExp(r'\d').hasMatch(password)) {
      result++;
    }
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      result++;
    }
    if (RegExp(r'[a-z]').hasMatch(password)) {
      result++;
    }
    if (RegExp(r'''[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`';]''').hasMatch(password) ||
        RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) {
      result++;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final displayedScore = password.isEmpty ? 0 : score;
    final color = displayedScore <= 1
        ? Colors.red.shade700
        : displayedScore == 2
            ? Colors.orange.shade700
            : displayedScore == 3
                ? const Color(0xFFD97706)
                : displayedScore == 4
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF16A34A);
    final label = password.isEmpty
        ? 'REQUIS'
        : displayedScore <= 1
            ? 'TRÈS FAIBLE'
            : displayedScore == 2
                ? 'FAIBLE'
                : displayedScore == 3
                    ? 'MOYEN'
                    : displayedScore == 4
                        ? 'BON'
                        : 'PARFAIT';
    return Column(children: [
        Row(children: [
          ...List.generate(
              5,
              (index) => Expanded(
                    child: Container(
                        height: 5,
                        margin: const EdgeInsets.only(right: 4),
                        color: index < displayedScore
                          ? color
                          : Colors.grey.shade300),
                  )),
                  Text(label,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Votre clé reste locale et ne quitte jamais l’appareil.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12))),
        ]);
      }
}

class _PasswordCriteriaList extends StatelessWidget {
  final String password;
  const _PasswordCriteriaList({required this.password});

  bool get hasMinLength => password.length >= 8;
  bool get hasDigit => RegExp(r'\d').hasMatch(password);
  bool get hasUppercase => RegExp(r'[A-Z]').hasMatch(password);
  bool get hasLowercase => RegExp(r'[a-z]').hasMatch(password);
  bool get hasSpecialChar =>
      RegExp(r'''[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`';]''').hasMatch(password) ||
      RegExp(r'[^a-zA-Z0-9]').hasMatch(password);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.security_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              SizedBox(width: 6),
              Text(
                'Critères requis pour le mot de passe :',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PasswordCriterionItem(
            label: 'Minimum 8 caractères',
            isValid: hasMinLength,
          ),
          const SizedBox(height: 6),
          _PasswordCriterionItem(
            label: 'Au moins 1 Chiffre',
            isValid: hasDigit,
          ),
          const SizedBox(height: 6),
          _PasswordCriterionItem(
            label: 'Au moins 1 Majuscule',
            isValid: hasUppercase,
          ),
          const SizedBox(height: 6),
          _PasswordCriterionItem(
            label: 'Au moins 1 Minuscule',
            isValid: hasLowercase,
          ),
          const SizedBox(height: 6),
          _PasswordCriterionItem(
            label: 'Au moins 1 Caractère spécial',
            isValid: hasSpecialChar,
          ),
        ],
      ),
    );
  }
}

class _PasswordCriterionItem extends StatelessWidget {
  final String label;
  final bool isValid;

  const _PasswordCriterionItem({
    required this.label,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF16A34A);
    const inactiveColor = Color(0xFF94A3B8);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isValid
                ? activeColor.withValues(alpha: 0.15)
                : Colors.white,
            border: Border.all(
              color: isValid ? activeColor : inactiveColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Icon(
            isValid ? Icons.check : Icons.circle,
            size: isValid ? 12 : 5,
            color: isValid ? activeColor : inactiveColor.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Roboto',
            fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
            color: isValid ? const Color(0xFF15803D) : const Color(0xFF64748B),
          ),
          child: Text(label),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  const _Option(this.icon, this.title, this.trailing);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: _card(),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF188038)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600))),
        trailing
      ]));
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? color;
  const _Row(this.icon, this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF188038), size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 13))),
        Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)))
      ]));
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(10),
      decoration: _card(),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)));
}

class _Message extends StatelessWidget {
  final String text;
  final bool error;
  const _Message(this.text, this.error);
  @override
  Widget build(BuildContext context) {
    final color = error ? Colors.red.shade700 : const Color(0xFF188038);
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(error ? Icons.error_outline : Icons.check_circle, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color)))
        ]));
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)));
}

class _DashedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _DashedCard({required this.child, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: CustomPaint(
          painter: const _Painter(),
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: child)));
}

class _Painter extends CustomPainter {
  const _Painter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(16)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Painter oldDelegate) => false;
}

BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Colors.grey.shade200),
    borderRadius: BorderRadius.circular(16));
ButtonStyle _button({Color color = const Color(0xFF0B57D0)}) =>
    ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
