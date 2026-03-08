import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 日次上限に達したときに渡される情報
class TtsDailyLimitInfo {
  final int limit;
  final int used;
  final String resetAtJst;
  final bool isPremium;

  const TtsDailyLimitInfo({
    required this.limit,
    required this.used,
    required this.resetAtJst,
    required this.isPremium,
  });
}

/// BotBubble 用 VOICEVOX TTS サービス。
/// - 2秒スロットル（連打スキップ）
/// - 24時間キャッシュ（同一テキスト・当日中は再生成しない）
/// - キュー1個（新しいリクエストで前の再生をキャンセル）
/// - 200文字上限（超過分は切り捨て）
/// - 日次上限超過時は flutter_tts でフォールバック再生
class VoicevoxTtsService {
  static const int _maxChars = 200;
  static const Duration _throttle = Duration(seconds: 2);
  // 同日内の同テキスト再生成を避けるため 24 時間キャッシュ
  static const Duration _cacheTtl = Duration(hours: 24);

  final _cache = <String, _CacheEntry>{};
  DateTime? _lastPlayTime;

  /// プレビュー用静的キャッシュ（インスタンスをまたいで共有、アプリ再起動まで保持）
  /// キャッシュ命中時は API を呼ばないため日次カウントに影響しない。
  static final Map<String, Uint8List> _previewCache = {};
  int _currentSpeakId = 0;
  final _player = AudioPlayer();

  /// 残り回数（null = 未取得）。プレミアムユーザーは表示不要。
  final ValueNotifier<int?> remainingNotifier = ValueNotifier(null);

  /// プレミアム判定（null = 未取得）
  final ValueNotifier<bool?> isPremiumNotifier = ValueNotifier(null);

  /// フォールバック用端末 TTS（日次上限超過時に使用）
  final FlutterTts _fallbackTts = FlutterTts();

  late final HttpsCallable _ttsProxy = FirebaseFunctions.instanceFor(
    region: 'asia-northeast1',
  ).httpsCallable('ttsProxy');

  /// [text] を [character] の声で読み上げる。
  /// targetLang == 'ja' のときのみ呼ばれる前提。
  /// [onPlayStart]: 音声再生が始まる直前に呼ばれ、音声の長さ(Duration)が渡される。
  /// [onDailyLimitFallback]: 日次上限に達し端末 TTS にフォールバックする直前に呼ばれる。
  Future<void> speak(
    String text,
    String character, {
    void Function(Duration)? onPlayStart,
    void Function(TtsDailyLimitInfo)? onDailyLimitFallback,
  }) async {
    text = text
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return;

    // 疑問文の語尾イントネーション: ASCII '?' → 全角 '？' に変換
    // VOICEVOX は '？' を検知して is_interrogative=true を自動設定し、語尾ピッチを上昇させる
    if (text.endsWith('?')) {
      text = '${text.substring(0, text.length - 1)}？';
    }

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
        debugPrint('[VoicevoxTTS] cache hit – skipping API call');
      } else {
        final result = await _ttsProxy.call<Map<String, dynamic>>({
          'text': text,
          'character': character,
        });
        if (myId != _currentSpeakId) return;

        // 使用量を更新:
        //   ① サーバーが usage を返した場合 → サーバー値で上書き（正確）
        //   ② 返さなかった場合（Functions 旧バージョン等）→ ローカルで -1（フォールバック）
        final rawUsage = result.data['usage'];
        if (rawUsage is Map) {
          final remaining = rawUsage['remaining'];
          final premium = rawUsage['isPremium'];
          if (remaining is num) remainingNotifier.value = remaining.toInt();
          if (premium is bool) isPremiumNotifier.value = premium;
          debugPrint('[VoicevoxTTS] usage from server: remaining=$remaining isPremium=$premium');
        } else if (isPremiumNotifier.value != true &&
            remainingNotifier.value != null) {
          // 旧 Functions など usage が返ってこない場合はローカルで 1 減算
          remainingNotifier.value =
              (remainingNotifier.value! - 1).clamp(0, 9999);
          debugPrint('[VoicevoxTTS] usage local decrement: remaining=${remainingNotifier.value}');
        }

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
      // 設定画面のスピードスライダーを反映する（speakPreview と同じロジック）
      final prefs = await SharedPreferences.getInstance();
      final ttsRate = prefs.getDouble('tts_speech_rate') ?? 0.40;
      final speed = (ttsRate * 2.0).clamp(0.3, 2.0);
      await _player.setSpeed(speed);
      onPlayStart?.call(audioDuration);
      await _player.play();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        final details = e.details;
        if (details is Map && details['daily'] == true) {
          // 日次上限超過 → 端末 TTS へフォールバック
          final info = TtsDailyLimitInfo(
            limit: (details['limit'] as num?)?.toInt() ?? 100,
            used: (details['used'] as num?)?.toInt() ?? 0,
            resetAtJst: details['resetAtJst'] as String? ?? '',
            isPremium: details['isPremium'] as bool? ?? false,
          );
          isPremiumNotifier.value = info.isPremium;
          onDailyLimitFallback?.call(info);
          await _speakFallback(text);
          return;
        }
      }
      debugPrint('[VoicevoxTTS] error: $e');
    } catch (e) {
      debugPrint('[VoicevoxTTS] error: $e');
    }
  }

  /// 端末標準 TTS でフォールバック再生（日本語固定）
  Future<void> _speakFallback(String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRate = prefs.getDouble('tts_speech_rate') ?? 0.40;
      final double rate = Platform.isIOS ? savedRate : (savedRate + 0.45).clamp(0.0, 1.0);
      await _fallbackTts.setLanguage('ja-JP');
      await _fallbackTts.setSpeechRate(rate);
      if (Platform.isIOS) {
        await _fallbackTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          ],
        );
      }
      await _fallbackTts.speak(text);
    } catch (e) {
      debugPrint('[VoicevoxTTS] fallback TTS error: $e');
    }
  }

  /// チャット画面起動時に今日の残り回数を Firestore から先読みする。
  /// すでに取得済みなら何もしない。
  Future<void> fetchUsageIfNeeded() async {
    if (remainingNotifier.value != null) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final db = FirebaseFirestore.instance;

      // プレミアム判定
      final userDoc = await db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final hasSub = userData['hasSubscription'] == true;
      bool isPremium = false;
      if (hasSub) {
        final expField = userData['expirationDate'];
        if (expField == null) {
          isPremium = true;
        } else if (expField is Timestamp) {
          isPremium = expField.millisecondsSinceEpoch > DateTime.now().millisecondsSinceEpoch;
        }
      }
      isPremiumNotifier.value = isPremium;

      // プレミアムユーザーは残り回数表示不要
      if (isPremium) return;

      // JST 今日の日付文字列
      final jstNow = DateTime.now().toUtc().add(const Duration(hours: 9));
      final dateStr =
          '${jstNow.year}-${jstNow.month.toString().padLeft(2, '0')}-${jstNow.day.toString().padLeft(2, '0')}';

      final usageSnap = await db
          .collection('users')
          .doc(uid)
          .collection('usage')
          .doc('ttsDaily')
          .get();

      const limit = 30;
      if (usageSnap.exists) {
        final data = usageSnap.data()!;
        if (data['date'] == dateStr) {
          final count = (data['count'] as num?)?.toInt() ?? 0;
          remainingNotifier.value = (limit - count).clamp(0, limit);
        } else {
          // 昨日以前のデータ → 今日はまだ 0 回
          remainingNotifier.value = limit;
        }
      } else {
        remainingNotifier.value = limit;
      }
    } catch (e) {
      debugPrint('[VoicevoxTTS] fetchUsage error: $e');
    }
  }

  /// 設定画面のテスト再生用。
  /// - 初回のみ VOICEVOX API を呼ぶ（1回分カウント）
  /// - 2回目以降は静的キャッシュから再生 → API 未呼び出し = 日次カウント対象外
  /// - [ttsRate] は設定値 0.2〜0.8。0.5 で等倍(1.0x)再生。
  /// - 戻り値: true=再生成功、false=日次上限超過（呼び出し元でフォールバックすること）
  Future<bool> speakPreview(
    String text,
    String character,
    double ttsRate, {
    void Function()? onPlayStart,
  }) async {
    text = text.trim();
    if (text.isEmpty) return false;

    // 疑問文の語尾イントネーション: ASCII '?' → 全角 '？' に変換
    if (text.endsWith('?')) {
      text = '${text.substring(0, text.length - 1)}？';
    }
    final cacheKey = '$character:$text';
    Uint8List bytes;

    if (_previewCache.containsKey(cacheKey)) {
      // キャッシュヒット時も日次上限を確認（上限超過なら端末TTSへ）
      final isPremium = isPremiumNotifier.value;
      final remaining = remainingNotifier.value;
      if (isPremium == false && remaining != null && remaining <= 0) {
        debugPrint('[VoicevoxTTS] speakPreview: cache hit but limit exceeded');
        return false;
      }
      bytes = _previewCache[cacheKey]!;
      debugPrint('[VoicevoxTTS] speakPreview: cache hit');
    } else {
      try {
        final result = await _ttsProxy.call<Map<String, dynamic>>({
          'text': text,
          'character': character,
        });
        final audioBase64 = result.data['audioBase64'] as String?;
        if (audioBase64 == null || audioBase64.isEmpty) return false;
        bytes = base64Decode(audioBase64);
        _previewCache[cacheKey] = bytes;
        debugPrint('[VoicevoxTTS] speakPreview: fetched and cached');
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'resource-exhausted') {
          final details = e.details;
          if (details is Map && details['daily'] == true) {
            // 日次上限超過 → remainingを0に更新して呼び出し元へ通知
            remainingNotifier.value = 0;
            debugPrint('[VoicevoxTTS] speakPreview: daily limit exceeded');
            return false;
          }
        }
        debugPrint('[VoicevoxTTS] speakPreview error: $e');
        return false;
      } catch (e) {
        debugPrint('[VoicevoxTTS] speakPreview error: $e');
        return false;
      }
    }

    try {
      if (_player.playing) await _player.stop();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/voicevox_preview.wav');
      await file.writeAsBytes(bytes, flush: true);
      await _player.setFilePath(file.path);
      // ttsRate 0.5 = 等倍(1.0x)、0.2 = 0.4x(遅い)、0.8 = 1.6x(速い)
      final speed = (ttsRate * 2.0).clamp(0.3, 2.0);
      await _player.setSpeed(speed);
      onPlayStart?.call(); // 再生直前に通知
      await _player.play();
      return true;
    } catch (e) {
      debugPrint('[VoicevoxTTS] speakPreview play error: $e');
      return false;
    }
  }

  Future<void> stop() async {
    _currentSpeakId++; // 進行中の speak を無効化
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _fallbackTts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _currentSpeakId++;
    try {
      await _player.dispose();
    } catch (_) {}
    try {
      await _fallbackTts.stop();
    } catch (_) {}
    remainingNotifier.dispose();
    isPremiumNotifier.dispose();
  }
}

class _CacheEntry {
  final Uint8List bytes;
  final DateTime time;
  _CacheEntry(this.bytes, this.time);
}
