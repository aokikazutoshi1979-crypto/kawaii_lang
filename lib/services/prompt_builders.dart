import 'package:kawaii_lang/services/feedback_labels.dart';

class PromptBuilders {
  // 他の関数が既にある場合はこの下に追加して下さい

  // 問い合わせ1
  static String buildAccuracyPrompt({
    required String userAnswer,
    required String originalQuestion,
    required String targetLang,
    required String nativeLang,
  }) {
  return ''' 
以下の判定ルールに従って,
判定ルールの「1」に該当するか,
または判定ルールの「2」に該当するか,
を判定し,必ず「1」または「2」のみを返して下さい.

判定対象: $userAnswer
正解文: $originalQuestion

判定ルール:
- 「2」= 判定対象は,正解文と意味や意図が明らかに異なる.
- 「2」= 判定対象が $targetLang で書かれていない.
- 「1」= 判定対象が $targetLang で書かれており,かつ,正解文と同じ意味や意図を持ち,自然な言い換えや同義表現として通用する.
  - 厳密に同じ単語である必要はない.
  - 「こんにちは」「やあ」「どうも」「よろしく」「はじめまして」など,場面で似た意味を伝えられる場合も「1」とする.


以下の形式で返して下さい：
出力は必ず「1」または「2」のみを返して下さい.
（説明,空白,改行は禁止です）
''';
  }


  // 問い合わせ4
  static String buildGrammarPrompt({
    required String userAnswer,
    required String targetLang,
  }) {
    return '''
以下の判定ルールに従って,以下の判定対象が,${targetLang}の文法として正しい文章かどうかを判定し,必ず JSON 形式で回答して下さい.  

判定対象: $userAnswer

判定ルール:
- 「1」= ${targetLang}の文法的に正しい
- 「2」= ${targetLang}の文法的に誤っている
※句読点（ピリオド,カンマ,クエスチョンマークなど）は考慮しないで下さい.
※語順,助詞や冠詞の有無を考慮して下さい.

以下の形式で返して下さい：
出力は必ず「1」または「2」のみを JSON 形式で返して下さい.
（説明,空白,改行は禁止です）
{
  "answer": "1"
}
''';
  }

  // 問5：ユーザー入力の翻訳
  static String buildUserAnswerTranslationPrompt({
    required String nativeLang,
    required String userAnswer,
  }) {
    return '''

以下の翻訳対象を,${nativeLang}に翻訳して下さい.

翻訳対象: ${userAnswer}

※翻訳結果のみを返して下さい.
（説明,空白,改行は禁止です）
''';
  }

  // 問い合わせ6：模範的な翻訳（正しい文を提示する）
  static String buildOriginalQuestionTranslationPrompt({
    required String originalQuestion,
    required String targetLang,
  }) {
    return '''
 
以下の翻訳対象を,${targetLang}に翻訳して下さい.

翻訳対象: ${originalQuestion}

※翻訳結果のみを返して下さい.
（説明,空白,改行は禁止です）
''';
  }

  // 問い合わせ7
  static String buildSymbolOrNumberOnlyCheckPrompt({
    required String userAnswer,
    required String targetLang,
  }) {
    return '''
以下の判定ルールに従って,以下の判定対象が,
判定ルールの「2」に該当するかを判定し,
必ず JSON 形式で回答して下さい.

判定対象: $userAnswer

判定ルール:
- 「2」= 判定対象は暴力的または侮辱的または卑猥な内容を含む

- 「2」= 文は「記号のみ」または「数字のみ」である
### 例（few-shot）  
Q: "12345"  → { "answer": "2" }  （数字のみ）
Q: "!!!"    → { "answer": "2" }  （記号のみ）
Q: "@"      → { "answer": "2" }  （記号のみ）
Q: "#"      → { "answer": "2" }  （記号のみ）
Q: "abc123" → { "answer": "1" }  （文字と数字の混在）  
Q: "Hello!" → { "answer": "1" }  （文字と記号の混在）  

- 「2」= 判定対象は `$targetLang` で書かれていない.

- 「1」= 上記のどれにも該当しない.

以下の形式で返して下さい：
出力は必ず「2」または「1」のみを JSON 形式で返して下さい.
（説明,空白,改行は禁止です）
{
  "answer": "1"
}
  ''';
  }

  //　問7:句読点を追加
  static String buildPunctuationPrompt(String input) {
  return '''
以下の対象文に自然な句読点（ピリオド,カンマ,クエスチョンマークなど）を追加して下さい.
句読点だけを追加して下さい.
句読点を追加する以外の変更は禁止です.

対象文： $input

### 例（few-shot）  
Q: "Where the station" → "Where the station?"  
Q: "駅どこですか" → "駅どこですか？"  

対象文に句読点を追加したら,対象文に句読点を追加した文のみ返して下さい.
対象文に句読点を追加しなかったら,対象文に句読点を追加しなかった文のみ返して下さい.
（説明,空白,改行は禁止です）
''';
  }

  /// 問8：元の訳文と意味が似ている別の文を作成する
static String buildSimilarQuestionPrompt({
  required String translatedText,
  required String targetLang,
  }) {
    return '''
  次の文と同じ意味を持ちながら、よりフレンドリーでカジュアルな${targetLang}の表現を1つ作成してください。

  対象の文: $translatedText

  【厳格な条件】
  - 必ず意味が同じで、自然なフレンドリー表現にすること。
  - 句読点やスペルの微変更だけはNG。
  - 意味が変わる表現、不自然な文もNG。
  - 出力は1文のみ。説明や改行、余計な記号は禁止。

  【NG例】
  "はじめまして。" → "初めまして。"
  "いいね！" → "良いね！"

  【OK例】
  "はじめまして。" → "やあ！会えてうれしいよ。"
  "いくらですか？" → "これっていくらかな？"
  "Give me a discount?" → "Can you cut me a deal?"

  出力: 言い換えた${targetLang}の文のみ。
  （説明、空白、改行は禁止です）
  ''';
  }

  /// 問10：同義の文の母語での訳を作成する
  static String buildSimilarQuestionInNativeLangPrompt({
    required String translatedText,
    required String nativeLang,
  }) {
    return '''
以下の翻訳対象を,${nativeLang}に翻訳して下さい.

翻訳対象: ${translatedText}

※翻訳結果のみを返して下さい.
（説明,空白,改行は禁止です）
''';
  }

  /// 問12：同義の文の音声転写を作成する
  static String buildSimilarQuestionTtsPrompt({
    required String translatedText,
    required String targetLang,
  }) {
    return '''
以下のルールに従って,転写対象の音声転写の結果（声調記号・音節間スペース有り）またはnullのみ返して下さい.  

転写言語: $targetLang
転写対象: $translatedText

判定ルール:
- 転写言語 = ja = ヘボン式ローマ字（例：konnichi-ha）
- 転写言語 = zh = 漢語拼音（Hanyu Pinyin）（例：nǐ hǎo）
- 転写言語 = zh_TW = 漢語拼音（Hanyu Pinyin）（例：nǐ hǎo）
- 転写言語 = ko = 改訂式ローマ字（Revised Romanization of Korean）（例：annyeonghaseyo）
- 転写言語 = 上記以外 = null

※音声転写の結果,またはnullのみ返して下さい.
（説明,空白,改行は禁止です）
''';
  }

  /// 問い合わせ：誤答時の解説
  static String buildIncorrectAnswerExplanationPrompt({
    required String userAnswer,
    required String nativeLang,
    required String targetLang,
  }) {
    return '''
以下の解説ルールに従って,解説対象はどんな場合に使う言葉か解説して下さい.

解説対象:${userAnswer}

解説ルール:
- 解説対象はそのまま${targetLang}で表示し,解説は${nativeLang}で行うこと.
  例:
   解説対象 = Nice to meet you.
   解説言語 = Japanese
   解説結果 = Nice to meet you. は,初めて会った人に対する挨拶で使われます.
   返すのはこの部分だけです→「Nice to meet you. は,初めて会った人に対する挨拶で使われます.」

※解説は必ず40文字以内で返して下さい.
※解説結果だけ返して下さい.
''';
  }

  static String buildSoftEncouragementPrompt({
    required String nativeLang,
  }) {
    return '''
以下のメッセージから一つだけ選び${nativeLang}で返して下さい.

メッセージ:
 惜しい!
 いい線いってます!もう一歩!
 あと少し!惜しい!
 ナイスチャレンジ!もう一歩!
 もう一歩!惜しい!
 グッドトライ!もう少し！
 もうちょい！惜しい!
 もう少し！惜しい!
 いい感じでした！
 ナイスワーク！惜しい!

※メッセージのみ返して下さい.
''';
  }

  static String buildListeningPrompt({
    required String userAnswer,
    required String originalQuestion,
    required String targetLang,
    required String nativeLang,
  }) {
    return '''
以下の判定ルールに従って,以下の判定対象の回答が正しいか判定し,必ず「1」または「2」のみを返して下さい.

判定対象: $userAnswer

判定ルール:
- 「1」= 判定対象と,「$originalQuestion」は同じ文である.
- 「2」= 判定対象と,「$originalQuestion」は同じ文ではない.

以下の形式で返して下さい：
出力は必ず「1」または「2」のみを返して下さい.
（説明,空白,改行は禁止です）
''';
  }

  // オリジナルの解説
  static String buildPrompt01({
    required String userAnswer,
    required String originalQuestion,
    required String targetLang,
    required String nativeLang,
  }) {
    return '''
$originalQuestion はどのような表現か,そして $targetLang で表現するならどのような表現が正しいかを説明してください.
必ず$nativeLang で説明してください.
必ず100文字以内で説明してください.
（100文字以上の説明は禁止.$nativeLang以外での説明は禁止.）
''';
  }

  // ユーザー回答とオリジナルの比較解説
  static String buildPrompt02({
    required String userAnswer,
    required String originalQuestion,
    required String targetLang,
    required String nativeLang,
  }) {
    return '''
$originalQuestion と $userAnswer は文の意味合いがなぜ違うのか簡単に説明してください.
必ず$nativeLang で説明してください.
必ず100文字以内で説明してください.
（100文字以上の説明は禁止.$nativeLang以外での説明は禁止.）
''';
  }
}
