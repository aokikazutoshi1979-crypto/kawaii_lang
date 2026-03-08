// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get categoryTitle => '选择类别';

  @override
  String get targetLanguage => '学习语言';

  @override
  String get level => '等级';

  @override
  String get scene => '学习场景';

  @override
  String get start => '开始';

  @override
  String get selectPrompt => '请选择所有项目。';

  @override
  String get langJapanese => '日语';

  @override
  String get langEnglish => '英语';

  @override
  String get langChineseSimplified => '中文（简体）';

  @override
  String get langChineseTraditional => '台湾';

  @override
  String get langKorean => '韩语';

  @override
  String get langSpanish => '西班牙语';

  @override
  String get langFrench => '法语';

  @override
  String get langGerman => '德语';

  @override
  String get langVietnamese => '越南语';

  @override
  String get langIndonesian => '印尼语';

  @override
  String get languageJapanese => '日语';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageChineseSimplified => '中文（简体）';

  @override
  String get languageChineseTraditional => '台湾';

  @override
  String get languageKorean => '韩语';

  @override
  String get languageSpanish => '西班牙语';

  @override
  String get languageFrench => '法语';

  @override
  String get languageGerman => '德语';

  @override
  String get languageVietnamese => '越南语';

  @override
  String get languageIndonesian => '印尼语';

  @override
  String get levelBeginner => '初级';

  @override
  String get levelIntermediate => '中级';

  @override
  String get levelAdvanced => '高级';

  @override
  String get sceneTravel => '旅行';

  @override
  String get sceneGreeting => '问候';

  @override
  String get sceneDating => '约会';

  @override
  String get sceneRestaurant => '餐厅';

  @override
  String get sceneShopping => '购物';

  @override
  String get sceneBusiness => '商务';

  @override
  String get selectQuestion => '出題を選んでください';

  @override
  String get translatePrompt => '来翻译看看吧！';

  @override
  String get termsOfService => '服务条款';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsContent => '在使用本应用程序之前，请阅读以下服务条款。使用本应用程序即表示您同意所有条款和条件。';

  @override
  String get privacyContent => '我们尊重您的隐私。所收集的信息仅用于学习支持和改进应用程序体验。';

  @override
  String get termsOfServiceContent =>
      '本应用旨在支持语言学习。\n\n【适用对象】\n本应用适用于所有年龄段。13岁以下的用户必须在监护人同意下使用本应用。\n\n【免责声明】\n由于使用本应用所造成的任何损失或不利，开发者不承担任何责任。\n\n【未来的付费功能】\n目前本应用为免费使用，但将来可能会引入部分付费功能，届时将提前通知用户。\n\n【终止使用】\n如用户违反本条款，开发者有权在不事先通知的情况下暂停或限制使用权限。';

  @override
  String get privacyPolicyContent =>
      '本应用尊重用户的隐私，并根据以下政策进行运营：\n\n【收集的信息】\n可能会收集不涉及个人身份的信息，如语言设置和使用记录。\n\n【使用目的】\n收集的信息将用于提升应用品质与用户体验，不会在未经同意的情况下提供给第三方。\n\n【第三方服务】\n如果将来增加付费功能，可能会使用第三方支付服务。\n\n【信息管理】\n所收集的信息将被妥善保管，确保安全。';

  @override
  String get errorTooLong => '消息过长。请将内容控制在大约100个字符以内。';

  @override
  String get errorRateLimit => '请求次数过多，请稍后再试（每分钟最多5次）。';

  @override
  String get errorNoMessage => '没有提供消息内容。';

  @override
  String get errorServerError => '服务器发生错误，请稍后再试。';

  @override
  String get keyboardGuideButton => '如果点 🌐 后没有显示目标语言的键盘，请点此查看';

  @override
  String get keyboardGuideIos =>
      '如果在 iOS 上无法显示目标语言的键盘：请前往 设置 > 通用 > 键盘 > 添加新键盘，选择目标语言。';

  @override
  String get keyboardGuideAndroid =>
      '如果在 Android 上无法显示目标语言的键盘：请前往 设置 > 系统 > 语言和输入法 > 键盘 > 添加键盘，选择目标语言。';

  @override
  String get keyboardGuideBody =>
      '如果您的手机中未安装目标语言的键盘，您将无法在聊天界面输入。请按照以下步骤添加：\n\niOS:\n设置 > 通用 > 键盘 > 添加新键盘\n\nAndroid:\n设置 > 语言和输入法 > 键盘 > 添加键盘';

  @override
  String get keyboardGuideTitle => '鍵盤設定指南';

  @override
  String get ok => '确定';

  @override
  String get correct => '回答正确！';

  @override
  String get incorrect => '修改示例';

  @override
  String answerMeaningPrefix(Object translation) {
    return '这就是你的答案的含义。:$translation';
  }

  @override
  String get answerTranslationPrefix => '翻译答案';

  @override
  String invalidMeaning(Object userAnswer) {
    return '$userAnswer： 作为一种学习语言，它毫无意义。';
  }

  @override
  String get errorBrokenGpt => '抱歉，系统出错。请重试。';

  @override
  String grammarCorrect(Object userAnswer) {
    return '$userAnswer：从语法上来说，这是正确的。';
  }

  @override
  String grammarIncorrect(Object userAnswer) {
    return '$userAnswer：这在语法上是不正确的。';
  }

  @override
  String get errorSessionMismatch => '您已从其他设备登录。请重新登录。';

  @override
  String get errorPunctuationFailed => '⚠️ 无法检索带标点的句子。';

  @override
  String get sceneTrial => '免费预览';

  @override
  String get todaysSpecialTitle => '今日推荐';

  @override
  String get freePreviewSubtitle => '免费预览';

  @override
  String get lockedMessage => '此期仅供订阅者阅读。';

  @override
  String get resetPassword => '忘记密码？';

  @override
  String get enterEmailForReset => '请输入电子邮件地址以重设密码。';

  @override
  String get sendResetEmail => '发送重设邮件';

  @override
  String get passwordResetSent => '已发送密码重设邮件。';

  @override
  String get passwordResetError => '发送重设邮件失败。';

  @override
  String get settingsTitle => '设置';

  @override
  String welcomeUser(Object name) {
    return '欢迎，$name';
  }

  @override
  String get filterLabel => '筛选：';

  @override
  String get filterTopicLabel => '主题';

  @override
  String get filterButton => '筛选';

  @override
  String get filterClear => '清除';

  @override
  String filterStatusSummary(Object count, Object level, Object topic) {
    return '$count • L:$level • T:$topic';
  }

  @override
  String filterResultsCount(Object count) {
    return '$count条';
  }

  @override
  String get levelStarter => '入门';

  @override
  String get tapToExpand => '点击展开';

  @override
  String get userNameTitle => '用户名';

  @override
  String get userNameIntro => '此名称会显示在应用中，可随时更改。';

  @override
  String get userNameHint => '请输入姓名';

  @override
  String get userNameContinue => '继续';

  @override
  String get userNameSave => '保存';

  @override
  String get userNameEdit => '修改用户名';

  @override
  String get userNameUpdated => '用户名已更新';

  @override
  String registeredDate(Object date) {
    return '注册日期: $date';
  }

  @override
  String userFetchFailed(Object error) {
    return '获取用户信息失败（错误：$error）';
  }

  @override
  String get languageUpdated => '语言设置已更新';

  @override
  String get registerAccount => '注册账户';

  @override
  String get registerSubtitle => '更换设备或删除应用时，学习记录会丢失。为保存数据，请在此注册账号。';

  @override
  String get loginTitle => '登录';

  @override
  String get loginSubtitle => '已有账户？请点击';

  @override
  String get logout => '登出';

  @override
  String get login => '登录';

  @override
  String get email => '电子邮件';

  @override
  String get password => '密码';

  @override
  String get invalidEmail => '请输入有效的电子邮件地址';

  @override
  String get passwordTooShort => '密码长度必须至少为6个字符';

  @override
  String get loginFailed => '登录失败';

  @override
  String get loginError => '登录错误';

  @override
  String get noAccountRegister => '没有账户？点此注册';

  @override
  String get register => '登记';

  @override
  String get registerFailed => '注册失败';

  @override
  String get purchaseSuccess => '感谢您的购买！';

  @override
  String get subscribe => '订阅';

  @override
  String get subscribeNow => '7天免费预览，加入基础计划';

  @override
  String get lockedTitle => '已锁定';

  @override
  String sceneTitle(Object sceneKey) {
    return '$sceneKey';
  }

  @override
  String get restorePurchase => '恢复购买';

  @override
  String get restorePurchaseSubtitle => '恢复您之前的订阅状态';

  @override
  String get restoringPurchase => '正在恢复购买记录...';

  @override
  String get restoreSubscription => '恢复订阅';

  @override
  String get subscriptionTitle => '订阅';

  @override
  String get subscriptionPlanTitle => '<订阅详情>';

  @override
  String get subscriptionPlanMonthly => '• 计划名称：基本计划';

  @override
  String get subscriptionPlanPeriod => '• 持续时间：1个月';

  @override
  String get subscriptionPlanPrice => '• 价格：1,500日元（含税）';

  @override
  String get subscriptionPlanTrial => '• 如果您不是会员，您只能尝试免费预览。';

  @override
  String get subscriptionCurrentStatusTitle => '当前状态';

  @override
  String get subscriptionStatusSubscribed => '• 已订阅：解锁所有学习场景（包括免费预览），可无限制使用。';

  @override
  String get subscriptionStatus => '• 已订阅：所有学习场景均开放可用。';

  @override
  String get subscriptionStatusTrial => '非会员：仅提供免费预览。';

  @override
  String get subscriptionManageButton => '在 Apple 管理订阅';

  @override
  String get subscriptionManageNote => '※ 可从以上链接取消或重新订阅。';

  @override
  String get subscriptionManageTitle => '订阅详情';

  @override
  String get subscriptionManageSubtitle => '查看计划并在此注册';

  @override
  String get subscriptionPriceTaxSuffix => '（含税）';

  @override
  String get languageSelectionTitle => '选择您的母语';

  @override
  String get languageSelectionDescription => '请选择您的语言';

  @override
  String get similarExpressionPrefix => '其他表述：';

  @override
  String get guest => '访客';

  @override
  String get viewTerms => '阅读使用条款 (EULA)';

  @override
  String get viewPrivacyPolicy => '阅读隐私政策';

  @override
  String get invalidPassword => '密码长度至少为6个字符';

  @override
  String get subscriptionStatusUnsubscribed => '不是会员';

  @override
  String get settings_deleteAccount => '删除账户';

  @override
  String get settings_resetData => '重置数据';

  @override
  String get settings_confirmDeleteAccount => '您确定要删除您的账户及所有数据吗？此操作不可撤销。';

  @override
  String get settings_confirmResetData => '您确定要重置数据吗？所有进度将被删除。';

  @override
  String get enterPassword => '请输入密码';

  @override
  String get cancel => '取消';

  @override
  String get logoutConfirmation => '您确定要退出吗？';

  @override
  String get viewFaq => '常见问题';

  @override
  String get checking => '正在判定…';

  @override
  String get sceneVocabulary => '短句';

  @override
  String get subsceneAll => '全部';

  @override
  String todayCorrectCount(Object count) {
    return '今日正确 $count题';
  }

  @override
  String streakDaysCount(Object days) {
    return '连续正确 $days天';
  }

  @override
  String get profileTitle => '个人资料';

  @override
  String totalCorrectCount(Object count) {
    return '累计正确 $count题';
  }

  @override
  String get categoryCorrectHeader => '分类正确数';

  @override
  String get noHistoryData => '暂无数据';

  @override
  String currentRank(Object rank) {
    return '当前等级：$rank';
  }

  @override
  String progressToRank(Object rank) {
    return '进度至 $rank';
  }

  @override
  String nextRankIn(Object count) {
    return '再答对 $count 题升到下一等级';
  }

  @override
  String get maxRankAchieved => '已达到最高等级';

  @override
  String get rankUpTitle => '升级了！';

  @override
  String rankUpBody(Object rank) {
    return '你已达到 $rank。';
  }

  @override
  String recentQuestionsTitle(Object count) {
    return '最近题目（最近$count题）';
  }

  @override
  String get startQuestionButton => '开始';

  @override
  String get questionListGuide => '下方选择一项即可开始练习。';

  @override
  String get tapToPractice => '点击练习';

  @override
  String get recordingAutoStopped => '录音已在 10 秒时自动停止。';

  @override
  String get recordingLabel => '录音中…';

  @override
  String get readingLabel => '阅读';

  @override
  String get listeningLabel => '听力';

  @override
  String get listeningPrompt => '在说什么？';

  @override
  String get sceneWork => '工作';

  @override
  String get sceneSocial_interactions_hobbies => '交流和爱好';

  @override
  String get sceneculture_entertainment => '文化和娱乐';

  @override
  String get scenecommunity_life => '社区生活';

  @override
  String get userAnswerHeader => '你的回答';

  @override
  String get badgeCorrect => '正确';

  @override
  String get badgeNeedsImprovement => '差一点！再试一次吧 🌸';

  @override
  String get hintLabel => '💡 试着这样说：';

  @override
  String get originalTranslationHeader => '原文翻译';

  @override
  String get originalTranscriptionHeader => '原文转写';

  @override
  String get originalExplanationHeader => '原文说明';

  @override
  String get similarExpressionHeader => '友好的相似表达';

  @override
  String incorrectMessageWithRaw(String raw) {
    return '$raw \n此回答在语法或语义上不正确。';
  }

  @override
  String get answerMeaningAccurate => '此回答准确地表达了题目的含义。';

  @override
  String get tumugiAccuracyCorrect =>
      'Your answer captures the meaning just right!';

  @override
  String get kasumiAccuracyCorrect =>
      'W-Well, the meaning is correct... not that I\'m saying you did great or anything.';

  @override
  String get tumugiAccuracyIncorrect => '差一点！再听一次，一起试试☺️ ';

  @override
  String get kasumiAccuracyIncorrect => '嗯…差一点。不过你肯定能行的。再来一次。';

  @override
  String get tsumugiIntroTitle => '初次见面，我是紬';

  @override
  String get tsumugiIntroBody => '在这里，你可以从简短的一句话开始练习。说不好也没关系，我们慢慢来，一起进步吧？';

  @override
  String get tsumugiIntroStartButton => '开始';

  @override
  String get tsumugiIntroWhoIsButton => '紬是谁？';

  @override
  String get tsumugiIntroLaterButton => '稍后';

  @override
  String get tsumugiProfileMenuTitle => '关于紬';

  @override
  String get tsumugiProfileScreenTitle => '关于紬';

  @override
  String get tsumugiProfileBody =>
      '我是紬。谢谢你来到这里。\n学习有时会很累。这种时候，稍微停下来歇一歇也没关系。\n不用着急。尊重你自己的节奏，我们一起慢慢走就好。\n随时都可以叫我。我在这里等你。☕\n\n这种时候来找我说说话吧\n・总觉得提不起劲\n・题目做不出来\n・想要有人夸夸你\n・想稍微休息一下\n・觉得今天已经很努力了\n\n小小的约定\n你说的事，只有我们之间知道。\n有时候不逼自己也没关系。你的节奏最重要。\n\n你能来，我一直都很期待呢。';

  @override
  String get tsumugiCatchphrase => '慢慢来就好。这里是安心的地方。';

  @override
  String get kasumiProfileMenuTitle => '关于香澄';

  @override
  String get kasumiProfileScreenTitle => '关于香澄';

  @override
  String get kasumiCatchphrase => '你有好好学习吗？……我在看着你呢。';

  @override
  String get kasumiProfileBody =>
      '我是香澄。……才不是担心你啊。\n只是觉得，都要学的话，就好好学嘛。\n如果有什么不懂的……好吧，你可以来问我。我会回答的。\n遇到困难不要客气。……帮这点忙而已，没什么。\n\n这种时候来找我说说话吧\n・完全提不起劲的时候\n・被题目难住了\n・想要被人夸一夸\n・不知道自己还能不能继续的时候\n\n小小的约定\n你说的事，只有我们之间知道。\n不用逼自己。按你自己的节奏就好。\n\n……嗯，一起加油也不是不行。';

  @override
  String get tsumugiLineNormal1 => '今日は短くていいよ。1行だけ、やってみよっか。';

  @override
  String get tsumugiLineNormal2 => 'うまく言えなくても大丈夫。ゆっくりでいいよ。';

  @override
  String get tsumugiLineNormal3 => '迷ったら、いちばん簡単なのから選ぼう。';

  @override
  String get tsumugiLineFree1 => '無料プレビューでも、雰囲気はちゃんと掴めるよ。';

  @override
  String get tsumugiLineFree2 => 'まずは気軽に。続けたくなったら、いつでも。';

  @override
  String get tsumugiLineFree3 => '今日はお試しだけでも、十分いい時間だよ。';

  @override
  String get tsumugiLineNight1 => '夜は無理しないで。1分だけでも十分だよ。';

  @override
  String get tsumugiLineNight2 => '今日はここまででもいいよ。続きはまた明日ね。';

  @override
  String get tsumugiLineNight3 => '遅い時間は、やさしい一言だけで大丈夫だよ。';

  @override
  String get subscriptionUpsellTitle => '使用基础方案继续学习！';

  @override
  String get subscriptionUpsellMessage => '免费方案只是体验。若想真正开口说话，现在就解锁所有场景！';

  @override
  String get basicPlan => '基本计划';

  @override
  String get upsellBodyText => '此分类仅限基本方案会员。\n解锁所有分类。\n7天免费试用。试用期内取消不收费。';

  @override
  String get trialStartButton => '开始7天免费试用';

  @override
  String get planDetailsButton => '查看套餐详情';

  @override
  String get notNowButton => '暂时不了';

  @override
  String get trialCopyText => '7天免费试用。试用期内取消不收费。';

  @override
  String get subscriptionBenefitDailyPractice => '每日练习：无限次使用';

  @override
  String get subscriptionBenefitAllCategories => '所有分类全开';

  @override
  String get subscriptionBenefitUnlimited => '练习次数无限制';

  @override
  String get subscriptionBenefitCancelAnytime => '随时可取消';

  @override
  String get iosCancelGuideText => '在 iPhone 上取消：设置 > Apple 账户 > 订阅。';

  @override
  String get subscriptionActivated => '订阅已激活。';

  @override
  String get retryButton => '再说一次';

  @override
  String get benefitNoCreditCard => '仅需 Apple ID 开始（无需信用卡）';

  @override
  String get benefitRenewalNotice => '续费前7天提醒';

  @override
  String get benefitAppleRefund => '7天内可通过Apple申请退款';

  @override
  String get searchHint => '搜索短语';

  @override
  String get dailyPracticeTitle => '今日练习';

  @override
  String get dailyPracticeEncourage => '说错了也没关系！可以试很多次的 🌸';

  @override
  String get dailyPracticeListenButton => '▶ 先听一听';

  @override
  String get dailyPracticeTryButton => '🎤 模仿说说看！';

  @override
  String get dailyPracticeStopButton => '停止';

  @override
  String get dailyPracticeDoneButton => '完成 →';

  @override
  String get dailyCompleteTitle => '今日练习完成！🎉';

  @override
  String get dailyCompleteSeeYouTomorrow => '明天见 👋';

  @override
  String get dailyCompleteMorePractice => '继续练习 →';

  @override
  String streakDaysDisplay(Object days) {
    return '$days天';
  }

  @override
  String get streakContinuing => '连续练习中！';

  @override
  String get dailyCompleteTodayPhrase => '今天练习的短语：';

  @override
  String dailyCompleteTodayCount(Object count) {
    return '今天练了$count次！🌟';
  }

  @override
  String get levelSelectQuestion => '你的日语水平是？🌸';

  @override
  String get levelSelectOptionStarterTitle => '完全零基础';

  @override
  String get levelSelectOptionStarterSub => '一句日语都不会';

  @override
  String get levelSelectOptionBeginnerTitle => '了解一点点';

  @override
  String get levelSelectOptionBeginnerSub => 'ありがとう、こんにちは……这个程度';

  @override
  String get levelSelectOptionIntermediateTitle => '有一定基础';

  @override
  String get levelSelectOptionIntermediateSub => '能说简单的句子';

  @override
  String get dailyLimitTitle => '今天练习得很棒！🌸';

  @override
  String get dailyLimitMessage => '今天的10次免费练习用完了！明天再来吧。订阅基础版，每天无限练习♪';

  @override
  String get dailyLimitClose => '返回首页';

  @override
  String get dailyLimitUpgrade => '查看基础版 ✨';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get categoryTitle => '選擇類別';

  @override
  String get targetLanguage => '學習語言';

  @override
  String get level => '等級';

  @override
  String get scene => '學習場景';

  @override
  String get start => '開始';

  @override
  String get selectPrompt => '請選擇所有項目。';

  @override
  String get langJapanese => '日語';

  @override
  String get langEnglish => '英語';

  @override
  String get langChineseSimplified => '中文（簡體）';

  @override
  String get langChineseTraditional => '台灣(繁體)';

  @override
  String get langKorean => '韓語';

  @override
  String get langSpanish => '西班牙語';

  @override
  String get langFrench => '法語';

  @override
  String get langGerman => '德語';

  @override
  String get langVietnamese => '越南語';

  @override
  String get langIndonesian => '印尼語';

  @override
  String get languageJapanese => '日語';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageChineseSimplified => '中文（簡體）';

  @override
  String get languageChineseTraditional => '台灣(繁體)';

  @override
  String get languageKorean => '韓語';

  @override
  String get languageSpanish => '西班牙語';

  @override
  String get languageFrench => '法語';

  @override
  String get languageGerman => '德語';

  @override
  String get languageVietnamese => '越南語';

  @override
  String get languageIndonesian => '印尼語';

  @override
  String get levelBeginner => '初級';

  @override
  String get levelIntermediate => '中級';

  @override
  String get levelAdvanced => '高級';

  @override
  String get sceneTravel => '旅行';

  @override
  String get sceneGreeting => '問候';

  @override
  String get sceneDating => '約會';

  @override
  String get sceneRestaurant => '餐廳';

  @override
  String get sceneShopping => '購物';

  @override
  String get sceneBusiness => '商務';

  @override
  String get translatePrompt => '來翻譯看看吧！';

  @override
  String get termsOfService => '服務條款';

  @override
  String get privacyPolicy => '隱私政策';

  @override
  String get termsContent => '在使用本應用程式之前，請閱讀以下服務條款。使用本應用程式即表示您同意所有條款和條件。';

  @override
  String get privacyContent => '我們尊重您的隱私。所收集的資訊僅用於學習支援和改善應用程式體驗。';

  @override
  String get termsOfServiceContent =>
      '本應用旨在支援語言學習。\n\n【適用對象】\n本應用適用於所有年齡層。13 歲以下使用者必須在監護人同意下使用本應用。\n\n【免責聲明】\n因使用本應用所造成的任何損失或不利，開發者不負擔任何責任。\n\n【未來的付費功能】\n目前本應用為免費使用，但未來可能會加入部分付費功能，屆時將提前通知使用者。\n\n【終止使用】\n如使用者違反本條款，開發者有權在不事先通知的情況下暫停或限制使用權限。';

  @override
  String get privacyPolicyContent =>
      '本應用尊重使用者的隱私，並根據以下政策進行運營：\n\n【收集的資訊】\n可能會收集不涉及個人身份的資訊，如語言設定和使用紀錄。\n\n【使用目的】\n收集的資訊將用於提升應用品質與使用者體驗，不會在未經同意的情況下提供給第三方。\n\n【第三方服務】\n如未來增加付費功能，可能會使用第三方支付服務。\n\n【資訊管理】\n所收集的資訊將被妥善保管，確保安全。';

  @override
  String get errorTooLong => '訊息過長。請將內容控制在大約100個字元以內。';

  @override
  String get errorRateLimit => '請求次數過多，請稍後再試（每分鐘最多5次）。';

  @override
  String get errorNoMessage => '沒有提供訊息內容。';

  @override
  String get errorServerError => '伺服器發生錯誤，請稍後再試。';

  @override
  String get keyboardGuideButton => '如果點 🌐 後沒有顯示目標語言的鍵盤，請點此查看';

  @override
  String get keyboardGuideIos =>
      '如果在 iOS 上無法顯示目標語言的鍵盤：請前往 設定 > 一般 > 鍵盤 > 新增鍵盤，選擇目標語言。';

  @override
  String get keyboardGuideAndroid =>
      '如果在 Android 上無法顯示目標語言的鍵盤：請前往 設定 > 系統 > 語言與輸入法 > 鍵盤 > 新增鍵盤，選擇目標語言。';

  @override
  String get keyboardGuideBody =>
      '如果您的手機中未安裝目標語言的鍵盤，您將無法在聊天介面輸入。請按照以下步驟新增：\n\niOS：\n設定 > 一般 > 鍵盤 > 新增鍵盤\n\nAndroid：\n設定 > 語言與輸入法 > 鍵盤 > 新增鍵盤';

  @override
  String get keyboardGuideTitle => '鍵盤設定指南';

  @override
  String get ok => '確定';

  @override
  String get correct => '回答正確！';

  @override
  String get incorrect => '需要修改。';

  @override
  String answerMeaningPrefix(Object translation) {
    return '這就是你答案的含義：$translation';
  }

  @override
  String get answerTranslationPrefix => '修改範例';

  @override
  String invalidMeaning(Object userAnswer) {
    return '$userAnswer：作為一種學習語言，它毫無意義。';
  }

  @override
  String get errorBrokenGpt => '抱歉，系統出錯。請重試。';

  @override
  String grammarCorrect(Object userAnswer) {
    return '$userAnswer：從語法上來說，這是正確的。';
  }

  @override
  String grammarIncorrect(Object userAnswer) {
    return '$userAnswer：這在語法上是不正確的。';
  }

  @override
  String get errorSessionMismatch => '您已從其他裝置登入。請重新登入。';

  @override
  String get errorPunctuationFailed => '⚠️ 無法檢索帶標點的句子。';

  @override
  String get sceneTrial => '免費預覽';

  @override
  String get todaysSpecialTitle => '今日推薦';

  @override
  String get freePreviewSubtitle => '免費預覽';

  @override
  String get lockedMessage => '此內容僅供訂閱者閱讀。';

  @override
  String get resetPassword => '忘記密碼？';

  @override
  String get enterEmailForReset => '請輸入電子郵件地址以重設密碼。';

  @override
  String get sendResetEmail => '發送重設郵件';

  @override
  String get passwordResetSent => '已發送密碼重設郵件。';

  @override
  String get passwordResetError => '發送重設郵件失敗。';

  @override
  String get settingsTitle => '設定';

  @override
  String welcomeUser(Object name) {
    return '歡迎，$name';
  }

  @override
  String get filterLabel => '篩選：';

  @override
  String get filterTopicLabel => '主題';

  @override
  String get filterButton => '篩選';

  @override
  String get filterClear => '清除';

  @override
  String filterStatusSummary(Object count, Object level, Object topic) {
    return '$count • L:$level • T:$topic';
  }

  @override
  String filterResultsCount(Object count) {
    return '$count條';
  }

  @override
  String get levelStarter => '入門';

  @override
  String get tapToExpand => '點擊展開';

  @override
  String get userNameTitle => '使用者名稱';

  @override
  String get userNameIntro => '此名稱會顯示在應用中，之後可更改。';

  @override
  String get userNameHint => '請輸入姓名';

  @override
  String get userNameContinue => '繼續';

  @override
  String get userNameSave => '儲存';

  @override
  String get userNameEdit => '變更使用者名稱';

  @override
  String get userNameUpdated => '使用者名稱已更新';

  @override
  String registeredDate(Object date) {
    return '註冊日期：$date';
  }

  @override
  String userFetchFailed(Object error) {
    return '取得使用者資訊失敗（錯誤：$error）';
  }

  @override
  String get languageUpdated => '語言設定已更新';

  @override
  String get registerAccount => '註冊帳戶';

  @override
  String get registerSubtitle => '更換裝置或刪除 App 時，學習記錄會遺失。為了保存資料，請在此註冊帳號。';

  @override
  String get loginTitle => '登入';

  @override
  String get loginSubtitle => '已有帳戶？請點擊';

  @override
  String get logout => '登出';

  @override
  String get login => '登入';

  @override
  String get email => '電子郵件';

  @override
  String get password => '密碼';

  @override
  String get invalidEmail => '請輸入有效的電子郵件地址';

  @override
  String get passwordTooShort => '密碼長度必須至少6個字元';

  @override
  String get loginFailed => '登入失敗';

  @override
  String get loginError => '登入錯誤';

  @override
  String get noAccountRegister => '沒有帳戶？點此註冊';

  @override
  String get register => '註冊';

  @override
  String get registerFailed => '註冊失敗';

  @override
  String get purchaseSuccess => '感謝您的購買！';

  @override
  String get subscribe => '訂閱';

  @override
  String get subscribeNow => '7天免費預覽，加入基礎方案';

  @override
  String get lockedTitle => '已鎖定';

  @override
  String sceneTitle(Object sceneKey) {
    return '$sceneKey';
  }

  @override
  String get restorePurchase => '恢復購買';

  @override
  String get restorePurchaseSubtitle => '恢復您之前的訂閱狀態';

  @override
  String get restoringPurchase => '正在恢復購買記錄...';

  @override
  String get restoreSubscription => '恢復訂閱';

  @override
  String get subscriptionTitle => '訂閱';

  @override
  String get subscriptionPlanTitle => '<訂閱詳情>';

  @override
  String get subscriptionPlanMonthly => '• 方案名稱：基本方案';

  @override
  String get subscriptionPlanPeriod => '• 持續期間：1 個月';

  @override
  String get subscriptionPlanPrice => '• 價格：1,500 日圓（含稅）';

  @override
  String get subscriptionPlanTrial => '• 如果您不是會員，您只能嘗試免費預覽。';

  @override
  String get subscriptionCurrentStatusTitle => '當前狀態';

  @override
  String get subscriptionStatusSubscribed => '• 已訂閱：解鎖所有學習場景（包括免費預覽），可無限次使用。';

  @override
  String get subscriptionStatus => '• 已訂閱：所有學習場景均已開放使用。';

  @override
  String get subscriptionStatusTrial => '非會員：僅提供免費預覽。';

  @override
  String get subscriptionManageButton => '在 Apple 上管理訂閱';

  @override
  String get subscriptionManageNote => '※ 可從以上連結取消或重新訂閱。';

  @override
  String get subscriptionManageTitle => '訂閱詳情';

  @override
  String get subscriptionManageSubtitle => '查看方案並在此訂閱';

  @override
  String get subscriptionPriceTaxSuffix => '（含稅）';

  @override
  String get languageSelectionTitle => '選擇您的母語';

  @override
  String get languageSelectionDescription => '請選擇您的語言';

  @override
  String get similarExpressionPrefix => '其他表達：';

  @override
  String get guest => '訪客';

  @override
  String get viewTerms => '閱讀使用條款 (EULA)';

  @override
  String get viewPrivacyPolicy => '閱讀隱私政策';

  @override
  String get invalidPassword => '密碼長度至少為6個字元';

  @override
  String get subscriptionStatusUnsubscribed => '不是會員';

  @override
  String get settings_deleteAccount => '刪除帳戶';

  @override
  String get settings_resetData => '重置資料';

  @override
  String get settings_confirmDeleteAccount => '您確定要刪除您的帳戶及所有資料嗎？此操作不可撤銷。';

  @override
  String get settings_confirmResetData => '您確定要重置資料嗎？所有進度將被刪除。';

  @override
  String get enterPassword => '請輸入密碼';

  @override
  String get cancel => '取消';

  @override
  String get logoutConfirmation => '您確定要登出嗎？';

  @override
  String get viewFaq => '常見問題';

  @override
  String get checking => '正在判定…';

  @override
  String get sceneVocabulary => '短句';

  @override
  String get subsceneAll => '全部';

  @override
  String todayCorrectCount(Object count) {
    return '今日正確 $count題';
  }

  @override
  String streakDaysCount(Object days) {
    return '連續正確 $days天';
  }

  @override
  String get profileTitle => '個人資料';

  @override
  String totalCorrectCount(Object count) {
    return '累計正確 $count題';
  }

  @override
  String get categoryCorrectHeader => '分類正確數';

  @override
  String get noHistoryData => '尚無資料';

  @override
  String currentRank(Object rank) {
    return '目前等級：$rank';
  }

  @override
  String progressToRank(Object rank) {
    return '進度至 $rank';
  }

  @override
  String nextRankIn(Object count) {
    return '再答對 $count 題即可升級';
  }

  @override
  String get maxRankAchieved => '已達最高等級';

  @override
  String get rankUpTitle => '升級了！';

  @override
  String rankUpBody(Object rank) {
    return '你已達到 $rank。';
  }

  @override
  String recentQuestionsTitle(Object count) {
    return '最近題目（最近$count題）';
  }

  @override
  String get startQuestionButton => '開始';

  @override
  String get questionListGuide => '下方選擇一項即可開始練習。';

  @override
  String get tapToPractice => '點擊練習';

  @override
  String get recordingAutoStopped => '錄音已於 10 秒時自動停止。';

  @override
  String get recordingLabel => '錄音中…';

  @override
  String get readingLabel => '閱讀';

  @override
  String get listeningLabel => '聽力';

  @override
  String get listeningPrompt => '在說什麼？';

  @override
  String get sceneWork => '工作';

  @override
  String get sceneSocial_interactions_hobbies => '交流和愛好';

  @override
  String get sceneculture_entertainment => '文化和娛樂';

  @override
  String get scenecommunity_life => '社區生活';

  @override
  String get userAnswerHeader => '你的回答';

  @override
  String get badgeCorrect => '正確';

  @override
  String get badgeNeedsImprovement => '差一點！再試一次吧 🌸';

  @override
  String get hintLabel => '💡 試著這樣說：';

  @override
  String get originalTranslationHeader => '原文翻譯';

  @override
  String get originalTranscriptionHeader => '原文轉寫';

  @override
  String get originalExplanationHeader => '原文說明';

  @override
  String get similarExpressionHeader => '友好的相似表達';

  @override
  String incorrectMessageWithRaw(String raw) {
    return '$raw \n這個回答在文法或語意上不正確。';
  }

  @override
  String get answerMeaningAccurate => '此回答準確地表達了題目的含義。';

  @override
  String get tumugiAccuracyCorrect =>
      'Your answer captures the meaning just right!';

  @override
  String get kasumiAccuracyCorrect =>
      'W-Well, the meaning is correct... not that I\'m saying you did great or anything.';

  @override
  String get tumugiAccuracyIncorrect => '差一點！再聽一次，一起試試☺️ ';

  @override
  String get kasumiAccuracyIncorrect => '嗯…差一點。不過你肯定能行的。再來一次。';

  @override
  String get tsumugiProfileMenuTitle => '關於紬';

  @override
  String get tsumugiProfileScreenTitle => '關於紬';

  @override
  String get tsumugiProfileBody =>
      '我是紬，謝謝你來到這裡。\n學習有時候會很累。那種時候，放慢一點、先喘口氣也沒關係。\n不用急，我們照著你的步調，一步一步往前走。\n想說話的時候，隨時都可以找我。我會一直在這裡等你。☕\n\n這些時候可以來找我聊聊\n・提不起勁的時候\n・題目怎麼想都解不開的時候\n・想被鼓勵一下的時候\n・想稍微休息一下的時候\n・覺得自己今天已經很努力的時候\n\n小小約定\n你跟我說的話，只會留在我們之間。\n覺得辛苦時，不用勉強自己。你的步調最重要。\n\n我一直都很期待你再回來。';

  @override
  String get tsumugiCatchphrase => '慢慢來就好，這裡是讓你安心的地方。';

  @override
  String get kasumiProfileMenuTitle => '關於香澄';

  @override
  String get kasumiProfileScreenTitle => '關於香澄';

  @override
  String get kasumiCatchphrase => '有好好努力嗎？……我可都在看著。';

  @override
  String get kasumiProfileBody =>
      '我是香澄。……才不是在擔心你喔。\n只是既然要學，就要好好學。\n如果有不懂的地方……嗯，你可以問我。我會回答你。\n卡住的時候別硬撐。……這點忙我還是會幫的。\n\n這些時候可以來找我\n・完全提不起勁的時候\n・被題目搞得一頭霧水的時候\n・想被誇一下的時候\n・不確定自己還能不能繼續的時候\n\n小小約定\n你跟我說的話，只會留在我們之間。\n不用逼自己太緊。照自己的步調走就好。\n\n……嗯，一起努力其實也不壞。';

  @override
  String get subscriptionUpsellTitle => '使用基本方案繼續學習！';

  @override
  String get subscriptionUpsellMessage => '免費方案只是體驗。若想真正開口說話，現在就解鎖所有場景！';

  @override
  String get basicPlan => '基本方案';

  @override
  String get upsellBodyText => '此分類僅限基本方案會員。\n解鎖所有分類。\n7天免費試用。試用期內取消不收費。';

  @override
  String get trialStartButton => '開始7天免費試用';

  @override
  String get planDetailsButton => '查看方案詳情';

  @override
  String get notNowButton => '暫時不了';

  @override
  String get trialCopyText => '7天免費試用。試用期內取消不收費。';

  @override
  String get subscriptionBenefitDailyPractice => '每日練習：無限次使用';

  @override
  String get subscriptionBenefitAllCategories => '所有分類全開';

  @override
  String get subscriptionBenefitUnlimited => '練習次數無限制';

  @override
  String get subscriptionBenefitCancelAnytime => '隨時可取消';

  @override
  String get iosCancelGuideText => '在 iPhone 上取消：設定 > Apple 帳號 > 訂閱。';

  @override
  String get subscriptionActivated => '訂閱已啟用。';

  @override
  String get retryButton => '再說一次';

  @override
  String get benefitNoCreditCard => '僅需 Apple ID 開始（無需信用卡）';

  @override
  String get benefitRenewalNotice => '續費前7天提醒';

  @override
  String get benefitAppleRefund => '7天內可透過Apple申請退款';

  @override
  String get searchHint => '搜尋短語';

  @override
  String get dailyPracticeTitle => '今日練習';

  @override
  String get dailyPracticeEncourage => '說錯了也沒關係！可以試很多次的 🌸';

  @override
  String get dailyPracticeListenButton => '▶ 先聽一聽';

  @override
  String get dailyPracticeTryButton => '🎤 模仿說說看！';

  @override
  String get dailyPracticeStopButton => '停止';

  @override
  String get dailyPracticeDoneButton => '完成 →';

  @override
  String get dailyCompleteTitle => '今日練習完成！🎉';

  @override
  String get dailyCompleteSeeYouTomorrow => '明天見 👋';

  @override
  String get dailyCompleteMorePractice => '繼續練習 →';

  @override
  String streakDaysDisplay(Object days) {
    return '$days天';
  }

  @override
  String get streakContinuing => '連續練習中！';

  @override
  String get dailyCompleteTodayPhrase => '今天練習的短語：';

  @override
  String dailyCompleteTodayCount(Object count) {
    return '今天練了$count次！🌟';
  }

  @override
  String get levelSelectQuestion => '你的日語程度是？🌸';

  @override
  String get levelSelectOptionStarterTitle => '完全零基礎';

  @override
  String get levelSelectOptionStarterSub => '一句日語都不會';

  @override
  String get levelSelectOptionBeginnerTitle => '了解一點點';

  @override
  String get levelSelectOptionBeginnerSub => 'ありがとう、こんにちは……這個程度';

  @override
  String get levelSelectOptionIntermediateTitle => '有一定基礎';

  @override
  String get levelSelectOptionIntermediateSub => '能說簡單的句子';

  @override
  String get dailyLimitTitle => '今天練習得很棒！🌸';

  @override
  String get dailyLimitMessage => '今天的10次免費練習用完了！明天再來吧。訂閱基礎版，每天無限練習♪';

  @override
  String get dailyLimitClose => '返回首頁';

  @override
  String get dailyLimitUpgrade => '查看基礎版 ✨';
}
