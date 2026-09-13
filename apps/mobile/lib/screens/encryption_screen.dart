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
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (!mounted || result == null || result.files.single.path == null) return;
    final file = result.files.single;
    setState(() {
      _fileName = file.name;
      _fileSize = file.size;
      _state = _state.copyWith(
          selectedFilePath: file.path,
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
    if (path != null && path.isNotEmpty) await Share.shareXFiles([XFile(path)]);
  }

  @override
  void dispose() {
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
                  onContinue: () {
                    if (_password.text.isEmpty) {
                      return _snack('Mot de passe requis');
                    }
                    if (_password.text != _confirmation.text) {
                      return _snack('Les mots de passe ne correspondent pas');
                    }
                    setState(() => _currentStep = 2);
                  },
                )
              else
                _StepSummary(
                  fileName: _fileName ?? 'Fichier sélectionné',
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
          const Text('Sécurisé par AES-GCM 256 bits côté client',
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
  final String fileSize;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final VoidCallback? onContinue;
  const _StepFileSelection(
      {required this.fileName,
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
          ? _FileCard(name: fileName!, size: fileSize, onClear: onClear)
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
  final VoidCallback onClear;
  const _FileCard(
      {required this.name, required this.size, required this.onClear});
  @override
  Widget build(BuildContext context) => Container(
      clipBehavior: Clip.antiAlias,
      decoration: _card(),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Row(children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red, size: 38),
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
                  child: Text('Prêt pour le chiffrement AES-256',
                      style: TextStyle(fontSize: 12))),
              Text('SHA256: 8f3c..b1',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 11))
            ]))
      ]));
}

class _StepSecurity extends StatelessWidget {
  final TextEditingController password, confirmation;
  final bool visible, deleteOriginal;
  final VoidCallback onVisibility, onBack, onContinue;
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
          _Pill('Clé locale AES', Color(0xFF188038))
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
        const _Strength(),
        const SizedBox(height: 18),
        const Text('Confirmer le mot de passe',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _Input(confirmation, 'Répétez le mot de passe', Icons.lock_outline,
            visible, const Icon(Icons.check_circle, color: Color(0xFF188038))),
        const SizedBox(height: 24),
        const Text('Options avancées',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _Option(
            Icons.delete_sweep_outlined,
            'Supprimer le fichier original',
            Switch(
                value: deleteOriginal,
                activeColor: const Color(0xFF188038),
                onChanged: onDelete)),
        const SizedBox(height: 8),
        const _Option(Icons.tune, 'Algorithme de chiffrement',
            _Pill('AES-256-GCM', Color(0xFF0B57D0))),
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
  final String? error, output;
  final VoidCallback onBack, onEncrypt, onShare;
  const _StepSummary(
      {required this.fileName,
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
              _Row(
                  Icons.insert_drive_file_outlined, 'Fichier source', fileName),
              _Row(Icons.data_usage_outlined, 'Taille originale', size),
              const _Row(Icons.security, 'Algorithme', 'AES-256-GCM',
                  color: Color(0xFF0B57D0)),
              _Row(Icons.lock_outline, 'Sortie générée', '$fileName.enc',
                  color: Color(0xFF0B57D0)),
              _Row(Icons.add_chart, 'Taille estimée', '$size + 16B MAC'),
              const _Row(
                  Icons.verified_user_outlined, 'Protection', 'Argon2id + AES')
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
        Expanded(child: _Badge('Vérification SHA-256 HMAC')),
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
  const _Strength();

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          ...List.generate(
              4,
              (_) => Expanded(
                    child: Container(
                        height: 5,
                        margin: const EdgeInsets.only(right: 4),
                        color: const Color(0xFF188038)),
                  )),
          const Text('FORTE',
              style: TextStyle(
                  color: Color(0xFF188038), fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Votre clé reste locale et ne quitte jamais l’appareil.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12))),
      ]);
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
