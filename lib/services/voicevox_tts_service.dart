import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// BotBubble 用 VOICEVOX TTS サービス。
/// - 2秒スロットル（連打スキップ）
/// - 30秒キャッシュ（同一テキスト再利用）
/// - キュー1個（新しいリクエストで前の再生をキャンセル）
/// - 200文字上限（超過分は切り捨て）
/// - 例外はすべて握りつぶして debugPrint のみ
class VoicevoxTtsService {
  static const int _maxChars = 200;
  static const Duration _throttle = Duration(seconds: 2);
  static const Duration _cacheTtl = Duration(seconds: 30);

  final _cache = <String, _CacheEntry>{};
  DateTime? _lastPlayTime;
  int _currentSpeakId = 0;
  final _player = AudioPlayer();

  late final HttpsCallable _ttsProxy = FirebaseFunctions.instanceFor(
    region: 'asia-northeast1',
  ).httpsCallable('ttsProxy');

  /// [text] を [character] の声で読み上げる。
  /// targetLang == 'ja' のときのみ呼ばれる前提。
  /// [onPlayStart] は音声再生が始まる直前に呼ばれ、音声の長さ(Duration)が渡される。
  Future<void> speak(
    String text,
    String character, {
    void Function(Duration)? onPlayStart,
  }) async {
    text = text
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return;

    if (text.length > _maxChars) text = text.substring(0, _maxChars);

    // スロットル
    final now = DateTime.now();
    if (_lastPlayTime != null &&
        now.difference(_lastPlayTime!) < _throttle) {
      debugPrint('[VoicevoxTTS] throttled – skipped');
      return;
    }
    _lastPlayTime = now;

    // キュー1個: 後発リクエストを優先するためにIDで管理
    final myId = ++_currentSpeakId;

    try {
      if (_player.playing) await _player.stop();
      if (myId != _currentSpeakId) return;

      final cacheKey = '$character:$text';
      Uint8List bytes;

      final cached = _cache[cacheKey];
      if (cached != null && now.difference(cached.time) < _cacheTtl) {
        bytes = cached.bytes;
        debugPrint('[VoicevoxTTS] cache hit');
      } else {
        final result = await _ttsProxy.call<Map<String, dynamic>>({
          'text': text,
          'character': character,
        });
        if (myId != _currentSpeakId) return; // 新しいリクエストが来ていたらキャンセル

        final audioBase64 = result.data['audioBase64'] as String?;
        if (audioBase64 == null || audioBase64.isEmpty) {
          debugPrint('[VoicevoxTTS] empty audioBase64');
          return;
        }
        bytes = base64Decode(audioBase64);
        _cache[cacheKey] = _CacheEntry(bytes, now);
      }

      if (myId != _currentSpeakId) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/voicevox_tts.wav');
      await file.writeAsBytes(bytes, flush: true);

      final audioDuration =
          await _player.setFilePath(file.path) ?? const Duration(seconds: 3);
      onPlayStart?.call(audioDuration);
      await _player.play();
    } catch (e) {
      debugPrint('[VoicevoxTTS] error: $e');
    }
  }

  Future<void> stop() async {
    _currentSpeakId++; // 進行中の speak を無効化
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _currentSpeakId++;
    try {
      await _player.dispose();
    } catch (_) {}
  }
}

class _CacheEntry {
  final Uint8List bytes;
  final DateTime time;
  _CacheEntry(this.bytes, this.time);
}
