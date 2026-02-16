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
  String get badgeNeedsImprovement => '需要改进';

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
  String get subscriptionUpsellTitle => '使用基础方案继续学习！';

  @override
  String get subscriptionUpsellMessage => '免费方案只是体验。若想真正开口说话，现在就解锁所有场景！';
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
  String get badgeNeedsImprovement => '需要改進';

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
  String get subscriptionUpsellTitle => '使用基本方案繼續學習！';

  @override
  String get subscriptionUpsellMessage => '免費方案只是體驗。若想真正開口說話，現在就解鎖所有場景！';
}
