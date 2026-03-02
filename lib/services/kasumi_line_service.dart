import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// 香澄のカテゴリ画面セリフサービス（ツンデレ・照れ屋・根は優しい）
class KasumiLineService {
  KasumiLineService._();
  static final KasumiLineService instance = KasumiLineService._();
  static final Random _rand = Random();

  static const String _recentHistoryPrefix = 'kasumiRecentLineHistory';
  static const int _repeatGap = 3;

  static const Map<String, List<String>> _lines = {
    'ja': [
      // normal
      '別に急かしてるわけじゃないけど…せっかく来たし、一言練習してみる？',
      'ちょっとだけ時間ある？短くていいから、一緒に話してみよう。',
      'むっ、やらないの？…やってみた方が絶対いいよ。短くていいから。',
      // free
      'お試し中でも、雰囲気はわかるでしょ。一言だけやってみて？',
      'まずは軽くやってみなよ。続けたくなったら…また来ればいいでしょ。',
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
      "Just start with something easy. If you feel like continuing… I guess I wouldn't mind.",
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
      "일단 가볍게 시작해. 더 하고 싶어지면… 뭐, 또 와도 돼.",
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
      "先轻松试试看吧。要是还想继续…再来也行。",
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
      "先輕鬆試試看吧。要是還想繼續…再來也行。",
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
      "Empieza con algo sencillo. Si luego quieres seguir… bueno, no me molesta.",
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
      "Commence tranquillement. Si tu veux continuer après… enfin, ça me va.",
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
      "Fang locker an. Wenn du danach weitermachen willst… na ja, meinetwegen.",
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
      "Cứ bắt đầu nhẹ nhàng thôi. Nếu muốn học tiếp… thì quay lại cũng được.",
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
      "Mulai santai saja dulu. Kalau nanti mau lanjut… ya, datang lagi juga boleh.",
      "Hari ini cukup mode coba-cobanya. …Balik lagi ya? Bukan karena aku peduli.",
      "Jangan terlalu memaksakan diri malam-malam. Semenit hari ini sudah cukup.",
      "Sudah malam. Jangan dipaksakan. …Besok balik lagi ya?",
      "Malam sudah, jadi yang pendek saja. …Satu kalimat bareng?",
    ],
  };

  static const List<String> _jaExtraFreeLines = [
    'まずは軽く一言でいいから。…別に期待してるわけじゃないけど。',
    '気負わなくていいって。短いのでいいから、先にやってみなさい。',
    'とりあえず一回だけでもやってみて。続きはそのあと考えればいいでしょ。',
    '最初はサクッとで十分よ。気に入ったら、また来ればいいだけ。',
    'お試しなんだから、難しく考えないで。まず一言、ね？',
    '一言だけならすぐ終わるし。…やってみても損はないでしょ。',
    '迷ってる時間がもったいないわ。まずは軽く口に出してみなさい。',
    '今日はお試し感覚でいいの。続けたくなったら、そのときまた来なさい。',
    '今日は体験だけで十分よ。気が向いたら、また来ればいいでしょ。',
    'お試しで一回やれたなら上出来。…次も来るかは、あなた次第ね。',
    '今日は軽く触るだけでもOK。続けたくなったら、また付き合ってあげる。',
    '体験だけで終わってもいいわ。…でも、また来たらちょっと嬉しいかも。',
    '今日はお試し分だけで切り上げても大丈夫。次やるなら、ちゃんと見てあげる。',
  ];

  Future<String> getLine({
    required bool hasSubscription,
    required String langCode,
    DateTime? now,
  }) async {
    final DateTime current = now ?? DateTime.now();
    final key = _resolveKey(langCode);
    final bucket = _resolveBucket(now: current, hasSubscription: hasSubscription);
    final candidates = _bucketLines(key, bucket);
    if (candidates.isEmpty) return (_lines['en'] ?? const ['...']).first;

    final prefs = await SharedPreferences.getInstance();
    final historyKey = _historyKey(key, bucket);
    final recent = _loadRecentIndices(
      prefs.getString(historyKey),
      candidateCount: candidates.length,
    );
    final pickedIndex = _pickIndexWithGap(
      candidateCount: candidates.length,
      recent: recent,
    );
    final updated = <int>[...recent, pickedIndex];
    final maxKeep = _repeatGap * 2;
    final trimmed = updated.length > maxKeep
        ? updated.sublist(updated.length - maxKeep)
        : updated;
    await prefs.setString(
      historyKey,
      trimmed.map((e) => e.toString()).join(','),
    );

    return candidates[pickedIndex];
  }

  int _resolveBucket({required DateTime now, required bool hasSubscription}) {
    if (now.hour >= 21) return 2; // night
    if (!hasSubscription) return 1; // free
    return 0; // normal
  }

  List<String> _bucketLines(String key, int bucket) {
    final all = _lines[key] ?? _lines['en']!;
    if (all.length < 9) return all;

    switch (bucket) {
      case 0:
        return all.sublist(0, 3); // normal
      case 1:
        return key == 'ja'
            ? [...all.sublist(3, 6), ..._jaExtraFreeLines]
            : all.sublist(3, 6); // free
      case 2:
        return all.sublist(6, 9); // night
      default:
        return all.sublist(0, 3);
    }
  }

  String _historyKey(String key, int bucket) {
    return '$_recentHistoryPrefix:$key:$bucket';
  }

  List<int> _loadRecentIndices(String? raw, {required int candidateCount}) {
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .where((i) => i >= 0 && i < candidateCount)
        .toList();
  }

  int _pickIndexWithGap({
    required int candidateCount,
    required List<int> recent,
  }) {
    if (candidateCount <= 1) return 0;

    final recentWindow = recent.length <= _repeatGap
        ? recent
        : recent.sublist(recent.length - _repeatGap);
    final blocked = <int>{};
    if (candidateCount > _repeatGap) {
      blocked.addAll(recentWindow);
    } else if (recentWindow.isNotEmpty) {
      // 候補が少なく「3回空ける」が物理的に不可能な場合は、最低でも連続一致を避ける。
      blocked.add(recentWindow.last);
    }

    var pool = <int>[
      for (var i = 0; i < candidateCount; i++)
        if (!blocked.contains(i)) i,
    ];
    if (pool.isEmpty) {
      final last = recentWindow.isNotEmpty ? recentWindow.last : -1;
      pool = <int>[
        for (var i = 0; i < candidateCount; i++)
          if (i != last) i,
      ];
      if (pool.isEmpty) return 0;
    }
    return pool[_rand.nextInt(pool.length)];
  }

  String _resolveKey(String langCode) {
    final norm = langCode.replaceAll('-', '_');
    if (_lines.containsKey(norm)) return norm;
    final base = norm.split('_').first;
    if (_lines.containsKey(base)) return base;
    return 'en';
  }
}
