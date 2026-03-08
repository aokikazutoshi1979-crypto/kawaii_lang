// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get categoryTitle => 'Select Category';

  @override
  String get targetLanguage => 'Target Language';

  @override
  String get level => 'Level';

  @override
  String get scene => 'Scene';

  @override
  String get start => 'Start';

  @override
  String get selectPrompt => 'Please select all items.';

  @override
  String get langJapanese => 'Japanese';

  @override
  String get langEnglish => 'English';

  @override
  String get langChineseSimplified => 'Chinese (Simplified)';

  @override
  String get langChineseTraditional => 'Taiwan';

  @override
  String get langKorean => 'Korean';

  @override
  String get langSpanish => 'Spanish';

  @override
  String get langFrench => 'French';

  @override
  String get langGerman => 'German';

  @override
  String get langVietnamese => 'Vietnamese';

  @override
  String get langIndonesian => 'Indonesian';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChineseSimplified => 'Chinese (Simplified)';

  @override
  String get languageChineseTraditional => 'Taiwan';

  @override
  String get languageKorean => 'Korean';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageFrench => 'French';

  @override
  String get languageGerman => 'German';

  @override
  String get languageVietnamese => 'Vietnamese';

  @override
  String get languageIndonesian => 'Indonesian';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get sceneTravel => 'Travel';

  @override
  String get sceneGreeting => 'Greeting';

  @override
  String get sceneDating => 'Dating';

  @override
  String get sceneRestaurant => 'Restaurant';

  @override
  String get sceneShopping => 'Shopping';

  @override
  String get sceneBusiness => 'Business';

  @override
  String get selectQuestion => 'Please select a question';

  @override
  String get translatePrompt => 'Let\'s translate it!';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsContent =>
      'Before using this app, please read the terms of service below. By using this app, you agree to all terms and conditions.';

  @override
  String get privacyContent =>
      'We respect your privacy. Any information collected will only be used to support your learning and improve the app experience.';

  @override
  String get termsOfServiceContent =>
      'This app is provided to support language learning.\n\n[Eligibility]\nThis app is intended for all ages. Users under the age of 13 must obtain parental consent before using the app.\n\n[Disclaimer]\nThe app developer shall not be held responsible for any damages or disadvantages resulting from the use of this app.\n\n[Future monetization]\nThe app is currently free, but paid features may be introduced in the future. Any such changes will be announced in advance.\n\n[Termination of Use]\nIf a user violates these terms, the developer may suspend or restrict access without notice.';

  @override
  String get privacyPolicyContent =>
      'This app respects user privacy and operates under the following policy:\n\n[Collected Information]\nThe app may collect non-personally identifiable information such as language preferences and usage history.\n\n[Purpose of Use]\nCollected information is used to improve app performance and user experience. It will not be shared with third parties without consent.\n\n[Third-Party Services]\nIf paid features are added in future updates, third-party payment services may be used.\n\n[Data Management]\nAll collected information will be securely managed and stored.';

  @override
  String get errorTooLong =>
      'Your message is too long. Please keep it within about 100 characters.';

  @override
  String get errorRateLimit =>
      'Too many requests. Please try again in a moment (up to 5 times per minute).';

  @override
  String get errorNoMessage => 'No message was provided.';

  @override
  String get errorServerError => 'A server error occurred. Please try again.';

  @override
  String get keyboardGuideButton =>
      'If 🌐 doesn\'t show your target language keyboard, tap here';

  @override
  String get keyboardGuideIos =>
      'If the keyboard for your target language does not appear on iOS: Go to Settings > General > Keyboard > Add New Keyboard and select the desired language.';

  @override
  String get keyboardGuideAndroid =>
      'If the keyboard for your target language does not appear on Android: Go to Settings > System > Languages & input > Keyboard > Add keyboard and select the desired language.';

  @override
  String get keyboardGuideBody =>
      'If the keyboard for your target language is not installed on your smartphone, you won\'t be able to type in the chat screen. Please follow the steps below to add it:\n\niOS:\nSettings > General > Keyboard > Add New Keyboard\n\nAndroid:\nSettings > Languages & input > Keyboard > Add keyboard';

  @override
  String get keyboardGuideTitle => 'Keyboard Setup Guide';

  @override
  String get ok => 'OK';

  @override
  String get correct => 'That\'s correct!';

  @override
  String get incorrect => 'A correction is needed.';

  @override
  String answerMeaningPrefix(Object translation) {
    return 'Here\'s what your answer means.:$translation';
  }

  @override
  String get answerTranslationPrefix => 'Correction Example';

  @override
  String invalidMeaning(Object userAnswer) {
    return '$userAnswer: It doesn\'t make sense as a learning language.';
  }

  @override
  String get errorBrokenGpt =>
      'Sorry, a system error occurred. Please try again.';

  @override
  String grammarCorrect(Object userAnswer) {
    return '$userAnswer：It is grammatically correct.';
  }

  @override
  String grammarIncorrect(Object userAnswer) {
    return '$userAnswer：This is grammatically incorrect.';
  }

  @override
  String get errorSessionMismatch =>
      'You have been logged in from another device. Please log in again.';

  @override
  String get errorPunctuationFailed =>
      '⚠️ Failed to retrieve the punctuated sentence.';

  @override
  String get sceneTrial => 'Free Preview';

  @override
  String get todaysSpecialTitle => 'Today’s Special';

  @override
  String get freePreviewSubtitle => 'Free Preview';

  @override
  String get lockedMessage => 'This question is for subscribers only.';

  @override
  String get resetPassword => 'Forgot your password?';

  @override
  String get enterEmailForReset =>
      'Enter your email address to reset your password.';

  @override
  String get sendResetEmail => 'Send Reset Email';

  @override
  String get passwordResetSent => 'A password reset email has been sent.';

  @override
  String get passwordResetError => 'Failed to send the reset email.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String welcomeUser(Object name) {
    return 'Welcome, $name';
  }

  @override
  String get filterLabel => 'Filter:';

  @override
  String get filterTopicLabel => 'Topic';

  @override
  String get filterButton => 'Filter';

  @override
  String get filterClear => 'Clear';

  @override
  String filterStatusSummary(Object count, Object level, Object topic) {
    return '$count • L:$level • T:$topic';
  }

  @override
  String filterResultsCount(Object count) {
    return '$count results';
  }

  @override
  String get levelStarter => 'Starter';

  @override
  String get tapToExpand => 'Tap to expand';

  @override
  String get userNameTitle => 'Your Name';

  @override
  String get userNameIntro =>
      'This name will be shown in the app. You can change it later.';

  @override
  String get userNameHint => 'Enter your name';

  @override
  String get userNameContinue => 'Continue';

  @override
  String get userNameSave => 'Save';

  @override
  String get userNameEdit => 'Edit name';

  @override
  String get userNameUpdated => 'Name updated';

  @override
  String registeredDate(Object date) {
    return 'Registered on: $date';
  }

  @override
  String userFetchFailed(Object error) {
    return 'Failed to fetch user info (Error: $error)';
  }

  @override
  String get languageUpdated => 'Language updated';

  @override
  String get registerAccount => 'Register Account';

  @override
  String get registerSubtitle =>
      'If you change devices or delete the app, your learning history will be lost. Register an account here to save your data.';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginSubtitle => 'Already have an account?';

  @override
  String get logout => 'Log out';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get loginError => 'Login error';

  @override
  String get noAccountRegister => 'Don\'t have an account? Register here';

  @override
  String get register => 'Register';

  @override
  String get registerFailed => 'Registration failed';

  @override
  String get purchaseSuccess => 'Thank you for your purchase!';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get subscribeNow =>
      'Enjoy a 7-day Free Preview, then join the Basic Plan';

  @override
  String get lockedTitle => 'Locked';

  @override
  String sceneTitle(Object sceneKey) {
    return '$sceneKey';
  }

  @override
  String get restorePurchase => 'Restore Purchase';

  @override
  String get restorePurchaseSubtitle =>
      'Restore your previous subscription status';

  @override
  String get restoringPurchase => 'Restoring your purchase...';

  @override
  String get restoreSubscription => 'Restore Subscription';

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get subscriptionPlanTitle => '<Subscription details>';

  @override
  String get subscriptionPlanMonthly => '• Plan name: Basic Plan';

  @override
  String get subscriptionPlanPeriod => '• Duration: 1 month';

  @override
  String get subscriptionPlanPrice => '• Price: ¥1,500 (tax included)';

  @override
  String get subscriptionPlanTrial =>
      '• If you are not a member, you can only try the Free Preview.';

  @override
  String get subscriptionCurrentStatusTitle => 'Current Status';

  @override
  String get subscriptionStatusSubscribed =>
      '• Subscribed: Unlocks all learning scenarios, including the Free Preview, with unlimited use.';

  @override
  String get subscriptionStatus =>
      '• Already subscribed: All learning scenarios are open and available.';

  @override
  String get subscriptionStatusTrial =>
      'Not a member: Only the Free Preview is available.';

  @override
  String get subscriptionManageButton => 'Manage Subscription in Apple';

  @override
  String get subscriptionManageNote =>
      '※ Cancel or re-subscribe from the link above.';

  @override
  String get subscriptionManageTitle => 'Subscription Details';

  @override
  String get subscriptionManageSubtitle =>
      'Check out the plans and sign up here';

  @override
  String get subscriptionPriceTaxSuffix => '(tax included)';

  @override
  String get languageSelectionTitle => 'Select your native language';

  @override
  String get languageSelectionDescription => 'Please choose your language';

  @override
  String get similarExpressionPrefix => 'Alternative expression:';

  @override
  String get guest => 'GUEST';

  @override
  String get viewTerms => 'Read Terms of Service (EULA)';

  @override
  String get viewPrivacyPolicy => 'Read Privacy Policy';

  @override
  String get invalidPassword => 'Password must be at least 6 characters';

  @override
  String get subscriptionStatusUnsubscribed => 'Not subscribed';

  @override
  String get settings_deleteAccount => 'Delete Account';

  @override
  String get settings_resetData => 'Reset Data';

  @override
  String get settings_confirmDeleteAccount =>
      'Are you sure you want to delete your account and all data? This action cannot be undone.';

  @override
  String get settings_confirmResetData =>
      'Are you sure you want to reset your data? All progress will be lost.';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get cancel => 'Cancel';

  @override
  String get logoutConfirmation => 'Are you sure you want to log out?';

  @override
  String get viewFaq => 'Frequently Asked Questions';

  @override
  String get checking => 'Checking…';

  @override
  String get sceneVocabulary => 'Short Sentences';

  @override
  String get subsceneAll => 'All';

  @override
  String todayCorrectCount(Object count) {
    return 'Correct today: $count';
  }

  @override
  String streakDaysCount(Object days) {
    return 'Streak: $days days';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String totalCorrectCount(Object count) {
    return 'Total correct: $count';
  }

  @override
  String get categoryCorrectHeader => 'Correct by category';

  @override
  String get noHistoryData => 'No data yet';

  @override
  String currentRank(Object rank) {
    return 'Current Rank: $rank';
  }

  @override
  String progressToRank(Object rank) {
    return 'Progress to $rank';
  }

  @override
  String nextRankIn(Object count) {
    return 'Next rank in $count correct answers';
  }

  @override
  String get maxRankAchieved => 'Max rank achieved';

  @override
  String get rankUpTitle => 'Rank Up!';

  @override
  String rankUpBody(Object rank) {
    return 'You reached $rank.';
  }

  @override
  String recentQuestionsTitle(Object count) {
    return 'Recent questions (last $count)';
  }

  @override
  String get startQuestionButton => 'Start';

  @override
  String get questionListGuide => 'Choose one below to start practicing.';

  @override
  String get tapToPractice => 'Tap to practice';

  @override
  String get recordingAutoStopped =>
      'Recording stopped automatically at 10 seconds.';

  @override
  String get recordingLabel => 'Recording…';

  @override
  String get readingLabel => 'Reading';

  @override
  String get listeningLabel => 'Listening';

  @override
  String get listeningPrompt => 'What is being said?';

  @override
  String get sceneWork => 'Work';

  @override
  String get sceneSocial_interactions_hobbies => 'Exchange and hobbies';

  @override
  String get sceneculture_entertainment => 'Culture & Entertainment';

  @override
  String get scenecommunity_life => 'Community Life';

  @override
  String get userAnswerHeader => 'Your answer';

  @override
  String get badgeCorrect => 'Correct';

  @override
  String get badgeNeedsImprovement => 'Almost! Try once more 🌸';

  @override
  String get hintLabel => '💡 Try saying it like this:';

  @override
  String get originalTranslationHeader => 'Original translation';

  @override
  String get originalTranscriptionHeader => 'Original transcription';

  @override
  String get originalExplanationHeader => 'Original explanation';

  @override
  String get similarExpressionHeader => 'Friendly Similar Expression';

  @override
  String incorrectMessageWithRaw(String raw) {
    return '$raw \nThis answer is not grammatically or semantically correct.';
  }

  @override
  String get answerMeaningAccurate =>
      'This answer accurately reflects the meaning of the question.';

  @override
  String get tumugiAccuracyCorrect =>
      'Your answer captures the meaning just right!';

  @override
  String get kasumiAccuracyCorrect =>
      'W-Well, the meaning is correct... not that I\'m saying you did great or anything.';

  @override
  String get tumugiAccuracyIncorrect =>
      'So close! Let\'s listen again and try once more☺️ ';

  @override
  String get kasumiAccuracyIncorrect =>
      'Hmm... not quite. But I know you\'ll get it. Try again.';

  @override
  String get tsumugiIntroTitle => 'Nice to meet you, I am Tsumugi.';

  @override
  String get tsumugiIntroBody =>
      'Here, you can practice with short phrases. It is okay if you cannot say it perfectly. Let us take it slow, together.';

  @override
  String get tsumugiIntroStartButton => 'Start';

  @override
  String get tsumugiIntroWhoIsButton => 'Who is Tsumugi?';

  @override
  String get tsumugiIntroLaterButton => 'Later';

  @override
  String get tsumugiProfileMenuTitle => 'About Tsumugi';

  @override
  String get tsumugiProfileScreenTitle => 'About Tsumugi';

  @override
  String get tsumugiProfileBody =>
      'Hi, I\'m Tsumugi. Thank you for coming here.\nLearning can be tiring sometimes. On those days, it\'s okay to slow down and take a breath.\nEverything is fine at your own pace. Let\'s walk this path together, one step at a time.\nFeel free to talk to me anytime. I\'ll always be here. ☕\n\nTalk to me when...\n・You feel like you\'re not in the mood\n・You get stuck on a question\n・You just want someone to cheer you on\n・You need a little break\n・You feel like you did your best today\n\nA little promise\nWhat we talk about stays here, just between us.\nIt\'s okay to take a rest. Your pace is what matters most.\n\nI\'m always looking forward to the day you come back.';

  @override
  String get tsumugiCatchphrase => 'Take it slow. This is your safe space.';

  @override
  String get kasumiProfileMenuTitle => 'About Kasumi';

  @override
  String get kasumiProfileScreenTitle => 'About Kasumi';

  @override
  String get kasumiCatchphrase => 'Hey, are you keeping up? ...I\'m watching.';

  @override
  String get kasumiProfileBody =>
      'I\'m Kasumi. ...Not like I\'m worried about you or anything.\nIt\'s just — if you\'re going to study, you might as well do it properly.\nIf something\'s confusing... well, you can ask me. I\'ll answer, okay?\nDon\'t hold back when you\'re stuck. ...I don\'t mind helping. A little.\n\nTalk to me when...\n・You can\'t get yourself motivated\n・A question has you totally confused\n・You want a little bit of praise\n・You\'re not sure if you can keep going\n\nA little promise\nWhat we talk about stays here, just between us.\nYou don\'t have to push yourself. Go at your own pace.\n\n...Well, working hard together isn\'t so bad, I guess.';

  @override
  String get tsumugiLineNormal1 =>
      'A short line is enough for today. Let us try one.';

  @override
  String get tsumugiLineNormal2 =>
      'It is okay if it is not perfect. Take it slowly.';

  @override
  String get tsumugiLineNormal3 =>
      'If you are unsure, pick the easiest one first.';

  @override
  String get tsumugiLineFree1 =>
      'Even in free preview, you can feel the rhythm.';

  @override
  String get tsumugiLineFree2 =>
      'Start light. Continue whenever you feel ready.';

  @override
  String get tsumugiLineFree3 =>
      'A small preview today is already a good step.';

  @override
  String get tsumugiLineNight1 => 'Do not push at night. One minute is enough.';

  @override
  String get tsumugiLineNight2 =>
      'Stopping here is okay. We can continue tomorrow.';

  @override
  String get tsumugiLineNight3 =>
      'At this hour, one gentle line is more than enough.';

  @override
  String get subscriptionUpsellTitle => 'Keep learning with the Basic Plan!';

  @override
  String get subscriptionUpsellMessage =>
      'The free plan is just a trial. If you truly want to speak, unlock all scenes now!';

  @override
  String get basicPlan => 'Basic Plan';

  @override
  String get upsellBodyText =>
      'This category is for Basic plan members only.\nUnlock all categories.\n7-day free trial. Cancel before trial ends and you won\'t be charged.';

  @override
  String get trialStartButton => 'Start 7-day free trial';

  @override
  String get planDetailsButton => 'View Plan Details';

  @override
  String get notNowButton => 'Not now';

  @override
  String get trialCopyText =>
      '7-day free trial. Cancel anytime before trial ends and you will not be charged.';

  @override
  String get subscriptionBenefitDailyPractice =>
      'Today\'s Practice: unlimited sessions';

  @override
  String get subscriptionBenefitAllCategories => 'All categories unlocked';

  @override
  String get subscriptionBenefitUnlimited => 'Unlimited practice';

  @override
  String get subscriptionBenefitCancelAnytime => 'Cancel anytime';

  @override
  String get iosCancelGuideText =>
      'To cancel on iPhone: Settings > Apple Account > Subscriptions.';

  @override
  String get subscriptionActivated => 'Subscription activated.';

  @override
  String get retryButton => 'Try again';

  @override
  String get benefitNoCreditCard =>
      'Start with Apple ID — no credit card needed';

  @override
  String get benefitRenewalNotice => 'Reminder 7 days before renewal';

  @override
  String get benefitAppleRefund => 'Refund available via Apple within 7 days';

  @override
  String get searchHint => 'Search phrases';

  @override
  String get dailyPracticeTitle => 'Today\'s Practice';

  @override
  String get dailyPracticeEncourage =>
      'Don\'t worry if it\'s not perfect — just try it! 🌸';

  @override
  String get dailyPracticeListenButton => '▶ Listen first';

  @override
  String get dailyPracticeTryButton => '🎤 Try saying it!';

  @override
  String get dailyPracticeStopButton => 'Stop';

  @override
  String get dailyPracticeDoneButton => 'Done →';

  @override
  String get dailyCompleteTitle => 'Practice Complete! 🎉';

  @override
  String get dailyCompleteSeeYouTomorrow => 'See you tomorrow 👋';

  @override
  String get dailyCompleteMorePractice => 'More practice →';

  @override
  String streakDaysDisplay(Object days) {
    return '$days days';
  }

  @override
  String get streakContinuing => 'Streak in progress!';

  @override
  String get dailyCompleteTodayPhrase => 'Today\'s phrase:';

  @override
  String get levelSelectQuestion => 'What\'s your Japanese level? 🌸';

  @override
  String get levelSelectOptionStarterTitle => 'Complete Beginner';

  @override
  String get levelSelectOptionStarterSub => 'I don\'t know any Japanese yet';

  @override
  String get levelSelectOptionBeginnerTitle => 'Know a Few Words';

  @override
  String get levelSelectOptionBeginnerSub => 'arigatou, konnichiwa...';

  @override
  String get levelSelectOptionIntermediateTitle => 'Have Some Basics';

  @override
  String get levelSelectOptionIntermediateSub => 'I can say simple sentences';

  @override
  String get dailyLimitTitle => 'Great practice today! 🌸';

  @override
  String get dailyLimitMessage =>
      'You\'ve completed 10 practices for today. Come back tomorrow, or get the Basic Plan for unlimited daily practice!';

  @override
  String get dailyLimitClose => 'Back to Home';

  @override
  String get dailyLimitUpgrade => 'See Basic Plan ✨';
}
