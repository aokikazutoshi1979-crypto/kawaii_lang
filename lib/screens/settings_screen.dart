// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'terms_of_service.dart';
import 'privacy_policy.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import '../widgets/keyboard_guide_button.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../screens/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'subscription_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kawaii_lang/services/subscription_state.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  // ScaffoldMessenger 用に BuildContext をキャッシュ
  static BuildContext? _scaffoldContext;

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends SubscriptionState<SettingsScreen> {
  final AuthService _authService = AuthService();
  Offerings? _offerings;
  bool _loadingOfferings = true;
  UserModel? _user;
  bool _isLoadingUser = false;
  String? selectedLang;
  String? selectedTargetLang;
  final String _faqUrl = 'https://kawaiilang.com/faq.html';

  final List<Map<String, String>> languages = [
    {'label': '日本語',                'code': 'ja'},
    {'label': 'English',              'code': 'en'},
    {'label': '中文(简化)',                  'code': 'zh'},
    {'label': '台灣(繁體)',     'code': 'zh_TW'},
    {'label': '한국어',                'code': 'ko'},
    {'label': 'Español',              'code': 'es'},
    {'label': 'Français',             'code': 'fr'},
    {'label': 'Deutsch',              'code': 'de'},
    {'label': 'Tiếng Việt',           'code': 'vi'},
    {'label': 'Bahasa Indonesia',     'code': 'id'}
  ];

  /// 外部URLをブラウザで開く
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open URL: $url')),
      );
    }
  }

  // ① SubscriptionService のインスタンスをフィールドとして用意
  late final SubscriptionService subscriptionService;

  @override
  void initState() {
    super.initState();
    // ② インスタンス化して初期化メソッドを呼び、完了後にリビルド
    subscriptionService = SubscriptionService.instance;
    subscriptionService.init().then((_) {
      setState(() {});
    });

    // １）言語設定のロード（既存）
    _loadLanguage();
    _loadTargetLanguage();

    // ２）RevenueCat の初期化＆オファー取得
    SubscriptionService.instance.init();
    _loadSubscriptionOfferings();

    // ３）匿名ログインでなければ、Firestore からユーザーデータを取得
    final isAnon = _authService.currentUser!.isAnonymous;
    _fetchUser();
  }

  Future<void> _loadSubscriptionOfferings() async {
    try {
      final off = await SubscriptionService.instance.getOfferings();
      setState(() => _offerings = off);
    } catch (e) {
      debugPrint('Offerings取得失敗: $e');
    } finally {
      setState(() => _loadingOfferings = false);
    }
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedLang = prefs.getString('user_language') ?? 'ja';
    });
  }

  Future<void> _loadTargetLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedTargetLang = prefs.getString('target_language');
    });
  }

  Future<void> _fetchUser() async {
    final uid = _authService.currentUser!.uid;
    print('💡 Firestoreからユーザーデータ取得中... UID: $uid');

    setState(() => _isLoadingUser = true);

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      print('💡 Firestoreの中身: ${doc.data()}');

      final user = await _authService.fetchCurrentUser();
      setState(() {
        _user = user;
      });
    } catch (e) {
      print('❌ ユーザー取得エラー: $e');
    } finally {
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _saveLanguage(String code) async {
    final parts = code.split(RegExp('[-_]'));
    final locale = (parts.length == 2)
      ? Locale(parts[0], parts[1])
      : Locale(parts[0]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_language', code);

    setState(() => selectedLang = code);
    MyApp.setLocale(context, locale);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.languageUpdated)),
    );
  }

  Future<void> _saveTargetLanguage(String code) async {
    final native = selectedLang;
    if (native != null && code == native) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.selectPrompt)),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('target_language', code);

    setState(() => selectedTargetLang = code);
  }

  Future<void> _handleLogout() async {
    // 1) RevenueCat の内部キャッシュをクリア
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('⚠️ Purchases.logOut() エラー: $e');
      // ここは握りつぶしても OK
    }

    // 2) Firebase の認証情報をクリア
    await _authService.signOut();




  // ─────────────────────────────────────
  // 環境変数でテスト用リセットを切り替え
  const bool isTestReset = bool.fromEnvironment(
    'TEST_RESET',
    defaultValue: false,
  );
  // ─────────────────────────────────────

  // ① 匿名サインイン＋Firestore ドキュメント作成
  await AuthService.signInAnonymouslyIfNeeded(
    force: isTestReset,
  );



    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ① セッションミスマッチ時はエラー画面のみ表示
    if (subscriptionService.isSessionMismatch) {
      return Scaffold(
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.errorSessionMismatch,
          ),
        ),
      );
    }

    final isAnon = _authService.currentUser!.isAnonymous;
    final loc = AppLocalizations.of(context)!;
    final displayName = isAnon
        ? loc.guest
        : (_user?.displayName ?? _user?.email ?? '');

    // ① RevenueCat パッケージ取得済みか判定
    final bool hasPackages = !_loadingOfferings &&
        (_offerings?.current?.availablePackages.isNotEmpty ?? false);

    // ユーザーデータ読み込み中はプログレス
    if (!isAnon && _isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ② サブスク状態を判定（State 継承のフラグを利用）
    final showSubscribe = !hasSubOnDevice;

    return Scaffold(
      appBar: AppBar(title: Text(loc.settingsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 匿名でも _user が取れていれば、ここを通るように
            if (_user != null) ...[
              // 匿名ユーザーなら "GUEST"、それ以外は displayName または email
              Text(
                loc.welcomeUser(
                  _authService.currentUser!.isAnonymous
                    ? loc.guest                   // ← arb の "guest": "ゲスト" を使う
                    : (_user!.email ?? 'User'),
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (!_authService.currentUser!.isAnonymous) ...[
                Text(
                  loc.registeredDate(
                    DateFormat.yMMMd().format(_user!.createdAt),
                  ),
                ),
              ],
              const Divider(height: 32),

              // サブスクリプション管理ボタンに変更（アイコン付き）
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  ),
                  icon: SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset(
                      'assets/images/icon/basic_plan002.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center, // 中央揃え
                    children: [
                      Text(loc.subscriptionManageTitle),
                      Text(
                        loc.subscriptionManageSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(loc.profileTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            const Divider(height: 32),

            if (isAnon) ...[
              // アカウント登録ボタンに変更
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center, // 中央揃え
                    children: [
                      Text(loc.registerAccount),
                      Text(
                        loc.registerSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ログインボタンに変更
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center, // 中央揃え
                    children: [
                      Text(loc.loginTitle),
                      Text(
                        loc.loginSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),
            ],

            if (selectedLang != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: KeyboardGuideButton(
                  targetLanguage: selectedTargetLang ?? selectedLang!,
                  alwaysVisible: true,
                ),
              ),
              const Divider(height: 32),
            ],

            // ① FAQ へのリンクボタン
            TextButton.icon(
              icon: const Icon(Icons.help_outline),
              label: Text(loc.viewFaq),
              onPressed: () => _launchUrl(_faqUrl),
            ),
            const Divider(height: 32),

            // ② 利用規約リンク
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(loc.termsOfService),
              onTap: () => _launchUrl('https://kawaiilang.com/terms.html'),
            ),
            const Divider(height: 16),

            // ③ プライバシーポリシーリンク
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text(loc.privacyPolicy),
              onTap: () => _launchUrl('https://kawaiilang.com/privacy.html'),
            ),
            const Divider(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Text(
                loc.languageSelectionTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center, // ← 中央寄せ
              ),
            ),
            ...languages.map((lang) {
              return Card(
                child: ListTile(
                  title: Text(lang['label']!),
                  trailing: selectedLang == lang['code']
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => _saveLanguage(lang['code']!),
                ),
              );
            }).toList(),
            const Divider(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Text(
                loc.targetLanguage,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            ...((selectedLang == null)
                    ? languages
                    : languages.where((lang) => lang['code'] != selectedLang))
                .map((lang) {
              return Card(
                child: ListTile(
                  title: Text(lang['label']!),
                  trailing: selectedTargetLang == lang['code']
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => _saveTargetLanguage(lang['code']!),
                ),
              );
            }).toList(),
            const Divider(height: 32),

            // ❷ ここからは非匿名ユーザーだけ
            if (!isAnon) ...[
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(loc.logout),
                onTap: () async {
                  // ダイアログで確認
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(loc.logout),                                   // 「ログアウト」
                      content: Text(loc.logoutConfirmation                           // arb に追加:
                          /* "本当にログアウトしますか？" */),                        
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(loc.cancel),                               // arb に追加: "キャンセル"
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(loc.ok),                              // arb に追加: "ログアウト"
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    // ① ログアウト処理を完了させてから…
                    await _handleLogout();

                    // ② 匿名ログイン
                    await FirebaseAuth.instance.signInAnonymously();

                    // ③ スタックを全部クリアしてスプラッシュ画面へ
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/splash',        // あなたのスプラッシュ画面のルート名
                      (route) => false, // 既存の全ルートを破棄
                    );
                  }
                }
              ),
            ],

            // ── アカウント削除／データ初期化 ──
            ListTile(
              leading: Icon(isAnon ? Icons.refresh : Icons.delete_forever),
              title: Text(
                isAnon
                    ? loc.settings_resetData
                    : loc.settings_deleteAccount,
              ),
              onTap: () async {
                final loc = AppLocalizations.of(context)!;
                // ① 確認ダイアログ用メッセージを選択
                final msg = isAnon
                    ? loc.settings_confirmResetData
                    : loc.settings_confirmDeleteAccount;
                // ② ダイアログを表示してユーザーが OK したか判定
                final ok = await _showConfirmDialog(context, msg);
                if (!ok) return; // キャンセルされたら以降の処理を中断

                try {
                  if (isAnon) {
                    await _authService.resetAnonymousData();
                  } else {
                    final pw = await _promptForPassword(context);
                    await _authService.deleteUserAccount(password: pw);
                  }
                  // ログ出力を追加
                  debugPrint("✅ アカウント削除／初期化完了。現在のuser=${FirebaseAuth.instance.currentUser}");
                  
                  // ここでスタックを全部クリアして初期画面へ戻す
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/splash', // あなたのアプリのスプラッシュルートに置き換えてください
                    (route) => false,
                  );
                } catch (e, st) {
                  debugPrint("❌ 削除エラー: $e\n$st");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('削除中にエラーが発生しました: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ── ここから下をクラス内に追加 ──
  Future<bool> _showConfirmDialog(BuildContext ctx, String message) {
    final loc = AppLocalizations.of(ctx)!;
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.ok),
          ),
        ],
      ),
    ).then((v) => v == true);
  }

  /// パスワード再入力ダイアログを表示し、入力された文字列を返す
  Future<String> _promptForPassword(BuildContext context) async {
    final controller = TextEditingController();
    // ダイアログを表示
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.enterPassword),  // arb に “enterPassword” を定義しておく
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(ctx)!.password,     // arb に “password” も定義
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(AppLocalizations.of(ctx)!.ok),
          ),
        ],
      ),
    );
    return result ?? '';
  }
}
