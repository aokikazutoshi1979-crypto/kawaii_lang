import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @categoryTitle.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ選択'**
  String get categoryTitle;

  /// No description provided for @targetLanguage.
  ///
  /// In ja, this message translates to:
  /// **'学びたい言語'**
  String get targetLanguage;

  /// No description provided for @level.
  ///
  /// In ja, this message translates to:
  /// **'レベル'**
  String get level;

  /// No description provided for @scene.
  ///
  /// In ja, this message translates to:
  /// **'学習場面'**
  String get scene;

  /// No description provided for @start.
  ///
  /// In ja, this message translates to:
  /// **'はじめる'**
  String get start;

  /// No description provided for @selectPrompt.
  ///
  /// In ja, this message translates to:
  /// **'すべての項目を選択してください。'**
  String get selectPrompt;

  /// No description provided for @langJapanese.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get langJapanese;

  /// No description provided for @langEnglish.
  ///
  /// In ja, this message translates to:
  /// **'英語'**
  String get langEnglish;

  /// No description provided for @langChineseSimplified.
  ///
  /// In ja, this message translates to:
  /// **'中国語(簡体)'**
  String get langChineseSimplified;

  /// No description provided for @langChineseTraditional.
  ///
  /// In ja, this message translates to:
  /// **'台湾中国語'**
  String get langChineseTraditional;

  /// No description provided for @langKorean.
  ///
  /// In ja, this message translates to:
  /// **'韓国語'**
  String get langKorean;

  /// No description provided for @langSpanish.
  ///
  /// In ja, this message translates to:
  /// **'スペイン語'**
  String get langSpanish;

  /// No description provided for @langFrench.
  ///
  /// In ja, this message translates to:
  /// **'フランス語'**
  String get langFrench;

  /// No description provided for @langGerman.
  ///
  /// In ja, this message translates to:
  /// **'ドイツ語'**
  String get langGerman;

  /// No description provided for @langVietnamese.
  ///
  /// In ja, this message translates to:
  /// **'ベトナム語'**
  String get langVietnamese;

  /// No description provided for @langIndonesian.
  ///
  /// In ja, this message translates to:
  /// **'インドネシア語'**
  String get langIndonesian;

  /// No description provided for @languageJapanese.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageEnglish.
  ///
  /// In ja, this message translates to:
  /// **'英語'**
  String get languageEnglish;

  /// No description provided for @languageChineseSimplified.
  ///
  /// In ja, this message translates to:
  /// **'中国語(簡体)'**
  String get languageChineseSimplified;

  /// No description provided for @languageChineseTraditional.
  ///
  /// In ja, this message translates to:
  /// **'台湾中国語'**
  String get languageChineseTraditional;

  /// No description provided for @languageKorean.
  ///
  /// In ja, this message translates to:
  /// **'韓国語'**
  String get languageKorean;

  /// No description provided for @languageSpanish.
  ///
  /// In ja, this message translates to:
  /// **'スペイン語'**
  String get languageSpanish;

  /// No description provided for @languageFrench.
  ///
  /// In ja, this message translates to:
  /// **'フランス語'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In ja, this message translates to:
  /// **'ドイツ語'**
  String get languageGerman;

  /// No description provided for @languageVietnamese.
  ///
  /// In ja, this message translates to:
  /// **'ベトナム語'**
  String get languageVietnamese;

  /// No description provided for @languageIndonesian.
  ///
  /// In ja, this message translates to:
  /// **'インドネシア語'**
  String get languageIndonesian;

  /// No description provided for @levelBeginner.
  ///
  /// In ja, this message translates to:
  /// **'初級'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In ja, this message translates to:
  /// **'中級'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In ja, this message translates to:
  /// **'上級'**
  String get levelAdvanced;

  /// No description provided for @sceneTravel.
  ///
  /// In ja, this message translates to:
  /// **'旅行'**
  String get sceneTravel;

  /// No description provided for @sceneGreeting.
  ///
  /// In ja, this message translates to:
  /// **'あいさつ'**
  String get sceneGreeting;

  /// No description provided for @sceneDating.
  ///
  /// In ja, this message translates to:
  /// **'デート'**
  String get sceneDating;

  /// No description provided for @sceneRestaurant.
  ///
  /// In ja, this message translates to:
  /// **'レストラン'**
  String get sceneRestaurant;

  /// No description provided for @sceneShopping.
  ///
  /// In ja, this message translates to:
  /// **'買い物'**
  String get sceneShopping;

  /// No description provided for @sceneBusiness.
  ///
  /// In ja, this message translates to:
  /// **'ビジネス'**
  String get sceneBusiness;

  /// No description provided for @selectQuestion.
  ///
  /// In ja, this message translates to:
  /// **'出題を選んでください'**
  String get selectQuestion;

  /// No description provided for @translatePrompt.
  ///
  /// In ja, this message translates to:
  /// **'翻訳してみましょう！'**
  String get translatePrompt;

  /// No description provided for @termsOfService.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get privacyPolicy;

  /// No description provided for @termsContent.
  ///
  /// In ja, this message translates to:
  /// **'このアプリをご利用いただく前に、以下の利用規約をご確認ください。本アプリを利用することにより、すべての条件に同意したものとみなされます。'**
  String get termsContent;

  /// No description provided for @privacyContent.
  ///
  /// In ja, this message translates to:
  /// **'本アプリは、ユーザーの個人情報を尊重します。取得した情報は、学習支援およびアプリの改善のためのみに使用されます。'**
  String get privacyContent;

  /// No description provided for @termsOfServiceContent.
  ///
  /// In ja, this message translates to:
  /// **'本アプリは、言語学習を支援する目的で提供されています。\n\n【利用対象】\n本アプリは全年齢を対象としています。13歳未満の未成年者は、保護者の同意を得た上でご利用ください。\n\n【免責事項】\nアプリの利用により生じた不利益・損害について、運営者は一切の責任を負いません。\n\n【将来的な課金要素について】\n現在は無料でご利用いただけますが、将来的に一部機能に課金が発生する場合があります。課金要素については事前にお知らせいたします。\n\n【利用の中止】\n利用者が本規約に違反した場合、運営者は通知なく利用を制限または停止できるものとします。'**
  String get termsOfServiceContent;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In ja, this message translates to:
  /// **'本アプリは、ユーザーのプライバシーを尊重し、以下の方針に基づいて運営されます。\n\n【収集する情報】\nユーザーの言語設定やアプリの利用履歴など、個人を特定しない範囲の情報を収集することがあります。\n\n【利用目的】\nアプリの品質向上、機能改善のために情報を活用します。無断で第三者に提供することはありません。\n\n【外部サービス】\n今後のアップデートで課金機能を導入する際、外部決済サービスを利用する場合があります。\n\n【情報の管理】\n取得した情報は適切に管理され、安全に保管されます。'**
  String get privacyPolicyContent;

  /// No description provided for @errorTooLong.
  ///
  /// In ja, this message translates to:
  /// **'メッセージが長すぎます。約100文字以内で入力してください。'**
  String get errorTooLong;

  /// No description provided for @errorRateLimit.
  ///
  /// In ja, this message translates to:
  /// **'アクセスが多いため、少し時間をおいて再試行してください（1分に最大5回まで）'**
  String get errorRateLimit;

  /// No description provided for @errorNoMessage.
  ///
  /// In ja, this message translates to:
  /// **'メッセージが入力されていません。'**
  String get errorNoMessage;

  /// No description provided for @errorServerError.
  ///
  /// In ja, this message translates to:
  /// **'サーバーエラーが発生しました。もう一度お試しください。'**
  String get errorServerError;

  /// No description provided for @keyboardGuideButton.
  ///
  /// In ja, this message translates to:
  /// **'🌐を押しても学びたい言語のキーボードが表示されない場合はこちら'**
  String get keyboardGuideButton;

  /// No description provided for @keyboardGuideIos.
  ///
  /// In ja, this message translates to:
  /// **'iOSで学びたい言語のキーボードが表示されない場合：「設定」>「一般」>「キーボード」>「新しいキーボードを追加」から目的の言語を追加してください。'**
  String get keyboardGuideIos;

  /// No description provided for @keyboardGuideAndroid.
  ///
  /// In ja, this message translates to:
  /// **'Androidで学びたい言語のキーボードが表示されない場合：「設定」>「システム」>「言語と入力」>「キーボード」>「キーボードを追加」から目的の言語を選択してください。'**
  String get keyboardGuideAndroid;

  /// No description provided for @keyboardGuideBody.
  ///
  /// In ja, this message translates to:
  /// **'お使いのスマートフォンに学びたい言語のキーボードがインストールされていない場合、チャット画面で入力できません。以下の手順で追加してください。\n\niOS:\n設定 > 一般 > キーボード > 新しいキーボードを追加\n\nAndroid:\n設定 > 言語と入力 > キーボード > キーボードを追加'**
  String get keyboardGuideBody;

  /// No description provided for @keyboardGuideTitle.
  ///
  /// In ja, this message translates to:
  /// **'キーボード追加ガイド'**
  String get keyboardGuideTitle;

  /// ダイアログのOKボタンラベル
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @correct.
  ///
  /// In ja, this message translates to:
  /// **'正解です！'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In ja, this message translates to:
  /// **'修正が必要です！'**
  String get incorrect;

  /// No description provided for @answerMeaningPrefix.
  ///
  /// In ja, this message translates to:
  /// **'あなたの回答の意味はこちらです。:「{translation}」'**
  String answerMeaningPrefix(Object translation);

  /// No description provided for @answerTranslationPrefix.
  ///
  /// In ja, this message translates to:
  /// **'修正例'**
  String get answerTranslationPrefix;

  /// ユーザーの回答が日本語として意味不明だったときのメッセージ
  ///
  /// In ja, this message translates to:
  /// **'「{userAnswer}」:学習言語として意味が通じません。'**
  String invalidMeaning(Object userAnswer);

  /// GPTの応答が壊れていたときに表示するメッセージ
  ///
  /// In ja, this message translates to:
  /// **'申し訳ありません。システムエラーが発生しました。もう一度お試しください。'**
  String get errorBrokenGpt;

  /// 文法的に正しいときの応答
  ///
  /// In ja, this message translates to:
  /// **'{userAnswer}：文法的には合っています。'**
  String grammarCorrect(Object userAnswer);

  /// 文法的に誤っているときの応答
  ///
  /// In ja, this message translates to:
  /// **'{userAnswer}：文法的に間違っています。'**
  String grammarIncorrect(Object userAnswer);

  /// No description provided for @errorSessionMismatch.
  ///
  /// In ja, this message translates to:
  /// **'他の端末でログインされました。再ログインしてください。'**
  String get errorSessionMismatch;

  /// No description provided for @errorPunctuationFailed.
  ///
  /// In ja, this message translates to:
  /// **'⚠️ 句読点付きの文が取得できませんでした。'**
  String get errorPunctuationFailed;

  /// No description provided for @sceneTrial.
  ///
  /// In ja, this message translates to:
  /// **'無料プレビュー'**
  String get sceneTrial;

  /// ロック中アラートの本文
  ///
  /// In ja, this message translates to:
  /// **'この問題はサブスクリプション加入者のみ利用できます。'**
  String get lockedMessage;

  /// No description provided for @resetPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを忘れた方はこちら'**
  String get resetPassword;

  /// No description provided for @enterEmailForReset.
  ///
  /// In ja, this message translates to:
  /// **'パスワードをリセットするためにメールアドレスを入力してください。'**
  String get enterEmailForReset;

  /// No description provided for @sendResetEmail.
  ///
  /// In ja, this message translates to:
  /// **'リセットメールを送信'**
  String get sendResetEmail;

  /// No description provided for @passwordResetSent.
  ///
  /// In ja, this message translates to:
  /// **'パスワードリセット用のメールを送信しました。'**
  String get passwordResetSent;

  /// No description provided for @passwordResetError.
  ///
  /// In ja, this message translates to:
  /// **'リセットメールの送信に失敗しました。'**
  String get passwordResetError;

  /// No description provided for @settingsTitle.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// No description provided for @welcomeUser.
  ///
  /// In ja, this message translates to:
  /// **'ようこそ、{name} さん'**
  String welcomeUser(Object name);

  /// No description provided for @filterLabel.
  ///
  /// In ja, this message translates to:
  /// **'絞り込み：'**
  String get filterLabel;

  /// No description provided for @filterTopicLabel.
  ///
  /// In ja, this message translates to:
  /// **'トピック'**
  String get filterTopicLabel;

  /// No description provided for @levelStarter.
  ///
  /// In ja, this message translates to:
  /// **'スターター'**
  String get levelStarter;

  /// No description provided for @tapToExpand.
  ///
  /// In ja, this message translates to:
  /// **'タップして全文を見る'**
  String get tapToExpand;

  /// No description provided for @userNameTitle.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名'**
  String get userNameTitle;

  /// No description provided for @userNameIntro.
  ///
  /// In ja, this message translates to:
  /// **'表示名として使います。後から変更できます。'**
  String get userNameIntro;

  /// No description provided for @userNameHint.
  ///
  /// In ja, this message translates to:
  /// **'名前を入力'**
  String get userNameHint;

  /// No description provided for @userNameContinue.
  ///
  /// In ja, this message translates to:
  /// **'はじめる'**
  String get userNameContinue;

  /// No description provided for @userNameSave.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get userNameSave;

  /// No description provided for @userNameEdit.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名を変更'**
  String get userNameEdit;

  /// No description provided for @userNameUpdated.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名を更新しました'**
  String get userNameUpdated;

  /// No description provided for @registeredDate.
  ///
  /// In ja, this message translates to:
  /// **'登録日: {date}'**
  String registeredDate(Object date);

  /// ユーザー取得エラー時の表示メッセージ
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報の取得に失敗しました（エラー: {error}）'**
  String userFetchFailed(Object error);

  /// No description provided for @languageUpdated.
  ///
  /// In ja, this message translates to:
  /// **'言語設定を更新しました'**
  String get languageUpdated;

  /// No description provided for @registerAccount.
  ///
  /// In ja, this message translates to:
  /// **'アカウント登録'**
  String get registerAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'端末変更やアプリ削除で学習履歴が失われます。データ保存のために、こちらからアカウント登録をしてください。'**
  String get registerSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'すでに登録済みの方はこちら'**
  String get loginSubtitle;

  /// No description provided for @logout.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get login;

  /// No description provided for @email.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get email;

  /// パスワード入力フィールドのプレースホルダー
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get password;

  /// No description provided for @invalidEmail.
  ///
  /// In ja, this message translates to:
  /// **'正しいメールアドレスを入力してください'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは6文字以上で入力してください'**
  String get passwordTooShort;

  /// No description provided for @loginFailed.
  ///
  /// In ja, this message translates to:
  /// **'ログインに失敗しました'**
  String get loginFailed;

  /// No description provided for @loginError.
  ///
  /// In ja, this message translates to:
  /// **'ログインエラー'**
  String get loginError;

  /// No description provided for @noAccountRegister.
  ///
  /// In ja, this message translates to:
  /// **'アカウントをお持ちでない方はこちら'**
  String get noAccountRegister;

  /// No description provided for @register.
  ///
  /// In ja, this message translates to:
  /// **'登録'**
  String get register;

  /// No description provided for @registerFailed.
  ///
  /// In ja, this message translates to:
  /// **'登録に失敗しました'**
  String get registerFailed;

  /// No description provided for @purchaseSuccess.
  ///
  /// In ja, this message translates to:
  /// **'ご購入ありがとうございます！'**
  String get purchaseSuccess;

  /// No description provided for @subscribe.
  ///
  /// In ja, this message translates to:
  /// **'加入する'**
  String get subscribe;

  /// No description provided for @subscribeNow.
  ///
  /// In ja, this message translates to:
  /// **'7日間無料お試し期間あり,ベーシックプランに加入する'**
  String get subscribeNow;

  /// ロック中アラートのタイトル
  ///
  /// In ja, this message translates to:
  /// **'ロック中'**
  String get lockedTitle;

  /// シーン名をそのままタイトルに表示します
  ///
  /// In ja, this message translates to:
  /// **'{sceneKey}'**
  String sceneTitle(Object sceneKey);

  /// No description provided for @restorePurchase.
  ///
  /// In ja, this message translates to:
  /// **'購入を復元'**
  String get restorePurchase;

  /// No description provided for @restorePurchaseSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'以前の購入状態を復元します'**
  String get restorePurchaseSubtitle;

  /// No description provided for @restoringPurchase.
  ///
  /// In ja, this message translates to:
  /// **'購入履歴を確認中...'**
  String get restoringPurchase;

  /// 以前購入したサブスクリプションを復元するボタンのラベル
  ///
  /// In ja, this message translates to:
  /// **'サブスクリプションを復元'**
  String get restoreSubscription;

  /// No description provided for @subscriptionTitle.
  ///
  /// In ja, this message translates to:
  /// **'サブスクリプション'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionPlanTitle.
  ///
  /// In ja, this message translates to:
  /// **'<サブスクリプション詳細>'**
  String get subscriptionPlanTitle;

  /// No description provided for @subscriptionPlanMonthly.
  ///
  /// In ja, this message translates to:
  /// **'• プラン名：ベーシックプラン'**
  String get subscriptionPlanMonthly;

  /// No description provided for @subscriptionPlanPeriod.
  ///
  /// In ja, this message translates to:
  /// **'• 期間：1ヶ月'**
  String get subscriptionPlanPeriod;

  /// No description provided for @subscriptionPlanPrice.
  ///
  /// In ja, this message translates to:
  /// **'• 価格：¥1,500（税込）'**
  String get subscriptionPlanPrice;

  /// No description provided for @subscriptionPlanTrial.
  ///
  /// In ja, this message translates to:
  /// **'• 未加入の場合：無料プレビューのみ体験可能です。'**
  String get subscriptionPlanTrial;

  /// No description provided for @subscriptionCurrentStatusTitle.
  ///
  /// In ja, this message translates to:
  /// **'現在の状態'**
  String get subscriptionCurrentStatusTitle;

  /// No description provided for @subscriptionStatusSubscribed.
  ///
  /// In ja, this message translates to:
  /// **'• 加入済みの場合：無料プレビューを含むすべての学習場面が開放され、何度でも利用可能。'**
  String get subscriptionStatusSubscribed;

  /// No description provided for @subscriptionStatus.
  ///
  /// In ja, this message translates to:
  /// **'• 加入済み：無料プレビューだけでなく、全3種類の学習場面が全て開放され、全ての場面を何度でも利用可能。'**
  String get subscriptionStatus;

  /// No description provided for @subscriptionStatusTrial.
  ///
  /// In ja, this message translates to:
  /// **'未加入：無料プレビューのみ体験可能です。'**
  String get subscriptionStatusTrial;

  /// No description provided for @subscriptionManageButton.
  ///
  /// In ja, this message translates to:
  /// **'Apple でサブスクリプション管理を開く'**
  String get subscriptionManageButton;

  /// No description provided for @subscriptionManageNote.
  ///
  /// In ja, this message translates to:
  /// **'※月額プランの解約・再加入は上記から行えます。'**
  String get subscriptionManageNote;

  /// No description provided for @subscriptionManageTitle.
  ///
  /// In ja, this message translates to:
  /// **'サブスクリプション詳細'**
  String get subscriptionManageTitle;

  /// No description provided for @subscriptionManageSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'プランの確認、加入はこちら'**
  String get subscriptionManageSubtitle;

  /// No description provided for @subscriptionPriceTaxSuffix.
  ///
  /// In ja, this message translates to:
  /// **'（税込）'**
  String get subscriptionPriceTaxSuffix;

  /// No description provided for @languageSelectionTitle.
  ///
  /// In ja, this message translates to:
  /// **'母語を選択'**
  String get languageSelectionTitle;

  /// No description provided for @languageSelectionDescription.
  ///
  /// In ja, this message translates to:
  /// **'ご利用の言語を選んでください'**
  String get languageSelectionDescription;

  /// No description provided for @similarExpressionPrefix.
  ///
  /// In ja, this message translates to:
  /// **'別の表現：'**
  String get similarExpressionPrefix;

  /// 匿名ユーザーの場合に表示する名前
  ///
  /// In ja, this message translates to:
  /// **'ゲスト'**
  String get guest;

  /// No description provided for @viewTerms.
  ///
  /// In ja, this message translates to:
  /// **'利用規約（EULA）を読む'**
  String get viewTerms;

  /// No description provided for @viewPrivacyPolicy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシーを読む'**
  String get viewPrivacyPolicy;

  /// ログイン時のパスワードバリデーションエラーメッセージ（6文字未満の場合）
  ///
  /// In ja, this message translates to:
  /// **'パスワードは6文字以上で入力してください'**
  String get invalidPassword;

  /// ユーザーがサブスクに加入していないときに表示するラベル
  ///
  /// In ja, this message translates to:
  /// **'未加入'**
  String get subscriptionStatusUnsubscribed;

  /// メール登録ユーザー向けの「アカウントを削除する」ボタンラベル
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除する'**
  String get settings_deleteAccount;

  /// 匿名ユーザー向けの「データを初期化する」ボタンラベル
  ///
  /// In ja, this message translates to:
  /// **'データを初期化する'**
  String get settings_resetData;

  /// アカウント削除時の確認ダイアログメッセージ
  ///
  /// In ja, this message translates to:
  /// **'本当にアカウントとすべてのデータを削除しますか？\nこの操作は取り消せません。'**
  String get settings_confirmDeleteAccount;

  /// 匿名データ初期化時の確認ダイアログメッセージ
  ///
  /// In ja, this message translates to:
  /// **'本当にデータを初期化しますか？\nこれまでの進捗がすべて消えます。'**
  String get settings_confirmResetData;

  /// アカウント削除時にパスワード再入力を促すダイアログタイトル
  ///
  /// In ja, this message translates to:
  /// **'パスワードを入力'**
  String get enterPassword;

  /// ダイアログのキャンセルボタンラベル
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @logoutConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'本当にログアウトしますか？'**
  String get logoutConfirmation;

  /// No description provided for @viewFaq.
  ///
  /// In ja, this message translates to:
  /// **'よくある質問'**
  String get viewFaq;

  /// No description provided for @checking.
  ///
  /// In ja, this message translates to:
  /// **'判定中です…'**
  String get checking;

  /// No description provided for @sceneVocabulary.
  ///
  /// In ja, this message translates to:
  /// **'短文'**
  String get sceneVocabulary;

  /// subSceneフィルタの「すべて」ボタン表示
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get subsceneAll;

  /// 今日の正解数
  ///
  /// In ja, this message translates to:
  /// **'今日の正解 {count}問'**
  String todayCorrectCount(Object count);

  /// 連続正解日数
  ///
  /// In ja, this message translates to:
  /// **'連続正解 {days}日'**
  String streakDaysCount(Object days);

  /// プロフィール画面タイトル
  ///
  /// In ja, this message translates to:
  /// **'プロフィール'**
  String get profileTitle;

  /// 累計正解数
  ///
  /// In ja, this message translates to:
  /// **'累計正解 {count}問'**
  String totalCorrectCount(Object count);

  /// カテゴリー別の正解数 見出し
  ///
  /// In ja, this message translates to:
  /// **'カテゴリー別の正解数'**
  String get categoryCorrectHeader;

  /// 履歴データがない場合の表示
  ///
  /// In ja, this message translates to:
  /// **'まだデータがありません'**
  String get noHistoryData;

  /// 現在のランク表示
  ///
  /// In ja, this message translates to:
  /// **'現在のランク: {rank}'**
  String currentRank(Object rank);

  /// 次のランクへの進捗
  ///
  /// In ja, this message translates to:
  /// **'次のランク {rank} までの進捗'**
  String progressToRank(Object rank);

  /// 次のランクまでの残り正解数
  ///
  /// In ja, this message translates to:
  /// **'次のランクまであと {count}問'**
  String nextRankIn(Object count);

  /// 最高ランク到達時の表示
  ///
  /// In ja, this message translates to:
  /// **'最高ランクに到達'**
  String get maxRankAchieved;

  /// ランクアップ時のタイトル
  ///
  /// In ja, this message translates to:
  /// **'ランクアップ！'**
  String get rankUpTitle;

  /// ランクアップ時の本文
  ///
  /// In ja, this message translates to:
  /// **'{rank}に到達しました'**
  String rankUpBody(Object rank);

  /// 最近解いた問題の見出し
  ///
  /// In ja, this message translates to:
  /// **'最近解いた問題（直近{count}件）'**
  String recentQuestionsTitle(Object count);

  /// 最近解いた問題の出題ボタン
  ///
  /// In ja, this message translates to:
  /// **'出題'**
  String get startQuestionButton;

  /// 出題リストのガイド文
  ///
  /// In ja, this message translates to:
  /// **'下から1つ選ぶと練習が始まります'**
  String get questionListGuide;

  /// 出題カードのサブラベル
  ///
  /// In ja, this message translates to:
  /// **'タップして練習'**
  String get tapToPractice;

  /// No description provided for @recordingAutoStopped.
  ///
  /// In ja, this message translates to:
  /// **'録音は10秒で自動停止しました。'**
  String get recordingAutoStopped;

  /// No description provided for @readingLabel.
  ///
  /// In ja, this message translates to:
  /// **'リーディング'**
  String get readingLabel;

  /// No description provided for @listeningLabel.
  ///
  /// In ja, this message translates to:
  /// **'リスニング'**
  String get listeningLabel;

  /// No description provided for @listeningPrompt.
  ///
  /// In ja, this message translates to:
  /// **'何と言っているでしょうか？'**
  String get listeningPrompt;

  /// Scene label for Work
  ///
  /// In ja, this message translates to:
  /// **'仕事'**
  String get sceneWork;

  /// Scene label for Social interactions and hobbies
  ///
  /// In ja, this message translates to:
  /// **'交流・趣味'**
  String get sceneSocial_interactions_hobbies;

  /// Scene label for Culture and Entertainment
  ///
  /// In ja, this message translates to:
  /// **'文化・エンタメ'**
  String get sceneculture_entertainment;

  /// Scene label for Community life
  ///
  /// In ja, this message translates to:
  /// **'地域生活'**
  String get scenecommunity_life;

  /// ユーザーの回答見出し
  ///
  /// In ja, this message translates to:
  /// **'あなたの回答'**
  String get userAnswerHeader;

  /// 正解ラベル
  ///
  /// In ja, this message translates to:
  /// **'正解'**
  String get badgeCorrect;

  /// 不正解ラベル／改善が必要
  ///
  /// In ja, this message translates to:
  /// **'改善点があります'**
  String get badgeNeedsImprovement;

  /// オリジナル文の翻訳の見出し
  ///
  /// In ja, this message translates to:
  /// **'オリジナルの翻訳'**
  String get originalTranslationHeader;

  /// オリジナル文の音声転写の見出し
  ///
  /// In ja, this message translates to:
  /// **'オリジナルの音声転写'**
  String get originalTranscriptionHeader;

  /// オリジナル文の解説の見出し
  ///
  /// In ja, this message translates to:
  /// **'オリジナルの解説'**
  String get originalExplanationHeader;

  /// 類似表現の見出し
  ///
  /// In ja, this message translates to:
  /// **'フレンドリーな類似表現'**
  String get similarExpressionHeader;

  /// 誤答メッセージ。raw はユーザーの回答文字列
  ///
  /// In ja, this message translates to:
  /// **'{raw} \nこちらの回答は、文法的や意味的に正しくありません。'**
  String incorrectMessageWithRaw(String raw);

  /// ユーザーの回答が出題の意味を的確に表している場合に表示されるメッセージ
  ///
  /// In ja, this message translates to:
  /// **'この回答は出題の意味ついて的確に表しています。'**
  String get answerMeaningAccurate;

  /// No description provided for @subscriptionUpsellTitle.
  ///
  /// In ja, this message translates to:
  /// **'ベーシックプランで学習を続けましょう！'**
  String get subscriptionUpsellTitle;

  /// No description provided for @subscriptionUpsellMessage.
  ///
  /// In ja, this message translates to:
  /// **'無料プランは体験だけ。本気で話せるようになるなら、今すぐ全シーン解放！'**
  String get subscriptionUpsellMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'id',
        'ja',
        'ko',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
