// Added by AIy: update support. It looks at this app's GitHub releases, shows a small banner when a newer version is
// there, downloads it (an interrupted download continues where it stopped) and opens the Android installer.
// To take it out: delete this file and aiy_update_config.dart, and remove the AiyUpdateHost(...) wrapper in main.dart.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'aiy_update_config.dart';

class AiyUpdateHost extends StatefulWidget {
  final Widget child;
  const AiyUpdateHost({super.key, required this.child});

  @override
  State<AiyUpdateHost> createState() => _AiyUpdateHostState();
}

enum _Step { none, available, downloading, paused, ready }

class _AiyUpdateHostState extends State<AiyUpdateHost> {
  _Step _step = _Step.none;
  String _version = '';
  String _notes = '';
  String _apkUrl = '';
  String _sha = '';
  int _size = 0;
  int _got = 0;
  String _msg = '';
  bool _hidden = false;
  bool _stop = false;
  HttpClient? _client;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 4), _check);
  }

  @override
  void dispose() {
    _stop = true;
    _client?.close(force: true);
    super.dispose();
  }

  Future<Directory> _dir() async {
    final d = Directory('${(await getApplicationDocumentsDirectory()).path}/aiy_update');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  Future<void> _check() async {
    if (kAiyUpdateRepo.isEmpty || !Platform.isAndroid) return;
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final have = int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
      final res = await (await c.getUrl(Uri.parse('https://github.com/$kAiyUpdateRepo/releases/latest/download/version.json'))).close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;
      final j = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
      if (((j['build'] as num?)?.toInt() ?? 0) <= have) return;
      _version = '${j['versionName'] ?? ''}';
      _notes = '${j['notes'] ?? ''}';
      _apkUrl = '${j['apk'] ?? ''}';
      _sha = '${j['sha256'] ?? ''}'.toLowerCase();
      _size = (j['size'] as num?)?.toInt() ?? 0;
      if (!_apkUrl.startsWith('https://') || !mounted) return;
      final part = File('${(await _dir()).path}/app.apk.part');
      setState(() => _step = _Step.available);
      // A download that was interrupted earlier continues by itself.
      if (part.existsSync() && part.lengthSync() > 0) unawaited(_download());
    } catch (_) {
      // No internet or no release yet: nothing to show.
    } finally {
      c.close(force: true);
    }
  }

  Future<bool> _verified(File f) async {
    if (_size > 0 && f.lengthSync() != _size) return false;
    if (_sha.isEmpty) return true;
    return (await sha256.bind(f.openRead()).first).toString() == _sha;
  }

  Future<void> _download() async {
    _stop = false;
    setState(() {
      _step = _Step.downloading;
      _msg = '';
    });
    try {
      final dir = await _dir();
      final part = File('${dir.path}/app.apk.part');
      final done = File('${dir.path}/app.apk');
      if (done.existsSync()) {
        if (await _verified(done)) {
          if (mounted) setState(() => _step = _Step.ready);
          return;
        }
        done.deleteSync();
      }
      var have = part.existsSync() ? part.lengthSync() : 0;
      if (_size > 0 && have > _size) {
        part.deleteSync();
        have = 0;
      }
      final c = _client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final req = await c.getUrl(Uri.parse(_apkUrl));
      if (have > 0) req.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
      final res = await req.close();
      if (res.statusCode == 200) {
        have = 0;
      } else if (res.statusCode != 206) {
        throw 'HTTP ${res.statusCode}';
      }
      final sink = part.openWrite(mode: have > 0 ? FileMode.append : FileMode.write);
      _got = have;
      var last = DateTime.now();
      try {
        await for (final chunk in res.timeout(const Duration(seconds: 30))) {
          if (_stop) break;
          sink.add(chunk);
          _got += chunk.length;
          if (mounted && DateTime.now().difference(last).inMilliseconds > 250) {
            last = DateTime.now();
            setState(() {});
          }
        }
      } finally {
        await sink.close();
      }
      if (_stop) {
        if (mounted) setState(() => _step = _Step.paused);
        return;
      }
      part.renameSync(done.path);
      if (!await _verified(done)) {
        done.deleteSync();
        throw 'The downloaded file is damaged';
      }
      if (mounted) setState(() => _step = _Step.ready);
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _Step.paused;
          _msg = 'The download stopped. Tap Resume to continue where it stopped.';
        });
      }
    }
  }

  Future<void> _install() async {
    final f = File('${(await _dir()).path}/app.apk');
    if (f.existsSync()) await OpenFilex.open(f.path, type: 'application/vnd.android.package-archive');
  }

  String _mb(int b) => '${(b / 1048576).toStringAsFixed(1)} MB';

  Widget _button(String label, VoidCallback onTap, {bool main = false}) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: main ? const Color(0xFF4F6BFF) : const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(10)),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      );

  Widget _banner() {
    final progress = _size > 0 ? (_got / _size).clamp(0.0, 1.0) : null;
    String line;
    final buttons = <Widget>[];
    switch (_step) {
      case _Step.available:
        line = 'Version $_version is available${_size > 0 ? ' (${_mb(_size)})' : ''}';
        buttons.add(_button('Later', () => setState(() => _hidden = true)));
        buttons.add(_button('Download', _download, main: true));
      case _Step.downloading:
        line = 'Downloading $_version  ${_size > 0 ? '${_mb(_got)} of ${_mb(_size)}' : _mb(_got)}';
        buttons.add(_button('Pause', () => _stop = true));
      case _Step.paused:
        line = _msg.isEmpty ? 'Paused at ${_mb(_got)}' : _msg;
        buttons.add(_button('Resume', _download, main: true));
      case _Step.ready:
        line = 'Version $_version is ready to install';
        buttons.add(_button('Later', () => setState(() => _hidden = true)));
        buttons.add(_button('Install', _install, main: true));
      case _Step.none:
        line = '';
    }
    return Material(
      color: const Color(0xFF1E2433),
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(line, style: const TextStyle(color: Colors.white, fontSize: 14)),
          if (_step == _Step.available && _notes.trim().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text(_notes.trim().split('\n').first, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFB9C0E6), fontSize: 12))),
          if (_step == _Step.downloading) Padding(padding: const EdgeInsets.only(top: 8), child: LinearProgressIndicator(value: progress)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: buttons),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = View.of(context);
    final bottom = v.viewPadding.bottom / v.devicePixelRatio;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [
        widget.child,
        if (_step != _Step.none && !(_hidden && _step != _Step.downloading)) Positioned(left: 12, right: 12, bottom: 12 + bottom, child: _banner()),
      ]),
    );
  }
}
