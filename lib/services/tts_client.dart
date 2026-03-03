// ============================
// tts_client.dart
// ============================
import 'dart:developer' as dev;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'character_asset_service.dart';

/// VOICEVOX ベース TTS サーバーへリクエストして音声を再生するクライアント。
///
/// シングルトンで保持し、再生中の音声を停止してから新しい音声を再生する。
class TtsClient {
  TtsClient._();

  static final TtsClient instance = TtsClient._();

  // TODO: .envから読み込む
  static const String _apiKey = 'YOUR_API_KEY';
  static const String _endpoint = 'https://tts.kawaiilang.com/tts';

  final AudioPlayer _player = AudioPlayer();

  /// キャラクターに対応する VOICEVOX スピーカー名を返す。
  static String speakerName(String character) {
    return character == CharacterAssetService.kasumi ? '四国めたん' : '春日部つむぎ';
  }

  /// [text] をキャラクター [character] の声で読み上げる。
  ///
  /// エラーが発生した場合はログに出力して終了する（例外は再スローしない）。
  Future<void> speak(String text, String character) async {
    if (text.trim().isEmpty) return;

    try {
      await _stop();
      final bytes = await _fetchAudio(text, character);
      if (bytes == null) return;

      final file = await _saveToTemp(bytes);
      await _player.setFilePath(file.path);
      await _player.play();
    } catch (e, st) {
      dev.log('[TtsClient] 再生エラー: $e', error: e, stackTrace: st);
    }
  }

  /// 再生中の音声を停止する。
  Future<void> stop() async {
    await _stop();
  }

  /// AudioPlayer を破棄する。アプリ終了時などに呼ぶ。
  Future<void> dispose() async {
    await _player.dispose();
  }

  // ---------- private ----------

  Future<void> _stop() async {
    if (_player.playing) {
      await _player.stop();
    }
  }

  Future<List<int>?> _fetchAudio(String text, String character) async {
    final body = '{"text":${_jsonString(text)},"speakerName":${_jsonString(speakerName(character))}}';

    dev.log('[TtsClient] POST $_endpoint | speaker=${speakerName(character)} | text=$text');

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _apiKey,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      dev.log('[TtsClient] HTTPエラー: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Future<File> _saveToTemp(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tts_output.wav');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// JSON文字列リテラルに変換（dart:convertを使わず最小実装）。
  String _jsonString(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return '"$escaped"';
  }
}
