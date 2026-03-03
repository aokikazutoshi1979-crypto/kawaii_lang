import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

String buildTsumugiPrompt({
  required String uiLanguageCode,
  required String promptText,
  required String targetLanguageName,
}) {
  final prompt = promptText.trim();
  final target = targetLanguageName.trim();
  if (prompt.isEmpty) return '';

  final lang = _norm(uiLanguageCode);
  final rnd = Random();

  final templates = _templatesFor(lang);
  final tmpl = templates[rnd.nextInt(templates.length)];
  return tmpl
      .replaceAll('{prompt}', prompt)
      .replaceAll('{target}', target.isEmpty ? 'English' : target);
}

String buildTsumugiQuestionLine({
  required String uiLanguageCode,
  required String targetLanguageName,
}) {
  final target = targetLanguageName.trim();
  final lang = _norm(uiLanguageCode);
  final rnd = Random();
  final templates = _questionLineTemplates(lang);
  final tmpl = templates[rnd.nextInt(templates.length)];
  return tmpl.replaceAll('{target}', target.isEmpty ? 'English' : target);
}

String formatPromptQuote(String uiLanguageCode, String promptText) {
  final prompt = promptText.trim();
  if (prompt.isEmpty) return '';
  final lang = _norm(uiLanguageCode);
  if (lang == 'ja' || lang == 'zh' || lang == 'zh_tw') {
    return '「$prompt」';
  }
  return '"$prompt"';
}

List<String> tsumugiPraiseLines(String uiLanguageCode) {
  switch (_norm(uiLanguageCode)) {
    case 'ja':
      return const [
        'すごい、自然に聞こえたよ。',
        'いいね、ちゃんと伝わったよ☺️',
        'いい調子だよ。',
        '発音、よくなってきてるよ！前より自信が出てきたね。',
        'それ、日本人に通じる言い方だよ☺️',
        '完璧じゃなくても大丈夫。伝わることが大事だよ。',
        'ゆっくりでよかったんだよ。ちゃんと聞こえたよ☺️',
      ];
    case 'ko':
      return const [
        '좋아, 자연스럽게 들렸어.',
        '잘했어, 충분히 전달됐어☺️',
        '멋져! 계속 해보자.',
      ];
    case 'zh':
      return const [
        '很好，听起来很自然。',
        '不错，意思传达到了☺️',
        '太棒了，继续吧。',
      ];
    case 'zh_tw':
      return const [
        '很好，聽起來很自然。',
        '不錯，意思有傳達到☺️',
        '太棒了，繼續吧。',
      ];
    case 'es':
      return const [
        'Genial, sonó natural.',
        'Muy bien, se entendió☺️',
        '¡Perfecto, sigue así!',
      ];
    case 'fr':
      return const [
        'Super, ça sonnait naturel.',
        'Très bien, c\'était clair☺️',
        'Parfait, continue comme ça.',
      ];
    case 'de':
      return const [
        'Super, das klang natürlich.',
        'Sehr gut, das kam rüber☺️',
        'Perfekt, mach weiter so.',
      ];
    case 'vi':
      return const [
        'Tuyệt, nghe tự nhiên lắm.',
        'Rất ổn, truyền đạt tốt rồi☺️',
        'Hoàn hảo, tiếp tục nhé.',
      ];
    case 'id':
      return const [
        'Bagus, terdengar natural.',
        'Hebat, pesannya tersampaikan☺️',
        'Mantap, lanjut ya.',
      ];
    case 'en':
    default:
      return const [
        'Nice! That came through.',
        'Great — that sounded natural.',
        'Awesome! Keep going.',
        'Perfect!',
        'Yes! You nailed it.',
        'Your pronunciation is getting better — I can really hear it!',
        'A real Japanese person would understand that perfectly☺️',
        "It doesn't have to be perfect. You got the meaning across!",
        'Taking your time is totally fine. I heard you clearly☺️',
      ];
  }
}

String tsumugiNextPrompt(String uiLanguageCode) {
  switch (_norm(uiLanguageCode)) {
    case 'ja':
      return '次に行こうか？';
    case 'ko':
      return '다음으로 가볼까?';
    case 'zh':
      return '要不要试试下一题？';
    case 'zh_tw':
      return '要不要試試下一題？';
    case 'es':
      return '¿Vamos con la siguiente?';
    case 'fr':
      return 'On passe à la suivante ?';
    case 'de':
      return 'Weiter zur nächsten?';
    case 'vi':
      return 'Sang câu tiếp theo nhé?';
    case 'id':
      return 'Lanjut ke yang berikutnya?';
    case 'en':
    default:
      return 'Ready for the next one?';
  }
}

String tsumugiSentenceJoiner(String uiLanguageCode) {
  final lang = _norm(uiLanguageCode);
  if (lang == 'ja' || lang == 'zh' || lang == 'zh_tw') return '';
  return ' ';
}

String tsumugiNamePrefix(String uiLanguageCode, String? displayName) {
  final name = (displayName ?? '').trim();
  if (name.isEmpty) return '';
  switch (_norm(uiLanguageCode)) {
    case 'ja':
      return '$nameさん、';
    case 'ko':
      return '$name님, ';
    case 'zh':
    case 'zh_tw':
      return '$name，';
    case 'es':
    case 'fr':
    case 'de':
    case 'vi':
    case 'id':
    case 'en':
    default:
      return '$name, ';
  }
}

List<String> _templatesFor(String lang) {
  switch (lang) {
    case 'ja':
      return [
        '「{prompt}」って{target}でどう言うのかな？よかったら教えてね☺️',
        '「{prompt}」を{target}で言ってみてくれる？ゆっくりで大丈夫だよ。',
        '{target}で「{prompt}」って言える？一緒にやってみよう☺️',
      ];
    case 'en':
    default:
      return [
        'How do you say \"{prompt}\" in {target}? I\'d love to know! ☺️',
        'Could you try \"{prompt}\" in {target}? Take your time.',
        'Can you say \"{prompt}\" in {target}? I\'m cheering for you☺️',
      ];
  }
}

List<String> _questionLineTemplates(String lang) {
  switch (lang) {
    case 'ja':
      return [
        '{target}でどう言うのかな？よかったら教えてね☺️',
        'ゆっくりで大丈夫だよ。{target}で言ってみてくれる？',
        '{target}で言えるかな？一緒にやってみよう☺️',
      ];
    case 'en':
      return [
        'Quick one ☺️ How do you say this in {target}?',
        'Take your time — can you say it in {target}?',
        'Could you try it in {target}? I\'d love to know! ☺️',
      ];
    case 'ko':
      return [
        '{target}로 어떻게 말할까? 알려줘☺️',
        '천천히 해도 괜찮아. {target}로 말해볼래?',
        '{target}로 말할 수 있을까? 함께 해보자☺️',
      ];
    case 'zh':
      return [
        '{target}里怎么说呢？告诉我吧☺️',
        '慢慢来也可以。用{target}说说看？',
        '用{target}能说出来吗？一起试试☺️',
      ];
    case 'zh_tw':
      return [
        '{target}要怎麼說呢？告訴我吧☺️',
        '慢慢來也可以。用{target}說說看？',
        '用{target}能說出來嗎？一起試試☺️',
      ];
    case 'es':
      return [
        '¿Cómo se dice en {target}? ¡Cuéntame☺️',
        'Puedes ir despacio. ¿Lo intentas en {target}?',
        '¿Te animas a decirlo en {target}? ☺️',
      ];
    case 'fr':
      return [
        'Comment on dit en {target} ? Dis‑moi☺️',
        'Prends ton temps. Tu peux essayer en {target} ?',
        'Tu veux le dire en {target} ? ☺️',
      ];
    case 'de':
      return [
        'Wie sagt man das auf {target}? Sag\'s mir☺️',
        'Lass dir Zeit. Versuch es auf {target}?',
        'Magst du es auf {target} sagen? ☺️',
      ];
    case 'vi':
      return [
        'Nói thế này bằng {target} thế nào nhỉ? Cho mình biết nhé☺️',
        'Cứ từ từ nhé. Bạn thử nói bằng {target} được không?',
        'Bạn có thể nói bằng {target} không? Cùng thử nhé☺️',
      ];
    case 'id':
      return [
        'Bagaimana mengucapkannya dalam {target}? Ceritakan ya☺️',
        'Pelan-pelan saja. Coba ucapkan dalam {target}, ya?',
        'Bisa bilangnya dalam {target}? Ayo coba☺️',
      ];
    default:
      return [
        'How do you say this in {target}?',
        'Can you try it in {target}?',
        'Take your time — try it in {target}.',
      ];
  }
}

String _norm(String s) => s.replaceAll('-', '_').toLowerCase();

// ─────────────────────────────────────────────
// 香澄（ツンデレ・照れ屋・根は優しい）版
// ─────────────────────────────────────────────

String buildKasumiQuestionLine({
  required String uiLanguageCode,
  required String targetLanguageName,
}) {
  final target = targetLanguageName.trim();
  final lang = _norm(uiLanguageCode);
  final rnd = Random();
  final templates = _kasumiQuestionLineTemplates(lang);
  final tmpl = templates[rnd.nextInt(templates.length)];
  return tmpl.replaceAll('{target}', target.isEmpty ? 'English' : target);
}

List<String> kasumiPraiseLines(String uiLanguageCode) {
  switch (_norm(uiLanguageCode)) {
    case 'ja':
      return const [
        'ちゃんとできてるじゃない。…少し見直したかも。',
        'ま、まあ悪くなかったよ。次も行こ？',
        'べ、別に感動したわけじゃないけど。よかったよ。',
      ];
    case 'ko':
      return const [
        '제법 잘하네. …조금 다시 봤어.',
        '뭐, 나쁘지는 않았어. 다음 가자?',
        '감동받은 건 아닌데. 잘했어.',
      ];
    case 'zh':
      return const [
        '还行嘛。…稍微对你改观了一点。',
        '嗯，还不错。下一题？',
        '我又没有感动什么的。挺好的。',
      ];
    case 'zh_tw':
      return const [
        '還行嘛。…稍微對你改觀了一點。',
        '嗯，還不錯。下一題？',
        '我又沒有感動什麼的。挺好的。',
      ];
    case 'es':
      return const [
        'Nada mal. …Quizá te subestimé un poco.',
        'Bu-bueno, no estuvo mal. ¿Siguiente?',
        'No estoy impresionada ni nada. Pero… bien hecho.',
      ];
    case 'fr':
      return const [
        'Pas mal du tout. …J\'ai peut-être un peu sous-estimé.',
        'Bo-bon, c\'était correct. La suivante ?',
        'Je suis pas impressionnée hein. Mais… bien joué.',
      ];
    case 'de':
      return const [
        'Gar nicht schlecht. …Vielleicht hab ich dich unterschätzt.',
        'N-na gut, das war okay. Nächste?',
        'Ich bin nicht beeindruckt oder so. Aber… gut gemacht.',
      ];
    case 'vi':
      return const [
        'Không tệ đâu. …Mình có thể đã đánh giá thấp bạn.',
        'Thôi được, không tệ. Câu tiếp?',
        'Mình không ấn tượng hay gì. Nhưng… làm tốt đấy.',
      ];
    case 'id':
      return const [
        'Lumayan juga. …Mungkin aku terlalu meremehkanmu.',
        'Y-ya, tidak buruk. Selanjutnya?',
        'Bukan berarti aku terkesan ya. Tapi… bagus.',
      ];
    case 'en':
    default:
      return const [
        "Not bad at all… I might've underestimated you.",
        "W-well, that wasn't too bad. Next one?",
        "I'm not impressed or anything. But… good job.",
      ];
  }
}

String kasumiNextPrompt(String uiLanguageCode) {
  switch (_norm(uiLanguageCode)) {
    case 'ja':
      return '次は？';
    case 'ko':
      return '다음은?';
    case 'zh':
      return '下一题？';
    case 'zh_tw':
      return '下一題？';
    case 'es':
      return '¿Siguiente?';
    case 'fr':
      return 'La suivante ?';
    case 'de':
      return 'Nächste?';
    case 'vi':
      return 'Câu tiếp?';
    case 'id':
      return 'Selanjutnya?';
    case 'en':
    default:
      return 'Next one?';
  }
}

// ─────────────────────────────────────────────
// 正解案内セリフ（不正解時の黄色バブルの前に表示）
// ─────────────────────────────────────────────

String tsumugiCorrectAnswerIntro(String uiLanguageCode) {
  final lang = _norm(uiLanguageCode);
  final rnd = Random();
  final lines = _tsumugiCorrectIntroLines(lang);
  return lines[rnd.nextInt(lines.length)];
}

String kasumiCorrectAnswerIntro(String uiLanguageCode) {
  final lang = _norm(uiLanguageCode);
  final rnd = Random();
  final lines = _kasumiCorrectIntroLines(lang);
  return lines[rnd.nextInt(lines.length)];
}

List<String> _tsumugiCorrectIntroLines(String lang) {
  switch (lang) {
    case 'ja':
      return [
        'こっちが正解だよ☺️',
        'こう言えると完璧！',
        '正解はこれだよ〜',
      ];
    case 'ko':
      return [
        '이게 정답이야☺️',
        '이렇게 하면 완벽해!',
        '정답은 이거야~',
      ];
    case 'zh':
      return [
        '这才是正确答案☺️',
        '这样说就对啦！',
        '正确答案在这里~',
      ];
    case 'zh_tw':
      return [
        '這才是正確答案☺️',
        '這樣說就對啦！',
        '正確答案在這裡~',
      ];
    case 'es':
      return [
        '¡Aquí está la respuesta correcta☺️',
        '¡Así es como se dice!',
        '¡Esta es la respuesta correcta~',
      ];
    case 'fr':
      return [
        'Voilà la bonne réponse☺️',
        'C\'est comme ça qu\'on le dit !',
        'La bonne réponse, c\'est ça~',
      ];
    case 'de':
      return [
        'Das ist die richtige Antwort☺️',
        'So sagt man es richtig!',
        'Die Antwort ist diese~',
      ];
    case 'vi':
      return [
        'Đây là câu trả lời đúng☺️',
        'Nói như thế này là đúng rồi!',
        'Câu trả lời đúng là đây~',
      ];
    case 'id':
      return [
        'Ini jawaban yang benar☺️',
        'Begini cara yang tepat!',
        'Ini jawabannya~',
      ];
    case 'en':
    default:
      return [
        'Here\'s the right answer☺️',
        'This is how it goes!',
        'Try this one next time~',
      ];
  }
}

List<String> _kasumiCorrectIntroLines(String lang) {
  switch (lang) {
    case 'ja':
      return [
        '…これが正解よ。覚えておいてよね。',
        'ちゃんと覚えてよね。',
        '正解はこっちよ。次は間違えないで。',
      ];
    case 'ko':
      return [
        '…이게 정답이야. 잘 기억해둬.',
        '제대로 기억해둬.',
        '정답은 이거야. 다음엔 틀리지 마.',
      ];
    case 'zh':
      return [
        '…这才是正确答案。记住了。',
        '好好记住了。',
        '正确答案是这个。下次别搞错了。',
      ];
    case 'zh_tw':
      return [
        '…這才是正確答案。記住了。',
        '好好記住了。',
        '正確答案是這個。下次別搞錯了。',
      ];
    case 'es':
      return [
        '…Esta es la respuesta correcta. Recuérdalo.',
        'Memoriza esto bien.',
        'La respuesta correcta es esta. La próxima no te equivoques.',
      ];
    case 'fr':
      return [
        '…Voilà la bonne réponse. Retiens-le.',
        'Mémorise ça bien.',
        'C\'est la bonne réponse. La prochaine fois, ne te trompe pas.',
      ];
    case 'de':
      return [
        '…Das ist die richtige Antwort. Merk dir das.',
        'Präg dir das gut ein.',
        'Die richtige Antwort ist diese. Nächstes Mal kein Fehler.',
      ];
    case 'vi':
      return [
        '…Đây là câu trả lời đúng. Nhớ nhé.',
        'Nhớ lấy điều này.',
        'Câu trả lời đúng là đây. Lần sau đừng sai nữa.',
      ];
    case 'id':
      return [
        '…Ini jawaban yang benar. Ingat ya.',
        'Ingat-ingat ini baik-baik.',
        'Jawaban yang benar adalah ini. Jangan salah lagi ya.',
      ];
    case 'en':
    default:
      return [
        '…This is the right one. Don\'t forget.',
        'At least remember this much.',
        'Here. The correct answer. No more mistakes.',
      ];
  }
}

// ─────────────────────────────────────────────
// 類似表現案内セリフ（正解時の黄色バブルの前に表示）
// ─────────────────────────────────────────────

Future<String> tsumugiSimilarExpressionIntro(String uiLanguageCode) async {
  final lang = _norm(uiLanguageCode);
  final lines = _tsumugiSimilarIntroLines(lang);
  const historyKey = 'tsumugiSimilarIntroHistory';
  const repeatGap = 3;
  final rnd = Random();

  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(historyKey) ?? '';
  final recent = raw.isEmpty
      ? <int>[]
      : raw
          .split(',')
          .map((s) => int.tryParse(s))
          .whereType<int>()
          .where((i) => i >= 0 && i < lines.length)
          .toList();

  final recentWindow =
      recent.length <= repeatGap ? recent : recent.sublist(recent.length - repeatGap);
  final blockCount = lines.length > repeatGap
      ? recentWindow.length
      : recentWindow.length.clamp(0, lines.length - 1);
  final blocked = recentWindow.length > blockCount
      ? recentWindow.sublist(recentWindow.length - blockCount).toSet()
      : recentWindow.toSet();

  var pool = [for (var i = 0; i < lines.length; i++) if (!blocked.contains(i)) i];
  if (pool.isEmpty) {
    final last = recentWindow.isNotEmpty ? recentWindow.last : -1;
    pool = [for (var i = 0; i < lines.length; i++) if (i != last) i];
    if (pool.isEmpty) pool = [0];
  }
  final picked = pool[rnd.nextInt(pool.length)];

  final updated = [...recent, picked];
  final maxKeep = repeatGap * 2;
  final trimmed = updated.length > maxKeep ? updated.sublist(updated.length - maxKeep) : updated;
  await prefs.setString(historyKey, trimmed.map((e) => e.toString()).join(','));

  return lines[picked];
}

String kasumiSimilarExpressionIntro(String uiLanguageCode) {
  final lang = _norm(uiLanguageCode);
  final rnd = Random();
  final lines = _kasumiSimilarIntroLines(lang);
  return lines[rnd.nextInt(lines.length)];
}

List<String> _tsumugiSimilarIntroLines(String lang) {
  switch (lang) {
    case 'ja':
      return [
        'こんな言い方もあるよ〜☺️',
        'あとね、似たフレーズも教えるね！',
        'こういう表現もあるんだ☺️',
        'ちょっと似てる言い方も紹介するね！',
        'ついでに、別の言い方も覚えちゃおう！',
        'こんな表現も使えるよ〜！',
        'おまけで、似たフレーズも見てみて☺️',
        'あわせてこっちも覚えると便利だよ！',
      ];
    case 'ko':
      return [
        '이런 표현도 있어~☺️',
        '비슷한 말도 알려줄게!',
        '이렇게도 말할 수 있어☺️',
        '비슷한 표현도 소개해줄게!',
        '이 기회에 다른 말도 같이 외워봐!',
        '이런 식으로도 쓸 수 있어~!',
        '덤으로 비슷한 말도 확인해봐☺️',
        '이것도 알아두면 편리해!',
      ];
    case 'zh':
      return [
        '还有这种说法哦~☺️',
        '来，再教你一个类似的表达！',
        '这样说也可以☺️',
        '顺便介绍一个相似的说法！',
        '趁这个机会，另一种说法也记下来吧！',
        '这个表达也可以用哦~！',
        '顺带看看这个类似的说法☺️',
        '记住这个也很方便哦！',
      ];
    case 'zh_tw':
      return [
        '還有這種說法哦~☺️',
        '來，再教你一個類似的表達！',
        '這樣說也可以☺️',
        '順便介紹一個相似的說法！',
        '趁這個機會，另一種說法也記下來吧！',
        '這個表達也可以用喔~！',
        '順帶看看這個類似的說法☺️',
        '記住這個也很方便喔！',
      ];
    case 'es':
      return [
        'También puedes decirlo así~☺️',
        '¡Mira, hay otra forma de decirlo!',
        'Esta expresión también funciona☺️',
        '¡Te presento una expresión parecida!',
        '¡Aprovecha y aprende otra forma de decirlo!',
        '¡Esta manera de decirlo también vale~!',
        'Echa un vistazo a esta expresión similar☺️',
        '¡Saberlo también te será muy útil!',
      ];
    case 'fr':
      return [
        'On peut aussi le dire comme ça~☺️',
        'Tiens, voici une autre façon de le dire !',
        'Cette expression marche aussi☺️',
        'Je te présente une expression similaire !',
        'Profites-en pour apprendre une autre façon de le dire !',
        'Cette formulation fonctionne aussi~!',
        'Jette un œil à cette expression similaire☺️',
        'La connaître sera bien utile !',
      ];
    case 'de':
      return [
        'Man kann es auch so sagen~☺️',
        'Schau, hier ist noch eine andere Ausdrucksweise!',
        'Das geht auch☺️',
        'Hier ist ein ähnlicher Ausdruck für dich!',
        'Lern doch gleich noch eine andere Variante!',
        'So kann man es auch ausdrücken~!',
        'Wirf mal einen Blick auf diesen ähnlichen Ausdruck☺️',
        'Das kennst du zu wissen ist sehr praktisch!',
      ];
    case 'vi':
      return [
        'Cũng có thể nói như thế này nè~☺️',
        'Để mình chỉ thêm một cách nói tương tự nhé!',
        'Cách này cũng được☺️',
        'Mình giới thiệu thêm một cách diễn đạt tương tự nhé!',
        'Nhân tiện, học thêm một cách nói khác luôn nào!',
        'Cách nói này cũng dùng được nha~!',
        'Xem thêm cách diễn đạt tương tự này nhé☺️',
        'Biết thêm cái này cũng rất tiện đó!',
      ];
    case 'id':
      return [
        'Ada juga cara lain untuk mengatakannya~☺️',
        'Nih, ada ekspresi serupa yang bisa dipakai!',
        'Ini juga bisa digunakan☺️',
        'Yuk, kenalan sama ungkapan yang mirip ini!',
        'Sekalian, pelajari cara lain untuk mengatakannya!',
        'Cara ini juga bisa dipakai lho~!',
        'Lihat juga ekspresi serupa ini ya☺️',
        'Tahu yang ini juga sangat berguna!',
      ];
    case 'en':
    default:
      return [
        'Here\'s another way to say it~☺️',
        'Oh, there\'s a similar expression too!',
        'You could also say it like this☺️',
        'Let me show you a similar phrase!',
        'While we\'re at it, learn this one too!',
        'This expression works the same way~!',
        'Take a look at this similar phrase☺️',
        'Knowing this one will come in handy!',
      ];
  }
}

List<String> _kasumiSimilarIntroLines(String lang) {
  switch (lang) {
    case 'ja':
      return [
        '…ついでに、こういう言い方もあるから。',
        '参考程度に教えてあげる。',
        'べ、別に親切にしてるわけじゃないけど。こんな表現も覚えておいて。',
        '…一応、こっちの言い方もあるわ。',
        'これも使えるから、覚えておきなさい。',
        '勘違いしないでよね。ついでに別の言い方も見せただけ。',
      ];
    case 'ko':
      return [
        '…겸사겸사, 이런 말도 있으니까.',
        '참고 삼아 알려줄게.',
        '딱히 친절하게 구는 건 아닌데. 이런 표현도 기억해둬.',
        '…덧붙여서, 이런 말도 써.',
        '참고로 이것도 알아둬.',
        '착각하지 마. 그냥 다른 표현도 보여준 거야.',
      ];
    case 'zh':
      return [
        '…顺便说一句，还有这种说法。',
        '给你参考一下。',
        '不是特别好心才告诉你的。这个表达也记一下。',
        '…另外，这样说也很常见。',
        '给你个参考，这句也能用。',
        '别误会，我只是顺手多教你一种说法。',
      ];
    case 'zh_tw':
      return [
        '…順便說一句，還有這種說法。',
        '給你參考一下。',
        '不是特別好心才告訴你的。這個表達也記一下。',
        '…另外，這樣說也很常見。',
        '給你個參考，這句也能用。',
        '別誤會，我只是順手多教你一種說法。',
      ];
    case 'es':
      return [
        '…Ya que estamos, también existe esta expresión.',
        'Te lo digo de referencia.',
        'No es que quiera ser amable o algo así. Recuerda esta también.',
        '…Además, también se dice así.',
        'Tómalo como referencia: esta también sirve.',
        'No te confundas, solo te enseño otra forma de decirlo.',
      ];
    case 'fr':
      return [
        '…Tant qu\'on y est, il y a aussi cette façon de dire.',
        'Pour ta culture personnelle.',
        'C\'est pas que je sois sympa ou quoi. Retiens ça aussi.',
        '…Au passage, on dit aussi comme ça.',
        'Garde-la en tête, ça peut servir.',
        'Ne te méprends pas, je te montre juste une autre tournure.',
      ];
    case 'de':
      return [
        '…Und nebenbei, es gibt auch diesen Ausdruck.',
        'Zur Information für dich.',
        'Ich bin nicht besonders nett oder so. Merk dir das auch.',
        '…Nebenbei gesagt, so sagt man es auch.',
        'Merk dir das ruhig, das kann nützlich sein.',
        'Versteh das nicht falsch. Ich zeige dir nur noch eine Variante.',
      ];
    case 'vi':
      return [
        '…Nhân tiện, còn có cách nói này nữa.',
        'Để tham khảo thêm cho bạn.',
        'Không phải mình tốt bụng hay gì. Nhớ cả cái này đi.',
        '…Tiện thể thì cũng nói kiểu này được.',
        'Bạn cứ ghi nhớ câu này để tham khảo.',
        'Đừng hiểu lầm, mình chỉ thêm một cách nói thôi.',
      ];
    case 'id':
      return [
        '…Sekalian, ada juga ungkapan seperti ini.',
        'Sebagai referensi untukmu.',
        'Bukan berarti aku baik hati ya. Ingat yang ini juga.',
        '…Sekalian, ini juga sering dipakai.',
        'Buat referensi, yang ini juga oke.',
        'Jangan salah paham, aku cuma nunjukin satu cara lain.',
      ];
    case 'en':
    default:
      return [
        '…By the way, there\'s also this expression.',
        'Just for your reference.',
        'It\'s not like I\'m being nice or anything. Remember this one too.',
        '…And there\'s this way to say it too.',
        'You can use this one as well, so remember it.',
        'Don\'t get the wrong idea. I\'m just showing you another phrasing.',
      ];
  }
}

List<String> _kasumiQuestionLineTemplates(String lang) {
  switch (lang) {
    case 'ja':
      return [
        '{target}で言えるかな？…別に試してるわけじゃないけど。',
        'これ、{target}で言ってみて。難しくないでしょ、きっと。',
        '{target}でどう言う？…一緒に考えてあげる。',
      ];
    case 'ko':
      return [
        '{target}로 말할 수 있어? …별로 시험하는 건 아닌데.',
        '{target}로 말해봐. 어렵지 않을 거야, 아마.',
        '{target}로 어떻게 말해? …같이 생각해줄게.',
      ];
    case 'zh':
      return [
        '能用{target}说出来吗？…我又没在考你什么。',
        '用{target}说说看。应该不难，肯定的。',
        '{target}怎么说？…帮你想想也行。',
      ];
    case 'zh_tw':
      return [
        '能用{target}說出來嗎？…我又沒在考你什麼。',
        '用{target}說說看。應該不難，肯定的。',
        '{target}怎麼說？…幫你想想也行。',
      ];
    case 'es':
      return [
        '¿Puedes decirlo en {target}? …No te estoy poniendo a prueba ni nada.',
        'Dilo en {target}. No es difícil, seguro.',
        '¿Cómo se dice en {target}? …Te ayudo a pensarlo.',
      ];
    case 'fr':
      return [
        'Tu peux le dire en {target} ? …Je te teste pas, hein.',
        'Dis-le en {target}. C\'est pas dur, j\'en suis sûre.',
        'Comment on dit en {target} ? …Je t\'aide à y réfléchir.',
      ];
    case 'de':
      return [
        'Kannst du es auf {target} sagen? …Ich teste dich nicht oder so.',
        'Sag es auf {target}. Es ist bestimmt nicht schwer.',
        'Wie sagt man das auf {target}? …Ich helfe dir nachdenken.',
      ];
    case 'vi':
      return [
        'Bạn có thể nói bằng {target} không? …Mình không phải đang thử bạn đâu.',
        'Thử nói bằng {target} xem. Chắc không khó đâu.',
        '{target} nói thế nào nhỉ? …Mình giúp bạn nghĩ.',
      ];
    case 'id':
      return [
        'Bisa bilang dalam {target}? …Bukan berarti aku mengujimu ya.',
        'Bilang dalam {target} dong. Pasti tidak susah kok.',
        'Gimana bilangnya dalam {target}? …Aku bantu mikir deh.',
      ];
    case 'en':
    default:
      return [
        "Can you say it in {target}? …I'm not testing you or anything.",
        "Try saying it in {target}. It's not that hard, I'm sure.",
        "How do you say it in {target}? …I'll help you figure it out.",
      ];
  }
}
