import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prompt_builders.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';

class SessionMismatchException implements Exception {}

/// API 呼び出し失敗時にステージ・ステータス・ボディを保持する例外
class GptApiException implements Exception {
  final int? statusCode;
  final String? responseBody; // 先頭200文字
  final String message;
  const GptApiException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() => message;
}

class GptService {
  static const _apiUrl = 'https://asia-northeast1-kawaii-language-chat.cloudfunctions.net/api/chat';

  /// [prompt]：APIに送るプロンプト本文
  /// [model]：使いたいモデル名。省略時は gpt-3.5-turbo
  static Future<String?> getChatResponse(
    String prompt,
    String userInput,
    AppLocalizations loc, {
    String model = 'gpt-3.5-turbo',
  }) async {
    try {
      // prompt をトリム
      final trimmedPrompt = prompt.trim();
      // userInput もトリム
      final trimmedInput = userInput.trim();

      // Firebase Auth からトークン取得
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      if (idToken == null) {
        return 'ログイン状態が確認できませんでした。もう一度ログインしてください。';
      }

      // セッションID取得
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('sessionId') ?? '';

      // API呼び出し
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'X-Session-ID': sessionId,
        },
        body: jsonEncode({
          'message': trimmedPrompt, // ここが prompt
          'userInput': trimmedInput,
          'model': model,           // 追加した model フィールド
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'];
      } else {
        final errorData = jsonDecode(response.body);
        final errorCode = errorData['errorCode'];

        switch (errorCode) {
          case 'TOO_LONG':
            return loc.errorTooLong;
          case 'RATE_LIMIT':
            return loc.errorRateLimit;
          case 'SESSION_MISMATCH':
            throw SessionMismatchException(); // ✅ これが重要！
        }

        // fallback
        return 'サーバーからエラーが返されました（${response.statusCode}）';
      }
    } catch (e) {
      // 🔥 セッション例外はそのまま外へ投げ直す
      if (e is SessionMismatchException) throw e;
      debugPrint("❌ 通信エラー: $e");
      return null;
    }
  }

  /// 失敗時に [GptApiException] を throw するバージョン。
  /// ステータスコード・レスポンスボディ（先頭200文字）・例外メッセージを保持する。
  /// 成功時は GPT の返答文字列を返す。
  static Future<String> getChatResponseOrThrow(
    String prompt,
    String userInput,
    AppLocalizations loc, {
    String model = 'gpt-3.5-turbo',
  }) async {
    final trimmedPrompt = prompt.trim();
    final trimmedInput = userInput.trim();

    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    if (idToken == null) {
      throw const GptApiException('認証トークンが取得できません（未ログイン状態）');
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionId') ?? '';

    http.Response response;
    try {
      response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'X-Session-ID': sessionId,
        },
        body: jsonEncode({
          'message': trimmedPrompt,
          'userInput': trimmedInput,
          'model': model,
        }),
      );
    } catch (e) {
      throw GptApiException(e.toString());
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['reply'] as String?) ?? '';
    }

    // 非200: ボディ先頭200文字を保持して throw
    final rawBody = response.body;
    final body200 = rawBody.length > 200 ? rawBody.substring(0, 200) : rawBody;

    try {
      final errorData = jsonDecode(rawBody);
      final errorCode = errorData['errorCode'];
      if (errorCode == 'SESSION_MISMATCH') throw SessionMismatchException();
    } catch (e) {
      if (e is SessionMismatchException) rethrow;
      // JSON パース失敗はそのまま下へ
    }

    throw GptApiException(
      'HTTP ${response.statusCode}',
      statusCode: response.statusCode,
      responseBody: body200,
    );
  }
}
