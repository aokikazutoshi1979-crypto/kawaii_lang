import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/speech_service.dart';
import '../services/question_manager.dart';
import '../widgets/message_list.dart';
import '../widgets/mic_area.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import '../utils/lang_utils.dart';
import '../services/gpt_service.dart';
import 'package:kawaii_lang/services/prompt_builders.dart';
import '../widgets/keyboard_guide_button.dart';
import 'dart:convert'; // ✅ これが必要！
import 'package:kawaii_lang/services/history_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kawaii_lang/config/quiz_mode_config.dart';
import 'package:kawaii_lang/widgets/mode_toggle_bar.dart';
import '../models/quiz_mode.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:ui';
// 先頭で：プラットフォーム別にしたい場合
import 'dart:io' show Platform, File;
import '../common/scene_label.dart';
import 'package:kawaii_lang/services/language_catalog.dart';
import 'question_list_screen.dart';
import '../utils/tsumugi_prompt.dart' as tsumugi_prompt;
import '../services/character_asset_service.dart';
import '../services/voicevox_tts_service.dart';


class ChatScreen extends StatefulWidget {
  final String nativeLang;
  final String targetLang;
  final String scene;
  final String promptLang;
  final bool isNativePrompt;
  final String selectedQuestionText;
  final String correctAnswerText;
  final List<Map<String, String>> questionList;
  final int selectedIndex;
  final QuizMode mode; // ★追加
  final bool showRecommendedStartLink;
  final String? recommendedReturnScene;

  const ChatScreen({
    required this.nativeLang,
    required this.targetLang,
    required this.scene,
    required this.promptLang,
    required this.isNativePrompt,
    required this.selectedQuestionText,
    required this.correctAnswerText,
    required this.questionList,
    required this.selectedIndex,
    required this.mode,
    this.showRecommendedStartLink = false,
    this.recommendedReturnScene,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  AppLocalizations get loc => AppLocalizations.of(context)!; // ← これを追加
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  String get nativeName => getLangLabelEn(widget.nativeLang);
  String get targetName => getLangLabelEn(widget.targetLang);
  List<Map<String, dynamic>> _messages = [];
  bool _hasInput = false;
  bool _hasSubmitted = false;

  late SpeechService _speechService;
  late QuestionManager _questionManager;
  late QuizMode _mode;

  bool _isListening = false;
  bool _isKeyboardMode = false;
  String _nativeCode = 'ja';

  String _currentNativeText = ''; // ← 出題を保持
  String _tsumugiQuestionText = '';
  bool _isPromptExpanded = false;

  late String _targetCode;

  DateTime? _lastReset;
  int _requestCount = 0;

  // ── 追加メンバ
  final List<DateTime> _sendTimestamps = [];
  DateTime? _rateLimitResetTime;
  bool _hasShownRateLimitError = false;

  bool _hasShownSessionError = false;

  static const List<Map<String, Object>> _ranks = [
    {'name': 'Starter', 'threshold': 0},
    {'name': 'Explorer', 'threshold': 25},
    {'name': 'Speaker', 'threshold': 100},
    {'name': 'Fluent', 'threshold': 300},
    {'name': 'Pro', 'threshold': 600},
    {'name': 'Master', 'threshold': 1000},
  ];

  final Queue<double> _ampQueue = Queue<double>();
  StreamSubscription<Amplitude>? _ampSub;
  double _ampEma = 0.0;

  final Queue<String> _recentTumugiLines = Queue<String>();
  final Random _rng = Random();

  // 録音用
  final AudioRecorder _rec = AudioRecorder();
  String? _pendingAudioPath;   // 送信時にメッセへ添付するための一時バッファ
  int? _pendingDurationMs;
  DateTime? _recStartAt;
  Timer? _recLimitTimer;       // 10秒上限のタイマー

  late final FlutterTts _tts;   // ← 追加
  bool _ttsReady = false;       // ← 追加
  bool _isSpeaking = false;     // ← 追加

  // VOICEVOX TTS（日本語学習時のみ使用）
  final VoicevoxTtsService _voicevoxService = VoicevoxTtsService();
  // 日次上限 SnackBar は 1 セッションで 1 回だけ表示
  bool _ttsDailyLimitSnackBarShown = false;

  // ── 送信前ボタン有効判定
  bool get _canSend {
    final now = DateTime.now();
    if (_rateLimitResetTime != null && now.isBefore(_rateLimitResetTime!)) {
      return false;
    }
    _sendTimestamps.retainWhere((t) => now.difference(t) < Duration(minutes: 1));
    return _sendTimestamps.length < 10;
  }

  bool _revealListeningText = false;
  String? _displayName;
  String _selectedCharacter = CharacterAssetService.defaultCharacter;
  static const String _thinkingRole = 'thinking';

  String _pickTumugiLine() {
    final isKasumi = _selectedCharacter == CharacterAssetService.kasumi;
    final baseLines = isKasumi
        ? tsumugi_prompt.kasumiPraiseLines(_nativeCode)
        : tsumugi_prompt.tsumugiPraiseLines(_nativeCode);
    final pool = List<String>.from(baseLines)
      ..removeWhere((line) => _recentTumugiLines.contains(line));
    if (pool.isEmpty) {
      pool.addAll(baseLines);
    }
    final baseLine = pool[_rng.nextInt(pool.length)];
    _recentTumugiLines.addLast(baseLine);
    while (_recentTumugiLines.length > 3) {
      _recentTumugiLines.removeFirst();
    }
    final prefix = tsumugi_prompt.tsumugiNamePrefix(_nativeCode, _displayName);
    final joiner = tsumugi_prompt.tsumugiSentenceJoiner(_nativeCode);
    final nextPrompt = isKasumi
        ? tsumugi_prompt.kasumiNextPrompt(_nativeCode)
        : tsumugi_prompt.tsumugiNextPrompt(_nativeCode);
    return '$prefix$baseLine$joiner$nextPrompt';
  }

  Map<String, dynamic> _buildThinkingMessage() {
    final isKasumi = _selectedCharacter == CharacterAssetService.kasumi;
    final code = _nativeCode.replaceAll('-', '_');
    final candidates = () {
      switch (code) {
        case 'ja':
          return isKasumi
              ? const [
                  'べ、別に迷ってないし',
                  'ちょっと待ちなさいよ',
                  'ちゃんと考えてるから',
                ]
              : const [
                  'うーん、考え中…',
                  'ちょっと待ってね',
                  '今まとめてるよ',
                ];
        case 'en':
          return isKasumi
              ? const [
                  "I-I'm not stuck, okay?",
                  'Give me a sec.',
                  "I'm thinking this through.",
                ]
              : const [
                  'Hmm, thinking...',
                  'One sec.',
                  "I'm putting it together.",
                ];
        case 'zh':
          return isKasumi
              ? const [
                  '我、我才没卡住呢',
                  '等一下啦',
                  '我在认真想啦',
                ]
              : const [
                  '我想想…',
                  '稍等一下哦',
                  '我在整理一下',
                ];
        case 'zh_TW':
          return isKasumi
              ? const [
                  '我、我才沒有卡住呢',
                  '等一下啦',
                  '我有在認真想啦',
                ]
              : const [
                  '我想想…',
                  '等我一下喔',
                  '我整理一下',
                ];
        case 'ko':
          return isKasumi
              ? const [
                  '벼, 별로 막힌 거 아니거든',
                  '잠깐만 기다려',
                  '나도 제대로 생각 중이야',
                ]
              : const [
                  '음, 생각 중이야...',
                  '잠깐만 기다려줘',
                  '지금 정리하고 있어',
                ];
        case 'es':
          return isKasumi
              ? const [
                  'N-no es que me haya bloqueado, ¿vale?',
                  'Espera un momento.',
                  'Lo estoy pensando en serio.',
                ]
              : const [
                  'A ver, déjame pensar...',
                  'Un segundito.',
                  'Lo estoy ordenando.',
                ];
        case 'fr':
          return isKasumi
              ? const [
                  "J-je ne bloque pas, d'accord ?",
                  'Attends une seconde.',
                  'Je réfléchis sérieusement.',
                ]
              : const [
                  'Voyons... je réfléchis.',
                  'Une petite seconde.',
                  'Je mets ça au clair.',
                ];
        case 'de':
          return isKasumi
              ? const [
                  'I-ich hänge nicht fest, klar?',
                  'Warte kurz.',
                  'Ich denke das gerade richtig durch.',
                ]
              : const [
                  'Hm, ich überlege...',
                  'Einen Moment bitte.',
                  'Ich ordne das gerade.',
                ];
        case 'vi':
          return isKasumi
              ? const [
                  'T-tôi đâu có bí đâu nhé.',
                  'Đợi một chút.',
                  'Tôi đang nghĩ nghiêm túc mà.',
                ]
              : const [
                  'Ừm, để mình nghĩ chút...',
                  'Chờ mình một chút nhé.',
                  'Mình đang sắp xếp lại.',
                ];
        case 'id':
          return isKasumi
              ? const [
                  'A-aku bukan kehabisan ide, ya.',
                  'Tunggu sebentar.',
                  'Aku lagi mikir serius kok.',
                ]
              : const [
                  'Hmm, aku pikir dulu...',
                  'Tunggu sebentar, ya.',
                  'Lagi aku rapikan dulu.',
                ];
        default:
          return isKasumi
              ? const [
                  "I-I'm not stuck, okay?",
                  'Give me a sec.',
                  "I'm thinking this through.",
                ]
              : const [
                  'Hmm, thinking...',
                  'One sec.',
                  "I'm putting it together.",
                ];
      }
    }();
    return {
      'role': _thinkingRole,
      'text': candidates[_rng.nextInt(candidates.length)],
      'avatarPath': CharacterAssetService.chatAvatar(_selectedCharacter),
      'fadingOut': false,
    };
  }

  String _pickTsumugiAccuracyCorrect(AppLocalizations loc) {
    final code = _nativeCode.replaceAll('-', '_');
    final base = loc.tumugiAccuracyCorrect;
    final candidates = switch (code) {
      'ja' => <String>[
          base,
          'ちゃんと意味が伝わってるよ！その調子！',
          '意味はしっかり合ってる！よく伝わってくるよ。',
          'うん、意味はばっちりだね！がんばってるね。',
        ],
      'en' => <String>[
          base,
          'The meaning comes through perfectly! Keep it up!',
          "You've got the meaning down! That really works.",
          "Meaning is spot on! You're doing great.",
        ],
      'zh' => <String>[
          '意思表达得很准确！就是这样，继续加油！',
          '你的意思完全对！这样就没问题啦。',
          '意思完全正确！你表达得很好呢。',
          '嗯，意思很到位！你真的很棒哦。',
        ],
      'zh_TW' => <String>[
          '意思表達得很準確！就是這樣，繼續加油！',
          '你的意思完全對！這樣就沒問題啦。',
          '意思完全正確！你表達得很好呢。',
          '嗯，意思很到位！你真的很棒喔。',
        ],
      'ko' => <String>[
          '의미도 완벽해! 정말 잘하고 있어!',
          '뜻이 딱 맞아! 그대로 계속해봐.',
          '의미가 잘 전달됐어! 대단한걸.',
          '응, 의미는 완벽해! 잘하고 있어.',
        ],
      'es' => <String>[
          '¡El significado está perfecto! ¡Sigue así!',
          '¡Tu respuesta transmite justo lo que se pide! ¡Muy bien!',
          '¡Has captado el significado! Qué bien te ha salido.',
          '¡El sentido es correcto! Lo estás haciendo genial.',
        ],
      'fr' => <String>[
          'Le sens est parfait ! Continue comme ça !',
          'Tu as bien saisi la signification ! Super !',
          "Le sens passe très bien ! C'est vraiment bien.",
          "Oui, le sens est bon ! Tu t'en sors vraiment bien.",
        ],
      'de' => <String>[
          'Die Bedeutung stimmt genau! Weiter so!',
          'Du hast den Sinn richtig erfasst! Das ist toll!',
          'Die Bedeutung kommt super rüber! Wirklich gut.',
          'Ja, die Bedeutung ist korrekt! Du machst das prima.',
        ],
      'vi' => <String>[
          'Ý nghĩa hoàn toàn đúng! Tuyệt lắm, cứ tiếp tục nhé!',
          'Bạn nắm bắt ý nghĩa rất chính xác! Cố lên!',
          'Ý nghĩa truyền đạt rất tốt! Thật ấn tượng đấy.',
          'Ừ, ý nghĩa rất chuẩn! Bạn đang làm tốt lắm.',
        ],
      'id' => <String>[
          'Maknanya sudah tepat sekali! Terus semangat ya!',
          'Kamu sudah menangkap maknanya dengan baik! Bagus banget!',
          'Makna tersampaikan dengan sempurna! Keren banget.',
          'Ya, maknanya sudah pas! Kamu hebat!',
        ],
      _ => <String>[base],
    };
    return candidates[_rng.nextInt(candidates.length)];
  }

  String _pickKasumiAccuracyCorrect(AppLocalizations loc) {
    final code = _nativeCode.replaceAll('-', '_');
    final base = loc.kasumiAccuracyCorrect;
    final candidates = switch (code) {
      'ja' => <String>[
          base,
          'ま、意味はちゃんと合ってるわ。…悪くないじゃない。',
          'うん、意図は伝わってる。べ、別に褒めてるわけじゃないけど。',
          '意味は合ってるわよ。ここまでできれば十分でしょ。',
        ],
      'en' => <String>[
          base,
          "Yeah, your meaning is right. D-don't get the wrong idea.",
          'You got the meaning across. Not bad... I guess.',
          "The meaning checks out. I mean, that's all.",
        ],
      'zh' => <String>[
          '哼，意思是对的啦……我才不是在夸你呢。',
          '嗯，意思表达到了。也、也就还行吧。',
          '这句意思没问题。别误会，我可没特别夸你。',
          '至少意思说对了，继续保持吧。',
        ],
      'zh_TW' => <String>[
          '哼，意思是對的啦……我才沒有在誇你。',
          '嗯，意思有傳達到。也、也就還可以吧。',
          '這句意思沒問題。別誤會，我可不是特別稱讚你。',
          '至少意思說對了，繼續保持吧。',
        ],
      'ko' => <String>[
          '흥, 뜻은 맞았거든... 칭찬하는 건 아니야.',
          '응, 의미는 제대로 전달됐어. 뭐, 나쁘진 않네.',
          '이 문장은 뜻이 맞아. 오해하지 마, 특별히 칭찬한 건 아니니까.',
          '적어도 의미는 정확해. 이대로 계속해.',
        ],
      'es' => <String>[
          'B-bueno, el sentido está bien... no creas que te estoy halagando.',
          'Sí, la idea se entiende. N-no te emociones.',
          'Lograste transmitir el significado. No está mal... supongo.',
          'El significado es correcto. Sigue así, ¿vale?',
        ],
      'fr' => <String>[
          'B-bon, le sens est correct... ne va pas croire que je te félicite.',
          "Oui, l'idée passe bien. N-ne prends pas la grosse tête.",
          "Tu as bien transmis le sens. Ce n'est pas mal... enfin, voilà.",
          "Le sens est juste. Continue comme ça, d'accord ?",
        ],
      'de' => <String>[
          'N-na ja, die Bedeutung stimmt... bilde dir bloß nichts ein.',
          'Ja, der Sinn kommt rüber. A-aber werde jetzt nicht überheblich.',
          'Du hast die Bedeutung richtig getroffen. Nicht schlecht... denke ich.',
          'Die Aussage passt so. Mach einfach weiter, klar?',
        ],
      'vi' => <String>[
          'Ừm... ý thì đúng đó, nhưng đừng nghĩ là mình khen nhé.',
          'Đúng rồi, ý bạn truyền đạt ổn. Đ-đừng tự mãn đấy.',
          'Bạn diễn đạt đúng nghĩa rồi. Cũng không tệ... chắc vậy.',
          'Nghĩa là chuẩn đó. Cứ giữ phong độ này nhé.',
        ],
      'id' => <String>[
          'Y-ya, maknanya sudah benar... jangan geer dulu.',
          'Iya, maksudnya tersampaikan. J-jangan salah paham, ya.',
          'Kamu menyampaikan maknanya dengan tepat. Lumayan... kurasa.',
          'Maknanya sudah pas. Lanjutkan saja begitu.',
        ],
      _ => <String>[base],
    };
    return candidates[_rng.nextInt(candidates.length)];
  }

  String _pickTsumugiAccuracyIncorrect(AppLocalizations loc) {
    final code = _nativeCode.replaceAll('-', '_');
    final base = loc.tumugiAccuracyIncorrect;
    final candidates = switch (code) {
      'ja' => <String>[
          base,
          '惜しい！意味が少し違うかも。もう一度一緒に見てみよう。',
          'うーん、意味がちょっと違うみたい。大丈夫、一緒に直そう！',
          '意味が合ってないかな…でも気にしないで！次はきっとできるよ。',
          'ちょっとズレちゃったね。じっくり見直してみよう。',
          '惜しかった！意味が少しズレちゃってるよ。もう一回挑戦してみて！',
          '意味が違うみたいだね…一緒に確かめてみよう。',
          'ほんのちょっとだけ意味が違うよ。次は合わせられると思う！',
          'うまくいかなかったね。でも大丈夫、少しだけズレてるだけだから！',
          '意味がずれちゃったかな。でも、ここを直せばきっと合うよ！',
        ],
      'en' => <String>[
          base,
          "Almost! The meaning is a bit different. Let's check it again together.",
          "The meaning doesn't quite match... but don't worry! You'll get it next time.",
          "Hmm, the meaning is a little off. Let's take another look!",
          "Close, but the meaning slipped a little. Let's try again together!",
          "The meaning is a bit different. Let's figure it out together!",
          "Not quite the same meaning. But I believe you can get it right!",
          "The meaning shifted a little. Let's review it and try again!",
          "Oops, the meaning doesn't match. No worries — let's fix it together!",
          "The meaning is a tiny bit off. You're so close though!",
        ],
      'zh' => <String>[
          '意思有点偏差呢…我们一起来确认吧！',
          '差一点！意思稍微不一样。我们再一起看看吧。',
          '嗯，意思有点不一样。没关系，一起改正吧！',
          '意思对不上呢…但不要气馁！下次一定能行的。',
          '稍微偏了一点哟。我们仔细再看看吧。',
          '可惜！意思稍微偏了。再挑战一次吧！',
          '意思好像不太一样呢…我们一起确认一下吧。',
          '意思只是稍微有点不同哦。下次一定能对上的！',
          '这次没成功呢。但没关系，就只是偏了一点点！',
          '意思偏了一点。但是，只要修正这里，一定能对上的！',
        ],
      'zh_TW' => <String>[
          '意思有點偏差呢…我們一起來確認吧！',
          '差一點！意思稍微不一樣。我們再一起看看吧。',
          '嗯，意思有點不一樣。沒關係，一起改正吧！',
          '意思對不上呢…但不要氣餒！下次一定能行的。',
          '稍微偏了一點喔。我們仔細再看看吧。',
          '可惜！意思稍微偏了。再挑戰一次吧！',
          '意思好像不太一樣呢…我們一起確認一下吧。',
          '意思只是稍微有點不同喔。下次一定能對上的！',
          '這次沒成功呢。但沒關係，就只是偏了一點點！',
          '意思偏了一點。但是，只要修正這裡，一定能對上的！',
        ],
      'ko' => <String>[
          '의미가 조금 다른 것 같아…같이 확인해보자！',
          '아깝다! 의미가 조금 달라. 다시 같이 봐보자.',
          '음, 의미가 좀 다른 것 같아. 괜찮아, 같이 고쳐보자！',
          '의미가 안 맞는 것 같은데…하지만 신경 쓰지 마! 다음엔 할 수 있어.',
          '살짝 빗나갔네. 찬찬히 다시 봐보자.',
          '아깝다! 의미가 조금 빗나갔어. 한 번 더 도전해봐！',
          '의미가 다른 것 같은데…같이 확인해보자.',
          '아주 조금 의미가 달라. 다음엔 맞출 수 있을 거야！',
          '이번엔 아쉽게 됐네. 하지만 괜찮아, 조금 빗나간 것뿐이야！',
          '의미가 살짝 달라졌어. 하지만 여기만 고치면 분명히 맞을 거야！',
        ],
      'es' => <String>[
          "El significado no coincide del todo... ¡revisémoslo juntos!",
          "¡Casi! El significado es un poco diferente. Veamos juntos.",
          "Hmm, el significado no encaja. ¡No te preocupes, vamos a corregirlo!",
          "El sentido no coincide... ¡pero no te rindas! La próxima seguro que sí.",
          "Se desvió un poco. Revisémoslo con calma.",
          "¡Qué pena! El sentido cambió un poco. ¡Inténtalo otra vez!",
          "El significado parece diferente... ¡vamos a revisarlo juntos!",
          "El sentido está un poquito desviado. ¡Seguro que la próxima lo logras!",
          "No salió esta vez. Pero no pasa nada, ¡es solo un pequeño desvío!",
          "El sentido se desvió un poco. Pero si corriges esto, ¡lo conseguirás!",
        ],
      'fr' => <String>[
          "Le sens est un peu décalé... révisons ensemble !",
          "Presque ! Le sens est légèrement différent. Regardons ensemble.",
          "Hmm, le sens ne correspond pas tout à fait. Pas de souci, on va arranger ça !",
          "Le sens ne colle pas... mais ne te décourage pas ! La prochaine fois sera la bonne.",
          "C'est un peu décalé. Regardons ça tranquillement.",
          "Dommage ! Le sens a glissé. Essaie encore !",
          "Le sens semble différent... révisons-le ensemble !",
          "C'est juste un tout petit décalage. Tu vas y arriver la prochaine fois !",
          "Ça n'a pas marché cette fois. Pas grave, c'est juste un petit écart !",
          "Le sens a un peu dévié. Mais si tu corriges ça, tu y seras !",
        ],
      'de' => <String>[
          "Die Bedeutung ist etwas daneben... lass uns das gemeinsam überprüfen!",
          "Fast! Die Bedeutung ist ein bisschen anders. Schauen wir es gemeinsam an.",
          "Hmm, die Bedeutung passt nicht ganz. Kein Problem, lass es uns zusammen korrigieren!",
          "Die Bedeutung stimmt nicht... aber nicht aufgeben! Beim nächsten Mal klappt es.",
          "Ein kleines bisschen daneben. Lass uns in Ruhe nochmal schauen.",
          "Schade! Die Bedeutung ist ein bisschen abgewichen. Noch mal versuchen!",
          "Die Bedeutung scheint anders zu sein... lass uns das gemeinsam prüfen!",
          "Die Bedeutung ist nur ein kleines bisschen anders. Beim nächsten Mal schaffst du es!",
          "Hat diesmal nicht geklappt. Aber kein Stress, es ist nur ein kleiner Unterschied!",
          "Die Bedeutung ist leicht verrutscht. Wenn du das korrigierst, passt es!",
        ],
      'vi' => <String>[
          'Ý nghĩa hơi lệch một chút... hãy cùng nhau xem lại nhé!',
          'Suýt rồi! Ý nghĩa hơi khác một chút. Hãy cùng nhau xem lại nào.',
          'Ừm, ý nghĩa chưa khớp. Không sao, cùng nhau sửa lại nhé!',
          'Ý nghĩa chưa khớp... nhưng đừng nản lòng! Lần sau chắc chắn được thôi.',
          'Lệch một chút rồi. Hãy xem lại cẩn thận nhé.',
          'Tiếc quá! Ý nghĩa bị lệch một chút. Thử lại lần nữa nhé!',
          'Ý nghĩa có vẻ khác một chút... cùng nhau kiểm tra nhé!',
          'Ý nghĩa chỉ khác một chút thôi. Lần sau bạn sẽ làm được!',
          'Lần này không thành. Nhưng không sao, chỉ lệch một chút thôi!',
          'Ý nghĩa lệch một chút rồi. Nhưng chỉ cần sửa chỗ này là được thôi!',
        ],
      'id' => <String>[
          'Maknanya sedikit meleset... ayo kita periksa bersama!',
          'Hampir! Maknanya sedikit berbeda. Yuk, kita lihat lagi bersama.',
          'Hmm, maknanya kurang tepat. Tidak apa-apa, mari kita perbaiki bersama!',
          'Maknanya belum cocok... tapi jangan menyerah! Pasti bisa di kesempatan berikutnya.',
          'Sedikit meleset. Mari kita lihat dengan seksama.',
          'Sayang sekali! Maknanya sedikit bergeser. Coba lagi ya!',
          'Maknanya tampak berbeda... ayo kita periksa bersama!',
          'Maknanya hanya sedikit berbeda. Pasti bisa di kesempatan berikutnya!',
          'Kali ini belum berhasil. Tapi tidak apa-apa, cuma meleset sedikit!',
          'Maknanya sedikit bergeser. Tapi kalau ini diperbaiki, pasti cocok!',
        ],
      _ => <String>[base],
    };
    return candidates[_rng.nextInt(candidates.length)];
  }

  String _pickKasumiAccuracyIncorrect(AppLocalizations loc) {
    final code = _nativeCode.replaceAll('-', '_');
    final base = loc.kasumiAccuracyIncorrect;
    final candidates = switch (code) {
      'ja' => <String>[
          base,
          '意味がズレてるわ。もう一回、落ち着いて見直しなさい。',
          'ちょっと意味が違うわね。次は合わせられるでしょ。',
          '惜しいけど、意味は別物よ。ここ直せばいけるわ。',
          '全然違うとは言わないけど…意味がズレてる。ちゃんと確認して。',
          '惜しいって言えば惜しいけど、意味が違うのよね。もう一回。',
          '意味が合ってないわよ。こんなとこで詰まらないで。',
          'はあ…意味がずれてるじゃない。落ち着いて読み直しなさい。',
          '意味が違う。あなたならもっとできるはずよ。',
          '次は絶対合わせなさいよ。意味がズレてるんだから。',
        ],
      'en' => <String>[
          base,
          'Your meaning is off. Take another look.',
          'Close, but the meaning changed. Try one more time.',
          "Not quite the same meaning. You'll get it next round.",
          "The meaning doesn't match. Don't get tripped up here.",
          "Hmm... the meaning is off. Just take a breath and read it again.",
          "That's not the right meaning. You can do better than that.",
          "The meaning slipped. Check it over and try again.",
          "Off on the meaning. Make sure you get it right next time.",
          "I know you can figure it out. The meaning's just a bit off.",
        ],
      'zh' => <String>[
          '意思不太对。再看一遍吧。',
          '差一点，但意思偏了。再试一次。',
          '这句和题目的意思不一样，再调整一下。',
          '还不完全对，不过你下一次能做好的。',
          '意思不对嘛。别在这里犯错了。',
          '哼…意思跑掉了。冷静下来再看看吧。',
          '意思不对。你应该能做得更好的。',
          '意思偏了。检查一下再试试。',
          '意思不对。下次一定要对啊。',
          '我知道你能搞清楚的。意思只是偏了一点而已。',
        ],
      'zh_TW' => <String>[
          '意思不太對。再看一遍吧。',
          '差一點，但意思跑掉了。再試一次。',
          '這句和題目的意思不一樣，再調整一下。',
          '還沒完全對，不過你下次可以的。',
          '意思不對嘛。別在這裡出錯了。',
          '哼…意思跑掉了。冷靜下來再看看吧。',
          '意思不對。你應該能做得更好的。',
          '意思偏了。檢查一下再試試。',
          '意思不對。下次一定要對啊。',
          '我知道你能搞清楚的。意思只是偏了一點而已。',
        ],
      'ko' => <String>[
          '의미가 조금 달라. 다시 한번 보자.',
          '아깝지만 뜻이 바뀌었어. 한 번 더 해봐.',
          '문장은 괜찮은데 의도가 달라졌어.',
          '완전히 틀린 건 아니야. 다음엔 맞출 수 있어.',
          '의미가 다르잖아. 여기서 막히면 안 되지.',
          '흠...의미가 달라졌어. 차분하게 다시 읽어봐.',
          '의미가 틀렸어. 더 잘할 수 있을 텐데.',
          '의미가 빗나갔네. 다시 확인하고 해봐.',
          '의미가 틀렸잖아. 다음엔 꼭 맞추라고.',
          '네가 알아낼 수 있다는 건 알아. 의미가 조금 틀린 것뿐이야.',
        ],
      'es' => <String>[
          'El sentido no coincide. Revísalo otra vez.',
          'Casi, pero cambió el significado. Inténtalo de nuevo.',
          'La frase suena bien, pero la idea es distinta.',
          'No está del todo mal. La próxima te sale.',
          'El significado no cuadra. No te quedes atascado aquí.',
          'Hm... el sentido se fue. Cálmate y léelo de nuevo.',
          'El significado es incorrecto. Puedes hacerlo mejor.',
          'El sentido se desvió. Revísalo y vuelve a intentarlo.',
          'El sentido está mal. Asegúrate de acertar la próxima vez.',
          'Sé que puedes resolverlo. El significado solo está un poco desviado.',
        ],
      'fr' => <String>[
          "Le sens n'est pas tout à fait le bon. Regarde encore une fois.",
          "Presque, mais l'idée a changé. Réessaie.",
          "La phrase est correcte, mais l'intention n'est pas la même.",
          "Ce n'est pas loin. La prochaine fois, tu l'auras.",
          "Le sens ne correspond pas. Ne te bloque pas là-dessus.",
          "Hmm... le sens a glissé. Calme-toi et relis.",
          "Le sens est incorrect. Tu peux faire mieux que ça.",
          "Le sens a dévié. Vérifie et réessaie.",
          "Le sens est faux. Assure-toi de le trouver la prochaine fois.",
          "Je sais que tu peux y arriver. Le sens n'est qu'un tout petit peu décalé.",
        ],
      'de' => <String>[
          'Die Bedeutung passt noch nicht ganz. Schau es dir nochmal an.',
          'Knapp daneben, aber der Sinn hat sich geändert.',
          'Der Satz klingt okay, nur die Aussage ist anders.',
          'Nicht komplett falsch. Beim nächsten Mal passt es.',
          'Die Bedeutung stimmt nicht. Hänge hier nicht fest.',
          'Hm... die Bedeutung ist abgerutscht. Beruhige dich und lies noch mal.',
          'Die Bedeutung ist falsch. Du kannst das besser.',
          'Der Sinn ist verrutscht. Überprüf es und versuch es nochmal.',
          'Die Bedeutung ist falsch. Achte nächstes Mal darauf.',
          'Ich weiß, dass du es herausfinden kannst. Der Sinn ist nur ein kleines bisschen daneben.',
        ],
      'vi' => <String>[
          'Ý nghĩa chưa đúng lắm. Xem lại một lần nhé.',
          'Gần đúng rồi, nhưng nghĩa đã bị lệch. Thử lại đi.',
          'Câu ổn, nhưng ý định khác với đề bài.',
          'Chưa chuẩn hẳn đâu, nhưng lần sau bạn làm được.',
          'Ý nghĩa không đúng. Đừng bị vấp ở đây.',
          'Hm... nghĩa bị lệch rồi. Bình tĩnh đọc lại đi.',
          'Ý nghĩa sai rồi. Bạn có thể làm tốt hơn thế.',
          'Nghĩa bị lệch rồi. Kiểm tra lại và thử nữa nhé.',
          'Ý nghĩa sai. Lần sau phải chắc chắn đúng nhé.',
          'Mình biết bạn có thể tìm ra được. Nghĩa chỉ lệch một chút thôi.',
        ],
      'id' => <String>[
          'Maknanya belum pas. Coba cek sekali lagi.',
          'Hampir benar, tapi maknanya jadi beda.',
          'Kalimatnya oke, tapi maksudnya tidak sama.',
          'Belum tepat sepenuhnya, tapi di percobaan berikutnya kamu pasti bisa.',
          'Maknanya tidak cocok. Jangan tersangkut di sini.',
          'Hm... maknanya meleset. Tenang dan baca lagi ya.',
          'Maknanya salah. Kamu bisa lebih baik dari ini.',
          'Maknanya meleset. Periksa lagi dan coba sekali lagi.',
          'Maknanya salah. Pastikan benar di kesempatan berikutnya.',
          'Aku tahu kamu bisa mencari tahu. Maknanya hanya sedikit meleset.',
        ],
      _ => <String>[base],
    };
    return candidates[_rng.nextInt(candidates.length)];
  }

  /// thinking バブルを消してボットバブルを追加し、必ず setState で UI を更新する。
  void _addBotBubble(String text) {
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((msg) => msg['role'] == _thinkingRole);
      _messages.add({'role': 'bot', 'text': text});
    });
  }

  /// API エラー情報をボットバブルとして表示する。
  /// 詳細は常に debugPrint へ。UI には debug のみ詳細を出し、
  /// release では汎用メッセージのみ表示する。
  void _showApiError(
    String stage, {
    int? statusCode,
    String? body,
    Object? error,
  }) {
    final sb = StringBuffer('⚠️ APIエラー [$stage]');
    if (statusCode != null) sb.write('\nHTTP: $statusCode');
    if (body != null && body.isNotEmpty) sb.write('\nBody: $body');
    if (error != null) sb.write('\n$error');
    debugPrint(sb.toString());

    if (kDebugMode) {
      _addBotBubble(sb.toString());
    } else {
      final loc = AppLocalizations.of(context);
      _addBotBubble(loc?.errorServerError ?? '⚠️ エラーが発生しました。もう一度お試しください。');
    }
  }

  Future<void> _flushPendingBotMessages(
    List<Map<String, dynamic>> pendingBotMessages,
  ) async {
    if (!mounted || pendingBotMessages.isEmpty) return;

    final thinkingIndex = _messages.lastIndexWhere(
      (msg) => msg['role'] == _thinkingRole,
    );
    if (thinkingIndex != -1) {
      final thinking = Map<String, dynamic>.from(_messages[thinkingIndex]);
      if (thinking['fadingOut'] != true) {
        setState(() {
          _messages[thinkingIndex] = {
            ...thinking,
            'fadingOut': true,
          };
        });
        await Future.delayed(const Duration(milliseconds: 180));
        if (!mounted) return;
      }
    }

    setState(() {
      _messages.removeWhere((msg) => msg['role'] == _thinkingRole);
      _messages.addAll(pendingBotMessages);
    });
  }

  // 返ってくる型が String でも Map でも安全に扱う
  bool _parseIsCorrectJson(dynamic response) {
    try {
      // 1) まず素の型を優先判定
      if (response is bool) return response;                 // true / false
      if (response is num)  return response == 1;            // 1 / 0
      if (response is String) {
        final s = response.trim().toLowerCase();
        if (s == '1' || s == 'true')  return true;           // "1" / "true"
        if (s == '0' || s == 'false') return false;          // "0" / "false"
        // JSON文字列の可能性
        final decoded = jsonDecode(s);
        return _parseIsCorrectJson(decoded);                 // 再帰
      }

      // 2) Map(JSON) を安全に走査
      if (response is Map) {
        // 代表キーを直接見る
        for (final k in const ['isCorrect', 'correct']) {
          if (response.containsKey(k)) {
            final v = response[k];
            final r = _parseIsCorrectJson(v);
            if (r is bool) return r;
          }
        }
        // よくあるネスト: result.isCorrect / data.isCorrect / evaluation.isCorrect
        for (final path in const [
          ['result', 'isCorrect'],
          ['data', 'isCorrect'],
          ['evaluation', 'isCorrect'],
        ]) {
          dynamic cur = response;
          for (final key in path) {
            if (cur is Map && cur.containsKey(key)) {
              cur = cur[key];
            } else {
              cur = null;
              break;
            }
          }
          if (cur != null) return _parseIsCorrectJson(cur);
        }
      }
    } catch (_) {
      // 解析失敗は下で false
    }
    return false; // 判定不能は不正解扱い
  }

  void _startAmplitudeStream() {
    _ampSub?.cancel();
    _ampQueue.clear();
    _ampEma = 0.0;
    _ampSub = _rec
        .onAmplitudeChanged(const Duration(milliseconds: 50))
        .listen((amp) {
      if (!mounted) return;
      final db = amp.current ?? -60.0;
      final normalized = ((db + 60.0) / 60.0).clamp(0.0, 1.0);
      const alpha = 0.25;
      _ampEma = (_ampEma * (1 - alpha)) + (normalized * alpha);
      setState(() {
        _ampQueue.add(_ampEma);
        while (_ampQueue.length > 40) {
          _ampQueue.removeFirst();
        }
      });
    });
  }

  void _stopAmplitudeStream({bool clear = true}) {
    _ampSub?.cancel();
    _ampSub = null;
    _ampEma = 0.0;
    if (clear) {
      _ampQueue.clear();
    }
  }

  int _rankIndexForUnique(int uniqueCorrect) {
    var index = 0;
    for (var i = 0; i < _ranks.length; i++) {
      final threshold = _ranks[i]['threshold'] as int;
      if (uniqueCorrect >= threshold) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }

  Future<void> _maybeShowRankUp() async {
    final stats = await HistoryService.instance.getProfileStats();
    final uniqueCorrect = stats.uniqueCorrect;
    final currentIndex = _rankIndexForUnique(uniqueCorrect);

    final prefs = await SharedPreferences.getInstance();
    final lastIndex = prefs.getInt('last_rank_index');
    if (lastIndex == null) {
      await prefs.setInt('last_rank_index', currentIndex);
      return;
    }

    if (currentIndex > lastIndex) {
      await prefs.setInt('last_rank_index', currentIndex);
      if (!mounted) return;
      final rankName = _ranks[currentIndex]['name'] as String;
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(loc.rankUpTitle),
            content: Text(loc.rankUpBody(rankName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.ok),
              ),
            ],
          );
        },
      );
    }
  }

  String _normalizeForDuplicateCheck(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'^[\"“”『』「」]+|[\"“”『』「」]+$'), '');
    s = s.replaceAll(RegExp(r'[.!?。！？…．、]+$'), '');
    return s;
  }

  String _normalizeRomaji(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  bool _isSameRomaji(String? a, String? b) {
    if (a == null || b == null) return false;
    final na = _normalizeRomaji(a);
    final nb = _normalizeRomaji(b);
    if (na.isEmpty || nb.isEmpty) return false;
    return na == nb;
  }

  Future<String?> _romajiForJapanese(String text, AppLocalizations loc) async {
    final t = text.trim();
    if (t.isEmpty) return null;
    final prompt = PromptBuilders.buildSimilarQuestionTtsPrompt(
      translatedText: t,
      targetLang: _targetCode,
    );
    final res = await GptService.getChatResponse(prompt, t, loc);
    if (res == null) return null;
    final r = res.trim();
    if (r.isEmpty || r.toLowerCase() == 'null') return null;
    return r;
  }

  bool _isDuplicateSimilar(String candidate, List<String> avoidList) {
    final c = _normalizeForDuplicateCheck(candidate);
    if (c.isEmpty) return true;
    for (final a in avoidList) {
      if (a.trim().isEmpty) continue;
      final n = _normalizeForDuplicateCheck(a);
      if (n.isNotEmpty && c == n) return true;
    }
    return false;
  }

  String _buildSimilarPromptWithAvoid({
    required String seed,
    required String targetLang,
    required List<String> avoidList,
  }) {
    final base = PromptBuilders.buildSimilarQuestionPrompt(
      translatedText: seed,
      targetLang: targetLang,
    );
    if (avoidList.isEmpty) return base;
    final quoted = avoidList.where((s) => s.trim().isNotEmpty).map((s) => '"$s"').join(', ');
    if (quoted.isEmpty) return base;
    return '$base\n\n【追加条件】\n- 次の表現と同一にならないこと: $quoted\n';
  }

  Future<String?> _generateSimilarExpression({
    required String seed,
    required String targetLang,
    required AppLocalizations loc,
    List<String> avoidList = const [],
  }) async {
    final basePrompt = PromptBuilders.buildSimilarQuestionPrompt(
      translatedText: seed,
      targetLang: targetLang,
    );
    final String? first = await GptService.getChatResponse(basePrompt, seed, loc);
    final String firstText = (first ?? '').trim();
    if (firstText.isEmpty) return null;
    if (!_isDuplicateSimilar(firstText, avoidList)) return firstText;

    final retryPrompt = _buildSimilarPromptWithAvoid(
      seed: seed,
      targetLang: targetLang,
      avoidList: avoidList,
    );
    final String? retry = await GptService.getChatResponse(retryPrompt, seed, loc);
    final String retryText = (retry ?? '').trim();
    if (retryText.isEmpty) return null;
    if (_isDuplicateSimilar(retryText, avoidList)) {
      debugPrint('similar expression duplicated; skipped');
      return null;
    }
    return retryText;
  }

  Widget _langPill(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  // 「母語の表記」で対象言語名を返す
  String _displayLangName(String rawCode) {
    final code = getLangCode(rawCode);              // "English" → "en" など正規化
    final display = getLangCode(widget.nativeLang); // 母語のコード
    return LanguageCatalog.instance.labelFor(code, displayLang: display);
  }

  String _displayLangCode(String rawCode) {
    final code = getLangCode(rawCode).replaceAll('_', '-');
    return code.toUpperCase();
  }

  /// 日次上限超過時: 端末 TTS フォールバックの SnackBar を 1 回だけ表示
  void _onTtsDailyLimitFallback(TtsDailyLimitInfo info) {
    if (_ttsDailyLimitSnackBarShown) return;
    _ttsDailyLimitSnackBarShown = true;
    if (!mounted) return;

    final String msg;
    if (_nativeCode == 'ja') {
      msg = '本日のアニメ声は上限に達したため、端末の標準音声で再生します（${info.resetAtJst}に回復）';
    } else {
      msg = 'Daily anime voice limit reached. Using device voice instead (resets at ${info.resetAtJst}).';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // 1) まず現在のモードを確定（← これが先）
    _mode = widget.mode; // QuizMode.reading / listening

    // 2) 既存の初期化
    _speechService = SpeechService();
    _controller.clear();
    _questionManager = QuestionManager(widget.questionList, widget.selectedIndex);
    _nativeCode = getLangCode(widget.nativeLang);
    _targetCode = getLangCode(widget.targetLang); // ★追加

    _tts = FlutterTts();
    // 3) TTS 初期化（内部で _ttsReady = true にする想定）
    _initTts();

    _loadDisplayName();
    _loadCharacter();

    // 日本語学習時: 残り回数を起動時に先読みしてバナーをすぐ表示
    if (_targetCode == 'ja') {
      _voicevoxService.fetchUsageIfNeeded();
    }

    // ★ 言語カタログを読み込んでから一度だけ再描画
    Future.microtask(() async {
      await LanguageCatalog.instance.ensureLoaded();
      if (mounted) {
        setState(() {
          _tsumugiQuestionText = _selectedCharacter == CharacterAssetService.kasumi
              ? tsumugi_prompt.buildKasumiQuestionLine(
                  uiLanguageCode: _nativeCode,
                  targetLanguageName: _displayLangName(widget.targetLang),
                )
              : tsumugi_prompt.buildTsumugiQuestionLine(
                  uiLanguageCode: _nativeCode,
                  targetLanguageName: _displayLangName(widget.targetLang),
                );
        });
      }
    });

    // 4) Listening で入室したら、自動再生（ビルド完了後に）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // if (_mode == QuizMode.listening) _speakCurrentQuestion();
    });
  }

  Future<void> _loadDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _displayName = prefs.getString('user_display_name');
    });
  }

  Future<void> _loadCharacter() async {
    final character = await CharacterAssetService.loadSelectedCharacter();
    if (!mounted) return;
    setState(() => _selectedCharacter = character);
  }

  Future<void> _initTts() async {
    final prefs = await SharedPreferences.getInstance();
    final double savedRate = prefs.getDouble('tts_speech_rate') ?? 0.40;
    final double rate = Platform.isIOS ? savedRate : (savedRate + 0.45).clamp(0.0, 1.0); // Androidはiosより速く感じにくい
    await _tts.setSpeechRate(rate);

    // （お好み）声の高さ
    await _tts.setPitch(1.0);

    await _setTtsLanguage();          // ← chat_bubble からコピペした関数を呼ぶ
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true); // 任意：再生完了待ちを有効化
    _ttsReady = true;
  }

  // Listening時は target、Reading時は native を優先して取る
  String _currentQuestionTextForMode() {
    final cur = _questionManager.current;
    // よく使うキーの安全フォールバック
    String from(Map m, String key) => (m[key] as String?)?.trim() ?? '';

    if (_mode == QuizMode.listening) {
      final t = from(cur, _targetCode);
      if (t.isNotEmpty) return t;
    } else {
      final n = from(cur, _nativeCode);
      if (n.isNotEmpty) return n;
    }
    // どちらも無ければ汎用キーを探索
    for (final k in const ['questionText', 'promptText', 'text', 'question']) {
      final v = (cur[k] as String?)?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _currentQuestionText() {
    // 1) 画面遷移時に明示的に渡されている場合（最優先）
    final sel = (widget.selectedQuestionText ?? '').trim();
    if (sel.isNotEmpty) return sel;

    // 2) 現在インデックスのアイテムから推測
    try {
      final idx = _questionManager.currentIndex;
      if (idx >= 0 && idx < widget.questionList.length) {
        final item = widget.questionList[idx];
        if (item is Map) {
          // あり得そうなキー名を優先順で探索
          for (final k in const [
            'questionText',
            'promptText',
            'text',
            'question',
            'body',
            'display',
          ]) {
            final v = item[k];
            if (v is String && v.trim().isNotEmpty) {
              return v.trim();
            }
          }
        }
      }
    } catch (_) {
      // 何もしない（下のフォールバックへ）
    }

    // 3) 最終フォールバック（本来は問題文を読むが、無い時は正解文を読む）
    final ans = (widget.correctAnswerText ?? '').trim();
    if (ans.isNotEmpty) return ans;

    return '';
  }

  // _ChatScreenState のメンバに追加（initStateやbuildの外）
  String get questionText {
    final cur = _questionManager.current;
    // 文字列取り出しの安全関数
    String pick(Map m, String key) => (m[key] as String?)?.trim() ?? '';

    if (_mode == QuizMode.listening) {
      // ★ Listening のときは target 言語を優先
      final t = pick(cur, _targetCode);
      if (t.isNotEmpty) return t;
      // なければフォールバックで native など汎用キー
      final n = pick(cur, _nativeCode);
      if (n.isNotEmpty) return n;
    } else {
      // ★ Reading のときは native を優先
      final n = pick(cur, _nativeCode);
      if (n.isNotEmpty) return n;
      // なければ target にフォールバック
      final t = pick(cur, _targetCode);
      if (t.isNotEmpty) return t;
    }

    // さらに一般キーにもフォールバック（必要なら調整）
    for (final k in const ['questionText', 'promptText', 'text', 'question', 'body']) {
      final v = (cur[k] as String?)?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  Widget _listeningQuestionCard() {
    final text = _currentQuestionTextForMode();
    if (text.isEmpty) return const SizedBox.shrink();

    final blurredText = Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.white.withOpacity(0.45)),
        ),
      ],
    );

    final plainText = Text(
      text,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ラベルなし大アイコンの再生ボタン
            Tooltip(
              message: '再生',
              child: FilledButton(
                onPressed: _isSpeaking ? null : () => _speakText(text),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  minimumSize: const Size(56, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.volume_up_rounded, size: 28),
              ),
            ),
            const SizedBox(width: 12),

            // ぼかし → 平文へスムーズに切替
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _revealListeningText
                    ? plainText
                    : blurredText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    const promptBubbleColor = Color(0xFFFFF0F5);
    final promptBorderColor = Colors.pink.shade200.withOpacity(0.6);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showRecommendedStartLink)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Align(
              alignment: Alignment.center,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: _openQuestionListFromRecommend,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text(
                    'おすすめから開始しました（問題を選び直す）',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (_mode == QuizMode.reading && _currentNativeText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 31.5,
                  backgroundImage: AssetImage(
                    CharacterAssetService.chatAvatar(_selectedCharacter),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPromptExpanded = !_isPromptExpanded;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: promptBubbleColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: promptBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tsumugiQuestionText.isNotEmpty
                                    ? _tsumugiQuestionText
                                    : _currentNativeText,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (tsumugi_prompt.formatPromptQuote(_nativeCode, _currentNativeText).isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _ExpandablePromptText(
                                  text: tsumugi_prompt.formatPromptQuote(_nativeCode, _currentNativeText),
                                  isExpanded: _isPromptExpanded,
                                  maxLines: 2,
                                  expandLabel: loc.tapToExpand,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE91E63),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        if (_mode == QuizMode.listening) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              loc.listeningPrompt,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                  Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
          _listeningQuestionCard(),
        ],
      ],
    );
  }

  Future<void> _speakText(String text) async {
    if (!_ttsReady || _isSpeaking) return;
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return;

    try {
      _isSpeaking = true;
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS failed: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> _speakCurrentQuestion() async {
    if (!_ttsReady || _isSpeaking) return;
    try {
      var text = _currentQuestionText();

      // ざっくりタグ/改行除去（SSMLやMarkdownが混ざっていても読みやすく）
      text = text
          .replaceAll(RegExp(r'<[^>]+>'), ' ') // SSML/HTMLタグ除去
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (text.isEmpty) {
        debugPrint('TTS: empty question text, skip.');
        return;
      }

      _isSpeaking = true;
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      if (!mounted) return;
      // フォールバック不要なら何もしない（ログだけでもOK）
      debugPrint('TTS failed: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == QuizMode.reading ? QuizMode.listening : QuizMode.reading;
    });
    if (_mode == QuizMode.listening) _speakCurrentQuestion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context)!;
    _loadQuestion(loc);
  }

  @override
  void dispose() {
    _recLimitTimer?.cancel();
    // 録音中なら止める（安全策）
    _rec.stop();
    _rec.dispose();
    _stopAmplitudeStream(clear: false);
    _tts.stop();
    _voicevoxService.dispose();
    _speechService.stop();
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _loadQuestion(AppLocalizations loc) {
    final q = _questionManager.current;

    final nativeText = (q[_nativeCode] as String?)?.trim() ?? '';
    final targetText = (q[_targetCode] as String?)?.trim() ?? '';

    final isListening = _mode == QuizMode.listening;

    setState(() {
      // ★ ここで毎回リセット（モードに関わらず）
      _revealListeningText = false;
      _currentNativeText = nativeText;
      _isPromptExpanded = false;
      _tsumugiQuestionText = _selectedCharacter == CharacterAssetService.kasumi
          ? tsumugi_prompt.buildKasumiQuestionLine(
              uiLanguageCode: _nativeCode,
              targetLanguageName: _displayLangName(widget.targetLang),
            )
          : tsumugi_prompt.buildTsumugiQuestionLine(
              uiLanguageCode: _nativeCode,
              targetLanguageName: _displayLangName(widget.targetLang),
            );

      if (isListening) {
        _messages = [
          // （必要なら）{'role': 'bot', 'text': loc.listeningPrompt}
        ];
      } else {
        _messages = [
          // {'role': 'bot', 'text': '${loc.translatePrompt}\n「$nativeText」'}
        ];
      }

      _hasInput = false;
      _hasSubmitted = false;
      _isKeyboardMode = false;
    });
  }

  void _speakIfListeningAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_mode == QuizMode.listening) _speakCurrentQuestion();
    });
  }

  void _loadNextQuestion() {
    _questionManager.next();
    final loc = AppLocalizations.of(context)!;
    _loadQuestion(loc);            // ← これが _revealListeningText を false にしてくれる
    // setState(() => _revealListeningText = false); // ← もう不要
  }

  void _startListening() async {
    final localeId = getLocaleId(widget.targetLang);
    final available = await _speechService.initialize(localeId);
    if (available) {
      // ★★ 録音開始（端末の一時フォルダへ .m4a で保存）
      try {
        final hasPerm = await _rec.hasPermission();
        if (hasPerm) {
          final tmp = await getTemporaryDirectory();
          final path = '${tmp.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _rec.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: path, // ← v6ではIO系プラットフォームで必須
          );
          _pendingAudioPath = path;                 // 後で吹き出しへ添付するため保持
          _recStartAt = DateTime.now();
          _startAmplitudeStream();

          // ★★ 10秒で自動停止（STT & 録音を同時に止める）
          _recLimitTimer?.cancel();
          _recLimitTimer = Timer(const Duration(seconds: 10), () {
            if (_isListening) {
              _stopListening(autoStopped: true);
            }
          });
        } else {
          // パーミッション無い場合は録音なしでSTTだけ動かす
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('マイクの権限がありません（録音なしで音声認識を開始します）')),
          );
        }
      } catch (e) {
        debugPrint('record.start failed: $e');
      }
      setState(() {
        _isListening = true;
        _isKeyboardMode = false;
      });
      _speechService.listen((recognizedText) {
        setState(() {
          _controller.text = (_controller.text + ' ' + recognizedText).trim();
          _hasInput = _controller.text.trim().isNotEmpty;
        });
      });
    }
  }

  Future<void> _setTtsLanguage() async {
    // ① —— まず最初に一度だけサポート言語・音声一覧を取得
    final List<dynamic>? langs = await _tts.getLanguages;

    final List<dynamic>? allVoices = await _tts.getVoices;

    switch (widget.targetLang?.toLowerCase()) {
      case 'en':
        await _tts.setLanguage('en-US');
        break;
      case 'ja':
        await _tts.setLanguage('ja-JP');
        break;
      case 'zh':
        // Chinese (Simplified)
        await _tts.setLanguage('zh-CN');
        break;
      case 'zh_tw':  // 元コードの分岐をそのまま使う場合
       // 正しい BCP-47 形式をセット
        await _tts.setLanguage('zh-TW');

        // （デバッグ用）台湾音声だけフィルターしてみる
        final taiwanVoices = allVoices
            ?.where((v) => v['locale'] == 'zh-TW')
            .toList();
        // print('🎤 zh‑TW voices: $taiwanVoices');

        await _tts.setVoice({
          'name': 'Mei‑Jia',    // 実機で getVoices して一致を確認
          'locale': 'zh-TW',
        });
        break;
      case 'ko':
        await _tts.setLanguage('ko-KR');
        break;
      case 'es':
        await _tts.setLanguage('es-ES');
        break;
      case 'fr':
        // 1) 言語を fr‑FR に設定
        await _tts.setLanguage('fr-FR');

        // 2) iOS 標準の女性声 “Marie” を指定
        await _tts.setVoice({
          'name': 'Audrey',
          'locale': 'fr-FR',
        });
        break;
      case 'de':
        await _tts.setLanguage('de-DE');
        break;
      case 'vi':
        await _tts.setLanguage('vi-VN');
        break;
      case 'id':
        await _tts.setLanguage('id-ID');
        break;
      default:
        await _tts.setLanguage('en-US');
    }
    await _tts.setSpeechRate(0.4); // 任意：ゆっくり読み上げ

    // ✅ iOSでサイレントモードでも再生されるようにする
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
      ],
    );
  }

  Future<void> _stopListening({bool autoStopped = false}) async {
    await _speechService.stop();

    // ★★ 10秒タイマー停止
    _recLimitTimer?.cancel();
    _stopAmplitudeStream(clear: true);

    // ★★ 録音停止 → 長さ計測 → バッファに保持
    try {
      if (await _rec.isRecording()) {
        final actualPath = await _rec.stop(); // 実際に保存されたパス（null の可能性も）
        // record.stop() が null を返す可能性に備えて pending を優先
        final path = actualPath ?? _pendingAudioPath;

        final durMs = (_recStartAt != null)
            ? DateTime.now().difference(_recStartAt!).inMilliseconds
            : null;

        _pendingAudioPath = path;            // 送信時にメッセへ添付
        _pendingDurationMs = durMs;
        _recStartAt = null;
      }
    } catch (e) {
      debugPrint('record.stop failed: $e');
    }

    if (autoStopped) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.recordingAutoStopped)),
      );
    }

    setState(() => _isListening = false);
  }

  Future<void> _cancelRecording() async {
    await _stopListening();
    final path = _pendingAudioPath;
    if (path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (f.existsSync()) {
          await f.delete();
        }
      } catch (_) {}
    }
    _pendingAudioPath = null;
    _pendingDurationMs = null;
    if (mounted) {
      setState(() {
        _controller.clear();
        _hasInput = false;
      });
    }
  }

  Future<void> _confirmRecording() async {
    await _stopListening();
  }

  void _activateKeyboardMode() async {
    setState(() {
      _isKeyboardMode = true;
      _isListening = false;
    });
    _speechService.stop();
    _stopAmplitudeStream(clear: true);

    // もし録音中なら止める
    try {
      if (await _rec.isRecording()) {
        await _rec.stop();
      }
    } catch (_) {}

    // 🔴 キーボードに切り替えたら pending 音声を破棄
    _pendingAudioPath = null;
    _pendingDurationMs = null;

    Future.delayed(const Duration(milliseconds: 100), () {
      _inputFocusNode.requestFocus();
    });
  }

  void _sendMessage() async {
    final rawInput = _controller.text.trim();
    if (rawInput.isEmpty) return;

    if (!_canSend) {
      if (!_hasShownRateLimitError) {
        setState(() {
          _messages.add({
            'role': 'bot',
            'text': AppLocalizations.of(context)!.errorRateLimit,
          });
          _hasShownRateLimitError = true;
        });
      }
      return;
    }

    _sendTimestamps.add(DateTime.now());

    setState(() {
      _controller.clear();
      _hasInput = false;
      _hasSubmitted = true;
      // ① 処理中バブルを即時表示（エラー時も必ず置き換えられる）
      _messages.removeWhere((msg) => msg['role'] == _thinkingRole);
      _messages.add(_buildThinkingMessage());
    });

    final loc = AppLocalizations.of(context)!;
    // final questionText = _questionManager.current[_nativeCode] ?? '';

    try {
      debugPrint('▶ Entering GPT request try-block');

      // ⑤ 正解チェック（問1）だけ mode で分岐
      final prompt1 = (_mode == QuizMode.listening)
        ? PromptBuilders.buildListeningPrompt(
            userAnswer:       rawInput,
            originalQuestion: questionText,
            targetLang:       targetName,
            nativeLang:       nativeName,
          )
        : PromptBuilders.buildAccuracyPrompt(
            userAnswer:       rawInput,
            originalQuestion: questionText,
            targetLang:       targetName,
            nativeLang:       nativeName,
          );


      // ② AccuracyCheck — 失敗時はエラーバブルを出して return（不正解扱いにしない）
      final String res1;
      try {
        res1 = await GptService.getChatResponseOrThrow(
          prompt1,
          rawInput,
          loc,
          model: 'gpt-4o',
        );
      } on GptApiException catch (e) {
        _showApiError('AccuracyCheck', statusCode: e.statusCode, body: e.responseBody, error: e.message);
        return;
      } on SessionMismatchException {
        rethrow; // 外側 catch で処理
      } catch (e) {
        _showApiError('AccuracyCheck', error: e);
        return;
      }

      // ★ JSONから正誤boolを抽出
      final bool isCorrectFlag = _parseIsCorrectJson(res1);

      if (isCorrectFlag) {
        if (rawInput == null || rawInput.trim().isEmpty) {
          setState(() {
            _messages.add({'role': 'bot', 'text': loc.errorPunctuationFailed});
          });
          return;
        }

        final bool shouldAttachAudio = !_isKeyboardMode && _pendingAudioPath != null;

        setState(() {
          final Map<String, dynamic> userMsg = {
            'role': 'user',
            'text': rawInput,
            'labelType': 'correct',
          };
          // 🎯 キーボードモードなら音声は付けない
          if (shouldAttachAudio) {
            userMsg['audioPath'] = _pendingAudioPath;   // 🎤 録音のローカルパス
            if (_pendingDurationMs != null) {
              userMsg['durationMs'] = _pendingDurationMs; // ⏱️ 表示用
            }
          }
          _messages.add(userMsg);
          _messages.removeWhere((msg) => msg['role'] == _thinkingRole);
          _messages.add(_buildThinkingMessage());

          // 入力欄のクリア（必要なら）
          _controller.clear();
          _hasInput = false;
        });

        // pending のクリアは setState の外でOK
        _pendingAudioPath = null;
        _pendingDurationMs = null;

        // ログイン中（匿名含む）のユーザーであれば履歴を記録
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // ここでだけ Firestore 書き込み
          final currentMap = widget.questionList[_questionManager.currentIndex];
          final questionId = currentMap['id'] as String;
          final scene      = currentMap['scene'] as String;
          final subScene   = currentMap['subScene'] as String;
          final level      = currentMap['level'] as String;

          try {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            debugPrint('→ recordAnswer call: q=$questionId target=$targetName native=$nativeName uid=$uid');

            await HistoryService.instance.recordAnswer(
              questionId: questionId,
              isCorrect:  isCorrectFlag,
              scene:      scene,
              subScene:   subScene,
              level:      level,
              mode:       _mode.name, // "reading" | "listening"
              targetLang: targetName,  // ★追加
              nativeLang: nativeName,  // ★追加
              targetCode: _targetCode,
              nativeCode: _nativeCode,
            );

            debugPrint('✓ recordAnswer saved');
          } catch (e) {
            debugPrint('▶ history record failed (ignored): $e');
          }
        }

        if (user != null) {
          await _maybeShowRankUp();
        }

        // 問6
        await _handleOriginalQuestionTranslation(
          questionText,
          loc,
          rawInput: rawInput,
          useAnswerPrefix: false,
          skipFirstBubble: true,           // ←①を出さない
          addAccuracyNoticeBubble: true,   // ←“的確です”通知を表示
          addFollowupTumugiReply: true,    // ←正解時の追加コメントも同時表示
          onlyFirstBubble: false,          // ←②以降も続ける
        );
        return;
      }



      // ③ SymbolCheck（問7）：記号または数字のみ、不適切文、母語以外で書かれているかチェック
      final minimalPrompt = PromptBuilders.buildSymbolOrNumberOnlyCheckPrompt(
        userAnswer: rawInput,
        targetLang: targetName,
      );
      final String res7;
      try {
        res7 = await GptService.getChatResponseOrThrow(minimalPrompt, rawInput, loc);
      } on GptApiException catch (e) {
        _showApiError('SymbolCheck', statusCode: e.statusCode, body: e.responseBody, error: e.message);
        return;
      } on SessionMismatchException {
        rethrow;
      } catch (e) {
        _showApiError('SymbolCheck', error: e);
        return;
      }
      final answer7 = _parseAnswer(res7);

      // ① or ② の両方で同じフロー
      if (answer7 == '1' || answer7 == '2') {
        if (rawInput == null || rawInput.trim().isEmpty) {
          setState(() {
            _messages.add({'role': 'bot', 'text': loc.errorPunctuationFailed});
          });
          return;
        }

        final bool shouldAttachAudio = !_isKeyboardMode && _pendingAudioPath != null;

        setState(() {
          final Map<String, dynamic> userMsg = {
            'role': 'user',
            'text': rawInput,
            'labelType': 'incorrect',
          };
          // 🎯 キーボードモードなら音声は付けない
          if (shouldAttachAudio) {
            userMsg['audioPath'] = _pendingAudioPath;   // 🎤 録音のローカルパス
            if (_pendingDurationMs != null) {
              userMsg['durationMs'] = _pendingDurationMs; // ⏱️ 表示用
            }
          }
          _messages.add(userMsg);
          _messages.removeWhere((msg) => msg['role'] == _thinkingRole);
          _messages.add(_buildThinkingMessage());

          // 入力欄のクリア（必要なら）
          _controller.clear();
          _hasInput = false;
        });

        // pending のクリアは setState の外でOK
        _pendingAudioPath = null;
        _pendingDurationMs = null;

        final accuracyFeedbackText = _selectedCharacter == CharacterAssetService.kasumi
            ? _pickKasumiAccuracyIncorrect(loc)
            : _pickTsumugiAccuracyIncorrect(loc);
        final pendingBotMessages = <Map<String, dynamic>>[];
        Future<void> flushPendingBotMessages() async {
          await _flushPendingBotMessages(pendingBotMessages);
          pendingBotMessages.clear();
        }

        // 1) オリジナルの翻訳（ターゲット言語）
        final prompt6 = PromptBuilders.buildOriginalQuestionTranslationPrompt(
          originalQuestion: questionText,
          targetLang:       targetName,
        );
        final String? res6 = await GptService.getChatResponse(prompt6, questionText, loc);
        final String translatedText = (res6 ?? '').trim();

        // 2) オリジナルの音声転写（対象言語が ja/zh/zh_tw/ko のときのみ）
        String? transcription6;
        {
          final norm = widget.targetLang.replaceAll('-', '_').toLowerCase();
          if (const {'ja', 'zh', 'zh_tw', 'ko'}.contains(norm) && translatedText.isNotEmpty) {
            final promptTts6 = PromptBuilders.buildSimilarQuestionTtsPrompt(
              translatedText: translatedText,
              targetLang: widget.targetLang,
            );
            final String? rawTrans6 = await GptService.getChatResponse(promptTts6, translatedText, loc);
            if (rawTrans6 != null && rawTrans6.toLowerCase() != 'null') {
              transcription6 = rawTrans6.trim();
            }
          }
        }

        // 3) 1つ目の吹き出し（修正例ハイライト）を表示

        // 🔶 ハイライト本文（訳文＋転写を全部ここに入れる）
        final highlightLines = <String>[];
        highlightLines.add(translatedText); // 訳文

        if (transcription6 != null && transcription6!.isNotEmpty) {
          highlightLines
            ..add('')                // 改行で1行空ける
            ..add(transcription6!);  // 転写テキストだけ追加
        }

        // キャラクター精度フィードバック（意味NG）
        pendingBotMessages.add({
          'role': 'bot',
          'text': accuracyFeedbackText,
          'labelType': 'info',
        });

        // キャラクターの正解案内セリフ
        pendingBotMessages.add({
          'role': 'tumugi',
          'text': _selectedCharacter == CharacterAssetService.kasumi
              ? tsumugi_prompt.kasumiCorrectAnswerIntro(_nativeCode)
              : tsumugi_prompt.tsumugiCorrectAnswerIntro(_nativeCode),
          'avatarPath': CharacterAssetService.chatAvatar(_selectedCharacter),
        });
        pendingBotMessages.add({
          'role': 'bot',
          // ★ ハイライト用（黄色ボックスの内容）
          'highlightTitle': loc.answerTranslationPrefix,  // 例: 修正例
          'highlightBody':  highlightLines.join('\n'),
          'text': '',
          'showAvatar': false,

          // 🔊 音声ボタン（本文に重複表示はしない）
          'tts': translatedText,
          'showTtsBody': false,
          'avatarPath': CharacterAssetService.chatAvatar(_selectedCharacter),

          'targetLang': widget.targetLang,
          // ← これで下側の「tts本文テキスト」を消せる
          // 'showTtsBody': false,
        });

        // 5) 類似表現（ターゲット言語）を生成（同一文は再生成）
        String? userRomaji;
        if (_targetCode == 'ja' && rawInput.trim().isNotEmpty) {
          userRomaji = await _romajiForJapanese(rawInput, loc);
        }

        String? similar = await _generateSimilarExpression(
          seed: questionText,
          targetLang: targetName,
          loc: loc,
          avoidList: [rawInput, translatedText],
        );
        if (similar == null || similar.isEmpty) {
          await flushPendingBotMessages();
          return;
        } // 念のためガード

        String? similarRomaji;
        if (_targetCode == 'ja' && userRomaji != null) {
          similarRomaji = await _romajiForJapanese(similar, loc);
          if (_isSameRomaji(similarRomaji, userRomaji)) {
            final retry = await _generateSimilarExpression(
              seed: questionText,
              targetLang: targetName,
              loc: loc,
              avoidList: [rawInput, translatedText, similar],
            );
            if (retry != null && retry.trim().isNotEmpty) {
              similar = retry;
              similarRomaji = await _romajiForJapanese(similar, loc);
            }
          }
        }

        // 6) 類似表現の母語訳
        final prompt10 = PromptBuilders.buildSimilarQuestionInNativeLangPrompt(
          translatedText: similar,
          nativeLang:     nativeName,
        );
        final String? nativeSimilarRes = await GptService.getChatResponse(prompt10, similar, loc);
        final String nativeSimilar = (nativeSimilarRes ?? '').trim();

        // 7) 類似表現の音声転写（ja/zh/zh_tw/koのみ）
        String? transcriptionSimilar;
        {
          final norm = widget.targetLang.replaceAll('-', '_').toLowerCase();
          if (norm == 'ja' && similarRomaji != null) {
            transcriptionSimilar = similarRomaji;
          } else if (const {'ja', 'zh', 'zh_tw', 'ko'}.contains(norm) && similar.isNotEmpty) {
            final prompt12 = PromptBuilders.buildSimilarQuestionTtsPrompt(
              translatedText: similar,
              targetLang: widget.targetLang,
            );
            final String? rawTranscription = await GptService.getChatResponse(prompt12, similar, loc);
            if (rawTranscription != null && rawTranscription.toLowerCase() != 'null') {
              transcriptionSimilar = rawTranscription.trim();
            }
          }
        }

        // ★ ハイライト本文（類似表現＋転写＋母語訳を全部まとめる）
        final simLines = <String>[];
        simLines.add(similar); // 1行目：類似表現
        if (transcriptionSimilar != null && transcriptionSimilar!.isNotEmpty) {
          simLines..add('')..add(transcriptionSimilar!); // 見出し不要なら転写だけ
        }
        if (nativeSimilar.isNotEmpty) {
          simLines..add('')..add(nativeSimilar); // 見出し不要ならそのまま
        }

        // 8) 2つ目の吹き出しを表示
        // テキスト部は見出し（類似表現）だけにして、本文は tts/nativetext/transcription に流す
        pendingBotMessages.add({
          'role': 'tumugi',
          'text': _selectedCharacter == CharacterAssetService.kasumi
              ? tsumugi_prompt.kasumiSimilarExpressionIntro(_nativeCode)
              : await tsumugi_prompt.tsumugiSimilarExpressionIntro(_nativeCode),
          'avatarPath': CharacterAssetService.chatAvatar(_selectedCharacter),
        });
        pendingBotMessages.add({
          'role': 'bot',
          // ★ ハイライト用（薄い緑色のボックスの内容）
          'highlightTitle': loc.similarExpressionHeader, // 例: 類似表現
          'highlightBody':  simLines.join('\n'),                      // ← 再生ボタン＆本文表示
          'showAvatar': false,

          // ★ 音声ボタン（本文は出さない）
          'tts': similar,              // ← これで再生アイコンが出る
          'showTtsBody': false,        // ← ttsテキストを本文に重複表示しない

          // ★ 通常本文（補足などを入れたいときだけ）
          'targetLang': widget.targetLang,
          // 'nativeText': nativeSimilar,         // ← 母語訳（ChatBubbleで本文下に表示）
          // if (transcriptionSimilar != null) 'transcription': transcriptionSimilar,
          // 'text': '',
        });
        await flushPendingBotMessages();

        return;
      } 

      if (rawInput == null || rawInput.trim().isEmpty) {
        setState(() {
          _messages.add({'role': 'bot', 'text': loc.errorPunctuationFailed});
        });
        return;
      }

      setState(() {
        final Map<String, dynamic> userMsg = {
          'role': 'user',
          'text': rawInput,                 // ← 句読点補完後のテキストを使う
          'labelType': 'incorrect',
        };
        if (_pendingAudioPath != null) {
          userMsg['audioPath'] = _pendingAudioPath;     // 🎤 録音のローカルパス
        }
        if (_pendingDurationMs != null) {
          userMsg['durationMs'] = _pendingDurationMs;   // ⏱️ 表示用
        }
        _messages.add(userMsg);

        // 入力欄のクリア（必要なら）
        _controller.clear();
        _hasInput = false;
      });

      // pending のクリアは setState の外でOK
      _pendingAudioPath = null;
      _pendingDurationMs = null;

    } on GptApiException catch (e) {
      // getChatResponseOrThrow 以外のヘルパー経由の GptApiException
      _showApiError(
        'API',
        statusCode: e.statusCode,
        body: e.responseBody,
        error: e.message,
      );
    } catch (e, st) {

      final err = e.toString();
      if (err.contains("RATE_LIMIT")) {
        final retrySec = 60;
        setState(() {
          _messages.removeWhere((msg) => msg['role'] == _thinkingRole);
          _rateLimitResetTime = DateTime.now().add(Duration(seconds: retrySec));
          _hasShownRateLimitError = true;
          _messages.add({'role': 'bot', 'text': loc.errorRateLimit});
        });
        Future.delayed(Duration(seconds: retrySec), () {
          setState(() {
            _rateLimitResetTime = null;
            _hasShownRateLimitError = false;
          });
        });
      } else {
        // 詳細付きエラーバブルを表示（kDebugMode/kReleaseMode 問わず）
        _showApiError('UnhandledError', error: e);
      }
    } finally {
      if (mounted) {
        setState(() {
          // thinking バブルが残っていれば必ず除去してUIを復帰させる
          _messages.removeWhere((msg) => msg['role'] == _thinkingRole);
          _isKeyboardMode = false;
        });
      }
    }
  }

  String _parseAnswer(String? res) {
    if (res == null) return '';
    final s = res.trim();

    // 0) そのまま "1" / "2" のケース
    if (s == '1' || s == '2') return s;

    // 1) ```json ... ``` のようなコードブロックが来た場合に中身だけ抜く
    final codeMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(s);
    final candidate = (codeMatch != null ? codeMatch.group(1) : s)?.trim() ?? '';

    // 2) JSONをまず試す
    try {
      final parsed = jsonDecode(candidate);

      // { "answer": "1" }
      if (parsed is Map && parsed['answer'] != null) {
        final v = parsed['answer'].toString().trim();
        if (v == '1' || v == '2') return v;
      }

      // "1" / 1 など
      if (parsed is String && (parsed == '1' || parsed == '2')) return parsed;
      if (parsed is num && (parsed == 1 || parsed == 2)) return parsed.toString();
    } catch (_) {
      // つづくフォールバックへ
    }

    // 3) フォールバック: "answer": "1" を拾う
    final m = RegExp(r'"?answer"?\s*:\s*"?(1|2)"?').firstMatch(candidate);
    if (m != null) return m.group(1)!;

    // 4) さらに最後の保険: 文中の単独 1/2
    final n = RegExp(r'\b[12]\b').firstMatch(candidate);
    if (n != null) return n.group(0)!;

    return '';
  }

  // 問5：ユーザー入力の翻訳
  Future<void> _handleUserAnswerTranslation(String userText, AppLocalizations loc) async {
    // 1) ユーザー入力の翻訳
    final prompt = PromptBuilders.buildUserAnswerTranslationPrompt(
      userAnswer: userText,
      nativeLang: nativeName,
    );
    final res = await GptService.getChatResponse(prompt, userText, loc);
    final translation = res?.trim() ?? '';

    // 2) 誤答解説を取得
    final explanationPrompt = PromptBuilders.buildIncorrectAnswerExplanationPrompt(
      userAnswer: userText,
      nativeLang: nativeName,
      targetLang: targetName,
    );
    final explRes = await GptService.getChatResponse(
      explanationPrompt,
      userText,
      loc,
    );
    final explanation = explRes?.trim();

    // 3) 翻訳と解説をひとつの吹き出しにまとめて追加
    final buffer = StringBuffer();
    buffer.write(loc.answerMeaningPrefix(translation));
    if (explanation != null &&
        explanation.isNotEmpty &&
        explanation.toLowerCase() != 'null') {
      buffer.write('\n');
      buffer.write(explanation);
    }
    setState(() {
      _messages.add({
        'role': 'bot',
        'text': buffer.toString(),
      });
    });
  }

  Future<void> _handleOriginalQuestionTranslation(
    String questionText,
    AppLocalizations loc, {
    String? rawInput,
    bool useAnswerPrefix = true,
    bool onlyFirstBubble = false,
    bool addAccuracyNoticeBubble = false,  // 追加：通知バブル
    bool addFollowupTumugiReply = false,   // 追加：追従コメントも同時表示
    bool skipFirstBubble = false,          // 追加：①をスキップ
  }) async {
    final pendingBotMessages = <Map<String, dynamic>>[];
    Future<void> flushPendingBotMessages() async {
      await _flushPendingBotMessages(pendingBotMessages);
      pendingBotMessages.clear();
    }

    // ①：模範訳の生成（skipFirstBubble が false の場合のみやる）
    String? translatedText;

    if (!skipFirstBubble) {
      // ① 問6：模範訳の生成
      final prompt6 = PromptBuilders.buildOriginalQuestionTranslationPrompt(
        originalQuestion: questionText,
        targetLang: targetName,
      );
      final String? res6 = await GptService.getChatResponse(
        prompt6,
        questionText,
        loc,
      );
      if (res6 == null) {
        debugPrint('❌ 問6の翻訳に失敗しました');
        if (addFollowupTumugiReply) {
          pendingBotMessages.add({
            'role': 'tumugi',
            'text': _pickTumugiLine(),
            'avatarPath': CharacterAssetService.chatAvatar(_selectedCharacter),
          });
        }
        await flushPendingBotMessages();
        return;
      }
      final translatedForFirst = res6.trim();

      // ——— ここから追加 ———
      // 問10’: オリジナル文の母語での逆翻訳
      final promptNative6 = PromptBuilders.buildSimilarQuestionInNativeLangPrompt(
        translatedText: translatedForFirst,
        nativeLang: nativeName,
      );
      final String? nativeOriginal = await GptService.getChatResponse(
        promptNative6,
        translatedForFirst,
        loc,
      );
      // “null” を捨てる
      final String? nativeOriginalText =
          (nativeOriginal == null || nativeOriginal.toLowerCase() == 'null')
              ? null
              : nativeOriginal.trim();

      // 問12’: オリジナル文の音声転写
      String? rawTrans6;
      if (const {'ja', 'zh', 'zh_tw', 'ko'}.contains(widget.targetLang)) {
        final promptTts6 = PromptBuilders.buildSimilarQuestionTtsPrompt(
          translatedText: translatedForFirst,
          targetLang: widget.targetLang,
        );
        rawTrans6 = await GptService.getChatResponse(
          promptTts6,
          translatedForFirst,
          loc,
        );
      } else {
        rawTrans6 = null;
      }
      final String? transcription6 =
          (rawTrans6 == null || rawTrans6.toLowerCase() == 'null')
              ? null
              : rawTrans6.trim();
      // ——— ここまで追加 ———

      // ①の ChatBubble を追加
      pendingBotMessages.add({
        'role': 'bot',
        'text': useAnswerPrefix
            ? loc.answerMeaningPrefix(translatedForFirst)
            : loc.answerTranslationPrefix,
        'highlightBody': translatedForFirst,   // 本文（例: Nice to meet you.）
        'showAvatar': false,

        'tts': translatedForFirst,
        'showTtsBody': false,              // 本文に重複表示させない

        'targetLang': widget.targetLang,
        // 追加分をもし取れたらキーに含める
        if (nativeOriginalText != null) 'nativeText': nativeOriginalText,
        if (transcription6    != null) 'transcription': transcription6,
      });
    }

    // ★ 正解通知バブル（②以降の”上”に差し込む）
    if (addAccuracyNoticeBubble) {
      pendingBotMessages.add({
        'role': 'bot',
        'text': _selectedCharacter == CharacterAssetService.kasumi
            ? _pickKasumiAccuracyCorrect(loc)
            : _pickTsumugiAccuracyCorrect(loc),
        'labelType': 'info',
      });
    }

    // ✅ 「①だけで終わる」モード
    if (onlyFirstBubble) {
      if (addFollowupTumugiReply) {
        pendingBotMessages.add({
          'role': 'tumugi',
          'text': _pickTumugiLine(),
          'avatarPath': CharacterAssetService.chatAvatar(_selectedCharacter),
        });
      }
      await flushPendingBotMessages();
      return;
    }

    // ②：類似表現
    final String seedForSimilar = (translatedText ?? questionText);
    final avoidList = <String>[];
    if (rawInput != null && rawInput.trim().isNotEmpty) avoidList.add(rawInput);
    if (translatedText != null && translatedText.trim().isNotEmpty) {
      avoidList.add(translatedText);
    }
    String? userRomaji;
    if (_targetCode == 'ja' && rawInput != null && rawInput.trim().isNotEmpty) {
      userRomaji = await _romajiForJapanese(rawInput, loc);
    }

    String? similar = await _generateSimilarExpression(
      seed: seedForSimilar,
      targetLang: targetName,
      loc: loc,
      avoidList: avoidList,
    );

    if (similar == null || similar.trim().isEmpty) {
      debugPrint('❌ 問8の類似表現生成に失敗しました');
      if (addFollowupTumugiReply) {
        pendingBotMessages.add({
          'role': 'tumugi',
          'text': _pickTumugiLine(),
          'avatarPath': CharacterAssetService.chatAvatar(_selectedCharacter),
        });
      }
      await flushPendingBotMessages();
      return;
    }

    String? similarRomaji;
    if (_targetCode == 'ja' && userRomaji != null) {
      similarRomaji = await _romajiForJapanese(similar, loc);
      if (_isSameRomaji(similarRomaji, userRomaji)) {
        final retry = await _generateSimilarExpression(
          seed: seedForSimilar,
          targetLang: targetName,
          loc: loc,
          avoidList: [...avoidList, similar],
        );
        if (retry != null && retry.trim().isNotEmpty) {
          similar = retry;
          similarRomaji = await _romajiForJapanese(similar, loc);
        }
      }
    }

    // ③ 問10：同義の文の母語での訳を生成
    final prompt10 = PromptBuilders.buildSimilarQuestionInNativeLangPrompt(
      translatedText: similar,
      nativeLang: nativeName,
    );

    final String? nativeSimilar = await GptService.getChatResponse(
      prompt10,
      similar,
      loc,
    );

    if (nativeSimilar == null) {
      debugPrint('❌ 問10の母語での訳生成に失敗しました');
      if (addFollowupTumugiReply) {
        pendingBotMessages.add({
          'role': 'tumugi',
          'text': _pickTumugiLine(),
          'avatarPath': CharacterAssetService.chatAvatar(_selectedCharacter),
        });
      }
      await flushPendingBotMessages();
      return;
    }

    // 問12：同義の文の音声転写を作成する
    String? rawTranscription;
    final norm = widget.targetLang.replaceAll('-', '_').toLowerCase();
    if (norm == 'ja' && similarRomaji != null) {
      rawTranscription = similarRomaji;
    } else if (const {'ja', 'zh', 'zh_tw', 'ko'}.contains(norm)) {
      final prompt12 = PromptBuilders.buildSimilarQuestionTtsPrompt(
        translatedText: similar,
        targetLang: widget.targetLang,
      );
      rawTranscription = await GptService.getChatResponse(
        prompt12,
        similar,
        loc,
      );
    } else {
      rawTranscription = null;
    }

    // “null” 文字列は捨てて、その他はそのまま使う
    final String? transcription =
        (rawTranscription == null || rawTranscription.toLowerCase() == 'null')
            ? null
            : rawTranscription;

    // ★ ハイライト本文（類似表現＋転写＋母語訳を全部まとめる）
    final simLines = <String>[];
    simLines.add(similar);                         // 1行目：類似表現
    if (transcription != null && transcription.isNotEmpty) {
      simLines..add('')..add(transcription);      // ラベル不要なら転写だけ
    }
    if (nativeSimilar.isNotEmpty) {
      simLines..add('')..add(nativeSimilar);      // ラベル不要ならそのまま
    }

    // まとめて ChatBubble に表示
    pendingBotMessages.add({
      'role': 'tumugi',
      'text': _selectedCharacter == CharacterAssetService.kasumi
          ? tsumugi_prompt.kasumiSimilarExpressionIntro(_nativeCode)
          : await tsumugi_prompt.tsumugiSimilarExpressionIntro(_nativeCode),
      'avatarPath': CharacterAssetService.chatAvatar(_selectedCharacter),
    });
    pendingBotMessages.add({
      'role': 'bot',

      // 🔶 黄色ハイライト
      'highlightTitle': loc.similarExpressionHeader, // 例: 類似表現
      'highlightBody': simLines.join('\n'),
      'showAvatar': false,

      // TTS は similar のみ
      'tts': similar,
      'showTtsBody': false,

      'targetLang': widget.targetLang,
      // 'nativeText':  nativeSimilar,   // ← ChatBubble で拾って表示
      // transcription が null のときはキーごと省略したい場合は
      // if (transcription != null) 'transcription': transcription,
    });
    if (addFollowupTumugiReply) {
      pendingBotMessages.add({
        'role': 'tumugi',
        'text': _pickTumugiLine(),
        'avatarPath': CharacterAssetService.chatAvatar(_selectedCharacter),
      });
    }
    await flushPendingBotMessages();
  }

  void _cancelInput() {
    _controller.clear();
    setState(() {
      _hasInput = false;
      _isKeyboardMode = false;
    });
  }

  void _resetChat() async {
    await _speechService.stop();
    await _tts.stop(); // ← 追加：念のため現在のTTS停止
    _controller.clear();
    final loc = AppLocalizations.of(context)!;
    _loadQuestion(loc);
    // _speakIfListeningAfterBuild(); // ← 追加
  }

  void _openQuestionListFromRecommend() {
    final scene = widget.recommendedReturnScene ?? widget.scene;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionListScreen(
          selectedScene: scene,
          targetLang: widget.targetLang,
          mode: _mode,
        ),
      ),
    );
  }

  Widget _styledBackButton(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.black87,
        ),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isListening = _mode == QuizMode.listening;
    final canPop = Navigator.of(context).canPop();
    final topInset = MediaQuery.of(context).padding.top + (isListening ? 0 : kToolbarHeight);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: isListening ? 0 : kToolbarHeight,
        leading: (!isListening && canPop)
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _styledBackButton(context),
              )
            : null,
        title: isListening
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _langPill(context, _displayLangCode(widget.nativeLang)), // 例: EN / JA
                      const SizedBox(width: 8),
                      const Icon(Icons.east_rounded, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      _langPill(context, _displayLangCode(widget.targetLang)), // 例: EN / JA
                    ],
                  ),
                ),
              ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image(
              image: AssetImage(CharacterAssetService.chatBackground(_selectedCharacter)),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: topInset),
            child: Column(
              children: [
                Expanded(
                  child: MessageList(
                    messages: _messages,
                    header: _buildChatHeader(),
                    botAvatarPath: CharacterAssetService.chatAvatar(_selectedCharacter),
                    // 日本語学習時のみ VOICEVOX で読み上げ
                    onSpeak: _targetCode == 'ja'
                        ? (text, onStart) => _voicevoxService.speak(
                              text, _selectedCharacter,
                              onPlayStart: onStart,
                              onDailyLimitFallback: _onTtsDailyLimitFallback,
                            )
                        : null,
                  ),
                ),
                // 採点後「もう一回言う」ボタン
                if (_hasSubmitted)
                  TextButton.icon(
                    onPressed: _resetChat,
                    icon: const Text('🔄', style: TextStyle(fontSize: 16)),
                    label: Text(
                      AppLocalizations.of(context)!.retryButton,
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.pink.shade300,
                    ),
                  ),
                // 残り回数バナー（無料ユーザーのみ・日本語学習時のみ）
                if (_targetCode == 'ja')
                  _TtsRemainingBanner(
                    remainingNotifier: _voicevoxService.remainingNotifier,
                    isPremiumNotifier: _voicevoxService.isPremiumNotifier,
                    nativeCode: _nativeCode,
                  ),
                MicArea(
                  isListening: _isListening,
                  isKeyboardMode: _isKeyboardMode,
                  hasInput: _hasInput,
                  hasSubmitted: _hasSubmitted,
                  waveformSamples: _ampQueue.toList(),
                  controller: _controller,
                  onMicTap: _isListening ? _confirmRecording : _startListening,
                  onRecordCancel: _cancelRecording,
                  onRecordConfirm: _confirmRecording,
                  onKeyboardTap: _activateKeyboardMode,
                  onSend: () {
                    setState(() => _revealListeningText = true); // ★ここで解除
                    _sendMessage();
                  },
                  onCancel: _cancelInput,
                  onReset: _resetChat,          // ← リロード時に再生も入れてある版
                  onNext: _loadNextQuestion,    // ← 次へで再生も入れてある版
                  onTextChanged: (text) => setState(() {
                    _hasInput = text.trim().isNotEmpty;
                  }),
                  focusNode: _inputFocusNode,
                  onDone: () {
                    if (_controller.text.trim().isEmpty) {
                      _cancelInput();
                    } else {
                      _speechService.stop(); // 念のためマイク停止
                      setState(() {
                        _isKeyboardMode = false;
                        _isListening    = false;
                      });
                    }
                  },
                ),

                KeyboardGuideButton(targetLanguage: widget.targetLang),
              ],
            ),
          ),
          if (isListening && canPop)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _styledBackButton(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandablePromptText extends StatelessWidget {
  const _ExpandablePromptText({
    required this.text,
    required this.isExpanded,
    required this.maxLines,
    required this.expandLabel,
    required this.style,
  });

  final String text;
  final bool isExpanded;
  final int maxLines;
  final String expandLabel;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = painter.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: style,
              maxLines: isExpanded ? null : maxLines,
              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (!isExpanded && isOverflowing)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  expandLabel,
                  style: style.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PromptBubbleTailPainter extends CustomPainter {
  const _PromptBubbleTailPainter({
    required this.fillColor,
    required this.borderColor,
  });

  final Color fillColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = borderColor;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _PromptBubbleTailPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}

/// 無料ユーザー向け VOICEVOX 残り回数バナー
/// isPremiumNotifier が true のとき、または残り回数が未取得のときは非表示。
class _TtsRemainingBanner extends StatelessWidget {
  const _TtsRemainingBanner({
    required this.remainingNotifier,
    required this.isPremiumNotifier,
    required this.nativeCode,
  });

  final ValueNotifier<int?> remainingNotifier;
  final ValueNotifier<bool?> isPremiumNotifier;
  final String nativeCode;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
      valueListenable: isPremiumNotifier,
      builder: (context, isPremium, _) {
        // プレミアムユーザーは表示しない
        if (isPremium == true) return const SizedBox.shrink();
        return ValueListenableBuilder<int?>(
          valueListenable: remainingNotifier,
          builder: (context, remaining, _) {
            if (remaining == null) return const SizedBox.shrink();
            const limit = 30;
            final label = nativeCode == 'ja' ? '残り' : 'Left';
            return Container(
              width: double.infinity,
              color: Colors.black26,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: Text(
                '🎙 $label $remaining/$limit',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.right,
              ),
            );
          },
        );
      },
    );
  }
}
