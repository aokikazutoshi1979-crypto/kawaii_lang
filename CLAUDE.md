  ## KawaiiLang プロジェクト 共通ルール

  KawaiiLangはFlutter製の日本語スピーキング練習アプリです。
  ターゲット：日本語初心者・シャイな学習者向け、かわいいAIキャラとの会話練習。

  ### 絶対に触れないもの
  - RevenueCatのサブスク課金ロジック（subscription_service.dart、subscription_state.dart）
  - VOICEVOXのTTS上限設定（voicevox_tts_service.dart）
  - 既存のARBキー（app_localizations_*.dart の既存ゲッター削除・変更禁止）

  ### コーディング方針
  - 変更は最小限に。既存ロジックを再利用する
  - 新規ファイルは必要最小限
  - ローカライズキーは全10言語（en/ja/zh/zh_TW/ko/es/fr/de/vi/id）に追加する

---

# KawaiiLang — Claude Code 作業指示書

## Operating Mode (Read first)
You are the dedicated AI developer for KawaiiLang.

- Follow this CLAUDE.md as the single source of truth.
- Implement tasks one by one (P0-1 → P0-2 → ...). Do not batch everything at once.
- Keep patches minimal: touch the fewest files possible.
- Do NOT change: RevenueCat flow, VoiceVox daily limit logic, localization key names, Firestore schema unless explicitly instructed.
- If there is ambiguity, choose the safest option and ask a single clarification question only if truly blocking.
- Output: (1) files changed, (2) what changed, (3) how to test.

## このファイルについて
競合19アプリ・263件の低評価レビュー分析から導いた実装優先順位。
詳細仕様は **`RESEARCH_BRIEF.md`** を参照。

---

## プロジェクト概要

- Flutter アプリ（iOS / Android）
- AI日本語スピーキング練習 × かわいいキャラクター（つむぎ / かすみ）
- バックエンド: Firebase（Auth / Firestore / Functions）
- 課金: RevenueCat（`purchases_flutter`）
- 音声: `flutter_tts`（標準）+ VOICEVOX（アニメ声、Firebase Functions 経由）
- AI: OpenAI GPT（`gpt_service.dart` / `prompt_builders.dart`）

## 重要ファイルマップ

| 役割 | ファイル |
|---|---|
| AI会話メイン画面 | `lib/screens/chat_screen.dart`（2904行） |
| AIキャラ台詞・褒め言葉 | `lib/utils/tsumugi_prompt.dart` |
| GPTプロンプト構築 | `lib/services/prompt_builders.dart` |
| TTS（アニメ声・日次制限） | `lib/services/voicevox_tts_service.dart` |
| サブスク画面 | `lib/screens/subscription_screen.dart` |
| 設定画面 | `lib/screens/settings_screen.dart` |
| ホーム画面（ほぼ空） | `lib/screens/home_screen.dart` |
| 多言語文字列 | `lib/l10n/app_localizations_ja.dart` 他 |

---

## 実装優先タスク（必ず RESEARCH_BRIEF.md を先に読むこと）

### 🔴 P0（低難度・最優先）

**P0-1: TTS速度スライダー**
- `settings_screen.dart` に `Slider`（0.3〜0.7）を追加
- `SharedPreferences` key: `'tts_speech_rate'`
- `chat_screen.dart:1115` の `setSpeechRate(0.40)` をprefs読み込みに変更
- 詳細: RESEARCH_BRIEF.md § P0-1

**P0-2: AIトーン改善（プロンプト）**
- `tsumugi_prompt.dart` の `tsumugiPraiseLines()` に具体的フィードバック文言を追加
- `prompt_builders.dart` のシステムプロンプトに「怒らない・具体フィードバック必須」を追記
- 詳細: RESEARCH_BRIEF.md § P0-2

**P0-3: 「もう一回言う」ボタン**
- 正解/不正解バブル表示後に `TextButton.icon` を追加
- `loc.retryButton` = `"もう一回言う"` / `"Try again"` を l10n に追加
- 詳細: RESEARCH_BRIEF.md § P0-3

**P0-4: サブスク画面の信頼シグナル**
- `subscription_screen.dart` の `_benefits()` に3行追加
  - ✅ クレカ不要（Apple IDだけ）
  - ✅ 更新7日前にプッシュ通知
  - ✅ 7日以内ならApple経由で返金申請可
- 詳細: RESEARCH_BRIEF.md § P0-4

### 🟠 P1（中難度）

**P1-1: ふりがな/ローマ字表示**
- `_romajiForJapanese()` を会話バブルにも適用（現状は正解表示のみ）
- `SharedPreferences` key: `'show_furigana'`（bool, default: true）
- 詳細: RESEARCH_BRIEF.md § P1-1

**P1-2: ホーム画面（今日のミッション）**
- `home_screen.dart` は現在プレースホルダー。3ミッションカード + ストリーク表示に実装
- 詳細: RESEARCH_BRIEF.md § P1-2

**P1-3: 日次会話上限（無料20回/日）**
- `SharedPreferences` で `daily_chat_count` / `daily_chat_date` を管理
- 上限到達時は温かいトーンのダイアログを表示（怒らない）
- 詳細: RESEARCH_BRIEF.md § P1-3

---

## コーディングルール

- ウィジェットの追加は最小限。既存パターンに合わせる
- l10n文字列は必ず `ja` / `en` 両方追加
- `SharedPreferences` のキーは `'snake_case'` に統一
- コメントは日本語OK
- 新規ファイルを作る前に既存サービスを使い回せないか確認

## 絶対にやらないこと

- `_initTts()` の既存ロジックを壊す
- `voicevox_tts_service.dart` の日次制限ロジックを変更する
- RevenueCat の課金フローを変更する（リジェクトリスク）

---

## 競合分析サマリー（参考）

263件の競合★1〜3レビューから判明した「全競合が失敗している点」:
1. 課金の壁（53%のレビューが課金への怒り）
2. 初心者に難しすぎる（26%）
3. AIが「すごいですね！」しか言わない（11%）
4. 音声認識精度（19%）
5. ふりがな/ローマ字なし（日本語特有）

KawaiiLangはP0〜P1の実装でこれら全てを競合より先に解決できる。
