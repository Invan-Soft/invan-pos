// DEBUG-ONLY: yangi versiya (.exe) ni backend /upload/build ga yuklash uchun test tugmasi.
// Bu fayl vaqtinchalik — testdan keyin o'chiriladi. Faqat kDebugMode'da chaqiriladi.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class UploadBuildDialog extends StatefulWidget {
  const UploadBuildDialog({super.key});

  @override
  State<UploadBuildDialog> createState() => _UploadBuildDialogState();
}

class _UploadBuildDialogState extends State<UploadBuildDialog> {
  final _versionCtrl = TextEditingController();
  final _changelogCtrl = TextEditingController();

  String? _filePath;
  String? _fileName;
  String _fileSizeLabel = '';

  bool _busy = false;
  bool _ok = false;
  String _status = '';

  // Yuklashni bekor qilish uchun (client.close() in-flight so'rovni uzadi)
  http.Client? _client;
  bool _canceled = false;

  // Oxirgi yuklangan versiya (GET {baseUrl}file)
  bool _loadingLast = true;
  String _lastVersion = '';
  String _lastChangelog = '';

  static const _accent = Color(0xff2B5278);
  static const _green = Color(0xff2E7D32);
  static const _red = Color(0xffE53935);

  String get _uploadUrl => '${ApiProvider.baseUrlINVAN2}upload/build';
  String get _fileUrl => '${ApiProvider.baseUrlINVAN2}file';
  bool get _isProd => ApiProvider.baseUrlINVAN2 == ApiProvider.INVAN2PRO;

  @override
  void initState() {
    super.initState();
    _fetchLast();
  }

  @override
  void dispose() {
    _versionCtrl.dispose();
    _changelogCtrl.dispose();
    _client?.close();
    super.dispose();
  }

  Future<void> _fetchLast() async {
    setState(() => _loadingLast = true);
    try {
      final res =
          await http.get(Uri.parse(_fileUrl)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _lastVersion = (data['version'] ?? '').toString();
            _lastChangelog = (data['change_log'] ?? '').toString();
          });
        }
      }
    } catch (_) {
      // jim
    } finally {
      if (mounted) setState(() => _loadingLast = false);
    }
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
    );
    if (res != null && res.files.single.path != null) {
      final size = await File(res.files.single.path!).length();
      setState(() {
        _filePath = res.files.single.path;
        _fileName = res.files.single.name;
        _fileSizeLabel = '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
      });
    }
  }

  Future<void> _upload() async {
    if (_filePath == null) {
      setState(() => _status = '.exe fayl tanlang');
      return;
    }
    if (_versionCtrl.text.trim().isEmpty) {
      setState(() => _status = 'Versiya kiriting (masalan 1.1.2+106)');
      return;
    }
    if (_changelogCtrl.text.trim().isEmpty) {
      setState(() => _status = 'Changelog kiriting (majburiy)');
      return;
    }

    final sw = Stopwatch()..start();
    _canceled = false;
    _client = http.Client();
    setState(() {
      _busy = true;
      _ok = false;
      _status = 'Yuklanmoqda... ($_fileSizeLabel)';
    });
    try {
      final req = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      final token = Pref.getString(PrefKeys.token, '');
      if (token.isNotEmpty) req.headers['Authorization'] = 'Bearer $token';
      req.fields['version'] = _versionCtrl.text.trim();
      req.fields['changelog'] = _changelogCtrl.text.trim();
      req.files.add(await http.MultipartFile.fromPath('file', _filePath!));

      debugPrint('⬆️ UPLOAD START → $_uploadUrl (${_versionCtrl.text.trim()})');
      final streamed =
          await _client!.send(req).timeout(const Duration(minutes: 10));
      final body = await streamed.stream.bytesToString();
      debugPrint('   javob: ${streamed.statusCode} (${sw.elapsed.inSeconds}s) $body');
      final ok = streamed.statusCode >= 200 && streamed.statusCode < 300;
      setState(() {
        _ok = ok;
        _status = ok
            ? '✅ Yuklandi (${sw.elapsed.inSeconds}s)'
            : '❌ ${streamed.statusCode}: $body';
      });
      if (ok) _fetchLast(); // oxirgi versiyani yangilaymiz
    } on TimeoutException {
      setState(() {
        _ok = false;
        _status = 'Timeout (10 daqiqa)';
      });
    } catch (e) {
      setState(() {
        _ok = false;
        _status = _canceled ? '⛔ Bekor qilindi' : 'Xato: $e';
      });
    } finally {
      sw.stop();
      _client?.close();
      _client = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  void _cancelUpload() {
    _canceled = true;
    _client?.close(); // in-flight so'rovni uzadi
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xff1B2530),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 16),
              _lastVersionCard(),
              const SizedBox(height: 16),
              _filePicker(),
              const SizedBox(height: 14),
              _field(_versionCtrl, 'Versiya', '1.1.2+106'),
              const SizedBox(height: 12),
              _field(_changelogCtrl, 'O‘zgarishlar (changelog)', null, maxLines: 2),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 14),
                _statusBar(),
              ],
              const SizedBox(height: 20),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Versiya yuklash',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (_isProd ? _red : _green).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_isProd ? 'PROD' : 'DEV',
              style: TextStyle(
                  color: _isProd ? _red : _green,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _lastVersionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: _loadingLast
                ? const Text('Oxirgi versiya yuklanmoqda...',
                    style: TextStyle(color: Colors.white54, fontSize: 13))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastVersion.isEmpty
                            ? 'Oxirgi versiya: —'
                            : 'Oxirgi yuklangan: $_lastVersion',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      if (_lastChangelog.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(_lastChangelog,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ),
                    ],
                  ),
          ),
          IconButton(
            tooltip: 'Yangilash',
            onPressed: _loadingLast ? null : _fetchLast,
            icon: const Icon(Icons.refresh, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _filePicker() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _busy ? null : _pickFile,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.attach_file, size: 18),
          label: const Text('.exe tanlash'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _fileName == null
                ? 'Fayl tanlanmagan'
                : '$_fileName  ·  $_fileSizeLabel',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: _fileName == null ? Colors.white38 : Colors.white,
                fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, String? hint,
      {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      enabled: !_busy,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24),
        isDense: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accent),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
    );
  }

  Widget _statusBar() {
    final bool err = !_ok && !_busy;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (_busy
                ? _accent
                : _ok
                    ? _green
                    : _red)
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (_busy)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
          if (_busy) const SizedBox(width: 10),
          Expanded(
            child: Text(_status,
                style: TextStyle(
                    color: _busy
                        ? Colors.white
                        : _ok
                            ? _green
                            : (err ? _red : Colors.white),
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    if (_busy) {
      // Yuklash jarayonida — faqat Bekor qilish
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: _cancelUpload,
            style: OutlinedButton.styleFrom(
              foregroundColor: _red,
              side: const BorderSide(color: _red),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Bekor qilish'),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Yopish', style: TextStyle(color: Colors.white70)),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _upload,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.cloud_upload, size: 18),
          label: const Text('Yuklash'),
        ),
      ],
    );
  }
}
