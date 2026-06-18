// DEBUG-ONLY: yangi versiya (.exe) ni backend /upload/build ga yuklash uchun test tugmasi.
// Bu fayl vaqtinchalik — testdan keyin o'chiriladi. Faqat kDebugMode'da chaqiriladi.
import 'dart:async';
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
  bool _busy = false;
  String _status = '';
  bool _ok = false;

  @override
  void dispose() {
    _versionCtrl.dispose();
    _changelogCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
    );
    if (res != null && res.files.single.path != null) {
      setState(() {
        _filePath = res.files.single.path;
        _fileName = res.files.single.name;
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
      // backend changelog'ni majburiy talab qiladi (400: "changelog is required")
      setState(() => _status = 'Changelog kiriting (majburiy)');
      return;
    }
    final sw = Stopwatch()..start();
    setState(() {
      _busy = true;
      _ok = false;
      _status = 'Yuklanmoqda...';
    });
    try {
      final uri = Uri.parse('${ApiProvider.baseUrlINVAN2}upload/build');
      final fileSize = await File(_filePath!).length();
      final mb = (fileSize / 1024 / 1024).toStringAsFixed(1);
      debugPrint('⬆️ UPLOAD START → $uri');
      debugPrint('   version = ${_versionCtrl.text.trim()}');
      debugPrint('   changelog = ${_changelogCtrl.text.trim()}');
      debugPrint('   file = $_fileName ($mb MB)');
      setState(() => _status = 'Yuklanmoqda... ($mb MB)');

      final req = http.MultipartRequest('POST', uri);
      // Endpoint ochiq (auth talab qilmaydi), lekin token bo'lsa zararsiz yuboramiz
      final token = Pref.getString(PrefKeys.token, '');
      if (token.isNotEmpty) req.headers['Authorization'] = 'Bearer $token';
      req.fields['version'] = _versionCtrl.text.trim();
      req.fields['changelog'] = _changelogCtrl.text.trim();
      req.files.add(await http.MultipartFile.fromPath('file', _filePath!));

      debugPrint('   so\'rov yuborilmoqda...');
      final streamed = await req.send().timeout(const Duration(minutes: 10));
      debugPrint('   javob keldi: ${streamed.statusCode} (${sw.elapsed.inSeconds}s)');
      final body = await streamed.stream.bytesToString();
      debugPrint('   body: $body');
      setState(() {
        _ok = streamed.statusCode >= 200 && streamed.statusCode < 300;
        _status = '${streamed.statusCode} (${sw.elapsed.inSeconds}s): $body';
      });
    } on TimeoutException {
      debugPrint('❌ UPLOAD TIMEOUT (10 daqiqa)');
      setState(() {
        _ok = false;
        _status = 'Timeout (10 daqiqa) — server javob bermadi';
      });
    } catch (e) {
      debugPrint('❌ UPLOAD ERROR: $e');
      setState(() {
        _ok = false;
        _status = 'Xato: $e';
      });
    } finally {
      sw.stop();
      debugPrint('⏱️ jami: ${sw.elapsed.inSeconds}s');
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Versiya yuklash (DEBUG)'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Endpoint: ${ApiProvider.baseUrlINVAN2}upload/build',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('.exe tanlash'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_fileName ?? 'Fayl tanlanmagan',
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _versionCtrl,
              decoration: const InputDecoration(
                labelText: 'version',
                hintText: '1.1.2+106',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _changelogCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'changelog',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_status.isNotEmpty)
              Text(_status,
                  style: TextStyle(
                      color: _ok ? Colors.green : Colors.red, fontSize: 12)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Yopish'),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _upload,
          child: _busy
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Yuklash'),
        ),
      ],
    );
  }
}
