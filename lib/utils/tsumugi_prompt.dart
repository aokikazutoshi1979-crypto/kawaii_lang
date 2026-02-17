import 'dart:math';

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
