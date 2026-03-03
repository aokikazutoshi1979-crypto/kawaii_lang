// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
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
import 'package:kawaii_lang/services/language_catalog.dart';
import 'profile_screen.dart';
import 'user_name_screen.dart';
import 'package:kawaii_lang/widgets/mode_toggle_bar.dart';
import '../models/quiz_mode.dart';
import 'tsumugi_profile_screen.dart';
import 'kasumi_profile_screen.dart';
import '../services/character_asset_service.dart';
import '../widgets/particle_burst.dart';

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
  String? _displayName;
  bool _languageCatalogReady = false;
  final String _faqUrl = 'https://kawaiilang.com/faq.html';
  QuizMode _selectedMode = QuizMode.reading;
  static const String _quizModePrefKey = 'quiz_mode';
  String _selectedCharacter = CharacterAssetService.defaultCharacter;

  final List<String> _languageCodes = const [
    'ja',
    'en',
    'zh',
    'zh_TW',
    'ko',
    'es',
    'fr',
    'de',
    'vi',
    'id',
  ];

  String _displayLangCode(BuildContext context) {
    final code = selectedLang;
    if (code != null && code.isNotEmpty) return code;
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'zh' &&
        locale.countryCode?.toUpperCase() == 'TW') {
      return 'zh_TW';
    }
    return locale.languageCode;
  }

  String _labelForLangCode(String? code, BuildContext context) {
    if (code == null) return '';
    if (!_languageCatalogReady) return code;
    return LanguageCatalog.instance.labelFor(
      code,
      displayLang: _displayLangCode(context),
    );
  }

  Future<void> _loadLanguageCatalog() async {
    await LanguageCatalog.instance.ensureLoaded();
    if (!mounted) return;
    setState(() => _languageCatalogReady = true);
  }

  /// 外部URLをブラウザで開く
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorServerError)),
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
    _loadDisplayName();
    _loadQuizMode();
    _loadCharacter();
    _loadLanguageCatalog();

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

  Future<void> _loadDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _displayName = prefs.getString('user_display_name');
    });
  }

  Future<void> _loadQuizMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quizModePrefKey);
    final mode =
        raw == QuizMode.listening.name ? QuizMode.listening : QuizMode.reading;
    if (!mounted) return;
    setState(() => _selectedMode = mode);
  }

  Future<void> _saveQuizMode(QuizMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quizModePrefKey, mode.name);
    if (!mounted) return;
    setState(() => _selectedMode = mode);
  }

  Future<void> _loadCharacter() async {
    final character = await CharacterAssetService.loadSelectedCharacter();
    if (!mounted) return;
    setState(() => _selectedCharacter = character);
  }

  Future<void> _saveCharacter(String character) async {
    await CharacterAssetService.saveSelectedCharacter(character);
    if (!mounted) return;
    setState(() => _selectedCharacter = character);
  }

  void _showParticles(BuildContext context, Offset center) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ParticleBurst(
        center: center,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  Future<void> _fetchUser() async {
    final uid = _authService.currentUser!.uid;
    print('💡 Firestoreからユーザーデータ取得中... UID: $uid');

    setState(() => _isLoadingUser = true);

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      print('💡 Firestoreの中身: ${doc.data()}');

      final user = await _authService.fetchCurrentUser();
      setState(() {
        _user = user;
        if ((_displayName == null || _displayName!.trim().isEmpty) &&
            (user?.displayName != null &&
                user!.displayName!.trim().isNotEmpty)) {
          _displayName = user.displayName!.trim();
        }
      });
    } catch (e) {
      print('❌ ユーザー取得エラー: $e');
    } finally {
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _saveLanguage(String code) async {
    final parts = code.split(RegExp('[-_]'));
    final locale =
        (parts.length == 2) ? Locale(parts[0], parts[1]) : Locale(parts[0]);

    final previousTarget = selectedTargetLang;
    var nextTarget = previousTarget;
    if (nextTarget == null || nextTarget == code) {
      nextTarget = _defaultTargetForNative(code);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_language', code);
    await prefs.setString('target_language', nextTarget);

    setState(() {
      selectedLang = code;
      selectedTargetLang = nextTarget;
    });
    MyApp.setLocale(context, locale);

    final loc = AppLocalizations.of(context)!;
    if (previousTarget == code) {
      final targetLabel = _labelForLangCode(nextTarget, context);
      final msg = loc.localeName.startsWith('ja')
          ? '母語の変更に合わせて、学びたい言語を「$targetLabel」に自動変更しました。'
          : 'Target language was automatically changed to "$targetLabel" to keep it different from your native language.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.languageUpdated)),
    );
  }

  Future<void> _saveTargetLanguage(String code) async {
    final native = selectedLang;
    if (native != null && code == native) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sameLanguageNotAllowedMessage(loc))),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('target_language', code);

    setState(() => selectedTargetLang = code);
  }

  String _defaultTargetForNative(String nativeCode) {
    return nativeCode == 'ja' ? 'en' : 'ja';
  }

  String _sameLanguageNotAllowedMessage(AppLocalizations loc) {
    if (loc.localeName.startsWith('ja')) {
      return '母語と学びたい言語は同じにできません。別の言語を選択してください。';
    }
    return 'Native language and target language must be different. Please choose another language.';
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

  String _modeSubtitle(AppLocalizations loc) {
    return _selectedMode == QuizMode.reading
        ? loc.readingLabel
        : loc.listeningLabel;
  }

  String _subscriptionSubtitle(AppLocalizations loc) {
    final price = _offerings?.current?.monthly?.storeProduct.priceString;
    final pricePart = (price == null || price.isEmpty)
        ? ''
        : '$price${loc.subscriptionPriceTaxSuffix}';
    if (pricePart.isEmpty) {
      return loc.subscriptionManageSubtitle;
    }
    return '$pricePart • ${loc.subscriptionPlanTrial}';
  }

  Future<void> _showModePicker(AppLocalizations loc) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(loc.readingLabel),
                trailing: _selectedMode == QuizMode.reading
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  await _saveQuizMode(QuizMode.reading);
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                title: Text(loc.listeningLabel),
                trailing: _selectedMode == QuizMode.listening
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  await _saveQuizMode(QuizMode.listening);
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreditsSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.copyright_rounded,
                        color: Colors.blueGrey.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Credits',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'VOICEVOX',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                _voicevoxCreditTile('春日部つむぎ'),
                const SizedBox(height: 8),
                _voicevoxCreditTile('四国めたん'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _voicevoxCreditTile(String characterName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.record_voice_over_rounded,
              size: 18, color: Colors.pink.shade300),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                characterName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                'VOICEVOX',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguagePicker({required bool target}) async {
    final loc = AppLocalizations.of(context)!;
    final candidates = (target && selectedLang != null)
        ? _languageCodes.where((code) => code != selectedLang).toList()
        : _languageCodes;
    final current = target ? selectedTargetLang : selectedLang;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                    target ? loc.targetLanguage : loc.languageSelectionTitle),
              ),
              ...candidates.map((code) {
                return ListTile(
                  title: Text(_labelForLangCode(code, context)),
                  trailing: current == code
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    if (target) {
                      await _saveTargetLanguage(code);
                    } else {
                      await _saveLanguage(code);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onDangerAction(bool isAnon) async {
    final loc = AppLocalizations.of(context)!;
    final msg = isAnon
        ? loc.settings_confirmResetData
        : loc.settings_confirmDeleteAccount;
    final ok = await _showConfirmDialog(context, msg);
    if (!ok) return;

    try {
      if (isAnon) {
        await _authService.resetAnonymousData();
      } else {
        final pw = await _promptForPassword(context);
        await _authService.deleteUserAccount(password: pw);
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/splash',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorServerError)),
      );
    }
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
    Widget? leading,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            leading ??
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? Colors.blueGrey.shade700,
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? const Color(0xFF1F2937),
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.blueGrey.shade600,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade500,
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAnon = _authService.currentUser?.isAnonymous ?? true;
    // ① セッションミスマッチ時はエラー画面のみ表示
    if (subscriptionService.isSessionMismatch && !isAnon) {
      return Scaffold(
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.errorSessionMismatch,
          ),
        ),
      );
    }

    final loc = AppLocalizations.of(context)!;
    final displayName =
        (_displayName != null && _displayName!.trim().isNotEmpty)
            ? _displayName!.trim()
            : (isAnon
                ? loc.guest
                : (_user?.displayName ?? _user?.email ?? loc.guest));

    // ユーザーデータ読み込み中はプログレス
    if (!isAnon && _isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final registeredDate = (!isAnon && _user != null)
        ? loc.registeredDate(DateFormat.yMMMd().format(_user!.createdAt))
        : null;
    final languageSectionTitle =
        '${loc.languageSelectionTitle} / ${loc.targetLanguage}';
    final modeSectionTitle = '${loc.readingLabel} / ${loc.listeningLabel}';
    final supportSectionTitle = '${loc.viewFaq} / ${loc.termsOfService}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(title: Text(loc.settingsTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 620 ? 24.0 : 14.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPadding, 12, horizontalPadding, 24),
                  children: [
                    _sectionCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.pink.shade50,
                                child: Icon(
                                  Icons.person_outline,
                                  color: Colors.pink.shade400,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.welcomeUser(displayName),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    if (registeredDate != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          registeredDate,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _sectionHeader(context, loc.profileTitle),
                    _sectionCard(
                      children: [
                        _settingsRow(
                          icon: Icons.edit_outlined,
                          title: loc.userNameEdit,
                          subtitle: displayName,
                          onTap: () async {
                            final updated = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserNameScreen(
                                  isOnboarding: false,
                                  initialName: _displayName,
                                ),
                              ),
                            );
                            if (updated != null && updated.trim().isNotEmpty) {
                              setState(() => _displayName = updated.trim());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.userNameUpdated)),
                              );
                            }
                          },
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),
                        if (_user != null) ...[
                          Container(
                            color: Colors.pink.shade50.withOpacity(0.6),
                            child: _settingsRow(
                              icon: Icons.workspace_premium_outlined,
                              title: loc.subscriptionManageTitle,
                              subtitle: _subscriptionSubtitle(loc),
                              leading: SizedBox(
                                width: 22,
                                height: 22,
                                child: Image.asset(
                                  'assets/images/icon/basic_plan002.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SubscriptionScreen()),
                              ),
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                        ],
                        _settingsRow(
                          icon: Icons.person_outline_rounded,
                          title: loc.profileTitle,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          ),
                        ),
                        if (isAnon) ...[
                          Divider(height: 1, color: Colors.grey.shade200),
                          _settingsRow(
                            icon: Icons.person_add_alt_1_outlined,
                            title: loc.registerAccount,
                            subtitle: loc.registerSubtitle,
                            onTap: () =>
                                Navigator.pushNamed(context, '/register'),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          _settingsRow(
                            icon: Icons.login_rounded,
                            title: loc.loginTitle,
                            subtitle: loc.loginSubtitle,
                            onTap: () => Navigator.pushNamed(context, '/login'),
                          ),
                        ],
                      ],
                    ),
                    _sectionHeader(context, 'キャラクター'),
                    _sectionCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              for (final char in CharacterAssetService
                                  .supportedCharacters) ...[
                                Expanded(
                                  child: GestureDetector(
                                    onTapDown: (d) {
                                      _saveCharacter(char);
                                      _showParticles(context, d.globalPosition);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _selectedCharacter == char
                                            ? Colors.pink.shade400
                                            : Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedCharacter == char
                                              ? Colors.pink.shade300
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.asset(
                                              CharacterAssetService
                                                  .chatAvatar(char),
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            CharacterAssetService
                                                .characterDisplayName(
                                                    char,
                                                    selectedLang ?? 'ja'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: _selectedCharacter == char
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),
                        _settingsRow(
                          icon: Icons.auto_awesome_rounded,
                          title: _selectedCharacter == 'kasumi'
                              ? loc.kasumiProfileMenuTitle
                              : loc.tsumugiProfileMenuTitle,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _selectedCharacter == 'kasumi'
                                  ? const KasumiProfileScreen()
                                  : const TsumugiProfileScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _sectionHeader(context, modeSectionTitle),
                    _sectionCard(
                      children: [
                        _settingsRow(
                          icon: Icons.tune_rounded,
                          title: modeSectionTitle,
                          subtitle: _modeSubtitle(loc),
                          onTap: () => _showModePicker(loc),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: ModeToggleBar(
                            value: _selectedMode,
                            onChanged: _saveQuizMode,
                            readingLabel: loc.readingLabel,
                            listeningLabel: loc.listeningLabel,
                          ),
                        ),
                      ],
                    ),
                    _sectionHeader(context, languageSectionTitle),
                    _sectionCard(
                      children: [
                        _settingsRow(
                          icon: Icons.translate_rounded,
                          title: loc.languageSelectionTitle,
                          subtitle: _labelForLangCode(selectedLang, context),
                          onTap: () => _showLanguagePicker(target: false),
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),
                        _settingsRow(
                          icon: Icons.language_rounded,
                          title: loc.targetLanguage,
                          subtitle:
                              _labelForLangCode(selectedTargetLang, context),
                          onTap: () => _showLanguagePicker(target: true),
                        ),
                      ],
                    ),
                    _sectionHeader(context, supportSectionTitle),
                    _sectionCard(
                      children: [
                        if (selectedLang != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                            child: KeyboardGuideButton(
                              targetLanguage:
                                  selectedTargetLang ?? selectedLang!,
                              alwaysVisible: true,
                            ),
                          ),
                        if (selectedLang != null)
                          Divider(height: 1, color: Colors.grey.shade200),
                        _settingsRow(
                          icon: Icons.help_outline_rounded,
                          title: loc.viewFaq,
                          onTap: () => _launchUrl(_faqUrl),
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),
                        _settingsRow(
                          icon: Icons.description_outlined,
                          title: loc.termsOfService,
                          onTap: () =>
                              _launchUrl('https://kawaiilang.com/terms.html'),
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),
                        _settingsRow(
                          icon: Icons.privacy_tip_outlined,
                          title: loc.privacyPolicy,
                          onTap: () =>
                              _launchUrl('https://kawaiilang.com/privacy.html'),
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),
                        _settingsRow(
                          icon: Icons.copyright_rounded,
                          title: 'Credits',
                          onTap: _showCreditsSheet,
                        ),
                      ],
                    ),
                    _sectionHeader(context, loc.logout),
                    _sectionCard(
                      children: [
                        if (!isAnon) ...[
                          _settingsRow(
                            icon: Icons.logout_rounded,
                            title: loc.logout,
                            subtitle: loc.logoutConfirmation,
                            onTap: () async {
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(loc.logout),
                                  content: Text(loc.logoutConfirmation),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(loc.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(loc.ok),
                                    ),
                                  ],
                                ),
                              );
                              if (shouldLogout == true) {
                                await _handleLogout();
                                await FirebaseAuth.instance.signInAnonymously();
                                if (!mounted) return;
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/splash',
                                  (route) => false,
                                );
                              }
                            },
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                        ],
                        _settingsRow(
                          icon: isAnon
                              ? Icons.refresh_rounded
                              : Icons.delete_forever_rounded,
                          title: isAnon
                              ? loc.settings_resetData
                              : loc.settings_deleteAccount,
                          subtitle: isAnon
                              ? loc.settings_confirmResetData
                              : loc.settings_confirmDeleteAccount,
                          iconColor: Colors.red.shade500,
                          titleColor: Colors.red.shade600,
                          trailing: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade400,
                          ),
                          onTap: () => _onDangerAction(isAnon),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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
        title: Text(AppLocalizations.of(ctx)!
            .enterPassword), // arb に “enterPassword” を定義しておく
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            hintText:
                AppLocalizations.of(ctx)!.password, // arb に “password” も定義
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

// ─────────────────────────────────────────────────────────────────────────────
