// ============================
// speech_service.dart
// ============================
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String? _localeId;

  Future<bool> initialize(String localeId) async {
    // —— ここで一律正規化 —— 
    final normalized = localeId.toLowerCase() == 'zh_TW'
        ? 'zh-TW'
        : localeId.replaceAll('_', '-');

    final available = await _speech.initialize(
      onStatus: (status) => print('Speech status: \$status'),
      onError: (error) => print('Speech error: \$error'),
    );

    if (!available) return false;

    final locales = await _speech.locales();
    print(locales.map((l) => l.localeId).toList());
    final matchedLocale = locales.firstWhere(
      (locale) => locale.localeId == normalized,
      orElse: () => locales.first,
    );

    _localeId = matchedLocale.localeId;
    return true;
  }

  void listen(Function(String) onResult) {
    if (_localeId != null) {
      _speech.listen(
        localeId: _localeId!,
        onResult: (val) {
          if (val.finalResult) { // ← 最終確定の結果だけ渡す
            onResult(val.recognizedWords);
          }
        },
      );
    }
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
