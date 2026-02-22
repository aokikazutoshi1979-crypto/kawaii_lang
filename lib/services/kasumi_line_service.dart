import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// 香澄のカテゴリ画面セリフサービス（ツンデレ・照れ屋・根は優しい）
class KasumiLineService {
  KasumiLineService._();
  static final KasumiLineService instance = KasumiLineService._();
  static final Random _rand = Random();

  static const String _lastDateKey = 'lastKasumiLineDate';
  static const String _lineIndexKey = 'todayKasumiLineIndex';
  static const String _lineBucketKey = 'todayKasumiLineBucket';

  static const Map<String, List<String>> _lines = {
    'ja': [
      // normal
      '別に急かしてるわけじゃないけど…せっかく来たし、一言練習してみる？',
      'ちょっとだけ時間ある？短くていいから、一緒に話してみよう。',
      'むっ、やらないの？…やってみた方が絶対いいよ。短くていいから。',
      // free
      'お試し中でも、雰囲気はわかるでしょ。一言だけやってみて？',
      'まず気軽にやってみなよ。続けたくなったら…また来てくれると、まあ、嬉しいけど。',
      '今日はお試しでも十分だよ。…また来てね。待ってるから、一応。',
      // night
      '夜は無理しないで。1分だけでも、今日は十分だよ。',
      'もう遅いし、無理しなくていいよ。…また明日、来てね。',
      '遅い時間だし、短い一言だけにしとこ。…一緒にやろうか。',
    ],
    'en': [
      "It's not like I wanted you to practice or anything… but since you're here, one line?",
      "You have a minute? Let's do something short together. No big deal.",
      "...You're not going to try? Fine. One line. It won't take long.",
      "Even in trial mode you can get the feel for it. Just try one line.",
      "Start easy. If you want to keep going… well, I wouldn't mind.",
      "Today's trial is enough. …Come back, okay? Not that I care.",
      "Don't push it tonight. Even one minute today is plenty.",
      "It's late, so don't overdo it. …Come back tomorrow, okay?",
      "It's late so let's keep it short. …One quick line together?",
    ],
    'ko': [
      "별로 기다린 건 아닌데…왔으니까 한마디 연습할래?",
      "잠깐 시간 있어? 짧아도 되니까 같이 말해보자.",
      "안 할 거야?…꼭 해보는 게 나아. 짧은 거라도.",
      "체험 중이라도 느낌은 알 수 있잖아. 한마디만 해봐?",
      "일단 가볍게 해봐. 계속하고 싶으면…또 오면 뭐, 기쁘긴 하지.",
      "오늘은 체험만으로도 충분해. …또 와줘. 기다리고 있을 거야.",
      "밤에는 무리하지 마. 1분만 해도 오늘은 충분해.",
      "늦었으니까 무리하지 마. …내일 또 와줘.",
      "늦은 시간이니까 짧은 한마디만. …같이 해볼까.",
    ],
    'zh': [
      "我可不是在等你或什么的…但既然来了，说一句练习一下？",
      "有一点时间吗？短的就好，一起说说吧。",
      "不做吗？…做了肯定更好。短的就行。",
      "体验版也能感受到氛围啦。试一句好吗？",
      "先随便试试吧。想继续的话…再来，也挺好的。",
      "今天体验一下也够了。…再来哦。不是说我等你，就是随便说说。",
      "晚上别太勉强。就一分钟，今天这样就够了。",
      "已经很晚了，别硬撑。…明天再来吧。",
      "时间晚了就说一句短的好了。…一起来？",
    ],
    'zh_TW': [
      "我可不是在等你之類的…但既然來了，說一句練習看看？",
      "有一點時間嗎？短的就好，一起說說吧。",
      "不做嗎？…做了肯定更好。短的就行。",
      "體驗版也能感受到氛圍啦。試一句好嗎？",
      "先隨便試試吧。想繼續的話…再來，也挺好的。",
      "今天體驗一下也夠了。…再來喔。不是說我等你，就是隨便說說。",
      "晚上別太勉強。就一分鐘，今天這樣就夠了。",
      "已經很晚了，別硬撐。…明天再來吧。",
      "時間晚了就說一句短的好了。…一起來？",
    ],
    'es': [
      "No es que estuviera esperándote o algo así… pero ya que estás, ¿una frase?",
      "¿Tienes un momento? Algo corto. Sin presión.",
      "¿No vas a intentarlo? …Venga, una frase. No te llevará mucho.",
      "Incluso en modo de prueba se puede captar el ambiente. ¿Una frase?",
      "Empieza con algo fácil. Si quieres continuar… bueno, no me importaría.",
      "Con el modo de prueba de hoy ya está bien. …Vuelve, ¿sí? No es que me importe.",
      "No te esfuerces de noche. Con un minuto hoy es suficiente.",
      "Es tarde. No te fuerces. …Vuelve mañana, ¿eh?",
      "Ya es tarde, así que algo breve. …¿Una línea juntas?",
    ],
    'fr': [
      "C'est pas que je t'attendais ou quoi… mais puisque tu es là, une phrase ?",
      "T'as une minute ? Quelque chose de court. Pas de pression.",
      "Tu vas pas essayer ? …Allez, une phrase. Ça prendra pas longtemps.",
      "Même en mode d'essai, on sent bien l'ambiance. Une phrase ?",
      "Commence par quelque chose de facile. Si tu veux continuer… bon, ça m'est égal.",
      "Avec le mode d'essai d'aujourd'hui c'est bien. …Reviens, hein ? Pas que ça me touche.",
      "T'en fais pas trop le soir. Une minute aujourd'hui c'est amplement suffisant.",
      "Il est tard. Force pas. …Reviens demain, d'accord ?",
      "Il est tard, donc quelque chose de court. …Une ligne ensemble ?",
    ],
    'de': [
      "Ich hab' nicht auf dich gewartet oder so… aber nun, da du da bist, eine Zeile?",
      "Hast du eine Minute? Was Kurzes. Kein Druck.",
      "Du versuchst's nicht? …Na gut, eine Zeile. Dauert nicht lang.",
      "Selbst im Testmodus spürt man die Atmosphäre. Eine Zeile?",
      "Fang locker an. Wenn du weitermachen willst… mir wäre das recht.",
      "Mit dem heutigen Test ist es schon gut. …Komm wieder, ja? Nicht dass mir's was ausmacht.",
      "Überanstreng dich nicht abends. Eine Minute heute reicht völlig.",
      "Es ist spät. Überfordere dich nicht. …Komm morgen wieder, okay?",
      "Es ist spät, also was Kurzes. …Eine Zeile zusammen?",
    ],
    'vi': [
      "Không phải là mình đang đợi bạn hay gì đó… nhưng đã đến rồi thì nói một câu nhé?",
      "Bạn có một phút không? Ngắn thôi. Không áp lực.",
      "Bạn không thử sao? …Thôi, một câu đi. Không lâu đâu.",
      "Dù chế độ thử cũng cảm nhận được không khí mà. Một câu nhé?",
      "Bắt đầu nhẹ thôi. Nếu muốn tiếp… mình không phản đối.",
      "Hôm nay thử thế này là đủ rồi. …Quay lại nhé? Không phải mình quan tâm gì.",
      "Buổi tối đừng cố quá. Một phút hôm nay là đủ lắm rồi.",
      "Muộn rồi. Đừng ép bản thân. …Ngày mai quay lại nhé?",
      "Muộn rồi nên ngắn thôi. …Một câu cùng nhau nhé?",
    ],
    'id': [
      "Bukan berarti aku menunggumu ya… tapi sudah di sini, satu kalimat saja?",
      "Punya semenit? Yang pendek saja. Tak perlu tekanan.",
      "Tidak mau coba? …Satu kalimat saja. Tidak lama kok.",
      "Meski mode coba, nuansanya sudah terasa. Satu kalimat?",
      "Mulai yang mudah saja. Kalau mau lanjut… ya, tak keberatan.",
      "Hari ini cukup mode coba-cobanya. …Balik lagi ya? Bukan karena aku peduli.",
      "Jangan terlalu memaksakan diri malam-malam. Semenit hari ini sudah cukup.",
      "Sudah malam. Jangan dipaksakan. …Besok balik lagi ya?",
      "Malam sudah, jadi yang pendek saja. …Satu kalimat bareng?",
    ],
  };

  Future<String> getLine({
    required bool hasSubscription,
    required String langCode,
    DateTime? now,
  }) async {
    final DateTime current = now ?? DateTime.now();
    final String today =
        '${current.year.toString().padLeft(4, '0')}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();

    final savedDate = prefs.getString(_lastDateKey);
    if (savedDate == today) {
      final savedBucket = prefs.getInt(_lineBucketKey) ?? 0;
      final savedIndex = prefs.getInt(_lineIndexKey) ?? 0;
      return _lineByBucketIndex(langCode, savedBucket, savedIndex);
    }

    final bucket = _resolveBucket(now: current, hasSubscription: hasSubscription);
    final index = _rand.nextInt(3);

    await prefs.setString(_lastDateKey, today);
    await prefs.setInt(_lineIndexKey, index);
    await prefs.setInt(_lineBucketKey, bucket);

    return _lineByBucketIndex(langCode, bucket, index);
  }

  int _resolveBucket({required DateTime now, required bool hasSubscription}) {
    if (now.hour >= 21) return 2; // night
    if (!hasSubscription) return 1; // free
    return 0; // normal
  }

  String _lineByBucketIndex(String langCode, int bucket, int index) {
    final key = _resolveKey(langCode);
    final all = _lines[key] ?? _lines['en']!;
    // 0=normal(0-2), 1=free(3-5), 2=night(6-8)
    final base = bucket * 3;
    final i = (base + index).clamp(0, all.length - 1);
    return all[i];
  }

  String _resolveKey(String langCode) {
    final norm = langCode.replaceAll('-', '_');
    if (_lines.containsKey(norm)) return norm;
    final base = norm.split('_').first;
    if (_lines.containsKey(base)) return base;
    return 'en';
  }
}
