import 'dart:math';

class TranslatePrompt {
  final String nativeText;
  final String correctTranslation;

  TranslatePrompt({required this.nativeText, required this.correctTranslation});
}

// 例題（最初はここにハードコードしてもOK。あとでJSON読み込みに切り替え）
final List<TranslatePrompt> samplePrompts = [
  TranslatePrompt(nativeText: 'これはペンです', correctTranslation: 'This is a pen.'),
  TranslatePrompt(nativeText: '私は学生です', correctTranslation: 'I am a student.'),
  TranslatePrompt(nativeText: 'あれは犬です', correctTranslation: 'That is a dog.'),
];

TranslatePrompt getRandomTranslatePrompt() {
  return samplePrompts[Random().nextInt(samplePrompts.length)];
}

String buildEvaluationPrompt({
  required String question,
  required String userAnswer,
  required String correctAnswer,
}) {
  return '''
あなたは言語学習の先生です。
以下の日本語を英語に翻訳する問題が出されました。

問題: $question
ユーザーの回答: $userAnswer
模範解答: $correctAnswer

ユーザーの回答が正しいかどうかを以下の基準で評価してください：

1. 正解 or 間違い
2. コメント（丁寧で簡潔に）

日本語で以下の形式で出力してください：

- 正誤: 正解 または 間違い
- コメント: （コメント文）
''';
}
