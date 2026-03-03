# KawaiiLang 実装ブリーフ — 競合レビュー263件分析から

> 作成元: kawaii_lang_research プロジェクト（競合19アプリ × 263件の★1〜3レビュー定量分析）
> 作成日: 2026-03-03
> 参照元ファイル: /Users/user/FlutterProjects/kawaii_lang_research/strategy_mvp_aso.md

---

## なぜこのブリーフを書いたか

競合アプリ（Talkpal・Jumpspeak・SakuraSpeak・Langua・Langotalk等）のApp Store低評価レビューを
263件収集・分析した結果、**全競合が同じ7つの失敗を繰り返している**ことが判明した。
このブリーフはその失敗を KawaiiLang が先回りして解決するための実装仕様書。

---

## 痛みクラスター Top 10（定量）

| 順 | クラスター | 件数/263 | 割合 |
|---|---|---|---|
| 1 | 課金の壁・詐欺感 | 140件 | 53% |
| 2 | 初心者に難しすぎる | 67件 | 26% |
| 3 | 音声認識・発音精度不良 | 49件 | 19% |
| 4 | クラッシュ・フリーズ・バグ | 40件 | 15% |
| 5 | AI返答が不自然・テンプレ感 | 28件 | 11% |
| 6 | 学習構造・導線の欠如 | 20件 | 8% |
| 7 | 進捗・履歴が残らない | 11件 | 4% |
| 8 | 会話速度が速すぎる | 5件 | 2% |
| 9 | 日本語スクリプト補助なし | 5件 | 2% |
| 10 | 話すことへの恐怖・恥ずかしさ | 3件※ | 1%※ |

> ※C10は直接言及が少ないが、C2〜C7の根底にある感情障壁として実質的影響は最大。

---

## 既存コード調査で判明した現状

| 機能 | 現状 | ファイル |
|---|---|---|
| TTS速度 | iOS: 0.40 / Android: 0.85 に**ハードコード** | `chat_screen.dart:1115` `_initTts()` |
| ローマ字変換 | `_romajiForJapanese()` は**正解表示のみ**に使用 | `chat_screen.dart:928` |
| ふりがな | **未実装** | — |
| AIトーン | つむぎ(優しい)/かすみ(ツンデレ) の称賛セリフは存在 | `tsumugi_prompt.dart` |
| VoiceVox日次制限 | 無料30回/日・プレミアム1000回/日 **実装済み** | `voicevox_tts_service.dart` |
| 「もう一回」 | セリフ内に文言はあるが**専用ボタン未実装** | `tsumugi_prompt.dart:469` |
| サブスク画面 | RevenueCat 連携済み・cancel any time 文言あり | `subscription_screen.dart` |
| 課金不安解消 | **7日前通知・使用量可視化なし** | — |
| ホーム画面 | **ほぼ空（プレースホルダー）** | `home_screen.dart` |
| 設定画面 | VoiceVox制限表示あり、速度設定**なし** | `settings_screen.dart` |
| 日次会話上限 | **未実装**（VoiceVox音声のみ制限あり） | — |

---

## 実装 ToDo（優先順）

### 🔴 P0 — 2日以内（低難度・最大インパクト）

---

#### P0-1: TTS速度スライダー（設定画面）

**根拠クラスター**: C2（初心者難しすぎる）/ C8（速度速すぎる）
**代表レビュー**: *"The app is great but there should be an option to slow down the tutor. He's speaking too quickly for me."* — Talkpal ★3

**現状**: `chat_screen.dart` の `_initTts()` で `0.40`(iOS) にハードコード。
**やること**:

1. `shared_preferences` に `'tts_speech_rate'` キーで保存（デフォルト `0.40`）
2. `settings_screen.dart` の既存 VOICEVOX セクション下に `Slider` を追加
   - 範囲: `0.3`〜`0.7`（ゆっくり ← → はやい）
   - 目盛りラベル: `🐢` / `ふつう` / `🐇`
3. `chat_screen.dart` の `_initTts()` を `prefs.getDouble('tts_speech_rate') ?? 0.40` に変更

```dart
// settings_screen.dart に追加するWidget例
ListTile(
  leading: const Icon(Icons.speed_rounded),
  title: Text(isJa ? '読み上げ速度' : 'Reading Speed'),
  subtitle: Slider(
    value: _ttsRate,
    min: 0.3, max: 0.7, divisions: 4,
    label: _ttsRateLabel(_ttsRate),
    onChanged: (v) async {
      setState(() => _ttsRate = v);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('tts_speech_rate', v);
    },
  ),
),
```

---

#### P0-2: AIプロンプト トーン再設計

**根拠クラスター**: C5（AI返答テンプレ）/ C10（恐怖・恥ずかしさ）
**代表レビュー**: *"Like talking to a real person if they always answered with 'Great work!'"* — Talkpal ★3 / *"Talking in another language is already nerve-racking, I don't need an aggressive-toned bot."* — Langua ★3

**現状**: `tsumugi_prompt.dart` の `tsumugiPraiseLines()` は "Great!" 系の短い肯定のみ。
**やること**: `tsumugiPraiseLines()` を **具体的なフィードバック付き** に拡張する。

```dart
// tsumugi_prompt.dart の tsumugiPraiseLines() を以下に置き換え
case 'ja':
  return const [
    'すごい、自然に聞こえたよ。',      // 既存（残す）
    'いいね、ちゃんと伝わったよ☺️',   // 既存（残す）
    'いい調子だよ。',                  // 既存（残す）
    // ▼ 追加: 具体的フィードバック付き
    '発音、よくなってきてるよ！前より自信が出てきたね。',
    'それ、日本人に通じる言い方だよ☺️',
    '完璧じゃなくても大丈夫。伝わることが大事だよ。',
    'ゆっくりでよかったんだよ。ちゃんと聞こえたよ☺️',
  ];
case 'en':
default:
  return const [
    'Nice! That came through.',          // 既存
    'Great — that sounded natural.',     // 既存
    'Awesome! Keep going.',              // 既存
    // ▼ 追加
    'Your pronunciation is getting better — I can really hear it!',
    'A real Japanese person would understand that perfectly☺️',
    "It doesn't have to be perfect. You got the meaning across!",
    'Taking your time is totally fine. I heard you clearly☺️',
  ];
```

また `lib/services/prompt_builders.dart` の GPT システムプロンプトに以下を追加：

```
// prompt_builders.dart のシステムプロンプト末尾に追加
- Never use an aggressive tone or raise your voice metaphorically.
- When the user makes an error, gently redirect with: "ちょっと待って！[correction]"
- Never say only "Great job!" — always add what specifically was good or a small next tip.
- If the user seems to be struggling, slow down and offer a hint proactively.
```

---

#### P0-3: 「もう一回」専用ボタンの追加

**根拠クラスター**: C4（音声認識精度）/ C10（恐怖・恥）
**代表レビュー**: *"It takes three or four tries to even get it to recognize your submission"* — Talkpal ★1

**現状**: `chat_screen.dart` の `widgets/mic_area.dart` にマイクボタンがある。
**やること**: 採点後の結果バブル下部に「もう一回言う 🔄」ボタンを追加し、前の問題を再出題。

実装箇所: `lib/widgets/message_list.dart` または `chat_screen.dart` の正解/不正解バブル表示直後に `TextButton` を追加。

```dart
// 正解/不正解バブルの下に追加
TextButton.icon(
  onPressed: _retryCurrentQuestion, // 既存の問題を再セット
  icon: const Text('🔄', style: TextStyle(fontSize: 16)),
  label: Text(
    loc.retryButton, // 'もう一回言う' / 'Try again'
    style: const TextStyle(fontSize: 13),
  ),
  style: TextButton.styleFrom(foregroundColor: Colors.pink.shade300),
),
```

l10n に追加:
- `app_localizations_ja.dart`: `retryButton` → `"もう一回言う"`
- `app_localizations_en.dart`: `retryButton` → `"Try again"`

---

#### P0-4: サブスク画面の信頼シグナル強化

**根拠クラスター**: C1（課金詐欺感 53%）— 最大クラスター
**代表レビュー**: *"Free trial did not cancel… A week later I saw a hundred and something dollar charge."* — Talkpal ★1

**現状**: `subscription_screen.dart` に `cancelAnytime` 文言はあるが、信頼シグナルが弱い。
**やること**: サブスク画面の `_benefits()` と CTA 上部に以下を追加。

```dart
// subscription_screen.dart の _benefits() を拡張
List<String> _benefits(AppLocalizations loc) => [
  loc.subscriptionBenefitAllCategories,    // 既存
  loc.subscriptionBenefitUnlimited,         // 既存
  '✅ ${loc.benefitNoCreditCard}',          // 追加: クレカ不要
  '✅ ${loc.benefitCancelAnytime}',         // 既存を✅付きに強化
  '✅ ${loc.benefitRenewalNotice}',         // 追加: 更新7日前通知
  '✅ ${loc.benefitAppleRefund}',           // 追加: Apple返金案内
];
```

l10n に追加:
- `benefitNoCreditCard`: `"Apple IDだけで開始（クレカ不要）"` / `"Start with Apple ID — no credit card needed"`
- `benefitRenewalNotice`: `"更新7日前にお知らせ"` / `"Reminder 7 days before renewal"`
- `benefitAppleRefund`: `"7日以内ならApple経由で返金申請可"` / `"Refund available via Apple within 7 days"`

---

### 🟠 P1 — 3〜5日（中難度・ユーザー体験の核）

---

#### P1-1: 会話テキストへのふりがな表示

**根拠クラスター**: C2（初心者難しすぎる）/ C9（スクリプト補助なし）
**代表レビュー**: *"There is no furigana for the Japanese option that would help prevent less mispronunciation."* — Talkpal ★1

**現状**:
- `chat_screen.dart:928` に `_romajiForJapanese(text, loc)` が実装済み（GPT経由でローマ字変換）
- 現在は**正解表示のみ**に使用、会話の出題テキストには未適用

**やること**:
1. `lib/widgets/message_list.dart` のボットバブル表示部分で、`targetLang == 'ja'` のとき、テキストの下にふりがな（またはローマ字）を薄字で表示する
2. `SharedPreferences` に `'show_furigana'` (bool, default: true) を追加
3. 設定画面にトグルを追加

実装方針:
- ふりがな付与は GPT に任せる（`_romajiForJapanese()` を参考に同様の関数を作成）
- または `ruby` タグ的なウィジェットで `RichText` + `WidgetSpan` で上部に小さく表示
- 負荷軽減のため、出題テキストが生成されたタイミングで非同期で取得しキャッシュ

```dart
// 簡易実装案: ボットバブル下部に薄いローマ字テキスト追加
if (showFurigana && targetLang == 'ja' && romajiText != null)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      romajiText!,
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey.shade500,
        fontStyle: FontStyle.italic,
      ),
    ),
  ),
```

---

#### P1-2: ホーム画面の実装（今日のミッション）

**根拠クラスター**: C6（学習構造の欠如）
**代表レビュー**: *"There is no structure at all. I gave them this advice over a year ago… it looks exactly the same."* — Langua ★3

**現状**: `home_screen.dart` は「ホーム」と「ログイン成功！」だけのプレースホルダー。

**やること**: 最低限の「今日のミッション」カードを3つ表示。

```dart
// home_screen.dart を以下の構造に置き換え
// ① 今日のミッション（3つ）: キャラが案内
// ② ストリーク表示（SharedPreferences から連続日数を取得）
// ③ 「始める」ボタン → category_selection_screen へ
```

ミッション例（`SharedPreferences` でシーン・カテゴリをローテーション）:
- 「今日の練習: 駅で道を聞く（3問）」
- 「苦手克服: 助詞の使い方（2問）」
- 「自由会話: つむぎと話してみよう」

---

#### P1-3: 日次会話上限（無料ティア設計）

**根拠クラスター**: C1（課金壁）への反省として、無料でも価値を感じさせる設計
**現状**: VoiceVox音声は30回/日の制限あり。チャット送信自体は無制限。

**やること**:
1. `SharedPreferences` に `'daily_chat_count'` と `'daily_chat_date'` を保存
2. 無料ユーザーの1日の会話ターン上限を **20回**（midnight JSTリセット）
3. 上限到達時のメッセージを「怒らない・温かい」トーンで表示

```dart
// chat_screen.dart の送信処理前に追加
if (!isSubscribed && dailyChatCount >= 20) {
  _showDailyLimitReached(); // 優しいメッセージのダイアログ
  return;
}

void _showDailyLimitReached() {
  showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('今日の練習、お疲れさま！🌸'),
    content: Text(
      '今日は${dailyChatCount}回練習したよ。\n'
      'また明日0時に回復するから、また話そうね☺️\n\n'
      'もっと練習したい人はプレミアムプランへ！'
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
      ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/subscription'),
        child: const Text('プランを見る'),
      ),
    ],
  ));
}
```

---

### 🟡 P2 — 1週間以内（中難度・継続率向上）

---

#### P2-1: 会話履歴の自動保存と振り返り画面

**根拠クラスター**: C7（進捗・履歴が残らない）
**現状**: `history_service.dart` が存在する。内容を確認して活用。
**やること**:
- 各会話セッション終了後、`HistoryService` に正解/不正解/ローマ字を保存
- `question_list_screen.dart` または新規 `review_screen.dart` で振り返り表示

---

#### P2-2: 弱点自動把握（カテゴリ別正答率）

**根拠クラスター**: C6（学習構造の欠如）
**やること**:
- Firestore の既存ユーザーデータに `categoryAccuracy: {scene: {correct: n, total: n}}` を追加
- ホーム画面のミッションに「苦手なシーン」を優先的に出す

---

## KawaiiLangの方向性（1文）

> **「日本語を話すことが怖い初心者が、かわいいAIキャラと安心して練習できる、課金も誠実な日本語スピーキングアプリ」**

---

## 次の2週間スプリント目標

P0（4タスク）+ P1-3（日次制限）を完了させ、App Store審査提出できる状態にする。
P0はすべて低難度で、合計実装工数 **2〜3日** の見積もり。

| 優先 | タスク | 担当ファイル | 難易度 | 工数 |
|---|---|---|---|---|
| P0-1 | TTS速度スライダー | `settings_screen.dart` + `chat_screen.dart:1115` | 低 | 2h |
| P0-2 | AIプロンプト トーン改善 | `tsumugi_prompt.dart` + `prompt_builders.dart` | 低 | 1h |
| P0-3 | 「もう一回」ボタン | `chat_screen.dart` / `mic_area.dart` | 低 | 2h |
| P0-4 | サブスク信頼シグナル | `subscription_screen.dart` + l10n | 低 | 1h |
| P1-1 | ふりがな表示 | `message_list.dart` + 新関数 | 中 | 4h |
| P1-2 | ホーム画面実装 | `home_screen.dart` | 中 | 4h |
| P1-3 | 日次チャット上限 | `chat_screen.dart` | 中 | 3h |

---

## 競合との差別化マトリクス（実装後）

| 機能 | Talkpal | Jumpspeak | SakuraSpeak | **KawaiiLang（実装後）** |
|---|---|---|---|---|
| ふりがな/ローマ字 | ✗ | ✗ | △ | **✅ 全テキスト** |
| 発話速度調整 | ✗ | ✗ | ✗ | **✅ 設定画面** |
| クレカ不要トライアル | ✗ | ✗ | ✗ | **✅** |
| 1タップ解約案内 | ✗ | ✗ | △ | **✅ 明示** |
| AIトーン：怒らない設計 | ✗（攻撃的指摘あり） | ✗ | △ | **✅ プロンプト設計** |
| 「もう一回」専用ボタン | ✗ | ✗ | ✗ | **✅** |
| 温かい上限到達メッセージ | ✗（冷たい壁） | ✗ | ✗ | **✅** |
| 価格（月額） | $14.99〜 | $6.67〜 | $18〜 | **¥1,500（約$10）** |
