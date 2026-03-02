// ============================
// tts_test_service.dart
// Firebase Functions ttsProxy 呼び出しの最小テストサービス
// ============================
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Firebase Functions (asia-northeast1) の ttsProxy を呼び出して音声を再生する
/// 最小テストサービス。
///
/// 使用例:
/// ```dart
/// await TtsTestService.instance.speak('こんにちは', 'tumugi');
/// ```
class TtsTestService {
  TtsTestService._();

  static final TtsTestService instance = TtsTestService._();

  final AudioPlayer _player = AudioPlayer();

  late final HttpsCallable _ttsProxy = FirebaseFunctions.instanceFor(
    region: 'asia-northeast1',
  ).httpsCallable('ttsProxy');

  /// [text] を [character] の声で読み上げる。
  ///
  /// - Functions に `{ text, character }` を送信
  /// - レスポンスの `audioBase64` を base64Decode → Uint8List に変換
  /// - 一時ファイル経由で just_audio で再生
  ///
  /// エラーが発生した場合はログに出力して終了する（例外は再スローしない）。
  Future<void> speak(String text, String character) async {
    if (text.trim().isEmpty) return;

    try {
      if (_player.playing) await _player.stop();

      final bytes = await _callTtsProxy(text, character);
      if (bytes == null) return;

      final file = await _saveToTemp(bytes);
      await _player.setFilePath(file.path);
      await _player.play();
    } catch (e, st) {
      dev.log('[TtsTestService] 再生エラー: $e', error: e, stackTrace: st);
    }
  }

  /// Functions を呼び出して音声バイト列を返す。失敗時は null。
  Future<Uint8List?> _callTtsProxy(String text, String character) async {
    dev.log('[TtsTestService] call ttsProxy | character=$character | text=$text');

    final result = await _ttsProxy.call<Map<String, dynamic>>({
      'text': text,
      'character': character,
    });

    final audioBase64 = result.data['audioBase64'] as String?;
    if (audioBase64 == null || audioBase64.isEmpty) {
      dev.log('[TtsTestService] audioBase64 が空またはnull');
      return null;
    }

    return base64Decode(audioBase64);
  }

  /// Uint8List を一時ファイルに書き込んで返す。
  Future<File> _saveToTemp(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tts_test_output.wav');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// 再生中の音声を停止する。
  Future<void> stop() async {
    if (_player.playing) await _player.stop();
  }

  /// AudioPlayer を破棄する。不要になったら呼ぶ。
  Future<void> dispose() async {
    await _player.dispose();
  }
}
