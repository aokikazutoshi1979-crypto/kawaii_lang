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

String _norm(String s) => s.replaceAll('-', '_').toLowerCase();
