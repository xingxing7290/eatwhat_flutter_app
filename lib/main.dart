// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPrimaryApiBase = 'http://113.44.50.108:8088/api';
const String kFallbackApiBase = 'http://113.44.50.108:3002/api';
const List<String> kApiBases = [kPrimaryApiBase, kFallbackApiBase];
const String kAssetBase = 'http://113.44.50.108:8088';
const Duration kRequestTimeout = Duration(seconds: 30);
const Duration kUploadTimeout = Duration(seconds: 90);
const double kUploadImageMaxSide = 1600;
const int kUploadImageQuality = 68;
const int kUploadImageMaxBytes = 2 * 1024 * 1024;
const int kFoodFocusMaxSide = 1400;

const kCream = Color(0xFFFDF7EF);
const kOat = Color(0xFFF5EBE6);
const kPaper = Color(0xFFFFFCF7);
const kPeach = Color(0xFFFFB4A2);
const kCoral = Color(0xFFE87867);
const kCaramel = Color(0xFFE09F67);
const kCoffee = Color(0xFF4A3E3D);
const kCocoa = Color(0xFF7D6257);
const kSage = Color(0xFF8AA36B);
const kHoney = Color(0xFFF3C96B);
const kLine = Color(0xFFEAD6C8);
const kImageExtensionPattern = r'\.(jpe?g|png|gif|webp|heic|heif)$';
const kThemeCreamPeach = 'cream_peach';

class AppThemePalette {
  const AppThemePalette({
    required this.key,
    required this.label,
    required this.description,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.text,
    required this.muted,
    required this.line,
    required this.success,
    required this.gradient,
  });

  final String key;
  final String label;
  final String description;
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color text;
  final Color muted;
  final Color line;
  final Color success;
  final List<Color> gradient;
}

const kThemePalettes = <AppThemePalette>[
  AppThemePalette(
    key: kThemeCreamPeach,
    label: '奶油蜜桃',
    description: '温柔奶油底色，适合日常饭桌记录',
    background: kCream,
    backgroundAlt: kOat,
    surface: kPaper,
    primary: kCaramel,
    secondary: kPeach,
    accent: kCoral,
    text: kCoffee,
    muted: kCocoa,
    line: kLine,
    success: kSage,
    gradient: [kCream, kOat, Color(0xFFFFF8F0)],
  ),
  AppThemePalette(
    key: 'japanese_wood',
    label: '日式原木',
    description: '米白、木色和鼠尾草绿，像小厨房手账',
    background: Color(0xFFFBF6EA),
    backgroundAlt: Color(0xFFEFE2D0),
    surface: Color(0xFFFFFCF4),
    primary: Color(0xFFC18754),
    secondary: Color(0xFFDDBB91),
    accent: Color(0xFF8FA37A),
    text: Color(0xFF493D32),
    muted: Color(0xFF7F6A58),
    line: Color(0xFFE2CBB2),
    success: Color(0xFF7E9B73),
    gradient: [Color(0xFFFBF6EA), Color(0xFFF1E3CF), Color(0xFFFFFAEF)],
  ),
  AppThemePalette(
    key: 'caramel_vintage',
    label: '焦糖复古',
    description: '暖咖和焦糖色，适合纪念日和周末家宴',
    background: Color(0xFFF8EFE4),
    backgroundAlt: Color(0xFFEAD3BA),
    surface: Color(0xFFFFFBF4),
    primary: Color(0xFFC47C44),
    secondary: Color(0xFFE7A96E),
    accent: Color(0xFFB96556),
    text: Color(0xFF4B3932),
    muted: Color(0xFF806358),
    line: Color(0xFFE3C4A7),
    success: Color(0xFF87996C),
    gradient: [Color(0xFFF8EFE4), Color(0xFFF1D7BD), Color(0xFFFFF7EC)],
  ),
  AppThemePalette(
    key: 'strawberry_lovers',
    label: '草莓恋人',
    description: '草莓粉和奶白色，情绪更甜一点',
    background: Color(0xFFFFF6F4),
    backgroundAlt: Color(0xFFF9E1DD),
    surface: Color(0xFFFFFCFA),
    primary: Color(0xFFE87583),
    secondary: Color(0xFFFFB7BE),
    accent: Color(0xFFDE6F57),
    text: Color(0xFF51383A),
    muted: Color(0xFF846064),
    line: Color(0xFFF0CBC7),
    success: Color(0xFF89A96D),
    gradient: [Color(0xFFFFF6F4), Color(0xFFFFE4E0), Color(0xFFFFFBF3)],
  ),
  AppThemePalette(
    key: 'warm_cafe',
    label: '暖咖厨房',
    description: '咖啡、蜂蜜和奶泡色，更有小餐馆氛围',
    background: Color(0xFFF7EFE7),
    backgroundAlt: Color(0xFFEADCCD),
    surface: Color(0xFFFFFBF5),
    primary: Color(0xFFA96F4A),
    secondary: Color(0xFFE3B47B),
    accent: Color(0xFFD8895B),
    text: Color(0xFF453832),
    muted: Color(0xFF776158),
    line: Color(0xFFE0C9B6),
    success: Color(0xFF8A9A68),
    gradient: [Color(0xFFF7EFE7), Color(0xFFEBD8C4), Color(0xFFFFF6EA)],
  ),
  AppThemePalette(
    key: 'candle_dinner',
    label: '晚餐烛光',
    description: '奶油底配酒红和暖金，适合纪念日晚餐',
    background: Color(0xFFFCF3EA),
    backgroundAlt: Color(0xFFF2D8C8),
    surface: Color(0xFFFFFBF6),
    primary: Color(0xFF9E5E45),
    secondary: Color(0xFFE8B86D),
    accent: Color(0xFFB85C5A),
    text: Color(0xFF493331),
    muted: Color(0xFF7C5C54),
    line: Color(0xFFE7C7AE),
    success: Color(0xFF879364),
    gradient: [Color(0xFFFCF3EA), Color(0xFFF4DCCB), Color(0xFFFFF5DD)],
  ),
  AppThemePalette(
    key: 'spring_picnic',
    label: '春日野餐',
    description: '浅草绿、米杏和桃粉，更轻快有周末感',
    background: Color(0xFFF7F4E8),
    backgroundAlt: Color(0xFFE5E8D0),
    surface: Color(0xFFFFFCF2),
    primary: Color(0xFF8B9A61),
    secondary: Color(0xFFFFC4A8),
    accent: Color(0xFFE48A72),
    text: Color(0xFF424234),
    muted: Color(0xFF717058),
    line: Color(0xFFDCE0BD),
    success: Color(0xFF78935B),
    gradient: [Color(0xFFF7F4E8), Color(0xFFE9EDD4), Color(0xFFFFF4E4)],
  ),
  AppThemePalette(
    key: 'morning_market',
    label: '烟火早市',
    description: '豆浆白、番茄红和葱绿色，适合早餐和家常菜',
    background: Color(0xFFFFF8EC),
    backgroundAlt: Color(0xFFF6E5C7),
    surface: Color(0xFFFFFDF7),
    primary: Color(0xFFD88445),
    secondary: Color(0xFFFFC978),
    accent: Color(0xFFE2604F),
    text: Color(0xFF443A2D),
    muted: Color(0xFF75624C),
    line: Color(0xFFEBD3A7),
    success: Color(0xFF71925F),
    gradient: [Color(0xFFFFF8EC), Color(0xFFF7E2BB), Color(0xFFFFF1DE)],
  ),
];

AppThemePalette paletteForKey(String key) {
  return kThemePalettes.firstWhere(
    (palette) => palette.key == key,
    orElse: () => kThemePalettes.first,
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EatwhatRoot());
}

class EatwhatRoot extends StatefulWidget {
  const EatwhatRoot({super.key});

  @override
  State<EatwhatRoot> createState() => _EatwhatRootState();
}

class _EatwhatRootState extends State<EatwhatRoot> {
  late final AppState appState;

  @override
  void initState() {
    super.initState();
    appState = AppState()..init();
  }

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      appState: appState,
      child: const EatwhatApp(),
    );
  }
}

class EatwhatApp extends StatelessWidget {
  const EatwhatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '安排吃啥',
      theme: cozyTheme(app.themePalette),
      home: AnimatedBuilder(
        animation: app,
        builder: (context, _) {
          if (app.loading) {
            return const SplashPage();
          }
          return app.isAuthed ? const HomeShell() : const LoginPage();
        },
      ),
    );
  }
}

ThemeData cozyTheme(AppThemePalette palette) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.secondary,
      brightness: Brightness.light,
      primary: palette.primary,
      secondary: palette.secondary,
      tertiary: palette.success,
      surface: palette.surface,
      onSurface: palette.text,
      error: palette.accent,
    ),
    scaffoldBackgroundColor: palette.background,
    fontFamilyFallback: const [
      'Microsoft YaHei',
      'PingFang SC',
      'Noto Sans CJK SC'
    ],
    visualDensity: VisualDensity.standard,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
      decorationColor: palette.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: palette.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardTheme(
      color: palette.surface,
      elevation: 0,
      shadowColor: palette.primary.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      labelStyle: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
      hintStyle: const TextStyle(color: Color(0xFFBFA99C)),
      prefixIconColor: palette.primary,
      suffixIconColor: palette.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: palette.primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 50),
        elevation: 0,
        shadowColor: palette.accent.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.text,
        backgroundColor: Colors.white.withValues(alpha: 0.62),
        side: BorderSide(color: palette.line),
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.accent,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: palette.secondary.withValues(alpha: 0.34),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? palette.accent
              : palette.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: palette.text,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.secondary.withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.72),
        ),
        foregroundColor: WidgetStateProperty.all(palette.text),
        side: WidgetStateProperty.all(BorderSide(color: palette.line)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.accent
            : palette.surface,
      ),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: palette.line, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: palette.accent,
      inactiveTrackColor: palette.secondary.withValues(alpha: 0.25),
      thumbColor: palette.primary,
      overlayColor: palette.secondary.withValues(alpha: 0.18),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.accent),
    dialogTheme: DialogTheme(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      titleTextStyle: TextStyle(
        color: palette.text,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kPaper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.text,
      contentTextStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required this.appState,
    required super.child,
  }) : super(notifier: appState);

  final AppState appState;

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing');
    return scope!.appState;
  }

  static AppState read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppScope>();
    final scope = element?.widget as AppScope?;
    assert(scope != null, 'AppScope is missing');
    return scope!.appState;
  }
}

extension AppContext on BuildContext {
  AppState get app => AppScope.of(this);
  AppState get appRead => AppScope.read(this);
}

class AppState extends ChangeNotifier {
  static const _tokenKey = 'eatwhat.accessToken';
  static const _cachedUserKey = 'eatwhat.cachedUser';
  static const _cachedHouseholdKey = 'eatwhat.cachedHousehold';
  static const _lastLoginAtKey = 'eatwhat.lastLoginAt';
  static const _savedUserKey = 'eatwhat.savedUsername';
  static const _savedPasswordKey = 'eatwhat.savedPassword';
  static const _rememberKey = 'eatwhat.rememberPassword';
  static const _themeKey = 'eatwhat.themeKey';

  bool loading = true;
  String? token;
  Map<String, dynamic>? user;
  Map<String, dynamic>? household;
  DateTime? lastLoginAt;
  String? sessionNotice;
  String themeKey = kThemeCreamPeach;

  bool get isAuthed => token != null && token!.isNotEmpty;
  AppThemePalette get themePalette => paletteForKey(themeKey);
  DateTime? get tokenExpiresAt => jwtExpiresAt(token);
  String get userId => textOf(user?['id'] ?? user?['_id'] ?? user?['uid']);
  String get displayName {
    final name = friendlyText(user?['displayName']);
    if (name.isNotEmpty) {
      return name;
    }
    final username = friendlyText(user?['username']);
    return username.isEmpty ? '你' : username;
  }

  String get householdName {
    final name = friendlyText(household?['name']);
    return name.isEmpty ? '我们的小家' : name;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    themeKey =
        paletteForKey(prefs.getString(_themeKey) ?? kThemeCreamPeach).key;
    user = jsonMap(prefs.getString(_cachedUserKey));
    household = jsonMap(prefs.getString(_cachedHouseholdKey));
    lastLoginAt = DateTime.tryParse(prefs.getString(_lastLoginAtKey) ?? '');
    if (isAuthed) {
      if (isJwtExpired(token)) {
        await clearSession(
          notice: '登录已过期，请重新登录',
          notify: false,
        );
      } else {
        loading = false;
        notifyListeners();
        unawaited(refreshMe().catchError((_) {}));
        return;
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<SavedLogin> savedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return SavedLogin(
      username: prefs.getString(_savedUserKey) ?? '',
      password: prefs.getString(_savedPasswordKey) ?? '',
      remember: prefs.getBool(_rememberKey) ?? false,
    );
  }

  Future<void> saveLogin(
      String username, String password, bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, remember);
    final savedUsername = username.trim();
    if (savedUsername.isNotEmpty) {
      await prefs.setString(_savedUserKey, savedUsername);
    } else {
      await prefs.remove(_savedUserKey);
    }
    if (remember) {
      await prefs.setString(_savedPasswordKey, password);
    } else {
      await prefs.remove(_savedPasswordKey);
    }
  }

  Future<void> setThemeKey(String key) async {
    final palette = paletteForKey(key);
    if (palette.key == themeKey) {
      return;
    }
    themeKey = palette.key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeKey);
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final response = await post('/auth/login',
        body: {
          'username': username,
          'password': password,
        },
        auth: false);
    final data = asMap(payload(response));
    token = textOf(data['token'] ?? data['accessToken']);
    if (token == null || token!.isEmpty) {
      throw const ApiException('登录接口没有返回 token');
    }
    user = asMap(data['user']);
    household = asMap(data['household']);
    sessionNotice = null;
    lastLoginAt = DateTime.now();
    await persistSession();
    notifyListeners();
  }

  Future<void> register({
    required String username,
    required String password,
    required String displayName,
    required String householdName,
    required String inviteCode,
  }) async {
    final response = await post('/auth/register',
        body: {
          'username': username,
          'password': password,
          'displayName': displayName,
          'householdName': householdName,
          'inviteCode': inviteCode,
        },
        auth: false);
    final data = asMap(payload(response));
    final newToken = textOf(data['token'] ?? data['accessToken']);
    if (newToken.isEmpty) {
      await login(username, password);
      return;
    }
    token = newToken;
    user = asMap(data['user']);
    household = asMap(data['household']);
    sessionNotice = null;
    lastLoginAt = DateTime.now();
    await persistSession();
    notifyListeners();
  }

  Future<void> refreshMe() async {
    final response = await get('/auth/me');
    final data = asMap(payload(response));
    user = asMap(data['user'] ?? data);
    household = asMap(data['household']);
    await persistCachedProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    await clearSession();
  }

  Future<List<ApiEndpointStatus>> checkApiEndpoints() async {
    final statuses = <ApiEndpointStatus>[];
    for (final apiBase in kApiBases) {
      final healthUri = healthUriForApiBase(apiBase);
      final startedAt = DateTime.now();
      try {
        final response = await rawHttpRequest(
          'GET',
          healthUri,
          const {
            'Accept': 'text/plain, application/json',
            'Accept-Encoding': 'identity',
            'X-Mobile-Client': 'eatwhat-flutter',
          },
          null,
        );
        final elapsed = DateTime.now().difference(startedAt);
        final message = utf8.decode(response.bodyBytes).trim();
        statuses.add(ApiEndpointStatus(
          apiBase: apiBase,
          healthUri: healthUri,
          ok: response.statusCode >= 200 && response.statusCode < 300,
          statusCode: response.statusCode,
          message: message.isEmpty ? response.reasonPhrase ?? '' : message,
          elapsed: elapsed,
        ));
      } catch (error) {
        statuses.add(ApiEndpointStatus(
          apiBase: apiBase,
          healthUri: healthUri,
          ok: false,
          message: errorText(error),
          elapsed: DateTime.now().difference(startedAt),
        ));
      }
    }
    return statuses;
  }

  Future<void> clearSession({String? notice, bool notify = true}) async {
    token = null;
    user = null;
    household = null;
    lastLoginAt = null;
    sessionNotice = notice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_cachedUserKey);
    await prefs.remove(_cachedHouseholdKey);
    await prefs.remove(_lastLoginAtKey);
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token!.isNotEmpty) {
      await prefs.setString(_tokenKey, token!);
    }
    if (lastLoginAt != null) {
      await prefs.setString(_lastLoginAtKey, lastLoginAt!.toIso8601String());
    }
    await persistCachedProfile(prefs: prefs);
  }

  Future<void> persistCachedProfile({SharedPreferences? prefs}) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    if (user == null || user!.isEmpty) {
      await store.remove(_cachedUserKey);
    } else {
      await store.setString(_cachedUserKey, jsonEncode(user));
    }
    if (household == null || household!.isEmpty) {
      await store.remove(_cachedHouseholdKey);
    } else {
      await store.setString(_cachedHouseholdKey, jsonEncode(household));
    }
  }

  Future<dynamic> get(String path,
      {Map<String, String>? query, bool auth = true}) {
    return request('GET', path, query: query, auth: auth);
  }

  Future<dynamic> post(String path,
      {Map<String, dynamic>? body, bool auth = true}) {
    return request('POST', path, body: body, auth: auth);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) {
    return request('PUT', path, body: body);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) {
    return request('PATCH', path, body: body);
  }

  Future<dynamic> delete(String path, {Map<String, String>? query}) {
    return request('DELETE', path, query: query);
  }

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip',
      'X-Mobile-Client': 'eatwhat-flutter',
    };
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }
    if (auth && isAuthed) {
      if (isJwtExpired(token)) {
        await clearSession(notice: '登录已过期，请重新登录');
        throw const ApiException('登录已过期，请重新登录', statusCode: 401);
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final encoded = body == null ? null : jsonEncode(body);
    if (!['GET', 'POST', 'PUT', 'PATCH', 'DELETE'].contains(method)) {
      throw ApiException('Unsupported request method: $method');
    }
    final bases = kApiBases;
    Object? lastError;
    for (var index = 0; index < bases.length; index += 1) {
      final uri = Uri.parse('${bases[index]}$path')
          .replace(queryParameters: cleanedQuery(query));
      try {
        final response = await rawHttpRequest(method, uri, headers, encoded);
        return decodeResponse(response);
      } on ApiException catch (error) {
        if (auth && error.isAuthExpired) {
          await clearSession(notice: '登录已过期，请重新登录');
        }
        rethrow;
      } catch (error) {
        lastError = error;
        if (index < bases.length - 1 && isRetriableNetworkError(error)) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          continue;
        }
        break;
      }
    }
    throw networkApiException(lastError);
  }

  Future<http.Response> rawHttpRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) async {
    if (uri.scheme != 'http') {
      throw ApiException('Unsupported API scheme: ${uri.scheme}');
    }
    final socket = await io.Socket.connect(
      uri.host,
      uri.hasPort ? uri.port : 80,
      timeout: const Duration(seconds: 10),
    ).timeout(kRequestTimeout);
    try {
      final bodyBytes = body == null ? null : utf8.encode(body);
      final requestPath =
          '${uri.path.isEmpty ? '/' : uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      final hostHeader = '${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      final requestHeaders = StringBuffer()
        ..write('$method $requestPath HTTP/1.0\r\n')
        ..write('Host: $hostHeader\r\n')
        ..write('Connection: close\r\n');
      headers.forEach((name, value) {
        final lower = name.toLowerCase();
        if (lower != 'host' &&
            lower != 'connection' &&
            lower != 'content-length') {
          requestHeaders.write('$name: $value\r\n');
        }
      });
      if (bodyBytes != null) {
        requestHeaders.write('Content-Length: ${bodyBytes.length}\r\n');
      }
      requestHeaders.write('\r\n');
      socket.add(latin1.encode(requestHeaders.toString()));
      if (bodyBytes != null) {
        socket.add(bodyBytes);
      }
      await socket.flush().timeout(kRequestTimeout);
      final rawResponse =
          await readSocketResponse(socket).timeout(kRequestTimeout);
      final parsed = parseHttpResponse(rawResponse);
      final responseBody = parsed.headers['content-encoding'] == 'gzip'
          ? io.gzip.decode(parsed.bodyBytes)
          : parsed.bodyBytes;
      return http.Response.bytes(
        responseBody,
        parsed.statusCode,
        headers: parsed.headers,
        reasonPhrase: parsed.reasonPhrase,
        request: http.Request(method, uri),
      );
    } finally {
      socket.destroy();
    }
  }

  Future<dynamic> multipart(
    String method,
    String path, {
    Map<String, String>? fields,
    Map<String, XFile>? files,
    Map<String, List<XFile>>? multiFiles,
  }) async {
    Object? lastError;
    for (var index = 0; index < kApiBases.length; index += 1) {
      try {
        final request = http.MultipartRequest(
            method, Uri.parse('${kApiBases[index]}$path'));
        request.headers['Accept'] = 'application/json';
        request.headers['Accept-Encoding'] = 'identity';
        if (isAuthed) {
          if (isJwtExpired(token)) {
            await clearSession(notice: '登录已过期，请重新登录');
            throw const ApiException('登录已过期，请重新登录', statusCode: 401);
          }
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.fields.addAll(fields ?? {});
        for (final entry in (files ?? {}).entries) {
          request.files.add(http.MultipartFile.fromBytes(
            entry.key,
            await entry.value.readAsBytes(),
            filename: uploadFileName(entry.value),
            contentType: uploadContentType(entry.value),
          ));
        }
        for (final entry in (multiFiles ?? {}).entries) {
          for (final file in entry.value) {
            request.files.add(http.MultipartFile.fromBytes(
              entry.key,
              await file.readAsBytes(),
              filename: uploadFileName(file),
              contentType: uploadContentType(file),
            ));
          }
        }
        final streamed = await request.send().timeout(kUploadTimeout);
        final response = await http.Response.fromStream(streamed)
            .timeout(kUploadTimeout, onTimeout: () {
          throw TimeoutException('upload response timeout');
        });
        return decodeResponse(response);
      } on ApiException catch (error) {
        if (error.isAuthExpired) {
          await clearSession(notice: '登录已过期，请重新登录');
        }
        rethrow;
      } catch (error) {
        lastError = error;
        if (index < kApiBases.length - 1 && isRetriableNetworkError(error)) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          continue;
        }
        break;
      }
    }
    throw networkApiException(
      lastError,
      prefix: '上传请求失败',
    );
  }

  dynamic decodeResponse(http.Response response) {
    dynamic body;
    final text = utf8.decode(response.bodyBytes);
    if (text.trim().isEmpty) {
      body = <String, dynamic>{};
    } else {
      try {
        body = jsonDecode(text);
      } catch (_) {
        body = text;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          body is Map ? textOf(body['message'] ?? body['error']) : text;
      throw ApiException(
        message.isEmpty ? '服务器请求失败 ${response.statusCode}' : message,
        statusCode: response.statusCode,
      );
    }
    return body;
  }
}

class SavedLogin {
  const SavedLogin({
    required this.username,
    required this.password,
    required this.remember,
  });

  final String username;
  final String password;
  final bool remember;
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  bool get isAuthExpired => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class ApiEndpointStatus {
  const ApiEndpointStatus({
    required this.apiBase,
    required this.healthUri,
    required this.ok,
    required this.message,
    required this.elapsed,
    this.statusCode,
  });

  final String apiBase;
  final Uri healthUri;
  final bool ok;
  final String message;
  final Duration elapsed;
  final int? statusCode;
}

Uri healthUriForApiBase(String apiBase) {
  final uri = Uri.parse(apiBase);
  final segments = uri.pathSegments.toList();
  if (segments.isNotEmpty && segments.last == 'api') {
    segments.removeLast();
  }
  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : 0,
    pathSegments: [...segments, 'health'],
  );
}

String apiBaseLabel(String apiBase) {
  final uri = Uri.parse(apiBase);
  final port = uri.hasPort ? ':${uri.port}' : '';
  final segments = uri.pathSegments.toList();
  if (segments.isNotEmpty && segments.last == 'api') {
    segments.removeLast();
  }
  final path = segments.isEmpty ? '' : '/${segments.join('/')}';
  return '${uri.host}$port$path';
}

bool isRetriableNetworkError(Object error) {
  return error is TimeoutException ||
      error is io.SocketException ||
      error is http.ClientException;
}

ApiException networkApiException(Object? error, {String prefix = '网络请求失败'}) {
  if (error is TimeoutException) {
    return const ApiException('网络连接超时，已自动重试，请稍后再试');
  }
  if (error is io.SocketException) {
    return ApiException('网络连接失败，请检查手机网络后重试：${error.message}');
  }
  if (error == null) {
    return ApiException(prefix);
  }
  return ApiException('$prefix：$error');
}

class ParsedHttpResponse {
  const ParsedHttpResponse({
    required this.statusCode,
    required this.reasonPhrase,
    required this.headers,
    required this.bodyBytes,
  });

  final int statusCode;
  final String reasonPhrase;
  final Map<String, String> headers;
  final List<int> bodyBytes;
}

Future<List<int>> readSocketResponse(io.Socket socket) {
  final completer = Completer<List<int>>();
  final bytes = <int>[];
  Timer? idleTimer;
  late final StreamSubscription<List<int>> subscription;

  void complete() {
    idleTimer?.cancel();
    if (!completer.isCompleted) {
      completer.complete(List<int>.unmodifiable(bytes));
    }
  }

  void scheduleIdleCompletion() {
    idleTimer?.cancel();
    idleTimer = Timer(const Duration(milliseconds: 500), () {
      subscription.cancel().whenComplete(complete);
    });
  }

  subscription = socket.listen(
    (chunk) {
      bytes.addAll(chunk);
      final parsedLength = parsedSocketContentLength(bytes);
      final headerEnd = httpHeaderEndIndex(bytes);
      if (headerEnd >= 0 &&
          parsedLength != null &&
          bytes.length - headerEnd - 4 >= parsedLength) {
        subscription.cancel().whenComplete(complete);
      } else {
        scheduleIdleCompletion();
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      idleTimer?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    },
    onDone: complete,
    cancelOnError: true,
  );

  return completer.future;
}

int? parsedSocketContentLength(List<int> bytes) {
  final headerEnd = httpHeaderEndIndex(bytes);
  if (headerEnd < 0) {
    return null;
  }
  final headerText = latin1.decode(bytes.sublist(0, headerEnd));
  for (final line in headerText.split('\r\n').skip(1)) {
    final separator = line.indexOf(':');
    if (separator <= 0) {
      continue;
    }
    final name = line.substring(0, separator).trim().toLowerCase();
    if (name == 'content-length') {
      return int.tryParse(line.substring(separator + 1).trim());
    }
  }
  return null;
}

ParsedHttpResponse parseHttpResponse(List<int> bytes) {
  final headerEnd = httpHeaderEndIndex(bytes);
  if (headerEnd < 0) {
    throw const ApiException('服务器响应格式无效');
  }
  final headerText = latin1.decode(bytes.sublist(0, headerEnd));
  final lines = headerText.split('\r\n');
  final statusParts = lines.first.split(' ');
  if (statusParts.length < 2) {
    throw const ApiException('服务器响应状态无效');
  }
  final statusCode = int.tryParse(statusParts[1]);
  if (statusCode == null) {
    throw const ApiException('服务器响应状态无效');
  }
  final headers = <String, String>{};
  for (final line in lines.skip(1)) {
    final separator = line.indexOf(':');
    if (separator > 0) {
      headers[line.substring(0, separator).trim().toLowerCase()] =
          line.substring(separator + 1).trim();
    }
  }
  return ParsedHttpResponse(
    statusCode: statusCode,
    reasonPhrase: statusParts.length > 2 ? statusParts.skip(2).join(' ') : '',
    headers: headers,
    bodyBytes: bytes.sublist(headerEnd + 4),
  );
}

int httpHeaderEndIndex(List<int> bytes) {
  for (var index = 0; index <= bytes.length - 4; index += 1) {
    if (bytes[index] == 13 &&
        bytes[index + 1] == 10 &&
        bytes[index + 2] == 13 &&
        bytes[index + 3] == 10) {
      return index;
    }
  }
  return -1;
}

Future<List<int>> readResponseBytes(io.HttpClientResponse response) {
  final expectedLength = response.contentLength;
  if (expectedLength == 0) {
    return Future<List<int>>.value(const <int>[]);
  }

  final completer = Completer<List<int>>();
  final bytes = <int>[];
  Timer? idleTimer;
  late final StreamSubscription<List<int>> subscription;

  void complete() {
    idleTimer?.cancel();
    if (!completer.isCompleted) {
      completer.complete(List<int>.unmodifiable(bytes));
    }
  }

  void scheduleIdleCompletion() {
    if (expectedLength > 0) {
      return;
    }
    idleTimer?.cancel();
    idleTimer = Timer(const Duration(milliseconds: 500), () {
      subscription.cancel().whenComplete(complete);
    });
  }

  subscription = response.listen(
    (chunk) {
      bytes.addAll(chunk);
      if (expectedLength > 0 && bytes.length >= expectedLength) {
        subscription.cancel().whenComplete(complete);
      } else {
        scheduleIdleCompletion();
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    },
    onDone: complete,
    cancelOnError: true,
  );

  return completer.future;
}

Map<String, String>? cleanedQuery(Map<String, String>? query) {
  if (query == null) {
    return null;
  }
  final cleaned = <String, String>{};
  for (final entry in query.entries) {
    if (entry.value.trim().isNotEmpty) {
      cleaned[entry.key] = entry.value.trim();
    }
  }
  return cleaned.isEmpty ? null : cleaned;
}

dynamic payload(dynamic response) {
  if (response is Map && response.containsKey('data')) {
    return response['data'];
  }
  return response;
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

Map<String, dynamic>? jsonMap(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  try {
    final map = asMap(jsonDecode(value));
    return map.isEmpty ? null : map;
  } catch (_) {
    return null;
  }
}

DateTime? jwtExpiresAt(String? token) {
  if (token == null || token.trim().isEmpty) {
    return null;
  }
  final parts = token.split('.');
  if (parts.length < 2) {
    return null;
  }
  try {
    final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
    final payloadMap = asMap(jsonDecode(utf8.decode(payloadBytes)));
    final seconds = int.tryParse(textOf(payloadMap['exp']));
    if (seconds == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  } catch (_) {
    return null;
  }
}

bool isJwtExpired(String? token) {
  final expiresAt = jwtExpiresAt(token);
  if (expiresAt == null) {
    return false;
  }
  return DateTime.now().toUtc().isAfter(
        expiresAt.subtract(const Duration(seconds: 30)),
      );
}

List<dynamic> asList(dynamic value) {
  if (value is List) {
    return value;
  }
  if (value is Map && value['items'] is List) {
    return value['items'] as List;
  }
  if (value is Map && value['meals'] is List) {
    return value['meals'] as List;
  }
  if (value is Map && value['list'] is List) {
    return value['list'] as List;
  }
  if (value is Map && value['data'] is List) {
    return value['data'] as List;
  }
  return const [];
}

String textOf(dynamic value) => value == null ? '' : value.toString();

String friendlyText(dynamic value) {
  final text = textOf(value).trim();
  if (text.isEmpty || looksBrokenText(text)) {
    return '';
  }
  return text;
}

String difficultyLabel(dynamic value) {
  final text = friendlyText(value).toLowerCase();
  return switch (text) {
    'easy' => '简单',
    'medium' => '中等',
    'hard' => '较难',
    '' => '家常',
    _ => friendlyText(value),
  };
}

bool looksBrokenText(String value) {
  final compact = value.replaceAll(RegExp(r'\s+'), '');
  if (compact.isEmpty) {
    return true;
  }
  final questionMarks = RegExp(r'[\?？]').allMatches(compact).length;
  return questionMarks >= 3 && questionMarks / compact.length > 0.45;
}

String idOf(dynamic value) {
  final map = asMap(value);
  return textOf(map['_id'] ?? map['id']);
}

String imageUrl(dynamic value) {
  final raw = textOf(value).trim();
  if (raw.isEmpty) {
    return '';
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  if (raw.startsWith('/')) {
    return '$kAssetBase$raw';
  }
  return '$kAssetBase/$raw';
}

String two(int value) => value.toString().padLeft(2, '0');
String dateString(DateTime value) =>
    '${value.year}-${two(value.month)}-${two(value.day)}';
String monthString(DateTime value) => '${value.year}-${two(value.month)}';
String monthTitleLabel(DateTime value) => '${value.year} 年 ${value.month} 月';

DateTime monthOnly(DateTime value) => DateTime(value.year, value.month);

DateTime addMonths(DateTime value, int months) =>
    DateTime(value.year, value.month + months);

String monthRelativeLabel(DateTime value) {
  final current = monthOnly(DateTime.now());
  final target = monthOnly(value);
  final diff =
      (target.year - current.year) * 12 + (target.month - current.month);
  if (diff == 0) {
    return '本月';
  }
  if (diff == -1) {
    return '上月';
  }
  if (diff == 1) {
    return '下月';
  }
  return diff > 0 ? '$diff 个月后' : '${diff.abs()} 个月前';
}

String dateTimeMinuteText(DateTime? value) {
  if (value == null) {
    return '暂无';
  }
  final local = value.toLocal();
  return '${dateString(local)} ${two(local.hour)}:${two(local.minute)}';
}

DateTime mondayOf(DateTime value) {
  return DateTime(value.year, value.month, value.day)
      .subtract(Duration(days: value.weekday - 1));
}

DateTime addWeeks(DateTime value, int weeks) =>
    mondayOf(value).add(Duration(days: weeks * 7));

String weekRangeLabel(DateTime value) {
  final start = mondayOf(value);
  final end = start.add(const Duration(days: 6));
  return '${dateString(start)} - ${dateString(end)}';
}

String weekRelativeLabel(DateTime value) {
  final current = mondayOf(DateTime.now());
  final target = mondayOf(value);
  final diff = target.difference(current).inDays ~/ 7;
  if (diff == 0) {
    return '本周';
  }
  if (diff == -1) {
    return '上周';
  }
  if (diff == 1) {
    return '下周';
  }
  return diff > 0 ? '$diff 周后' : '${diff.abs()} 周前';
}

String errorText(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  return error.toString().replaceFirst('Exception: ', '');
}

String uploadFileName(XFile file) {
  final rawName = file.name.trim().isNotEmpty
      ? file.name.trim()
      : file.path.split(RegExp(r'[\\/]')).last;
  final name = rawName.trim().isNotEmpty ? rawName.trim() : 'upload';
  if (RegExp(kImageExtensionPattern).hasMatch(name.toLowerCase())) {
    return name;
  }
  return '$name.jpg';
}

MediaType uploadContentType(XFile file) {
  final mime = file.mimeType?.toLowerCase().trim();
  if (mime != null && mime.startsWith('image/')) {
    return MediaType.parse(mime);
  }
  final name = uploadFileName(file).toLowerCase();
  if (name.endsWith('.heic')) return MediaType('image', 'heic');
  if (name.endsWith('.heif')) return MediaType('image', 'heif');
  if (name.endsWith('.png')) return MediaType('image', 'png');
  if (name.endsWith('.gif')) return MediaType('image', 'gif');
  if (name.endsWith('.webp')) return MediaType('image', 'webp');
  return MediaType('image', 'jpeg');
}

String readableFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
  }
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
}

String memoryPhotoPickerHint({
  required int existingCount,
  required int newCount,
}) {
  final limit = readableFileSize(kUploadImageMaxBytes);
  if (newCount > 0) {
    return '新增 $newCount 张已压缩为 JPG，保存时上传，单张目标不超过 $limit';
  }
  if (existingCount > 0) {
    return '已有 $existingCount 张线上照片，可继续补拍或从图库添加';
  }
  return '支持图库多选和现场拍照，会自动压缩为 JPG，适配服务器上传格式';
}

Future<XFile> createFoodFocusPhoto(XFile source) async {
  final bytes = await source.readAsBytes();
  final processed = await compute(renderFoodFocusBytes, bytes);
  final sourceName = uploadFileName(source);
  final baseName = sourceName.replaceFirst(RegExp(r'\.[^.]+$'), '');
  final safeName = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '-');
  final outputName =
      '${safeName.isEmpty ? 'food' : safeName}-focus-${DateTime.now().millisecondsSinceEpoch}.jpg';
  final outputPath = [
    io.Directory.systemTemp.path,
    outputName,
  ].join(io.Platform.pathSeparator);
  final outputFile = io.File(outputPath);
  await outputFile.writeAsBytes(processed, flush: true);
  return XFile(outputPath, name: outputName, mimeType: 'image/jpeg');
}

List<int> renderFoodFocusBytes(Uint8List inputBytes) {
  final decoded = img.decodeImage(inputBytes);
  if (decoded == null) {
    throw const FormatException('Unsupported image format');
  }

  var source = img.bakeOrientation(decoded);
  final maxSide = math.max(source.width, source.height);
  if (maxSide > kFoodFocusMaxSide) {
    source = source.width >= source.height
        ? img.copyResize(source,
            width: kFoodFocusMaxSide, interpolation: img.Interpolation.cubic)
        : img.copyResize(source,
            height: kFoodFocusMaxSide, interpolation: img.Interpolation.cubic);
  }

  final blurRadius =
      math.max(7, math.min(18, math.max(source.width, source.height) ~/ 95));
  final blurred = img.gaussianBlur(source.clone(), radius: blurRadius);
  final output = img.Image.from(source, noAnimation: true);
  final width = source.width;
  final height = source.height;
  final centerX = width * 0.5;
  final centerY = height * 0.54;
  final radiusX = width * 0.43;
  final radiusY = height * 0.37;
  const feather = 0.28;

  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final fg = source.getPixel(x, y);
      final bg = blurred.getPixel(x, y);
      final nx = (x - centerX) / radiusX;
      final ny = (y - centerY) / radiusY;
      final distance = math.sqrt(nx * nx + ny * ny);
      final backgroundWeight = smoothStep(1 - feather, 1 + feather, distance);
      final highlightWeight = 1 - smoothStep(0.72, 1.0, distance);

      final mutedBackground = mutedFoodBackground(bg.r, bg.g, bg.b);
      final foreground = [
        clampColor(
            fg.r * (1.04 + 0.05 * highlightWeight) + 5 * highlightWeight),
        clampColor(
            fg.g * (1.03 + 0.04 * highlightWeight) + 4 * highlightWeight),
        clampColor(
            fg.b * (1.02 + 0.03 * highlightWeight) + 2 * highlightWeight),
      ];

      final vignette = 1 - 0.10 * smoothStep(0.82, 1.45, distance);
      output.setPixelRgb(
        x,
        y,
        clampColor(lerpDoubleValue(
                foreground[0], mutedBackground[0], backgroundWeight) *
            vignette),
        clampColor(lerpDoubleValue(
                foreground[1], mutedBackground[1], backgroundWeight) *
            vignette),
        clampColor(lerpDoubleValue(
                foreground[2], mutedBackground[2], backgroundWeight) *
            vignette),
      );
    }
  }

  return encodeJpgWithinUploadLimit(output);
}

List<int> encodeJpgWithinUploadLimit(
  img.Image source, {
  int maxBytes = kUploadImageMaxBytes,
  int maxSide = kFoodFocusMaxSide,
}) {
  var output = source;
  final sourceMaxSide = math.max(source.width, source.height);
  if (sourceMaxSide > maxSide) {
    output = source.width >= source.height
        ? img.copyResize(
            source,
            width: maxSide,
            interpolation: img.Interpolation.cubic,
          )
        : img.copyResize(
            source,
            height: maxSide,
            interpolation: img.Interpolation.cubic,
          );
  }
  var quality = 86;

  while (true) {
    final encoded = img.encodeJpg(output, quality: quality);
    final currentMaxSide = math.max(output.width, output.height);
    if (encoded.length <= maxBytes ||
        (quality <= 52 && currentMaxSide <= 900)) {
      return encoded;
    }

    if (quality > 52) {
      quality -= 8;
      continue;
    }

    final nextMaxSide = math.max(900, (currentMaxSide * 0.84).round());
    output = output.width >= output.height
        ? img.copyResize(
            output,
            width: nextMaxSide,
            interpolation: img.Interpolation.cubic,
          )
        : img.copyResize(
            output,
            height: nextMaxSide,
            interpolation: img.Interpolation.cubic,
          );
    quality = 76;
  }
}

List<int> mutedFoodBackground(num red, num green, num blue) {
  final gray = red * 0.299 + green * 0.587 + blue * 0.114;
  return [
    clampColor((red * 0.42 + gray * 0.58) * 0.80 + 14),
    clampColor((green * 0.42 + gray * 0.58) * 0.80 + 10),
    clampColor((blue * 0.42 + gray * 0.58) * 0.76 + 8),
  ];
}

double smoothStep(double edge0, double edge1, double value) {
  final t = ((value - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double lerpDoubleValue(num start, num end, double amount) {
  return start + (end - start) * amount;
}

int clampColor(num value) {
  return value.round().clamp(0, 255);
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<T?> pushPage<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppBackdrop(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 82),
            SizedBox(height: 16),
            Text(
              '正在准备小家的饭桌...',
              style: TextStyle(fontWeight: FontWeight.w900, color: kCoffee),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool remember = false;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final saved = await context.appRead.savedLogin();
      if (!mounted) {
        return;
      }
      setState(() {
        usernameController.text = saved.username;
        passwordController.text = saved.password;
        remember = saved.remember;
      });
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (usernameController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      showMessage(context, '请输入账号和密码');
      return;
    }
    setState(() => submitting = true);
    try {
      await context.appRead
          .login(usernameController.text.trim(), passwordController.text);
      await context.appRead.saveLogin(
          usernameController.text.trim(), passwordController.text, remember);
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppBackdrop(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 92),
                  const SizedBox(height: 16),
                  SoftCard(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '安排吃啥',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: kCoffee,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '把两个人的一日三餐，记成一本温暖手账',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: kCocoa,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 22),
                        const PartnerPresencePill(
                          text: 'TA 正在等你一起决定今晚吃什么',
                        ),
                        if (context.app.sessionNotice != null &&
                            context.app.sessionNotice!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kPeach.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: kCoral.withValues(alpha: 0.28)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: kCoral, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.app.sessionNotice!,
                                    style: const TextStyle(
                                      color: kCoffee,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        TextField(
                          controller: usernameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: '账号',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          onSubmitted: (_) => submit(),
                          decoration: const InputDecoration(
                            labelText: '密码',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        CheckboxListTile(
                          value: remember,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('记住密码'),
                          onChanged: (value) =>
                              setState(() => remember = value ?? false),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: submitting ? null : submit,
                          icon: submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.login),
                          label: const Text('登录'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: submitting
                              ? null
                              : () => pushPage(context, const RegisterPage()),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('申请账号 / 加入小家'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final displayNameController = TextEditingController();
  final householdNameController = TextEditingController(text: '我们的饭桌');
  final inviteCodeController = TextEditingController();
  bool submitting = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    displayNameController.dispose();
    householdNameController.dispose();
    inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (usernameController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        displayNameController.text.trim().isEmpty) {
      showMessage(context, '请填写账号、昵称和密码');
      return;
    }
    setState(() => submitting = true);
    try {
      await context.appRead.register(
        username: usernameController.text.trim(),
        password: passwordController.text,
        displayName: displayNameController.text.trim(),
        householdName: householdNameController.text.trim(),
        inviteCode: inviteCodeController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('申请账号')),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle(
                      icon: Icons.favorite_border, title: '加入两个人的小家'),
                  const SizedBox(height: 12),
                  const Text(
                    '没有邀请码会创建新的小家；填写 TA 的邀请码会加入同一个小家。',
                    style: TextStyle(
                      color: kCocoa,
                      fontWeight: FontWeight.w800,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: '账号'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: displayNameController,
                    decoration: const InputDecoration(labelText: '昵称'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '密码'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: householdNameController,
                    decoration: const InputDecoration(labelText: '小家名称'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: inviteCodeController,
                    decoration: const InputDecoration(labelText: '邀请码，可不填'),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: submitting ? null : submit,
                    icon: const Icon(Icons.favorite_border),
                    label: Text(submitting ? '提交中...' : '创建 / 加入'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final pages = const [
    DashboardPage(),
    CalendarPage(),
    MealListPage(),
    MemoriesPage(),
    SettingsPage(),
  ];

  final titles = const ['小家首页', '双人日历', '菜谱', '回忆', '设置'];

  @override
  Widget build(BuildContext context) {
    final palette = context.app.themePalette;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 36, compact: true),
            const SizedBox(width: 10),
            Text(titles[index]),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: kLine),
                ),
                child: Text(
                  context.app.householdName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: kCoffee,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child:
                  PartnerPresencePill(text: partnerStatusText(titles[index])),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: pages[index],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: palette.background,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: palette.line),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: index,
                height: 68,
                onDestinationSelected: (value) => setState(() => index = value),
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: '首页'),
                  NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: '日历'),
                  NavigationDestination(
                      icon: Icon(Icons.restaurant_menu),
                      selectedIcon: Icon(Icons.restaurant),
                      label: '菜谱'),
                  NavigationDestination(
                      icon: Icon(Icons.photo_album_outlined),
                      selectedIcon: Icon(Icons.photo_album),
                      label: '回忆'),
                  NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: '设置'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String partnerStatusText(String title) {
  switch (title) {
    case '菜谱':
      return 'TA 正在翻你们的私房菜谱，遇到想吃的就投喂给 TA';
    case '双人日历':
      return '今天的饭桌计划可以像贴便签一样慢慢安排';
    case '回忆':
      return '饭后照片和小心情，会一起留在你们的小家时间线';
    case '设置':
      return '整理默认菜品、图片和小家资料，让两个人都看得舒服';
    default:
      return 'TA 正在看小家饭桌，今晚可以安排一道喜欢的菜';
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<dynamic> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<dynamic> load() async {
    final weekStart = dateString(mondayOf(DateTime.now()));
    final summary = asMap(
      payload(
        await loadPart(() => context.appRead.get('/dashboard/summary')),
      ),
    );
    final anniversaries = dashboardAnniversaryMenus(
      asMap({
        'anniversaries': payload(
          await loadPart(() => context.appRead.get('/anniversaries')),
        ),
      }),
    );
    final shopping = dashboardShoppingItems(
      asMap({
        'shoppingList': payload(
          await loadPart(
            () => context.appRead.get(
              '/shopping-list',
              query: {'weekStart': weekStart},
            ),
          ),
        ),
      }),
    );
    final defaultStatus = asMap(
      payload(
          await loadPart(() => context.appRead.get('/default-meals/status'))),
    );
    final openImageIssues = imageIssues(
      payload(
        await loadPart(
          () => context.appRead.get(
            '/meal-image-issues',
            query: {'status': 'open'},
          ),
        ),
      ),
    );
    if (summary.isNotEmpty) {
      return {
        ...summary,
        if (dashboardAnniversaryMenus(summary).isEmpty &&
            anniversaries.isNotEmpty)
          'anniversaries': anniversaries,
        if (dashboardShoppingItems(summary).isEmpty && shopping.isNotEmpty)
          'shoppingList': shopping,
        if (dashboardDefaultMealStatus(summary).isEmpty &&
            defaultStatus.isNotEmpty)
          'defaultMeals': defaultStatus,
        if (dashboardImageIssueOpenCount(summary) == 0 &&
            openImageIssues.isNotEmpty)
          'imageIssues': openImageIssues,
      };
    }
    final today = DateTime.now();
    final results = await Future.wait<dynamic>([
      loadPart(
          () => context.appRead.get('/schedules/day/${dateString(today)}')),
      loadPart(() => context.appRead.get('/meals', query: {'limit': '1'})),
    ]);
    final meals = mealListFrom(results[1]);
    return <String, dynamic>{
      'todaySchedule': asMap(payload(results[0])),
      'mealCount': dashboardMealCount(results[1], meals),
      'wishlist': 0,
      'memories': 0,
      'defaultMeals': defaultStatus,
      'imageIssues': openImageIssues,
      'anniversaries': anniversaries,
      'shoppingList': shopping,
    };
  }

  Future<dynamic> loadPart(Future<dynamic> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  void reload() => setState(() {
        future = load();
      });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => reload(),
      child: FutureBuilder<dynamic>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingList();
          }
          if (snapshot.hasError) {
            return ErrorState(
                message: errorText(snapshot.error!), onRetry: reload);
          }
          final data = asMap(payload(snapshot.data));
          final today = DateTime.now();
          final todaySchedule = dashboardTodaySchedule(data);
          final partnerWishlist = dashboardPartnerWishlist(data);
          final recentPhotos = dashboardRecentPhotos(data);
          final anniversaryMenus = dashboardAnniversaryMenus(data);
          final shopping = dashboardShoppingItems(data);
          final defaultStatus = dashboardDefaultMealStatus(data);
          final openIssueCount = dashboardImageIssueOpenCount(data);
          final showMaintenance = dashboardNeedsMaintenance(data);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              TodayScheduleCard(
                date: today,
                schedule: todaySchedule,
                onChanged: reload,
              ),
              const SizedBox(height: 14),
              SoftCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF2EA), Color(0xFFFFDCCA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandMark(size: 68, compact: true),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${context.app.displayName}，今天也好好吃饭',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: kCoffee,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'TA 想吃、周计划、饭后回忆都会汇总在这里。',
                                style: TextStyle(
                                  color: kCocoa,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TapedLabel(text: '两人共用', icon: Icons.people_alt),
                        TapedLabel(text: '本周排餐', icon: Icons.event_note),
                        TapedLabel(text: '饭后回忆', icon: Icons.photo_camera),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              pushPage(context, const WeeklyPlanPage()),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('生成本周菜单'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              pushPage(context, const ShoppingListPage()),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('购物清单'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              pushPage(context, const WishlistPage()),
                          icon: const Icon(Icons.favorite_outline),
                          label: const Text('TA 想吃'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DashboardTile(
                    icon: Icons.today,
                    label: '今天安排',
                    value: todayArrangementText(todaySchedule),
                    color: const Color(0xFFFFB4A2),
                  ),
                  DashboardTile(
                    icon: Icons.restaurant,
                    label: '菜品数量',
                    value: countText(data['mealCount'] ??
                        data['defaultMeals'] ??
                        data['meals']),
                    color: const Color(0xFFE09F67),
                  ),
                  DashboardTile(
                    icon: Icons.favorite,
                    label: '想吃提醒',
                    value: countText(data['wishlist'] ??
                        data['wishCount'] ??
                        data['partnerWishlist']),
                    color: const Color(0xFFFF8D7E),
                  ),
                  DashboardTile(
                    icon: Icons.photo_library_outlined,
                    label: '最近回忆',
                    value: countText(data['memories'] ??
                        data['memoryCount'] ??
                        data['recentPhotos']),
                    color: const Color(0xFF9E8B73),
                  ),
                  DashboardTile(
                    icon: Icons.shopping_bag_outlined,
                    label: '买菜进度',
                    value: shoppingDashboardRatioText(shopping),
                    color: const Color(0xFF8DAE8B),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (shopping.isNotEmpty) ...[
                DashboardShoppingCard(items: shopping),
                const SizedBox(height: 14),
              ],
              if (showMaintenance) ...[
                DashboardMaintenanceCard(
                  defaultStatus: defaultStatus,
                  openIssueCount: openIssueCount,
                ),
                const SizedBox(height: 14),
              ],
              if (partnerWishlist.isNotEmpty) ...[
                DashboardWishlistCard(
                    items: partnerWishlist, onChanged: reload),
                const SizedBox(height: 14),
              ],
              if (recentPhotos.isNotEmpty) ...[
                DashboardPhotoStrip(photos: recentPhotos),
                const SizedBox(height: 14),
              ],
              if (anniversaryMenus.isNotEmpty) ...[
                DashboardAnniversaryCard(menu: anniversaryMenus.first),
                const SizedBox(height: 14),
              ],
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                        icon: Icons.favorite_border, title: '双人互动'),
                    const SizedBox(height: 10),
                    const Text('TA 正在看你们的小家菜单，适合的菜可以一键安排进今天晚餐。'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              pushPage(context, const PhotoAlbumPage()),
                          icon: const Icon(Icons.photo_album_outlined),
                          label: const Text('饭桌相册'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              pushPage(context, const AnniversaryPage()),
                          icon: const Icon(Icons.celebration_outlined),
                          label: const Text('纪念日菜单'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              pushPage(context, const TableReviewPage()),
                          icon: const Icon(Icons.auto_graph_outlined),
                          label: const Text('饭桌回顾'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String countText(dynamic value) {
  if (value == null) {
    return '0';
  }
  if (value is num) {
    return value.toString();
  }
  if (value is List) {
    return value.length.toString();
  }
  if (value is Map) {
    for (final key in ['count', 'total', 'open', 'missing', 'length']) {
      if (value[key] != null) {
        return textOf(value[key]);
      }
    }
    return value.length.toString();
  }
  return textOf(value);
}

int dashboardMealCount(dynamic response, List<dynamic> meals) {
  final data = payload(response);
  if (data is Map) {
    final total = int.tryParse(textOf(data['total'] ?? data['count']));
    if (total != null) {
      return total;
    }
  }
  return meals.length;
}

String todayArrangementText(dynamic value) {
  final raw = textOf(value).trim();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
    return '待安排';
  }
  final map = asMap(value);
  if (map.isEmpty) {
    return countText(value);
  }
  var count = 0;
  for (final type in ['breakfast', 'lunch', 'dinner']) {
    if (mealNames(planMealValue(map, type)).isNotEmpty) {
      count++;
    }
  }
  if (count > 0) {
    return '$count 餐';
  }
  final direct = countText(map['count'] ?? map['total']);
  return direct == '0' ? '待安排' : direct;
}

Map<String, dynamic> dashboardTodaySchedule(Map<String, dynamic> data) {
  final schedule = asMap(data['todaySchedule'] ?? data['schedule']);
  if (schedule.isNotEmpty) {
    return schedule;
  }
  return asMap(data['today']);
}

List<Map<String, dynamic>> dashboardPartnerWishlist(Map<String, dynamic> data) {
  final raw = data['partnerWishlist'] ??
      data['taWishlist'] ??
      data['wishlistItems'] ??
      data['wishlist'];
  return asList(raw).map(asMap).where((item) => item.isNotEmpty).toList();
}

List<Map<String, dynamic>> dashboardRecentPhotos(Map<String, dynamic> data) {
  final raw = data['recentPhotos'] ??
      data['photos'] ??
      data['recentMemories'] ??
      data['memories'];
  return asList(raw).map((item) {
    if (item is String) {
      return {'photo': item};
    }
    return asMap(item);
  }).where((item) {
    return imageUrl(item['photo'] ?? item['url'] ?? item['src']).isNotEmpty;
  }).toList();
}

List<Map<String, dynamic>> dashboardShoppingItems(Map<String, dynamic> data) {
  final raw = data['shoppingList'] ??
      data['shoppingItems'] ??
      data['shopping'] ??
      data['shoppingListItems'];
  return shoppingItems(raw);
}

String shoppingDashboardRatioText(List<Map<String, dynamic>> items) {
  if (items.isEmpty) {
    return '待生成';
  }
  return '${shoppingPurchasedCount(items)}/${items.length}';
}

String shoppingItemPreviewText(Map<String, dynamic> item) {
  final name = friendlyText(item['name'] ?? item['title']);
  final amount = friendlyText(item['amount'] ?? item['quantity']);
  if (name.isEmpty) {
    return amount;
  }
  return amount.isEmpty ? name : '$name $amount';
}

Map<String, dynamic> dashboardDefaultMealStatus(Map<String, dynamic> data) {
  final status = asMap(
    data['defaultMeals'] ??
        data['defaultMealStatus'] ??
        data['defaultStatus'] ??
        data['defaultMeal'],
  );
  return status;
}

int intValue(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(textOf(value)) ?? 0;
}

int firstIntValue(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    if (data.containsKey(key)) {
      return intValue(data[key]);
    }
  }
  return 0;
}

int defaultMealMissingCount(Map<String, dynamic> status) {
  return firstIntValue(
    status,
    const ['missing', 'missingCount', 'notImported', 'notImportedCount'],
  );
}

int defaultMealImportedCount(Map<String, dynamic> status) {
  return firstIntValue(status, const ['imported', 'importedCount']);
}

int defaultMealTotalCount(Map<String, dynamic> status) {
  return firstIntValue(status, const ['total', 'defaultTotal', 'count']);
}

int dashboardImageIssueOpenCount(Map<String, dynamic> data) {
  final raw = data['imageIssues'] ??
      data['mealImageIssues'] ??
      data['imageIssueStatus'] ??
      data['imageIssueCount'];
  if (raw is List) {
    return raw.length;
  }
  final map = asMap(raw);
  if (map.isEmpty) {
    return intValue(raw);
  }
  final listed = imageIssues(map);
  if (listed.isNotEmpty) {
    return listed.length;
  }
  return firstIntValue(
    map,
    const ['open', 'openCount', 'pending', 'pendingCount', 'count', 'total'],
  );
}

bool dashboardNeedsMaintenance(Map<String, dynamic> data) {
  return defaultMealMissingCount(dashboardDefaultMealStatus(data)) > 0 ||
      dashboardImageIssueOpenCount(data) > 0;
}

List<Map<String, dynamic>> dashboardAnniversaryMenus(
  Map<String, dynamic> data, {
  DateTime? today,
}) {
  final raw = data['upcomingAnniversaries'] ??
      data['anniversaryMenus'] ??
      data['anniversaries'] ??
      data['menus'];
  final items = asList(raw).map(asMap).where((item) {
    return item.isNotEmpty &&
        (idOf(item).isNotEmpty || textOf(item['date']).isNotEmpty);
  }).toList();
  return anniversarySortedMenus(items, today: today);
}

class DashboardAnniversaryCard extends StatelessWidget {
  const DashboardAnniversaryCard({super.key, required this.menu});

  final Map<String, dynamic> menu;

  @override
  Widget build(BuildContext context) {
    final meals = anniversaryMenuMealNames(menu);
    final title =
        textOf(menu['title']).isEmpty ? '最近纪念日菜单' : textOf(menu['title']);
    return SoftCard(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF7E8), Color(0xFFFFD8D0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.celebration_outlined,
            title: '最近纪念日',
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: kCoffee,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoChip(
                anniversaryCountdownLabel(menu),
                icon: Icons.event_available_outlined,
              ),
              if (textOf(menu['date']).isNotEmpty)
                InfoChip(
                  textOf(menu['date']).split('T').first,
                  icon: Icons.calendar_today_outlined,
                ),
              if (textOf(menu['theme']).isNotEmpty)
                InfoChip(
                  textOf(menu['theme']),
                  icon: Icons.local_florist_outlined,
                ),
            ],
          ),
          if (meals.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meals
                  .take(5)
                  .map((item) => InfoChip(item, icon: Icons.restaurant_menu))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => pushPage(context, const AnniversaryPage()),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('准备这顿饭'),
          ),
        ],
      ),
    );
  }
}

class DashboardShoppingCard extends StatelessWidget {
  const DashboardShoppingCard({super.key, required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final remaining = shoppingRemainingItems(items);
    return SoftCard(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFBF1), Color(0xFFE6F1DC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.shopping_bag_outlined,
            title: '本周买菜',
          ),
          const SizedBox(height: 10),
          Text(
            shoppingProgressText(items),
            style: const TextStyle(
              color: kCoffee,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: shoppingProgressValue(items),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.72),
              color: context.app.themePalette.success,
            ),
          ),
          if (remaining.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: remaining
                  .take(5)
                  .map(
                    (item) => InfoChip(
                      shoppingItemPreviewText(item),
                      icon: Icons.local_grocery_store_outlined,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => pushPage(context, const ShoppingListPage()),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('去勾选采购项'),
          ),
        ],
      ),
    );
  }
}

class DashboardMaintenanceCard extends StatelessWidget {
  const DashboardMaintenanceCard({
    super.key,
    required this.defaultStatus,
    required this.openIssueCount,
  });

  final Map<String, dynamic> defaultStatus;
  final int openIssueCount;

  @override
  Widget build(BuildContext context) {
    final missing = defaultMealMissingCount(defaultStatus);
    final imported = defaultMealImportedCount(defaultStatus);
    final total = defaultMealTotalCount(defaultStatus);
    return SoftCard(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF5EC), Color(0xFFFFE1D8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.home_repair_service_outlined,
            title: '小家维护提醒',
          ),
          const SizedBox(height: 10),
          const Text(
            '把默认菜品和图片整理好，之后排餐、买菜和回忆都会更顺手。',
            style: TextStyle(color: kCocoa, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (missing > 0)
                InfoChip('缺失默认菜 $missing 道',
                    icon: Icons.restaurant_menu_outlined),
              if (openIssueCount > 0)
                InfoChip('待修正图片 $openIssueCount 张',
                    icon: Icons.report_outlined),
              if (total > 0)
                InfoChip('已导入 $imported/$total',
                    icon: Icons.check_circle_outline),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => pushPage(context, const SettingsPage()),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('去设置处理'),
          ),
        ],
      ),
    );
  }
}

String wishlistDashboardNote(Map<String, dynamic> item) {
  final note = textOf(item['note']);
  if (note.isNotEmpty) {
    return note;
  }
  return wishlistPriorityLabel(textOf(item['priority']));
}

String wishlistDashboardActionLabel(Map<String, dynamic> item) {
  return wishlistMealId(item).isEmpty ? '建谱并安排' : '今晚吃';
}

Future<void> scheduleWishlistForTodayDinner(
  BuildContext context,
  Map<String, dynamic> item,
) async {
  final wishlistId = idOf(item);
  var mealId = wishlistMealId(item);
  var mealName = wishlistMealName(item);
  if (mealName.isEmpty) {
    mealName = textOf(item['title']);
  }

  if (mealId.isEmpty) {
    mealId = await createMealFromWishlist(context, item);
    if (wishlistId.isNotEmpty) {
      await context.appRead.patch(
        '/wishlist/$wishlistId/meal',
        body: {'mealId': mealId},
      );
    }
  }

  await appendMealToTodayDinner(
    context,
    mealId: mealId,
    mealName: mealName,
  );
  if (wishlistId.isNotEmpty) {
    await context.appRead.patch(
      '/wishlist/$wishlistId/status',
      body: {'status': 'planned'},
    );
  }
}

class DashboardWishlistCard extends StatelessWidget {
  const DashboardWishlistCard({
    super.key,
    required this.items,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> items;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(3).toList();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: Icons.favorite_border, title: 'TA 想吃提醒'),
          const SizedBox(height: 10),
          ...visibleItems.map((item) {
            final title = wishlistMealName(item).isEmpty
                ? textOf(item['title'])
                : wishlistMealName(item);
            final note = wishlistDashboardNote(item);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: kPeach.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.restaurant, color: kCoral),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isEmpty ? '想吃一顿小家饭' : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        if (note.isNotEmpty)
                          Text(
                            note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: kCocoa),
                          ),
                      ],
                    ),
                  ),
                  if (!wishlistIsDone(item))
                    TextButton(
                      onPressed: () async {
                        try {
                          await scheduleWishlistForTodayDinner(context, item);
                          onChanged();
                        } catch (error) {
                          if (context.mounted) {
                            showMessage(context, errorText(error));
                          }
                        }
                      },
                      child: Text(wishlistDashboardActionLabel(item)),
                    ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => pushPage(context, const WishlistPage()),
              icon: const Icon(Icons.arrow_forward),
              label:
                  Text(items.length > 3 ? '查看全部 ${items.length} 项' : '查看想吃清单'),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardPhotoStrip extends StatelessWidget {
  const DashboardPhotoStrip({super.key, required this.photos});

  final List<Map<String, dynamic>> photos;

  @override
  Widget build(BuildContext context) {
    final visiblePhotos = photos.take(5).toList();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
              icon: Icons.photo_library_outlined, title: '最近饭桌照片'),
          const SizedBox(height: 12),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visiblePhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final photo = visiblePhotos[index];
                final url =
                    imageUrl(photo['photo'] ?? photo['url'] ?? photo['src']);
                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => pushPage(context, const PhotoAlbumPage()),
                  child: SizedBox(
                    width: 136,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RemoteImage(url: url),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              color: kCoffee.withValues(alpha: 0.58),
                              child: Text(
                                textOf(photo['title']).isEmpty
                                    ? textOf(photo['date'])
                                    : textOf(photo['title']),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => pushPage(context, const PhotoAlbumPage()),
            icon: const Icon(Icons.collections_outlined),
            label: const Text('打开饭桌相册'),
          ),
        ],
      ),
    );
  }
}

class TodayScheduleCard extends StatelessWidget {
  const TodayScheduleCard({
    super.key,
    required this.date,
    required this.schedule,
    required this.onChanged,
  });

  final DateTime date;
  final Map<String, dynamic> schedule;
  final VoidCallback onChanged;

  bool get hasMeals =>
      mealNames(planMealValue(schedule, 'breakfast')).isNotEmpty ||
      mealNames(planMealValue(schedule, 'lunch')).isNotEmpty ||
      mealNames(planMealValue(schedule, 'dinner')).isNotEmpty;

  List<String> get recordableMealTypes => scheduleMealTypesWithMeals(schedule);

  Future<void> openSchedule(BuildContext context) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ScheduleSheet(date: date, schedule: schedule),
    );
    if (changed == true) {
      onChanged();
    }
  }

  Future<void> recordMemory(BuildContext context, String type) async {
    final mealIds = scheduleMealIdsFor(schedule, type);
    if (mealIds.isEmpty) {
      showMessage(context, '这餐还没有安排菜品');
      return;
    }
    final changed = await pushPage(
      context,
      MemoryEditPage(
        initialDate: dateString(date),
        initialMealType: type,
        initialMealIds: mealIds,
        initialTitle: scheduleMemoryTitle(type),
      ),
    );
    if (changed == true && context.mounted) {
      showMessage(context, '已记录${mealTypeLabel(type)}回忆');
      onChanged();
    }
  }

  Future<void> addToShoppingList(BuildContext context) async {
    try {
      await addScheduleIngredientsToShoppingList(context, schedule);
    } catch (error) {
      if (context.mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordTypes = recordableMealTypes;
    final balanceHints = scheduleBalanceHints(schedule);
    return SoftCard(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFCF7), Color(0xFFFFEFE7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kPeach.withValues(alpha: 0.36),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.favorite, color: kCoral),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日饭桌',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${dateString(date)} · ${weekdayLabel(date.weekday)}',
                      style: const TextStyle(
                        color: kCocoa,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => openSchedule(context),
                icon: const Icon(Icons.edit_calendar_outlined),
                label: Text(hasMeals ? '调整' : '安排'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MealBadges(title: '早', value: planMealValue(schedule, 'breakfast')),
          MealBadges(title: '午', value: planMealValue(schedule, 'lunch')),
          MealBadges(title: '晚', value: planMealValue(schedule, 'dinner')),
          if (balanceHints.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: balanceHints
                  .take(3)
                  .map((hint) => InfoChip(hint, icon: Icons.eco_outlined))
                  .toList(),
            ),
          ],
          if (!hasMeals) ...[
            const SizedBox(height: 6),
            const Text(
              '今天还没有安排，先给两个人定一餐喜欢的。',
              style: TextStyle(color: kCocoa, fontWeight: FontWeight.w700),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => addToShoppingList(context),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('加入购物清单'),
                ),
                ...recordTypes.map(
                  (type) => OutlinedButton.icon(
                    onPressed: () => recordMemory(context, type),
                    icon: const Icon(Icons.auto_stories_outlined),
                    label: Text('记录${mealTypeLabel(type)}'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardTile extends StatelessWidget {
  const DashboardTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width > 640
          ? 156
          : (MediaQuery.sizeOf(context).width - 44) / 2,
      child: SoftCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.17),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900, color: kCoffee)),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: kCocoa,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<dynamic> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<dynamic> load() => context.appRead.get('/schedules', query: {
        'year': month.year.toString(),
        'month': month.month.toString(),
      });

  void reload() => setState(() {
        future = load();
      });

  void changeMonth(int delta) {
    setState(() {
      month = DateTime(month.year, month.month + delta);
      future = load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingList();
        }
        if (snapshot.hasError) {
          return ErrorState(
              message: errorText(snapshot.error!), onRetry: reload);
        }
        final schedules = scheduleMap(payload(snapshot.data));
        final days = DateUtils.getDaysInMonth(month.year, month.month);
        final today = DateTime.now();
        final isCurrentMonth =
            month.year == today.year && month.month == today.month;
        return RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              SoftCard(
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () => changeMonth(-1),
                        icon: const Icon(Icons.chevron_left)),
                    Expanded(
                      child: Text(
                        '${month.year} 年 ${month.month} 月',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                        onPressed: () => changeMonth(1),
                        icon: const Icon(Icons.chevron_right)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (isCurrentMonth) ...[
                TodayScheduleCard(
                  date: today,
                  schedule:
                      schedules[dateString(today)] ?? const <String, dynamic>{},
                  onChanged: reload,
                ),
                const SizedBox(height: 12),
              ],
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
                  mainAxisExtent: 232,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: days,
                itemBuilder: (context, index) {
                  final date = DateTime(month.year, month.month, index + 1);
                  return DayCard(
                    date: date,
                    schedule: schedules[dateString(date)] ?? const {},
                    onChanged: reload,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Map<String, Map<String, dynamic>> scheduleMap(dynamic value) {
  final data = payload(value);
  final result = <String, Map<String, dynamic>>{};
  if (data is Map) {
    final list = asList(data['schedules'] ?? data['items'] ?? data['list']);
    if (list.isNotEmpty) {
      for (final item in list) {
        final map = asMap(item);
        final date = textOf(map['date']);
        if (date.isNotEmpty) {
          result[date.substring(0, date.length >= 10 ? 10 : date.length)] = map;
        }
      }
      return result;
    }
    for (final entry in data.entries) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(entry.key.toString())) {
        result[entry.key.toString().substring(0, 10)] = asMap(entry.value);
      }
    }
  }
  if (data is List) {
    for (final item in data) {
      final map = asMap(item);
      final date = textOf(map['date']);
      if (date.isNotEmpty) {
        result[date.substring(0, date.length >= 10 ? 10 : date.length)] = map;
      }
    }
  }
  return result;
}

class DayCard extends StatelessWidget {
  const DayCard({
    super.key,
    required this.date,
    required this.schedule,
    required this.onChanged,
  });

  final DateTime date;
  final Map<String, dynamic> schedule;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final today = dateString(date) == dateString(DateTime.now());
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        final changed = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (_) => ScheduleSheet(date: date, schedule: schedule),
        );
        if (changed == true) {
          onChanged();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(13, 9, 13, 11),
        decoration: BoxDecoration(
          color: today ? const Color(0xFFFFF1EA) : kPaper,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: today ? kCoral : Colors.white.withValues(alpha: 0.9),
              width: today ? 1.8 : 1),
          boxShadow: [
            BoxShadow(
              color: kCaramel.withValues(alpha: today ? 0.20 : 0.12),
              blurRadius: today ? 24 : 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 10,
                decoration: BoxDecoration(
                  color: (today ? kCoral : kCaramel).withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900, color: kCoffee),
                ),
                const SizedBox(width: 6),
                Text(
                  weekdayLabel(date.weekday),
                  style: const TextStyle(
                    color: kCocoa,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (today)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: kPeach.withValues(alpha: 0.38),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, color: kCoral, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            MealBadges(title: '早', value: planMealValue(schedule, 'breakfast')),
            MealBadges(title: '午', value: planMealValue(schedule, 'lunch')),
            MealBadges(title: '晚', value: planMealValue(schedule, 'dinner')),
            const Spacer(),
            const Align(
              alignment: Alignment.bottomRight,
              child:
                  Icon(Icons.edit_calendar_outlined, size: 18, color: kCaramel),
            ),
          ],
        ),
      ),
    );
  }
}

class MealBadges extends StatelessWidget {
  const MealBadges({super.key, required this.title, required this.value});

  final String title;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final names = mealNames(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: names.isEmpty
              ? Colors.white.withValues(alpha: 0.56)
              : kPeach.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: kLine.withValues(alpha: 0.76)),
        ),
        child: Row(
          children: [
            Icon(
              mealIcon(title),
              size: 14,
              color: names.isEmpty ? const Color(0xFFBCA79B) : kCaramel,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: kCocoa,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                names.isEmpty ? '待定' : names.take(2).join('、'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: names.isEmpty ? const Color(0xFF9E8D83) : kCoffee,
                  fontWeight: names.isEmpty ? FontWeight.w600 : FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String weekdayLabel(int weekday) {
  const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return labels[(weekday - 1).clamp(0, 6)];
}

IconData mealIcon(String title) {
  switch (title) {
    case '早':
      return Icons.wb_twilight_outlined;
    case '午':
      return Icons.wb_sunny_outlined;
    default:
      return Icons.nights_stay_outlined;
  }
}

List<String> mealNames(dynamic value) {
  final result = <String>[];
  final list = value is Map
      ? asList(value['meals'] ?? value['mealIds'] ?? value['items'])
      : asList(value);
  for (final item in list) {
    if (item is String) {
      result.add(item);
    } else {
      final map = asMap(item);
      final nestedMeal = asMap(map['meal']);
      result.add(textOf(map['name'] ??
          map['title'] ??
          nestedMeal['name'] ??
          nestedMeal['title']));
    }
  }
  return result.where((item) => item.isNotEmpty).toList();
}

List<String> mealIdsFromPlanValue(dynamic value) {
  final result = <String>[];
  final list = value is Map
      ? asList(value['meals'] ?? value['mealIds'] ?? value['items'])
      : asList(value);
  for (final item in list) {
    final id = planItemMealId(item);
    if (id.isNotEmpty && !result.contains(id)) {
      result.add(id);
    }
  }
  return result;
}

List<String> scheduleMealIdsFor(Map<String, dynamic> schedule, String type) {
  return mealIdsFromPlanValue(planMealValue(schedule, type));
}

List<String> scheduleMealTypesWithMeals(Map<String, dynamic> schedule) {
  return mealTypes
      .where((type) => scheduleMealIdsFor(schedule, type).isNotEmpty)
      .toList();
}

List<String> scheduleMealTagTexts(Map<String, dynamic> schedule) {
  final values = <String>[];
  for (final type in mealTypes) {
    final items = planMealValue(schedule, type);
    final list = items is Map
        ? asList(items['meals'] ?? items['mealIds'] ?? items['items'])
        : asList(items);
    for (final item in list) {
      final map = asMap(item);
      final meal = asMap(map['meal']);
      final source = meal.isNotEmpty ? meal : map;
      for (final key in ['healthTags', 'tags', 'flavors', 'tasteTags']) {
        values.addAll(asList(source[key]).map(friendlyText));
      }
      for (final key in ['taste', 'category', 'subcategory']) {
        values.add(friendlyText(source[key]));
      }
    }
  }
  return values.where((item) => item.isNotEmpty).toSet().toList();
}

bool textContainsAny(String text, List<String> needles) {
  return needles.any(text.contains);
}

List<String> scheduleBalanceHints(Map<String, dynamic> schedule) {
  final hints = <String>[...planHints(schedule)];
  final arrangedTypes = scheduleMealTypesWithMeals(schedule);
  final tags = scheduleMealTagTexts(schedule);
  if (arrangedTypes.length >= 2 && tags.isNotEmpty) {
    final hasVegetable = tags.any(
      (tag) => textContainsAny(tag, const ['蔬菜', '青菜', '素', '清淡', '少油', '高纤']),
    );
    final hasProtein = tags.any(
      (tag) => textContainsAny(
          tag, const ['高蛋白', '肉', '鸡', '牛', '鱼', '蛋', '虾', '豆']),
    );
    final heavyCount = tags
        .where(
          (tag) =>
              textContainsAny(tag, const ['重口', '下饭', '香辣', '麻辣', '油炸', '红烧']),
        )
        .length;
    if (!hasVegetable) {
      hints.add('今天蔬菜偏少，补一份青菜更舒服');
    }
    if (heavyCount >= 2) {
      hints.add('重口菜偏多，搭配清淡汤水');
    }
    if (!hasProtein) {
      hints.add('蛋白质偏少，可以加蛋或豆制品');
    }
  }
  return hints
      .map(friendlyText)
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
}

Future<void> appendMealToTodayDinner(
  BuildContext context, {
  required String mealId,
  String mealName = '',
}) async {
  if (mealId.trim().isEmpty) {
    showMessage(context, '这个想吃项还没有关联菜品，先把它建成菜谱再安排。');
    return;
  }
  final app = context.appRead;
  final today = dateString(DateTime.now());
  final response = await app.get('/schedules/day/$today');
  final schedule = asMap(payload(response));
  final dinnerIds = mealIdsFromPlanValue(planMealValue(schedule, 'dinner'));
  if (!dinnerIds.contains(mealId)) {
    dinnerIds.add(mealId);
  }
  await app.put('/schedules/$today/dinner', body: {
    'mealIds': dinnerIds,
  });
  if (context.mounted) {
    final name = mealName.trim();
    showMessage(context, name.isEmpty ? '已安排到今天晚餐' : '今晚就吃「$name」');
  }
}

List<Map<String, String>> shoppingItemsFromIngredients(dynamic ingredients) {
  final merged = <String, Map<String, String>>{};
  for (final item in asList(ingredients)) {
    final map = asMap(item);
    final parsed = _parseIngredient(item, map);
    final name = parsed.$1;
    if (name.isEmpty) {
      continue;
    }
    final amount = parsed.$2;
    final category = shoppingCategoryFor(name);
    final key = _shoppingItemKey(name, category);
    final current = merged[key];
    if (current == null) {
      merged[key] = {
        'name': name,
        'amount': amount,
        'category': category,
      };
      continue;
    }
    if (amount.isNotEmpty) {
      final previous = current['amount'] ?? '';
      current['amount'] = previous.isEmpty ? amount : '$previous、$amount';
    }
  }
  return merged.values.toList();
}

(String, String) _parseIngredient(dynamic item, Map<String, dynamic> map) {
  var name = textOf(
    map['name'] ??
        map['title'] ??
        map['ingredient'] ??
        map['ingredientName'] ??
        item,
  ).trim();
  var amount = textOf(map['amount']).trim();
  if (amount.isEmpty) {
    final quantity = textOf(map['quantity']).trim();
    final unit = textOf(map['unit']).trim();
    amount = quantity.isEmpty ? unit : '$quantity$unit';
  }
  if (map.isEmpty && item is String) {
    final parts = item.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      name = parts.first.trim();
      amount = parts.sublist(1).join(' ').trim();
    }
  }
  return (name, amount);
}

String shoppingCategoryFor(String value) {
  final name = value.trim();
  if (name.isEmpty) {
    return 'other';
  }
  bool containsAny(List<String> words) => words.any(name.contains);
  if (containsAny(
      ['米', '面粉', '面条', '饼', '馒头', '包子', '粥', '年糕', '粉丝', '粉条', '玉米', '红薯'])) {
    return 'staple';
  }
  if (containsAny([
    '盐',
    '糖',
    '醋',
    '酱',
    '料酒',
    '葱',
    '姜',
    '蒜',
    '辣椒',
    '花椒',
    '孜然',
    '八角',
    '香油',
    '蚝油',
    '生抽',
    '老抽',
    '鸡精',
    '味精',
    '胡椒',
    '淀粉'
  ])) {
    return 'seasoning';
  }
  if (containsAny([
    '鸡',
    '鸭',
    '鱼',
    '虾',
    '牛',
    '羊',
    '猪',
    '肉',
    '蛋',
    '排骨',
    '里脊',
    '火腿',
    '培根',
    '丸',
    '肠'
  ])) {
    return 'meat_egg';
  }
  if (containsAny([
    '菜',
    '豆角',
    '黄瓜',
    '番茄',
    '西红柿',
    '青椒',
    '白菜',
    '菠菜',
    '生菜',
    '油麦',
    '西兰花',
    '萝卜',
    '茄子',
    '芹菜',
    '韭菜',
    '蘑菇',
    '木耳',
    '藕',
    '土豆',
    '洋葱',
    '豆腐'
  ])) {
    return 'vegetable';
  }
  return 'other';
}

Future<void> addMealIngredientsToShoppingList(
  BuildContext context,
  Map<String, dynamic> meal,
) async {
  final items = shoppingItemsFromIngredients(meal['ingredients']);
  if (items.isEmpty) {
    showMessage(context, '这道菜还没有食材，先在菜谱里补充食材。');
    return;
  }
  final app = context.appRead;
  final weekStart = dateString(mondayOf(DateTime.now()));
  final existingResponse =
      await app.get('/shopping-list', query: {'weekStart': weekStart});
  final existingKeys = shoppingItems(existingResponse)
      .map((item) =>
          _shoppingItemKey(textOf(item['name']), textOf(item['category'])))
      .toSet();

  var added = 0;
  for (final item in items) {
    final name = item['name'] ?? '';
    final category = item['category'] ?? 'other';
    final key = _shoppingItemKey(name, category);
    if (existingKeys.contains(key)) {
      continue;
    }
    await app.post('/shopping-list/items', body: {
      'weekStart': weekStart,
      'name': name,
      'amount': item['amount'] ?? '',
      'category': category,
    });
    existingKeys.add(key);
    added += 1;
  }

  if (context.mounted) {
    showMessage(
      context,
      added == 0 ? '这些食材已经在本周购物清单里' : '已加入本周购物清单（$added 项）',
    );
  }
}

List<Map<String, dynamic>> scheduleMealObjects(Map<String, dynamic> schedule) {
  final mealsById = <String, Map<String, dynamic>>{};
  for (final type in mealTypes) {
    final items = planMealValue(schedule, type);
    final list = items is Map
        ? asList(items['meals'] ?? items['mealIds'] ?? items['items'])
        : asList(items);
    for (final item in list) {
      final map = asMap(item);
      final nestedMeal = asMap(map['meal']);
      final meal = nestedMeal.isNotEmpty ? nestedMeal : map;
      final id = planItemMealId(item);
      if (id.isEmpty) {
        continue;
      }
      mealsById[id] = {
        ...meal,
        if (idOf(meal).isEmpty) '_id': id,
      };
    }
  }
  return mealsById.values.toList();
}

Future<void> addScheduleIngredientsToShoppingList(
  BuildContext context,
  Map<String, dynamic> schedule, {
  String emptyMessage = '今天还没有安排菜品，先安排一餐再生成采购项。',
  String noIngredientsMessage = '今日菜品还没有食材，先在菜谱里补充食材。',
  String allExistingMessage = '今日食材已经在本周购物清单里',
  String Function(int count)? addedMessageBuilder,
}) async {
  final scheduledMeals = scheduleMealObjects(schedule);
  final mealIds = scheduleMealIds(schedule);
  if (mealIds.isEmpty) {
    showMessage(context, emptyMessage);
    return;
  }

  final app = context.appRead;
  final weekStart = dateString(mondayOf(DateTime.now()));
  final existingResponse =
      await app.get('/shopping-list', query: {'weekStart': weekStart});
  final existingKeys = shoppingItems(existingResponse)
      .map((item) =>
          _shoppingItemKey(textOf(item['name']), textOf(item['category'])))
      .toSet();
  final mealsById = {
    for (final meal in scheduledMeals)
      if (idOf(meal).isNotEmpty) idOf(meal): meal,
  };

  var added = 0;
  var mealsWithIngredients = 0;
  for (final mealId in mealIds) {
    var meal = mealsById[mealId] ?? <String, dynamic>{};
    var items = shoppingItemsFromIngredients(meal['ingredients']);
    if (items.isEmpty) {
      final response = await app.get('/meals/$mealId');
      meal = asMap(payload(response));
      items = shoppingItemsFromIngredients(meal['ingredients']);
    }
    if (items.isEmpty) {
      continue;
    }
    mealsWithIngredients += 1;
    for (final item in items) {
      final name = item['name'] ?? '';
      final category = item['category'] ?? 'other';
      final key = _shoppingItemKey(name, category);
      if (existingKeys.contains(key)) {
        continue;
      }
      await app.post('/shopping-list/items', body: {
        'weekStart': weekStart,
        'name': name,
        'amount': item['amount'] ?? '',
        'category': category,
      });
      existingKeys.add(key);
      added += 1;
    }
  }

  if (context.mounted) {
    if (mealsWithIngredients == 0) {
      showMessage(context, noIngredientsMessage);
    } else {
      showMessage(
        context,
        added == 0
            ? allExistingMessage
            : addedMessageBuilder?.call(added) ?? '已加入本周购物清单（$added 项）',
      );
    }
  }
}

List<String> scheduleMealIds(Map<String, dynamic> schedule) {
  final ids = <String>[];
  for (final type in mealTypes) {
    for (final id in scheduleMealIdsFor(schedule, type)) {
      if (!ids.contains(id)) {
        ids.add(id);
      }
    }
  }
  return ids;
}

String _shoppingItemKey(String name, String category) =>
    '${category.trim()}|${name.trim().toLowerCase()}';

class ScheduleSheet extends StatefulWidget {
  const ScheduleSheet({
    super.key,
    required this.date,
    required this.schedule,
  });

  final DateTime date;
  final Map<String, dynamic> schedule;

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  String mealType = 'dinner';
  final selected = <String>{};
  final searchController = TextEditingController();
  String searchText = '';
  String category = '全部';
  late Future<dynamic> mealsFuture;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadSelectedForMealType(mealType);
    mealsFuture = loadMeals();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<String> categoriesFor(List<dynamic> meals) {
    final result = <String>{'全部'};
    for (final item in meals) {
      final meal = asMap(item);
      final value = textOf(meal['category']).trim();
      if (value.isNotEmpty) {
        result.add(value);
      }
    }
    return result.toList();
  }

  List<dynamic> visibleMeals(List<dynamic> meals) {
    final query = searchText.trim().toLowerCase();
    return meals.where((item) {
      final meal = asMap(item);
      final mealCategory = textOf(meal['category']).trim();
      final subcategory = textOf(meal['subcategory']).trim();
      final categoryMatched = category == '全部' ||
          mealCategory == category ||
          subcategory == category;
      if (!categoryMatched) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final ingredients = asList(meal['ingredients']).map((item) {
        final ingredient = asMap(item);
        return textOf(ingredient['name'] ?? item);
      }).join(' ');
      final steps = asList(meal['steps']).map((item) {
        final step = asMap(item);
        return textOf(step['description'] ?? item);
      }).join(' ');
      final searchable = [
        meal['name'],
        meal['description'],
        meal['category'],
        meal['subcategory'],
        asList(meal['tags']).map(textOf).join(' '),
        asList(meal['healthTags']).map(textOf).join(' '),
        ingredients,
        steps,
      ].map(textOf).join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  void loadSelectedForMealType(String type) {
    selected
      ..clear()
      ..addAll(scheduleMealIdsFor(widget.schedule, type));
  }

  Future<dynamic> loadMeals() {
    final query = searchController.text.trim();
    return context.appRead.get('/meals', query: {
      'limit': '200',
      if (query.isNotEmpty) 'search': query,
    });
  }

  void reloadMeals() {
    setState(() {
      mealsFuture = loadMeals();
    });
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await context.appRead
          .put('/schedules/${dateString(widget.date)}/$mealType', body: {
        'mealIds': selected.toList(),
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: FutureBuilder<dynamic>(
          future: mealsFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final hasError = snapshot.hasError;
            final meals = snapshot.hasData
                ? mealListFrom(snapshot.data)
                : const <dynamic>[];
            final categories = categoriesFor(meals);
            final filteredMeals = visibleMeals(meals);
            if (!categories.contains(category)) {
              category = '全部';
            }
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.84,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${dateString(widget.date)} 安排一餐',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'breakfast',
                          label: Text('早餐'),
                          icon: Icon(Icons.wb_twilight)),
                      ButtonSegment(
                          value: 'lunch',
                          label: Text('午餐'),
                          icon: Icon(Icons.wb_sunny_outlined)),
                      ButtonSegment(
                          value: 'dinner',
                          label: Text('晚餐'),
                          icon: Icon(Icons.nightlight_outlined)),
                    ],
                    selected: {mealType},
                    onSelectionChanged: (value) => setState(() {
                      mealType = value.first;
                      loadSelectedForMealType(mealType);
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => setState(() => searchText = value),
                    onSubmitted: (_) => reloadMeals(),
                    decoration: InputDecoration(
                      hintText: '搜索菜名、分类、食材或做法',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (searchText.isNotEmpty)
                            IconButton(
                              tooltip: '清空',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  searchController.clear();
                                  searchText = '';
                                  category = '全部';
                                });
                                reloadMeals();
                              },
                            ),
                          IconButton(
                            tooltip: '搜索菜品',
                            icon: const Icon(Icons.manage_search),
                            onPressed: reloadMeals,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = categories[index];
                        return ChoiceChip(
                          label: Text(item),
                          selected: category == item,
                          onSelected: (_) => setState(() => category = item),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLoading
                        ? '正在加载菜品目录...'
                        : hasError
                            ? '菜品目录加载失败'
                            : filteredMeals.isEmpty
                                ? '没有匹配的菜品'
                                : '可选菜品 ${filteredMeals.length} 个，已选 ${selected.length} 个',
                    style: const TextStyle(
                      color: kCocoa,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (hasError)
                    Expanded(
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: reloadMeals,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重新加载菜品目录'),
                        ),
                      ),
                    )
                  else if (filteredMeals.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          '换个关键词，或者切回“全部”目录试试',
                          style: TextStyle(
                            color: kCocoa,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredMeals.length,
                        itemBuilder: (context, index) {
                          final meal = asMap(filteredMeals[index]);
                          final id = idOf(meal);
                          return CheckboxListTile(
                            value: selected.contains(id),
                            title: Text(textOf(meal['name'])),
                            subtitle: Text(textOf(meal['category'])),
                            onChanged: (_) => setState(() {
                              if (selected.contains(id)) {
                                selected.remove(id);
                              } else {
                                selected.add(id);
                              }
                            }),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: const Icon(Icons.check),
                    label: Text(saving ? '保存中...' : '保存安排'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class MealListPage extends StatefulWidget {
  const MealListPage({super.key});

  @override
  State<MealListPage> createState() => _MealListPageState();
}

class _MealListPageState extends State<MealListPage> {
  final searchController = TextEditingController();
  late Future<dynamic> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<dynamic> load() => context.appRead.get('/meals', query: {
        'search': searchController.text,
        'limit': '200',
      });

  void reload() => setState(() {
        future = load();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SoftCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(icon: Icons.menu_book, title: '私房菜谱本'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    onSubmitted: (_) => reload(),
                    decoration: InputDecoration(
                      hintText: '搜索菜名、食材、做法...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: '筛选 / 刷新',
                        icon: const Icon(Icons.tune),
                        onPressed: reload,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TapedLabel(text: '默认菜谱', icon: Icons.bookmark),
                      TapedLabel(text: '照片优先', icon: Icons.image),
                      TapedLabel(text: '投喂给 TA', icon: Icons.favorite),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<dynamic>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingList();
                }
                if (snapshot.hasError) {
                  return ErrorState(
                      message: errorText(snapshot.error!), onRetry: reload);
                }
                final meals = mealListFrom(snapshot.data);
                if (meals.isEmpty) {
                  return EmptyState(
                    title: '还没有菜品',
                    action: '新增第一道菜',
                    onPressed: () async {
                      final changed =
                          await pushPage(context, const MealEditPage());
                      if (changed == true) {
                        reload();
                      }
                    },
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => reload(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.sizeOf(context).width > 760 ? 3 : 1,
                      mainAxisExtent:
                          MediaQuery.sizeOf(context).width > 760 ? 390 : 520,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      return MealCard(
                        meal: asMap(meals[index]),
                        onChanged: reload,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '新增菜谱',
        onPressed: () async {
          final changed = await pushPage(context, const MealEditPage());
          if (changed == true) {
            reload();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

List<dynamic> mealListFrom(dynamic response) {
  final data = payload(response);
  if (data is Map) {
    return asList(
        data['meals'] ?? data['items'] ?? data['list'] ?? data['data']);
  }
  return asList(data);
}

bool mealIsFavorite(Map<String, dynamic> meal) =>
    meal['favorite'] == true ||
    textOf(meal['favorite']).toLowerCase() == 'true';

Map<String, String> mealFavoriteUpdateFields(
  Map<String, dynamic> meal, {
  required bool favorite,
}) =>
    {
      'name': textOf(meal['name']),
      'favorite': favorite.toString(),
    };

double mealRatingValue(dynamic value, {double fallback = 0}) {
  final parsed = double.tryParse(textOf(value));
  final rating = parsed ?? fallback;
  if (rating < 0) {
    return 0;
  }
  if (rating > 5) {
    return 5;
  }
  return rating;
}

Map<String, String> mealRatingUpdateFields(
  Map<String, dynamic> meal, {
  required double rating,
}) =>
    {
      'name': textOf(meal['name']),
      'rating': mealRatingValue(rating).toStringAsFixed(1),
    };

Future<void> toggleMealFavorite(
  BuildContext context,
  Map<String, dynamic> meal, {
  VoidCallback? onChanged,
}) async {
  final id = idOf(meal);
  if (id.isEmpty) {
    showMessage(context, '没有找到这道菜');
    return;
  }
  if (textOf(meal['name']).isEmpty) {
    showMessage(context, '菜品名称为空，先补全名称再收藏');
    return;
  }
  final nextFavorite = !mealIsFavorite(meal);
  try {
    await context.appRead.multipart(
      'PUT',
      '/meals/$id',
      fields: mealFavoriteUpdateFields(meal, favorite: nextFavorite),
    );
    if (context.mounted) {
      showMessage(context, nextFavorite ? '已收藏到小家常吃' : '已取消收藏');
      onChanged?.call();
    }
  } catch (error) {
    if (context.mounted) {
      showMessage(context, errorText(error));
    }
  }
}

String mealDeleteConfirmMessage(Map<String, dynamic> meal) {
  final name = textOf(meal['name']);
  final target = name.isEmpty ? '这道菜' : '「$name」';
  return '确定删除$target吗？日历和饭后回忆里已经关联的历史记录不会自动清理。';
}

Future<double?> mealRatingDialog(
  BuildContext context, {
  required double initialRating,
}) {
  var selected = mealRatingValue(initialRating, fallback: 4);
  if (selected < 1) {
    selected = 4;
  }
  return showModalBottomSheet<double>(
    context: context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: kLine,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle(icon: Icons.star_rounded, title: '调整这道菜的评分'),
              const SizedBox(height: 14),
              Center(
                child: Wrap(
                  spacing: 6,
                  children: List.generate(5, (index) {
                    final value = index + 1.0;
                    final active = selected >= value;
                    return IconButton(
                      onPressed: () => setSheetState(() => selected = value),
                      icon: Icon(
                        active ? Icons.star_rounded : Icons.star_border_rounded,
                        color: active ? const Color(0xFFFFB23F) : kCocoa,
                        size: 34,
                      ),
                    );
                  }),
                ),
              ),
              Slider(
                value: selected,
                min: 1,
                max: 5,
                divisions: 8,
                label: selected.toStringAsFixed(1),
                onChanged: (value) => setSheetState(() => selected = value),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, selected),
                icon: const Icon(Icons.save_outlined),
                label: Text('保存 ${selected.toStringAsFixed(1)} 分'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.onChanged,
  });

  final Map<String, dynamic> meal;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final id = idOf(meal);
    final favorite = mealIsFavorite(meal);
    final image =
        imageUrl(meal['image'] ?? meal['coverImage'] ?? meal['imageUrl']);
    final tags = asList(meal['tags'])
        .map(textOf)
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList();
    final health = asList(meal['healthTags'])
        .map(textOf)
        .where((item) => item.isNotEmpty)
        .take(2)
        .toList();
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () async {
        await pushPage(context, MealDetailPage(mealId: id));
        onChanged();
      },
      child: HoverLift(
        child: SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(30)),
                    child: SizedBox(
                      height:
                          MediaQuery.sizeOf(context).width > 760 ? 178 : 230,
                      width: double.infinity,
                      child: RemoteImage(url: image),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: kCoffee.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        textOf(meal['isDefault']) == 'true' ||
                                meal['default'] == true
                            ? '默认菜谱'
                            : '小家菜谱',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 20,
                    child: Container(
                      width: 46,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            textOf(meal['name']).isEmpty
                                ? '未命名菜品'
                                : textOf(meal['name']),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: kCoffee,
                                  height: 1.08,
                                ),
                          ),
                        ),
                        _RoundIconButton(
                          tooltip: favorite ? '取消收藏' : '收藏',
                          icon: favorite
                              ? Icons.favorite
                              : Icons.favorite_border_outlined,
                          color: kCoral,
                          onPressed: () => toggleMealFavorite(
                            context,
                            meal,
                            onChanged: onChanged,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _RoundIconButton(
                          tooltip: '图片不对',
                          icon: Icons.report_gmailerrorred_outlined,
                          color: kCocoa,
                          onPressed: () => reportImageIssue(context, id),
                        ),
                        const SizedBox(width: 6),
                        _RoundIconButton(
                          tooltip: '编辑',
                          icon: Icons.edit_outlined,
                          color: kCoral,
                          onPressed: () async {
                            final changed = await pushPage(
                                context, MealEditPage(mealId: id));
                            if (changed == true) {
                              onChanged();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      textOf(meal['description']).isEmpty
                          ? '还没有写简介。'
                          : textOf(meal['description']),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kCocoa,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        InfoChip(
                          '${textOf(meal['cookTime']).isEmpty ? '30' : textOf(meal['cookTime'])} 分钟',
                          icon: Icons.timer_outlined,
                        ),
                        InfoChip(
                          difficultyLabel(meal['difficulty']),
                          icon: Icons.local_fire_department_outlined,
                        ),
                        InfoChip(
                          '${textOf(meal['rating']).isEmpty ? '0' : textOf(meal['rating'])} 分',
                          icon: Icons.star_rounded,
                        ),
                        ...tags.map(InfoChip.new),
                        ...health.map(
                            (item) => InfoChip(item, icon: Icons.eco_outlined)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> reportImageIssue(BuildContext context, String mealId) async {
  if (mealId.trim().isEmpty) {
    showMessage(context, '这个菜品缺少 ID，暂时无法记录图片问题');
    return;
  }
  final issue = await imageIssueDialog(context);
  if (issue == null) {
    return;
  }
  try {
    await context.appRead.post('/meal-image-issues', body: {
      'mealId': mealId,
      'issueType': issue['issueType'] ?? 'mismatch',
      'note': issue['note'] ?? '',
    });
    if (context.mounted) {
      showMessage(context, '已记录图片纠错');
    }
  } catch (error) {
    if (context.mounted) {
      showMessage(context, errorText(error));
    }
  }
}

const imageIssueReasons = <Map<String, String>>[
  {'type': 'mismatch', 'label': '菜名不匹配'},
  {'type': 'non_food', 'label': '不是菜品照片'},
  {'type': 'low_quality', 'label': '图片模糊或太暗'},
  {'type': 'missing', 'label': '没有展示成品'},
  {'type': 'duplicate', 'label': '重复或相似图片'},
];

String imageIssueTypeLabel(String type) {
  final normalized = type.trim();
  for (final reason in imageIssueReasons) {
    if (reason['type'] == normalized) {
      return reason['label']!;
    }
  }
  return normalized.isEmpty ? '图片与菜品不匹配' : friendlyText(normalized);
}

String imageIssueDraftNote({
  required String issueType,
  String note = '',
}) {
  final label = imageIssueTypeLabel(issueType);
  final content = note.trim();
  return content.isEmpty ? label : '$label：$content';
}

Future<Map<String, String>?> imageIssueDialog(BuildContext context) async {
  final noteController = TextEditingController();
  var issueType = 'mismatch';
  try {
    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('图片不对'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '先选一个原因，后续整理默认菜品图片时会优先处理。',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: imageIssueReasons.map((reason) {
                    final type = reason['type']!;
                    return ChoiceChip(
                      label: Text(reason['label']!),
                      selected: issueType == type,
                      onSelected: (_) => setState(() => issueType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '比如：图片像甜品，不像番茄牛腩',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'issueType': issueType,
                'note': imageIssueDraftNote(
                  issueType: issueType,
                  note: noteController.text,
                ),
              }),
              child: const Text('提交纠错'),
            ),
          ],
        ),
      ),
    );
  } finally {
    noteController.dispose();
  }
}

class MealDetailPage extends StatefulWidget {
  const MealDetailPage({super.key, required this.mealId});

  final String mealId;

  @override
  State<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends State<MealDetailPage> {
  late Future<dynamic> future;
  late Future<dynamic> memoriesFuture;

  @override
  void initState() {
    super.initState();
    future = loadMeal();
    memoriesFuture = loadMemories();
  }

  void reload() => setState(() {
        future = loadMeal();
        memoriesFuture = loadMemories();
      });

  Future<dynamic> loadMeal() => context.appRead.get('/meals/${widget.mealId}');

  Future<dynamic> loadMemories() =>
      context.appRead.get('/memories', query: {'mealId': widget.mealId});

  void reloadMemories() => setState(() {
        memoriesFuture = loadMemories();
      });

  Future<void> scheduleTodayDinner(Map<String, dynamic> meal) async {
    try {
      await appendMealToTodayDinner(
        context,
        mealId: widget.mealId,
        mealName: textOf(meal['name']),
      );
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> addIngredientsToShoppingList(Map<String, dynamic> meal) async {
    try {
      await addMealIngredientsToShoppingList(context, meal);
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> updateMealRating(Map<String, dynamic> meal) async {
    if (textOf(meal['name']).isEmpty) {
      showMessage(context, '菜品名称为空，先补全名称再评分');
      return;
    }
    final rating = await mealRatingDialog(
      context,
      initialRating: mealRatingValue(meal['rating'], fallback: 4),
    );
    if (rating == null || !mounted) {
      return;
    }
    try {
      await context.appRead.multipart(
        'PUT',
        '/meals/${widget.mealId}',
        fields: mealRatingUpdateFields(meal, rating: rating),
      );
      if (mounted) {
        showMessage(
            context, '已更新评分 ${mealRatingValue(rating).toStringAsFixed(1)} 分');
        reload();
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> deleteMeal(Map<String, dynamic> meal) async {
    final confirmed = await confirmDialog(
      context,
      title: '删除菜品',
      message: mealDeleteConfirmMessage(meal),
      confirmText: '删除',
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await context.appRead.delete('/meals/${widget.mealId}');
      if (mounted) {
        showMessage(context, '已删除菜品');
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('菜谱详情')),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: FutureBuilder<dynamic>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingList();
            }
            if (snapshot.hasError) {
              return ErrorState(
                  message: errorText(snapshot.error!), onRetry: reload);
            }
            final meal = asMap(payload(snapshot.data));
            final favorite = mealIsFavorite(meal);
            final image = imageUrl(
                meal['image'] ?? meal['coverImage'] ?? meal['imageUrl']);
            final photos = asList(meal['photos'])
                .map(imageUrl)
                .where((item) => item.isNotEmpty)
                .toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 11,
                          child: RemoteImage(url: image),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  kCoffee.withValues(alpha: 0.70),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const TapedLabel(
                                  text: '今晚可以投喂给 TA', icon: Icons.favorite),
                              const SizedBox(height: 10),
                              Text(
                                textOf(meal['name']).isEmpty
                                    ? '未命名菜品'
                                    : textOf(meal['name']),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      height: 1.06,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(textOf(meal['description']).isEmpty
                          ? '还没有简介。'
                          : textOf(meal['description'])),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InfoChip(
                              '${textOf(meal['prepTime']).isEmpty ? '0' : textOf(meal['prepTime'])} 分钟准备'),
                          InfoChip(
                              '${textOf(meal['cookTime']).isEmpty ? '30' : textOf(meal['cookTime'])} 分钟烹饪'),
                          InfoChip(difficultyLabel(meal['difficulty'])),
                          InfoChip(
                              '${textOf(meal['rating']).isEmpty ? '0' : textOf(meal['rating'])} 分'),
                          ...asList(meal['healthTags'])
                              .map(textOf)
                              .where((item) => item.isNotEmpty)
                              .map((item) =>
                                  InfoChip(item, icon: Icons.eco_outlined)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => scheduleTodayDinner(meal),
                            icon: const Icon(Icons.event_available_outlined),
                            label: const Text('今晚就吃它'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => toggleMealFavorite(
                              context,
                              meal,
                              onChanged: reload,
                            ),
                            icon: Icon(favorite
                                ? Icons.favorite
                                : Icons.favorite_border_outlined),
                            label: Text(favorite ? '取消收藏' : '收藏'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => updateMealRating(meal),
                            icon: const Icon(Icons.star_rounded),
                            label: const Text('调整评分'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final changed = await pushPage(
                                context,
                                MemoryEditPage(
                                  initialMealIds: [widget.mealId],
                                  initialTitle: '做了 ${textOf(meal['name'])}',
                                ),
                              );
                              if (changed == true && mounted) {
                                reloadMemories();
                                showMessage(context, '已记录这顿饭');
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('做过一次'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => addIngredientsToShoppingList(meal),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('加入购物清单'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final changed = await pushPage(
                                  context, MealEditPage(mealId: widget.mealId));
                              if (changed == true) {
                                reload();
                              }
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('编辑'),
                          ),
                          TextButton.icon(
                            onPressed: () => deleteMeal(meal),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('删除菜品'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                reportImageIssue(context, widget.mealId),
                            icon: const Icon(Icons.report_outlined),
                            label: const Text('图片不对'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DetailSection(
                    title: '主要食材',
                    icon: Icons.local_dining,
                    children: ingredientWidgets(meal['ingredients'])),
                DetailSection(
                    title: '做法步骤',
                    icon: Icons.menu_book_outlined,
                    children: stepWidgets(meal['steps'])),
                if (textOf(meal['tips']).isNotEmpty)
                  DetailSection(
                    title: '小技巧',
                    icon: Icons.lightbulb_outline,
                    children: [Text(textOf(meal['tips']))],
                  ),
                if (photos.isNotEmpty)
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                            icon: Icons.photo_library_outlined, title: '照片墙'),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: photos.length,
                          itemBuilder: (context, index) => ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: RemoteImage(url: photos[index]),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                MealRelatedMemoriesSection(
                  future: memoriesFuture,
                  onRetry: reloadMemories,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class MealRelatedMemoriesSection extends StatelessWidget {
  const MealRelatedMemoriesSection({
    super.key,
    required this.future,
    required this.onRetry,
  });

  final Future<dynamic> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: FutureBuilder<dynamic>(
        future: future,
        builder: (context, snapshot) {
          const title = SectionTitle(
              icon: Icons.auto_stories_outlined, title: '这道菜的饭后回忆');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                    icon: Icons.auto_stories_outlined, title: '这道菜的饭后回忆'),
                SizedBox(height: 12),
                LinearProgressIndicator(minHeight: 3),
              ],
            );
          }
          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 10),
                Text(errorText(snapshot.error!)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('重新加载'),
                ),
              ],
            );
          }
          final memories = mealRelatedMemoryItems(snapshot.data);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 10),
              if (memories.isEmpty)
                const Text('这道菜还没有饭后回忆，做过一次后会自动出现在这里。')
              else
                ...memories.map(
                  (memory) => MemoryCard(memory: memory, onChanged: onRetry),
                ),
            ],
          );
        },
      ),
    );
  }
}

List<Map<String, dynamic>> mealRelatedMemoryItems(dynamic response,
    {int limit = 3}) {
  final items = memoryListFrom(response)
      .map(asMap)
      .where((item) => item.isNotEmpty)
      .toList();
  if (limit <= 0) {
    return items;
  }
  return items.take(limit).toList();
}

List<Widget> ingredientWidgets(dynamic value) {
  final items = asList(value);
  if (items.isEmpty) {
    return const [Text('还没有录入食材。')];
  }
  return items.map((item) {
    final map = asMap(item);
    final name = textOf(map['name'] ?? item);
    final amount = textOf(map['amount']);
    return ListTile(
      dense: true,
      leading: const Icon(Icons.spa_outlined),
      title: Text(name),
      trailing: amount.isEmpty ? null : Text(amount),
    );
  }).toList();
}

List<Widget> stepWidgets(dynamic value) {
  final items = asList(value);
  if (items.isEmpty) {
    return const [Text('还没有录入做法。')];
  }
  return [
    for (var i = 0; i < items.length; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFFFE1D8),
              child: Text('${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child:
                    Text(textOf(asMap(items[i])['description'] ?? items[i]))),
          ],
        ),
      ),
  ];
}

class MealEditPage extends StatefulWidget {
  const MealEditPage({super.key, this.mealId});

  final String? mealId;

  @override
  State<MealEditPage> createState() => _MealEditPageState();
}

class _MealEditPageState extends State<MealEditPage> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController(text: '家常菜');
  final tagsController = TextEditingController();
  final ingredientsController = TextEditingController();
  final stepsController = TextEditingController();
  final tipsController = TextEditingController();
  final cookTimeController = TextEditingController(text: '30');
  final healthController = TextEditingController(text: '家常,下饭');
  String difficulty = '简单';
  double rating = 4.5;
  bool favorite = false;
  bool loading = false;
  bool initialLoading = false;
  XFile? image;
  String existingImage = '';

  @override
  void initState() {
    super.initState();
    if (widget.mealId != null) {
      loadMeal();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    tagsController.dispose();
    ingredientsController.dispose();
    stepsController.dispose();
    tipsController.dispose();
    cookTimeController.dispose();
    healthController.dispose();
    super.dispose();
  }

  Future<void> loadMeal() async {
    setState(() => initialLoading = true);
    try {
      final data =
          asMap(payload(await context.appRead.get('/meals/${widget.mealId}')));
      nameController.text = textOf(data['name']);
      descriptionController.text = textOf(data['description']);
      categoryController.text = textOf(data['category']);
      tagsController.text = asList(data['tags']).map(textOf).join(', ');
      ingredientsController.text = asList(data['ingredients']).map((item) {
        final map = asMap(item);
        return '${textOf(map['name'] ?? item)} ${textOf(map['amount'])}'.trim();
      }).join('\n');
      stepsController.text = asList(data['steps'])
          .map((item) => textOf(asMap(item)['description'] ?? item))
          .join('\n');
      tipsController.text = textOf(data['tips']);
      cookTimeController.text =
          textOf(data['cookTime']).isEmpty ? '30' : textOf(data['cookTime']);
      healthController.text = asList(data['healthTags']).map(textOf).join(', ');
      difficulty = textOf(data['difficulty']).isEmpty
          ? '简单'
          : textOf(data['difficulty']);
      rating = double.tryParse(textOf(data['rating'])) ?? 4.5;
      favorite = data['favorite'] == true;
      existingImage =
          imageUrl(data['image'] ?? data['coverImage'] ?? data['imageUrl']);
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => initialLoading = false);
      }
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final selected = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: kUploadImageMaxSide,
      maxHeight: kUploadImageMaxSide,
      imageQuality: kUploadImageQuality,
    );
    if (selected != null) {
      try {
        final focused = await createFoodFocusPhoto(selected);
        setState(() => image = focused);
        showMessage(context, '已自动突出菜品主体，柔化背景');
      } catch (_) {
        setState(() => image = selected);
      }
    }
  }

  Future<void> save() async {
    if (nameController.text.trim().isEmpty) {
      showMessage(context, '请填写菜名');
      return;
    }
    setState(() => loading = true);
    final ingredients = ingredientsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
      final parts = line.split(RegExp(r'\s+'));
      return {
        'name': parts.first,
        'amount': parts.length > 1 ? parts.sublist(1).join(' ') : '',
      };
    }).toList();
    final steps = stepsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => {'description': line})
        .toList();
    final fields = {
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'category': categoryController.text.trim(),
      'tags': jsonEncode(splitTags(tagsController.text)),
      'ingredients': jsonEncode(ingredients),
      'steps': jsonEncode(steps),
      'tips': tipsController.text.trim(),
      'servingSize': '2',
      'prepTime': '10',
      'cookTime': cookTimeController.text.trim(),
      'difficulty': difficulty,
      'taste': jsonEncode(splitTags(tagsController.text).take(3).toList()),
      'healthTags': jsonEncode(splitTags(healthController.text)),
      'spiceLevel': '0',
      'source': 'flutter',
      'favorite': favorite.toString(),
      'rating': rating.toStringAsFixed(1),
    };
    try {
      await context.appRead.multipart(
        widget.mealId == null ? 'POST' : 'PUT',
        widget.mealId == null ? '/meals' : '/meals/${widget.mealId}',
        fields: fields,
        files: image == null ? null : {'image': image!},
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mealId == null ? '新增菜谱' : '编辑菜谱')),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: initialLoading
            ? const LoadingList()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onTap: pickImage,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: image != null
                                  ? Image.file(io.File(image!.path),
                                      fit: BoxFit.cover)
                                  : RemoteImage(
                                      url: existingImage,
                                      placeholder: const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 48),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: '菜名')),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descriptionController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: '简介'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                            controller: categoryController,
                            decoration: const InputDecoration(labelText: '分类')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: tagsController,
                            decoration:
                                const InputDecoration(labelText: '标签，用逗号分隔')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: healthController,
                            decoration:
                                const InputDecoration(labelText: '健康/均衡标签')),
                        const SizedBox(height: 12),
                        TextField(
                          controller: ingredientsController,
                          minLines: 4,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: '食材',
                            helperText: '每行一个，例如：鸡蛋 2个',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: stepsController,
                          minLines: 5,
                          maxLines: 10,
                          decoration: const InputDecoration(
                            labelText: '做法步骤',
                            helperText: '每行一个步骤',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                            controller: tipsController,
                            decoration:
                                const InputDecoration(labelText: '小技巧')),
                        const SizedBox(height: 12),
                        TextField(
                          controller: cookTimeController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: '烹饪时间（分钟）'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: difficulty,
                          decoration: const InputDecoration(labelText: '难度'),
                          items: const ['简单', '中等', '进阶']
                              .map((item) => DropdownMenuItem(
                                  value: item, child: Text(item)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => difficulty = value ?? '简单'),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: favorite,
                          title: const Text('收藏'),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) =>
                              setState(() => favorite = value),
                        ),
                        Text('评分 ${rating.toStringAsFixed(1)}'),
                        Slider(
                          value: rating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          onChanged: (value) => setState(() => rating = value),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: loading ? null : save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(loading ? '保存中...' : '保存菜谱'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

List<String> splitTags(String value) {
  return value
      .split(RegExp(r'[,，、\s]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

class MemoriesPage extends StatefulWidget {
  const MemoriesPage({super.key});

  @override
  State<MemoriesPage> createState() => _MemoriesPageState();
}

class _MemoriesPageState extends State<MemoriesPage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<dynamic> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<dynamic> load() =>
      context.appRead.get('/memories', query: {'month': monthString(month)});
  void reload() => setState(() {
        future = load();
      });

  void changeMonth(int delta) {
    setState(() {
      month = DateTime(month.year, month.month + delta);
      future = load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<dynamic>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingList();
          }
          if (snapshot.hasError) {
            return ErrorState(
                message: errorText(snapshot.error!), onRetry: reload);
          }
          final items = memoryListFrom(snapshot.data);
          return RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                SoftCard(
                  child: Row(
                    children: [
                      IconButton(
                          onPressed: () => changeMonth(-1),
                          icon: const Icon(Icons.chevron_left)),
                      Expanded(
                        child: Text(
                          '${month.year} 年 ${month.month} 月饭后回忆',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                          onPressed: () => changeMonth(1),
                          icon: const Icon(Icons.chevron_right)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  EmptyState(
                    title: '这个月还没有回忆',
                    action: '记录一顿饭',
                    onPressed: () async {
                      final changed =
                          await pushPage(context, const MemoryEditPage());
                      if (changed == true) {
                        reload();
                      }
                    },
                  )
                else
                  ...items
                      .map((item) =>
                          MemoryCard(memory: asMap(item), onChanged: reload))
                      .toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await pushPage(context, const MemoryEditPage());
          if (changed == true) {
            reload();
          }
        },
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('记录回忆'),
      ),
    );
  }
}

List<dynamic> memoryListFrom(dynamic response) {
  final data = payload(response);
  if (data is Map) {
    return asList(data['memories'] ?? data['items'] ?? data['list']);
  }
  return asList(data);
}

List<String> memoryMealIds(Map<String, dynamic> memory) {
  final result = <String>[];
  for (final item in asList(memory['mealIds'] ?? memory['meals'])) {
    final id = item is String ? item : idOf(item);
    if (id.isNotEmpty && !result.contains(id)) {
      result.add(id);
    }
  }
  return result;
}

List<String> memoryPhotoUrls(Map<String, dynamic> memory) => asList(
      memory['photos'],
    ).map(imageUrl).where((item) => item.isNotEmpty).toList();

List<String> memoryExistingPhotoRefs(Map<String, dynamic> memory) =>
    asList(memory['photos'])
        .map(textOf)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.memory, this.onChanged});

  final Map<String, dynamic> memory;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final id = idOf(memory);
    final photos = memoryPhotoUrls(memory);
    final meals = mealNames(memory['mealIds'] ?? memory['meals']);
    final rating = textOf(memory['rating']);
    final actualCookTime = textOf(memory['actualCookTime']);
    final nextImprovement = textOf(memory['nextImprovement']);
    final hasChips = rating.isNotEmpty ||
        (actualCookTime.isNotEmpty && actualCookTime != '0') ||
        meals.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photos.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                    aspectRatio: 16 / 9, child: RemoteImage(url: photos.first)),
              ),
            const SizedBox(height: 10),
            Text(
              textOf(memory['title']).isEmpty
                  ? '一顿饭的回忆'
                  : textOf(memory['title']),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
                '${textOf(memory['date']).split('T').first} · ${mealTypeLabel(textOf(memory['mealType']))} · ${textOf(memory['mood'])}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (rating.isNotEmpty) InfoChip('$rating 分'),
                if (actualCookTime.isNotEmpty && actualCookTime != '0')
                  InfoChip('$actualCookTime 分钟'),
                ...meals.take(3).map(
                      (item) => InfoChip(item, icon: Icons.restaurant_menu),
                    ),
              ],
            ),
            if (hasChips) const SizedBox(height: 8),
            if (textOf(memory['note']).isNotEmpty) Text(textOf(memory['note'])),
            if (nextImprovement.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('下次改进：$nextImprovement'),
            ],
            if (onChanged != null && id.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final changed = await pushPage(
                        context,
                        MemoryEditPage(memory: memory),
                      );
                      if (changed == true) {
                        onChanged?.call();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('编辑'),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () async {
                      final confirmed = await confirmDialog(
                        context,
                        title: '删除回忆',
                        message: '删除后这条饭后回忆不会再出现在时间线和相册里。',
                        confirmText: '删除',
                      );
                      if (!confirmed || !context.mounted) {
                        return;
                      }
                      try {
                        await context.appRead.delete('/memories/$id');
                        if (context.mounted) {
                          showMessage(context, '已删除回忆');
                          onChanged?.call();
                        }
                      } catch (error) {
                        if (context.mounted) {
                          showMessage(context, errorText(error));
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('删除'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String mealTypeLabel(String value) {
  switch (value) {
    case 'breakfast':
      return '早餐';
    case 'lunch':
      return '午餐';
    case 'dinner':
      return '晚餐';
    default:
      return value;
  }
}

String normalizedMealType(String value) {
  return mealTypes.contains(value) ? value : 'dinner';
}

String scheduleMemoryTitle(String type) {
  return '${mealTypeLabel(normalizedMealType(type))}饭后回忆';
}

class MemoryEditPage extends StatefulWidget {
  const MemoryEditPage({
    super.key,
    this.initialMealIds = const [],
    this.initialTitle = '',
    this.initialDate = '',
    this.initialMealType = 'dinner',
    this.memory,
  });

  final List<String> initialMealIds;
  final String initialTitle;
  final String initialDate;
  final String initialMealType;
  final Map<String, dynamic>? memory;

  @override
  State<MemoryEditPage> createState() => _MemoryEditPageState();
}

class _MemoryEditPageState extends State<MemoryEditPage> {
  late final TextEditingController dateController;
  late final TextEditingController titleController;
  final moodController = TextEditingController(text: '开心');
  final noteController = TextEditingController();
  final actualCookTimeController = TextEditingController();
  final nextImprovementController = TextEditingController();
  String mealType = 'dinner';
  double rating = 5;
  final selectedMealIds = <String>{};
  final existingPhotos = <String>[];
  final imagePicker = ImagePicker();
  final photos = <XFile>[];
  late Future<dynamic> mealsFuture;
  bool saving = false;
  bool pickingPhotos = false;

  @override
  void initState() {
    super.initState();
    final memory = widget.memory;
    final defaultDate = widget.initialDate.trim().isEmpty
        ? dateString(DateTime.now())
        : widget.initialDate.trim().split('T').first;
    dateController = TextEditingController(
      text: textOf(memory?['date']).split('T').first.isEmpty
          ? defaultDate
          : textOf(memory?['date']).split('T').first,
    );
    titleController = TextEditingController(
      text: memory == null ? widget.initialTitle : textOf(memory['title']),
    );
    mealType = normalizedMealType(widget.initialMealType);
    if (memory != null) {
      moodController.text = textOf(memory['mood']);
      noteController.text = textOf(memory['note']);
      actualCookTimeController.text = textOf(memory['actualCookTime']);
      nextImprovementController.text = textOf(memory['nextImprovement']);
      mealType = textOf(memory['mealType']).isEmpty
          ? mealType
          : textOf(memory['mealType']);
      rating = double.tryParse(textOf(memory['rating'])) ?? rating;
      selectedMealIds.addAll(memoryMealIds(memory));
      existingPhotos.addAll(memoryExistingPhotoRefs(memory));
    } else {
      selectedMealIds.addAll(widget.initialMealIds);
    }
    mealsFuture = context.appRead.get('/meals', query: {'limit': '200'});
    recoverLostPhotos();
  }

  @override
  void dispose() {
    dateController.dispose();
    titleController.dispose();
    moodController.dispose();
    noteController.dispose();
    actualCookTimeController.dispose();
    nextImprovementController.dispose();
    super.dispose();
  }

  void addPhotos(List<XFile> selected, {String? message}) {
    if (selected.isEmpty) {
      return;
    }
    setState(() => photos.addAll(selected));
    showMessage(context, message ?? '已添加 ${selected.length} 张照片');
  }

  Future<void> addFoodFocusedPhotos(List<XFile> selected) async {
    if (selected.isEmpty) {
      return;
    }
    final focusedPhotos = <XFile>[];
    final failedNames = <String>[];
    for (final photo in selected) {
      try {
        focusedPhotos.add(await createFoodFocusPhoto(photo));
      } catch (error) {
        final fileName = uploadFileName(photo);
        failedNames.add(fileName);
      }
    }
    if (!mounted) {
      return;
    }
    if (focusedPhotos.isNotEmpty) {
      addPhotos(
        focusedPhotos,
        message: failedNames.isEmpty
            ? '已压缩并转换为可上传照片 ${focusedPhotos.length} 张'
            : '已添加 ${focusedPhotos.length} 张，跳过 ${failedNames.length} 张不支持的图片',
      );
    } else {
      showMessage(context, '图片格式暂不支持，请选择 JPG、PNG 或重新拍照后再试');
    }
  }

  Future<void> recoverLostPhotos() async {
    try {
      final response = await imagePicker.retrieveLostData();
      if (!mounted || response.isEmpty) {
        return;
      }
      final recovered = response.files ??
          (response.file == null ? const <XFile>[] : <XFile>[response.file!]);
      if (recovered.isNotEmpty) {
        await addFoodFocusedPhotos(recovered);
      } else if (response.exception != null) {
        showMessage(context, '恢复照片失败：${response.exception}');
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, '恢复照片失败：${errorText(error)}');
      }
    }
  }

  Future<void> choosePhotoSource() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: kLine,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('从图库选择'),
                subtitle: const Text('支持一次选择多张饭后照片'),
                onTap: () => Navigator.pop(sheetContext, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('调用相机拍摄'),
                subtitle: const Text('现场拍一张，直接加入这顿回忆'),
                onTap: () => Navigator.pop(sheetContext, 'camera'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'gallery') {
      await pickPhotosFromGallery();
    } else if (action == 'camera') {
      await takePhoto();
    }
  }

  Future<void> pickPhotosFromGallery() async {
    if (pickingPhotos) {
      return;
    }
    setState(() => pickingPhotos = true);
    try {
      final selected = await imagePicker.pickMultiImage(
        maxWidth: kUploadImageMaxSide,
        maxHeight: kUploadImageMaxSide,
        imageQuality: kUploadImageQuality,
      );
      if (mounted) {
        await addFoodFocusedPhotos(selected);
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, '图库选择失败：${errorText(error)}');
      }
    } finally {
      if (mounted) {
        setState(() => pickingPhotos = false);
      }
    }
  }

  Future<void> takePhoto() async {
    if (pickingPhotos) {
      return;
    }
    setState(() => pickingPhotos = true);
    try {
      final selected = await imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: kUploadImageMaxSide,
        maxHeight: kUploadImageMaxSide,
        imageQuality: kUploadImageQuality,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (selected != null && mounted) {
        await addFoodFocusedPhotos([selected]);
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, '拍照失败：${errorText(error)}');
      }
    } finally {
      if (mounted) {
        setState(() => pickingPhotos = false);
      }
    }
  }

  void removePhoto(int index) {
    setState(() => photos.removeAt(index));
  }

  void removeExistingPhoto(int index) {
    setState(() => existingPhotos.removeAt(index));
  }

  Widget buildPhotoPickerSection(BuildContext context) {
    final photoCount = existingPhotos.length + photos.length;
    final title = photoCount == 0 ? '饭后照片' : '饭后照片 $photoCount 张';
    final hint = memoryPhotoPickerHint(
      existingCount: existingPhotos.length,
      newCount: photos.length,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPaper,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kPeach.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    const Icon(Icons.photo_camera_back_outlined, color: kCoral),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      hint,
                      style: const TextStyle(color: kCocoa),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: pickingPhotos ? null : choosePhotoSource,
                icon: pickingPhotos
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                tooltip: '添加照片',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              InfoChip('图库多选', icon: Icons.photo_library_outlined),
              InfoChip('相机拍照', icon: Icons.photo_camera_outlined),
              InfoChip('自动转 JPG', icon: Icons.compress_outlined),
            ],
          ),
          const SizedBox(height: 12),
          if (photoCount == 0)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: pickingPhotos ? null : choosePhotoSource,
              child: Container(
                height: 116,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kOat.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kLine),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: pickingPhotos ? kCocoa : kCoral,
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pickingPhotos ? '正在打开照片入口...' : '添加图库照片或调用相机',
                      style: const TextStyle(
                        color: kCoffee,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photoCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final isExisting = index < existingPhotos.length;
                final photoIndex =
                    isExisting ? index : index - existingPhotos.length;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isExisting)
                        RemoteImage(url: imageUrl(existingPhotos[index]))
                      else
                        Image.file(
                          io.File(photos[photoIndex].path),
                          fit: BoxFit.cover,
                        ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: () => isExisting
                              ? removeExistingPhoto(index)
                              : removePhoto(photoIndex),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: pickingPhotos ? null : pickPhotosFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('从图库选择'),
              ),
              OutlinedButton.icon(
                onPressed: pickingPhotos ? null : takePhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('拍照添加'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      final memoryId = idOf(widget.memory);
      await context.appRead.multipart(
        memoryId.isEmpty ? 'POST' : 'PUT',
        memoryId.isEmpty ? '/memories' : '/memories/$memoryId',
        fields: {
          'date': dateController.text.trim(),
          'mealType': mealType,
          'title': titleController.text.trim(),
          'mood': moodController.text.trim(),
          'note': noteController.text.trim(),
          'rating': rating.toStringAsFixed(0),
          'actualCookTime': actualCookTimeController.text.trim(),
          'nextImprovement': nextImprovementController.text.trim(),
          'mealIds': jsonEncode(selectedMealIds.toList()),
          'existingPhotos': jsonEncode(existingPhotos),
          'participants': jsonEncode(context.appRead.userId.isEmpty
              ? const []
              : [context.appRead.userId]),
        },
        multiFiles: {'photos': photos},
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记录饭后回忆')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 72),
          child: FilledButton.icon(
            onPressed: saving ? null : save,
            icon: const Icon(Icons.save_outlined),
            label: Text(saving ? '保存中...' : '保存回忆'),
          ),
        ),
      ),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                      controller: dateController,
                      decoration:
                          const InputDecoration(labelText: '日期 YYYY-MM-DD')),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'breakfast', label: Text('早餐')),
                      ButtonSegment(value: 'lunch', label: Text('午餐')),
                      ButtonSegment(value: 'dinner', label: Text('晚餐')),
                    ],
                    selected: {mealType},
                    onSelectionChanged: (value) =>
                        setState(() => mealType = value.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: '标题')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: moodController,
                      decoration: const InputDecoration(labelText: '心情')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: '备注'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: actualCookTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '实际耗时（分钟）'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nextImprovementController,
                    decoration: const InputDecoration(labelText: '下次改进'),
                  ),
                  const SizedBox(height: 12),
                  Text('评分 ${rating.toStringAsFixed(0)} 星'),
                  Slider(
                    value: rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) => setState(() => rating = value),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<dynamic>(
                    future: mealsFuture,
                    builder: (context, snapshot) {
                      final meals = snapshot.hasData
                          ? mealListFrom(snapshot.data)
                          : const <dynamic>[];
                      return ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text('相关菜品 ${selectedMealIds.length} 个'),
                        children: meals.map((item) {
                          final meal = asMap(item);
                          final id = idOf(meal);
                          return CheckboxListTile(
                            value: selectedMealIds.contains(id),
                            title: Text(textOf(meal['name'])),
                            onChanged: (_) => setState(() {
                              selectedMealIds.contains(id)
                                  ? selectedMealIds.remove(id)
                                  : selectedMealIds.add(id);
                            }),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  buildPhotoPickerSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeekSwitcher extends StatelessWidget {
  const WeekSwitcher({
    super.key,
    required this.weekStart,
    required this.onChanged,
  });

  final DateTime weekStart;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCurrentWeek =
        dateString(mondayOf(weekStart)) == dateString(mondayOf(DateTime.now()));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kOat.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: '上一周',
            onPressed: () => onChanged(addWeeks(weekStart, -1)),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  weekRangeLabel(weekStart),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: kCoffee,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weekRelativeLabel(weekStart),
                  style: const TextStyle(
                    color: kCocoa,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: '下一周',
            onPressed: () => onChanged(addWeeks(weekStart, 1)),
            icon: const Icon(Icons.chevron_right),
          ),
          if (!isCurrentWeek) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => onChanged(mondayOf(DateTime.now())),
              child: const Text('本周'),
            ),
          ],
        ],
      ),
    );
  }
}

class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
    this.suffix = '',
  });

  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = monthOnly(month) == monthOnly(DateTime.now());
    final title = suffix.isEmpty
        ? monthTitleLabel(month)
        : '${monthTitleLabel(month)} · $suffix';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kOat.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: '上个月',
            onPressed: () => onChanged(addMonths(month, -1)),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: kCoffee,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  monthRelativeLabel(month),
                  style: const TextStyle(
                    color: kCocoa,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: '下个月',
            onPressed: () => onChanged(addMonths(month, 1)),
            icon: const Icon(Icons.chevron_right),
          ),
          if (!isCurrentMonth) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => onChanged(monthOnly(DateTime.now())),
              child: const Text('本月'),
            ),
          ],
        ],
      ),
    );
  }
}

class WeeklyPlanPage extends StatefulWidget {
  const WeeklyPlanPage({super.key});

  @override
  State<WeeklyPlanPage> createState() => _WeeklyPlanPageState();
}

class _WeeklyPlanPageState extends State<WeeklyPlanPage> {
  DateTime weekStart = mondayOf(DateTime.now());
  late Future<dynamic> future;
  Map<String, dynamic>? draft;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<dynamic> load() => context.appRead
      .get('/weekly-plans', query: {'weekStart': dateString(weekStart)});
  void reload() => setState(() {
        future = load();
      });

  void setWeekStart(DateTime value) => setState(() {
        weekStart = mondayOf(value);
        draft = null;
        future = load();
      });

  void removeDraftMeal(String date, String type, String mealId) {
    final current = draft;
    if (current == null) {
      return;
    }
    setState(() {
      draft = removeMealFromWeeklyDraft(
        current,
        date: date,
        type: type,
        mealId: mealId,
      );
    });
  }

  Future<void> addDraftMeal(String date, String type) async {
    final current = draft;
    if (current == null) {
      return;
    }
    final meal = await pickMealForWeeklyDraft(context);
    if (meal == null) {
      return;
    }
    setState(() {
      draft = addMealToWeeklyDraft(
        current,
        date: date,
        type: type,
        meal: meal,
      );
    });
  }

  Future<void> generate() async {
    setState(() => busy = true);
    try {
      final response = await context.appRead.post('/weekly-plans/generate',
          body: {'weekStart': dateString(weekStart)});
      setState(() => draft = asMap(payload(response)));
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> apply() async {
    if (draft == null) {
      showMessage(context, '请先生成草稿');
      return;
    }
    setState(() => busy = true);
    try {
      await context.appRead.post('/weekly-plans/apply', body: {
        'days': draft!['days'] ?? draft!['plan'] ?? draft,
      });
      if (mounted) {
        showMessage(context, '已应用到日历');
        reload();
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本周饭桌计划')),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: FutureBuilder<dynamic>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingList();
            }
            if (snapshot.hasError) {
              return ErrorState(
                  message: errorText(snapshot.error!), onRetry: reload);
            }
            final data = asMap(payload(snapshot.data));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${weekRelativeLabel(weekStart)}饭桌计划',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      WeekSwitcher(
                        weekStart: weekStart,
                        onChanged: setWeekStart,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: busy ? null : generate,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('生成草稿'),
                          ),
                          OutlinedButton.icon(
                            onPressed: busy ? null : apply,
                            icon: const Icon(Icons.check),
                            label: const Text('应用到日历'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PlanBlock(title: '当前周计划', data: data),
                if (draft != null) ...[
                  const SizedBox(height: 12),
                  PlanBlock(
                    title: '新生成草稿',
                    data: {'days': draft!['preview'] ?? draft!['days'] ?? []},
                    editable: true,
                    onRemoveMeal: removeDraftMeal,
                    onAddMeal: addDraftMeal,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class PlanBlock extends StatelessWidget {
  const PlanBlock({
    super.key,
    required this.title,
    required this.data,
    this.editable = false,
    this.onRemoveMeal,
    this.onAddMeal,
  });

  final String title;
  final Map<String, dynamic> data;
  final bool editable;
  final void Function(String date, String type, String mealId)? onRemoveMeal;
  final void Function(String date, String type)? onAddMeal;

  @override
  Widget build(BuildContext context) {
    final days = asList(
        data['preview'] ?? data['days'] ?? data['plan'] ?? data['items']);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(icon: Icons.calendar_view_week_outlined, title: title),
          const SizedBox(height: 10),
          if (days.isEmpty)
            Text(textOf(data).isEmpty ? '暂无内容' : textOf(data))
          else
            ...days.map((item) {
              final day = asMap(item);
              final hints = planHints(day);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(textOf(day['date']),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    if (editable) ...[
                      PlanMealEditorRow(
                        title: '早',
                        type: 'breakfast',
                        date: textOf(day['date']),
                        value: planMealValue(day, 'breakfast'),
                        onRemoveMeal: onRemoveMeal,
                        onAddMeal: onAddMeal,
                      ),
                      PlanMealEditorRow(
                        title: '午',
                        type: 'lunch',
                        date: textOf(day['date']),
                        value: planMealValue(day, 'lunch'),
                        onRemoveMeal: onRemoveMeal,
                        onAddMeal: onAddMeal,
                      ),
                      PlanMealEditorRow(
                        title: '晚',
                        type: 'dinner',
                        date: textOf(day['date']),
                        value: planMealValue(day, 'dinner'),
                        onRemoveMeal: onRemoveMeal,
                        onAddMeal: onAddMeal,
                      ),
                    ] else ...[
                      MealBadges(
                          title: '早', value: planMealValue(day, 'breakfast')),
                      MealBadges(
                          title: '午', value: planMealValue(day, 'lunch')),
                      MealBadges(
                          title: '晚', value: planMealValue(day, 'dinner')),
                    ],
                    if (hints.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: hints
                            .map((item) =>
                                InfoChip(item, icon: Icons.eco_outlined))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

dynamic planMealValue(Map<String, dynamic> day, String type) {
  final meals = asMap(day['meals']);
  return day[type] ?? meals[type] ?? const [];
}

List<String> planHints(Map<String, dynamic> day) {
  final values = asList(
    day['hints'] ?? day['balanceHints'] ?? day['healthHints'] ?? day['tips'],
  );
  return values
      .map(friendlyText)
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
}

class PlanMealEditorRow extends StatelessWidget {
  const PlanMealEditorRow({
    super.key,
    required this.title,
    required this.type,
    required this.date,
    required this.value,
    this.onRemoveMeal,
    this.onAddMeal,
  });

  final String title;
  final String type;
  final String date;
  final dynamic value;
  final void Function(String date, String type, String mealId)? onRemoveMeal;
  final void Function(String date, String type)? onAddMeal;

  @override
  Widget build(BuildContext context) {
    final entries = planMealEntries(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(mealIcon(title), size: 16, color: kCaramel),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              title,
              style: const TextStyle(
                color: kCocoa,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: entries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '待定',
                      style: TextStyle(
                        color: Color(0xFF9E8D83),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entries.map((entry) {
                      final mealId = entry['id'] ?? '';
                      return InputChip(
                        label: Text(entry['name'] ?? mealId),
                        onDeleted: mealId.isEmpty || onRemoveMeal == null
                            ? null
                            : () => onRemoveMeal!(date, type, mealId),
                      );
                    }).toList(),
                  ),
          ),
          IconButton.filledTonal(
            tooltip: '添加菜品',
            onPressed: onAddMeal == null ? null : () => onAddMeal!(date, type),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

Future<Map<String, dynamic>?> pickMealForWeeklyDraft(
  BuildContext context,
) async {
  final app = context.appRead;
  final searchController = TextEditingController();
  Future<dynamic> loadMeals() {
    final search = searchController.text.trim();
    return app.get('/meals', query: {
      'limit': '200',
      if (search.isNotEmpty) 'search': search,
    });
  }

  try {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var future = loadMeals();
        return StatefulBuilder(
          builder: (context, setState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SoftCard(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.78,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(
                        icon: Icons.restaurant_menu,
                        title: '选择一道加入草稿',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: '搜索菜名、食材或做法',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            tooltip: '搜索',
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () => setState(() {
                              future = loadMeals();
                            }),
                          ),
                        ),
                        onSubmitted: (_) => setState(() {
                          future = loadMeals();
                        }),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: FutureBuilder<dynamic>(
                          future: future,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LoadingList();
                            }
                            if (snapshot.hasError) {
                              return ErrorState(
                                message: errorText(snapshot.error!),
                                onRetry: () => setState(() {
                                  future = loadMeals();
                                }),
                              );
                            }
                            final meals = mealListFrom(snapshot.data)
                                .map(asMap)
                                .where((meal) => idOf(meal).isNotEmpty)
                                .toList();
                            if (meals.isEmpty) {
                              return const EmptyState(title: '没有找到菜品');
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              itemCount: meals.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final meal = meals[index];
                                final cookTime =
                                    textOf(meal['cookTime']).isEmpty
                                        ? '30'
                                        : textOf(meal['cookTime']);
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    textOf(meal['name']),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      textOf(meal['category']),
                                      '$cookTime 分钟',
                                    ]
                                        .where((item) => item.isNotEmpty)
                                        .join(' · '),
                                  ),
                                  trailing:
                                      const Icon(Icons.add_circle_outline),
                                  onTap: () =>
                                      Navigator.pop(sheetContext, meal),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  } finally {
    searchController.dispose();
  }
}

List<Map<String, String>> planMealEntries(dynamic value) {
  final list = value is Map
      ? asList(value['meals'] ?? value['mealIds'] ?? value['items'])
      : asList(value);
  return list
      .map((item) {
        final id = planItemMealId(item);
        final name = planItemMealName(item);
        return {
          'id': id,
          'name': name.isEmpty ? id : name,
        };
      })
      .where((item) =>
          (item['id'] ?? '').isNotEmpty || (item['name'] ?? '').isNotEmpty)
      .toList();
}

String planItemMealId(dynamic item) {
  if (item is String) {
    return item;
  }
  final map = asMap(item);
  final nestedMeal = asMap(map['meal']);
  final nestedId = idOf(nestedMeal);
  if (nestedId.isNotEmpty) {
    return nestedId;
  }
  final directId = idOf(map);
  if (directId.isNotEmpty) {
    return directId;
  }
  return textOf(map['mealId'] ?? map['id'] ?? item);
}

String planItemMealName(dynamic item) {
  if (item is String) {
    return item;
  }
  final map = asMap(item);
  final nestedMeal = asMap(map['meal']);
  return textOf(map['name'] ??
      map['title'] ??
      nestedMeal['name'] ??
      nestedMeal['title'] ??
      item);
}

Map<String, dynamic> addMealToWeeklyDraft(
  Map<String, dynamic> draft, {
  required String date,
  required String type,
  required Map<String, dynamic> meal,
}) {
  final mealId = idOf(meal);
  if (mealId.isEmpty) {
    return draft;
  }
  final result = Map<String, dynamic>.from(draft);
  for (final key in ['days', 'preview', 'plan']) {
    if (!result.containsKey(key)) {
      continue;
    }
    result[key] = asList(result[key]).map((rawDay) {
      final day = Map<String, dynamic>.from(asMap(rawDay));
      if (textOf(day['date']).split('T').first != date) {
        return day;
      }
      final meals = Map<String, dynamic>.from(asMap(day['meals']));
      final current = asList(day[type] ?? meals[type]).toList();
      if (current.any((item) => planItemMealId(item) == mealId)) {
        return day;
      }
      final value = key == 'preview' ? Map<String, dynamic>.from(meal) : mealId;
      final updated = [...current, value];
      if (day.containsKey(type)) {
        day[type] = updated;
      }
      meals[type] = updated;
      day['meals'] = meals;
      return day;
    }).toList();
  }
  return result;
}

Map<String, dynamic> removeMealFromWeeklyDraft(
  Map<String, dynamic> draft, {
  required String date,
  required String type,
  required String mealId,
}) {
  final result = Map<String, dynamic>.from(draft);
  for (final key in ['days', 'preview', 'plan']) {
    if (!result.containsKey(key)) {
      continue;
    }
    result[key] = asList(result[key]).map((rawDay) {
      final day = Map<String, dynamic>.from(asMap(rawDay));
      if (textOf(day['date']).split('T').first != date) {
        return day;
      }
      final meals = Map<String, dynamic>.from(asMap(day['meals']));
      final current = asList(day[type] ?? meals[type]);
      final filtered =
          current.where((item) => planItemMealId(item) != mealId).toList();
      if (day.containsKey(type)) {
        day[type] = filtered;
      }
      meals[type] = filtered;
      day['meals'] = meals;
      return day;
    }).toList();
  }
  return result;
}

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  DateTime weekStart = mondayOf(DateTime.now());
  late Future<dynamic> future;
  bool showOnlyRemaining = false;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<dynamic> load() => context.appRead
      .get('/shopping-list', query: {'weekStart': dateString(weekStart)});
  void reload() => setState(() {
        future = load();
      });

  void setWeekStart(DateTime value) => setState(() {
        weekStart = mondayOf(value);
        future = load();
      });

  Future<void> generate() async {
    try {
      await context.appRead.post('/shopping-list/generate',
          body: {'weekStart': dateString(weekStart)});
      reload();
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> addItem() async {
    final draft = await shoppingItemDialog(
      context,
      title: '补充采购项',
      initialCategory: 'other',
    );
    if (draft == null) {
      return;
    }
    try {
      await context.appRead.post('/shopping-list/items', body: {
        'weekStart': dateString(weekStart),
        ...draft,
      });
      reload();
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> clearPurchased() async {
    try {
      await context.appRead.delete('/shopping-list/purchased',
          query: {'weekStart': dateString(weekStart)});
      reload();
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('购物清单')),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: FutureBuilder<dynamic>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingList();
            }
            if (snapshot.hasError) {
              return ErrorState(
                  message: errorText(snapshot.error!), onRetry: reload);
            }
            final allItems = shoppingItems(snapshot.data);
            final items =
                showOnlyRemaining ? shoppingRemainingItems(allItems) : allItems;
            final purchasedCount = shoppingPurchasedCount(allItems);
            final grouped = <String, List<Map<String, dynamic>>>{};
            for (final item in items) {
              grouped
                  .putIfAbsent(
                      shoppingCategoryLabel(item['category']), () => [])
                  .add(item);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${weekRelativeLabel(weekStart)}购物清单',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      WeekSwitcher(
                        weekStart: weekStart,
                        onChanged: setWeekStart,
                      ),
                      const SizedBox(height: 12),
                      if (allItems.isNotEmpty)
                        ShoppingProgressPanel(
                          items: allItems,
                          showOnlyRemaining: showOnlyRemaining,
                          onFilterChanged: (value) => setState(
                            () => showOnlyRemaining = value,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: generate,
                            icon: const Icon(Icons.playlist_add_check),
                            label: const Text('从周计划生成'),
                          ),
                          OutlinedButton.icon(
                            onPressed: addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('手动补充'),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                purchasedCount == 0 ? null : clearPurchased,
                            icon: const Icon(Icons.cleaning_services_outlined),
                            label: const Text('清空已购'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (allItems.isEmpty)
                  const EmptyState(title: '暂无采购项')
                else if (items.isEmpty)
                  const EmptyState(title: '已购项都收好啦')
                else
                  ...grouped.entries.map((entry) => ShoppingGroup(
                        title: entry.key,
                        items: entry.value,
                        weekStart: weekStart,
                        onChanged: reload,
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> shoppingItems(dynamic response) {
  final data = payload(response);
  final items = data is Map
      ? asList(data['items'] ?? data['manualItems'] ?? data['list'])
      : asList(data);
  return items.map(asMap).toList();
}

bool shoppingItemChecked(Map<String, dynamic> item) {
  return item['checked'] == true || item['purchased'] == true;
}

int shoppingPurchasedCount(List<Map<String, dynamic>> items) {
  return items.where(shoppingItemChecked).length;
}

List<Map<String, dynamic>> shoppingRemainingItems(
    List<Map<String, dynamic>> items) {
  return items.where((item) => !shoppingItemChecked(item)).toList();
}

double shoppingProgressValue(List<Map<String, dynamic>> items) {
  if (items.isEmpty) {
    return 0;
  }
  return shoppingPurchasedCount(items) / items.length;
}

String shoppingProgressText(List<Map<String, dynamic>> items) {
  if (items.isEmpty) {
    return '还没有采购项';
  }
  final purchased = shoppingPurchasedCount(items);
  final remaining = items.length - purchased;
  return '已购 $purchased / 共 ${items.length}，剩余 $remaining 项';
}

String shoppingCategoryLabel(dynamic value) {
  switch (textOf(value)) {
    case 'vegetable':
      return '蔬菜';
    case 'meat_egg':
      return '肉蛋';
    case 'staple':
      return '主食';
    case 'seasoning':
      return '调料';
    case 'other':
    case '':
      return '其他';
    default:
      return textOf(value);
  }
}

const List<String> kShoppingCategoryValues = [
  'vegetable',
  'meat_egg',
  'staple',
  'seasoning',
  'other',
];

String normalizedShoppingCategory(dynamic value) {
  final category = textOf(value);
  return kShoppingCategoryValues.contains(category) ? category : 'other';
}

Map<String, String>? shoppingItemDraftFromText(
  String value, {
  String category = 'other',
}) {
  final text = value.trim();
  if (text.isEmpty) {
    return null;
  }
  final parts = text.split(RegExp(r'\s+'));
  final name = parts.first.trim();
  if (name.isEmpty) {
    return null;
  }
  final amount = parts.length > 1 ? parts.sublist(1).join(' ').trim() : '';
  return {
    'name': name,
    'amount': amount,
    'category': normalizedShoppingCategory(category),
  };
}

Future<Map<String, String>?> shoppingItemDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
  String initialAmount = '',
  String initialCategory = 'other',
}) async {
  final nameController = TextEditingController(text: initialName);
  final amountController = TextEditingController(text: initialAmount);
  var category = normalizedShoppingCategory(initialCategory);
  String? error;

  try {
    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '食材名称',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: '数量，例如 10个'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: '分类'),
                items: kShoppingCategoryValues
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(shoppingCategoryLabel(item)),
                        ))
                    .toList(),
                onChanged: (value) => setState(
                  () => category = normalizedShoppingCategory(value),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  setState(() => error = '请填写食材名称');
                  return;
                }
                Navigator.pop(context, {
                  'name': name,
                  'amount': amountController.text.trim(),
                  'category': category,
                });
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  } finally {
    nameController.dispose();
    amountController.dispose();
  }
}

class ShoppingProgressPanel extends StatelessWidget {
  const ShoppingProgressPanel({
    super.key,
    required this.items,
    required this.showOnlyRemaining,
    required this.onFilterChanged,
  });

  final List<Map<String, dynamic>> items;
  final bool showOnlyRemaining;
  final ValueChanged<bool> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.app.themePalette;
    final purchased = shoppingPurchasedCount(items);
    final remaining = items.length - purchased;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shoppingProgressText(items),
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InfoChip('剩余 $remaining', icon: Icons.shopping_bag_outlined),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: shoppingProgressValue(items),
              backgroundColor: Colors.white.withValues(alpha: 0.64),
              color:
                  purchased == items.length ? palette.success : palette.accent,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: showOnlyRemaining,
            onChanged: onFilterChanged,
            title: const Text(
              '只看未购',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: const Text('买菜时隐藏已经勾选的食材，列表更清爽'),
          ),
        ],
      ),
    );
  }
}

class ShoppingGroup extends StatelessWidget {
  const ShoppingGroup({
    super.key,
    required this.title,
    required this.items,
    required this.weekStart,
    required this.onChanged,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final DateTime weekStart;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(icon: Icons.shopping_basket_outlined, title: title),
            ...items.map((item) {
              final id = idOf(item);
              final checked =
                  item['checked'] == true || item['purchased'] == true;
              final amount = textOf(item['amount']);
              final category = normalizedShoppingCategory(item['category']);
              final subtitle = [
                if (amount.isNotEmpty) amount,
                shoppingCategoryLabel(category),
              ].join(' · ');
              return CheckboxListTile(
                value: checked,
                title: Text(textOf(item['name'])),
                subtitle: Text(subtitle),
                secondary: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '编辑',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        final draft = await shoppingItemDialog(
                          context,
                          title: '编辑采购项',
                          initialName: textOf(item['name']),
                          initialAmount: amount,
                          initialCategory: category,
                        );
                        if (draft == null) {
                          return;
                        }
                        try {
                          await context.appRead
                              .patch('/shopping-list/items/$id', body: {
                            'weekStart': dateString(weekStart),
                            ...draft,
                          });
                          onChanged();
                        } catch (error) {
                          if (context.mounted) {
                            showMessage(context, errorText(error));
                          }
                        }
                      },
                    ),
                    IconButton(
                      tooltip: '删除',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        try {
                          await context.appRead
                              .delete('/shopping-list/items/$id', query: {
                            'weekStart': dateString(weekStart),
                          });
                          onChanged();
                        } catch (error) {
                          if (context.mounted) {
                            showMessage(context, errorText(error));
                          }
                        }
                      },
                    ),
                  ],
                ),
                onChanged: (value) async {
                  try {
                    await context.appRead
                        .patch('/shopping-list/items/$id', body: {
                      'weekStart': dateString(weekStart),
                      'checked': value ?? false,
                    });
                    onChanged();
                  } catch (error) {
                    if (context.mounted) {
                      showMessage(context, errorText(error));
                    }
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late Future<dynamic> future;
  String statusFilter = 'open';

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<dynamic> load() => context.appRead.get(
        '/wishlist',
        query: statusFilter == 'all' ? null : {'status': statusFilter},
      );
  void reload() => setState(() {
        future = load();
      });

  void setStatusFilter(String value) => setState(() {
        statusFilter = value;
        future = load();
      });

  Future<void> addWish() async {
    final title = await textDialog(context, title: '想吃什么', hint: '比如：周末想吃番茄牛腩');
    if (title == null || title.trim().isEmpty) {
      return;
    }
    try {
      await context.appRead.post('/wishlist', body: {
        'title': title.trim(),
        'note': '',
        'category': '小家想吃',
        'priority': 'high',
      });
      reload();
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('想吃清单')),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: FutureBuilder<dynamic>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingList();
            }
            if (snapshot.hasError) {
              return ErrorState(
                  message: errorText(snapshot.error!), onRetry: reload);
            }
            final items = wishlistItems(snapshot.data);
            final filterCard = SoftCard(
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'open',
                    label: Text('\u60f3\u5403\u4e2d'),
                    icon: Icon(Icons.favorite_border),
                  ),
                  ButtonSegment(
                    value: 'planned',
                    label: Text('\u5df2\u5b89\u6392'),
                    icon: Icon(Icons.event_available_outlined),
                  ),
                  ButtonSegment(
                    value: 'done',
                    label: Text('\u5df2\u5b8c\u6210'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: 'all',
                    label: Text('\u5168\u90e8'),
                    icon: Icon(Icons.list_alt_outlined),
                  ),
                ],
                selected: {statusFilter},
                onSelectionChanged: (value) => setStatusFilter(value.first),
              ),
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                filterCard,
                const SizedBox(height: 12),
                SoftCard(
                  child: FilledButton.icon(
                    onPressed: addWish,
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('添加想吃'),
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  EmptyState(
                    title:
                        '\u6682\u65f6\u6ca1\u6709${wishlistStatusLabel(statusFilter)}\u9879',
                  )
                else
                  ...items.map(
                      (item) => WishlistCard(item: item, onChanged: reload)),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> wishlistItems(dynamic response) {
  final data = payload(response);
  final items = data is Map
      ? asList(data['items'] ?? data['wishlist'] ?? data['list'])
      : asList(data);
  return items.map(asMap).toList();
}

String wishlistStatusLabel(String status) {
  switch (status) {
    case 'open':
      return '\u60f3\u5403\u4e2d';
    case 'planned':
      return '\u5df2\u5b89\u6392';
    case 'done':
      return '\u5df2\u5b8c\u6210';
    case 'all':
      return '\u5168\u90e8';
    default:
      return '\u60f3\u5403';
  }
}

String wishlistStatusBadgeLabel(Map<String, dynamic> item) {
  final status = textOf(item['status']);
  return wishlistStatusLabel(status.isEmpty ? 'open' : status);
}

bool wishlistIsDone(Map<String, dynamic> item) {
  return textOf(item['status']) == 'done';
}

String wishlistPriorityLabel(String priority) {
  switch (priority) {
    case 'high':
      return '优先想吃';
    case 'low':
      return '随缘想吃';
    case 'normal':
      return '普通想吃';
    default:
      return '普通想吃';
  }
}

List<String> wishlistSignalLabels(Map<String, dynamic> item) {
  final labels = <String>[];
  if (item['createdByPartner'] == true) {
    labels.add('TA 创建');
  }
  if (item['votedByPartner'] == true) {
    labels.add('TA 也投了');
  } else if (item['partnerSignal'] == true) {
    labels.add('TA 想吃');
  }
  if (item['votedByMe'] == true) {
    labels.add('我已投');
  }
  return labels.toSet().toList();
}

String wishlistMealId(Map<String, dynamic> item) {
  final meal = asMap(item['mealId'] ?? item['meal']);
  final nestedId = idOf(meal);
  return nestedId.isNotEmpty ? nestedId : textOf(item['mealId']);
}

String wishlistMealName(Map<String, dynamic> item) {
  final meal = asMap(item['mealId'] ?? item['meal']);
  final name = textOf(meal['name']);
  return name.isNotEmpty ? name : textOf(item['title']);
}

Map<String, String> wishlistMealDraftFields(Map<String, dynamic> item) {
  final title = friendlyText(item['title']).isNotEmpty
      ? friendlyText(item['title'])
      : '\u5c0f\u5bb6\u60f3\u5403';
  final note = friendlyText(item['note']);
  final category = friendlyText(item['category']).isNotEmpty
      ? friendlyText(item['category'])
      : '\u5c0f\u5bb6\u60f3\u5403';
  final tags = <String>{
    '\u60f3\u5403\u6e05\u5355',
    category,
    if (textOf(item['priority']) == 'high') '\u4f18\u5148\u60f3\u5403',
  }.where((item) => item.trim().isNotEmpty).toList();
  return {
    'name': title,
    'description': note.isEmpty
        ? '\u6765\u81ea\u60f3\u5403\u6e05\u5355\uff1a$title'
        : note,
    'category': category,
    'tags': jsonEncode(tags),
    'ingredients': jsonEncode(<Map<String, String>>[]),
    'steps': jsonEncode(<Map<String, String>>[]),
    'tips': '',
    'servingSize': '2',
    'prepTime': '10',
    'cookTime': '30',
    'difficulty': 'easy',
    'taste': jsonEncode(['\u5bb6\u5e38']),
    'healthTags': jsonEncode(['\u5bb6\u5e38', '\u5feb\u624b']),
    'spiceLevel': '0',
    'source': 'wishlist',
    'favorite': 'false',
    'rating': '4.0',
  };
}

Future<String> createMealFromWishlist(
  BuildContext context,
  Map<String, dynamic> item,
) async {
  final response = await context.appRead.multipart(
    'POST',
    '/meals',
    fields: wishlistMealDraftFields(item),
  );
  final mealId = idOf(payload(response));
  if (mealId.isEmpty) {
    throw const ApiException(
        '\u83dc\u8c31\u521b\u5efa\u6210\u529f\u4f46\u6ca1\u6709\u8fd4\u56de\u83dc\u54c1 ID');
  }
  return mealId;
}

class WishlistCard extends StatelessWidget {
  const WishlistCard({super.key, required this.item, required this.onChanged});

  final Map<String, dynamic> item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final id = idOf(item);
    final status =
        textOf(item['status']).isEmpty ? 'open' : textOf(item['status']);
    final isDone = wishlistIsDone(item);
    final isPlanned = status == 'planned';
    final priority = textOf(item['priority']);
    final priorityIcon = priority == 'high'
        ? Icons.local_fire_department_outlined
        : priority == 'low'
            ? Icons.spa_outlined
            : Icons.flag_outlined;
    final signalLabels = wishlistSignalLabels(item);

    Future<void> updateStatus(String nextStatus) async {
      if (id.isEmpty) {
        return;
      }
      try {
        await context.appRead.patch(
          '/wishlist/$id/status',
          body: {'status': nextStatus},
        );
        onChanged();
      } catch (error) {
        if (context.mounted) {
          showMessage(context, errorText(error));
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(textOf(item['title']),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip(
                  wishlistStatusBadgeLabel(item),
                  icon: isDone
                      ? Icons.check_circle_outline
                      : isPlanned
                          ? Icons.event_available_outlined
                          : Icons.favorite_border,
                ),
                InfoChip(
                  wishlistPriorityLabel(priority),
                  icon: priorityIcon,
                ),
                ...signalLabels.map(
                  (label) => InfoChip(
                    label,
                    icon: label == '我已投'
                        ? Icons.thumb_up_alt_outlined
                        : Icons.favorite_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (textOf(item['note']).isNotEmpty) Text(textOf(item['note'])),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.appRead.post('/wishlist/$id/vote');
                    onChanged();
                  },
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  label: Text('投票 ${countText(item['votes'])}'),
                ),
                if (!isPlanned && !isDone)
                  OutlinedButton.icon(
                    onPressed: () => updateStatus('planned'),
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('标记已安排'),
                  ),
                if (!isDone)
                  OutlinedButton.icon(
                    onPressed: () => updateStatus('done'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('\u6807\u8bb0\u5b8c\u6210'),
                  ),
                if (isPlanned || isDone)
                  OutlinedButton.icon(
                    onPressed: () => updateStatus('open'),
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('\u91cd\u65b0\u60f3\u5403'),
                  ),
                if (!isDone)
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await scheduleWishlistForTodayDinner(context, item);
                        onChanged();
                      } catch (error) {
                        if (context.mounted) {
                          showMessage(context, errorText(error));
                        }
                      }
                    },
                    icon: const Icon(Icons.dinner_dining_outlined),
                    label: Text(wishlistDashboardActionLabel(item)),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.appRead.delete('/wishlist/$id');
                    onChanged();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoAlbumPage extends StatefulWidget {
  const PhotoAlbumPage({super.key});

  @override
  State<PhotoAlbumPage> createState() => _PhotoAlbumPageState();
}

class _PhotoAlbumPageState extends State<PhotoAlbumPage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<dynamic> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<dynamic> load() =>
      context.appRead.get('/photo-album', query: {'month': monthString(month)});
  void reload() => setState(() {
        future = load();
      });

  void setMonth(DateTime value) => setState(() {
        month = monthOnly(value);
        future = load();
      });

  Future<Map<String, dynamic>> loadAlbumMemory(
      Map<String, dynamic> photo) async {
    final memoryId = albumPhotoMemoryId(photo);
    if (memoryId.isEmpty) {
      throw const ApiException('这张照片还没有关联饭后回忆');
    }
    final date = albumPhotoDate(photo);
    final response = await context.appRead.get(
      '/memories',
      query: date.isEmpty ? {'month': monthString(month)} : {'date': date},
    );
    for (final item in memoryListFrom(response)) {
      final memory = asMap(item);
      if (idOf(memory) == memoryId) {
        return memory;
      }
    }
    return albumPhotoMemoryFallback(photo);
  }

  Future<void> editAlbumMemory(Map<String, dynamic> photo) async {
    try {
      final memory = await loadAlbumMemory(photo);
      if (!mounted) {
        return;
      }
      final changed = await pushPage(context, MemoryEditPage(memory: memory));
      if (changed == true && mounted) {
        reload();
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> deleteAlbumMemory(Map<String, dynamic> photo) async {
    final memoryId = albumPhotoMemoryId(photo);
    if (memoryId.isEmpty) {
      showMessage(context, '这张照片还没有关联饭后回忆');
      return;
    }
    final confirmed = await confirmDialog(
      context,
      title: '删除回忆',
      message: '删除后这条饭后回忆和其中的照片都会从相册里移除。',
      confirmText: '删除',
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await context.appRead.delete('/memories/$memoryId');
      if (mounted) {
        showMessage(context, '已删除回忆');
        reload();
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  void showPhotoDetail(Map<String, dynamic> photo) {
    final url = imageUrl(photo['url'] ?? photo['photo'] ?? photo['src']);
    final title =
        textOf(photo['title']).isEmpty ? '一张饭桌照片' : textOf(photo['title']);
    final date = textOf(photo['date']).split('T').first;
    final mood = textOf(photo['mood']);
    final note = textOf(photo['note'] ?? photo['remark']);
    final meals = photoMealNames(photo);
    final memoryId = albumPhotoMemoryId(photo);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SoftCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 11,
                      child: RemoteImage(url: url),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (date.isNotEmpty)
                                InfoChip(date, icon: Icons.calendar_today),
                              if (mood.isNotEmpty)
                                InfoChip(mood, icon: Icons.favorite_outline),
                              ...meals.take(3).map((item) => InfoChip(
                                    item,
                                    icon: Icons.restaurant_menu,
                                  )),
                            ],
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(note),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: memoryId.isEmpty
                                    ? null
                                    : () {
                                        Navigator.pop(sheetContext);
                                        editAlbumMemory(photo);
                                      },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('编辑回忆'),
                              ),
                              TextButton.icon(
                                onPressed: memoryId.isEmpty
                                    ? null
                                    : () {
                                        Navigator.pop(sheetContext);
                                        deleteAlbumMemory(photo);
                                      },
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('删除'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close),
                              label: const Text('收起'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('饭桌相册')),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: FutureBuilder<dynamic>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingList();
            }
            if (snapshot.hasError) {
              return ErrorState(
                  message: errorText(snapshot.error!), onRetry: reload);
            }
            final photos = photoItems(snapshot.data);
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SoftCard(
                    child: MonthSwitcher(
                      month: month,
                      suffix: '饭桌相册',
                      onChanged: setMonth,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (photos.isEmpty)
                    const EmptyState(title: '这个月还没有饭桌照片')
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        return HoverLift(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => showPhotoDetail(photo),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: GridTile(
                                footer: Container(
                                  color: kCoffee.withValues(alpha: 0.62),
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    textOf(photo['title']).isEmpty
                                        ? textOf(photo['date'])
                                        : textOf(photo['title']),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                child: RemoteImage(
                                    url: imageUrl(photo['url'] ??
                                        photo['photo'] ??
                                        photo['src'])),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> photoItems(dynamic response) {
  final data = payload(response);
  final items = data is Map
      ? asList(data['photos'] ?? data['items'] ?? data['list'])
      : asList(data);
  return items.map((item) {
    if (item is String) {
      return {'url': item};
    }
    return asMap(item);
  }).toList();
}

String albumPhotoMemoryId(Map<String, dynamic> photo) {
  final nestedMemory = asMap(photo['memory']);
  return textOf(photo['memoryId'] ??
      photo['memory_id'] ??
      photo['memoryID'] ??
      nestedMemory['_id'] ??
      nestedMemory['id']);
}

String albumPhotoDate(Map<String, dynamic> photo) =>
    textOf(photo['date']).split('T').first;

Map<String, dynamic> albumPhotoMemoryFallback(Map<String, dynamic> photo) {
  final photoRef = textOf(photo['photo'] ?? photo['url'] ?? photo['src']);
  return {
    '_id': albumPhotoMemoryId(photo),
    'date': albumPhotoDate(photo),
    'mealType': photo['mealType'],
    'title': photo['title'],
    'mood': photo['mood'],
    'note': photo['note'] ?? photo['remark'],
    'rating': photo['rating'],
    'actualCookTime': photo['actualCookTime'],
    'nextImprovement': photo['nextImprovement'],
    'photos': photoRef.isEmpty ? const <String>[] : [photoRef],
    'mealIds': photo['meals'] ?? photo['mealIds'] ?? const <dynamic>[],
  };
}

List<String> photoMealNames(Map<String, dynamic> photo) {
  final names = <String>[
    ...mealNames(photo['meals'] ?? photo['mealIds']),
  ];
  final singleMeal = asMap(photo['meal']);
  final singleName = textOf(singleMeal['name'] ?? singleMeal['title']);
  if (singleName.isNotEmpty) {
    names.add(singleName);
  }
  return names.where((item) => item.trim().isNotEmpty).toSet().toList();
}

enum ReviewScope { month, year }

List<String> reviewNextStepHints(Map<String, dynamic> data) {
  final summary = asMap(data['summary'] ?? data);
  final planned = intValue(summary['plannedMealCount']);
  final memories = intValue(summary['memoryCount']);
  final photos = intValue(summary['photoCount']);
  final wishlistOpen = intValue(summary['wishlistOpen']);
  final topMeals = asList(data['topMeals']);
  final hints = <String>[];

  if (planned == 0) {
    hints.add('先安排一顿这个周期最想吃的饭');
  }
  if (memories == 0) {
    hints.add('吃完后补一条饭后回忆，留下今天的味道');
  }
  if (photos == 0) {
    hints.add('下次开饭前拍一张饭桌照片');
  }
  if (wishlistOpen > 0) {
    hints.add('把 1 个想吃愿望安排进最近的晚餐');
  }
  if (planned > 0 && topMeals.isEmpty) {
    hints.add('多安排几顿后会形成常上桌菜榜');
  }
  if (hints.isEmpty) {
    hints.add('给最喜欢的一道菜补充做法、照片或小技巧');
  }

  return hints.take(3).toList();
}

class TableReviewPage extends StatefulWidget {
  const TableReviewPage({super.key});

  @override
  State<TableReviewPage> createState() => _TableReviewPageState();
}

class _TableReviewPageState extends State<TableReviewPage> {
  ReviewScope scope = ReviewScope.month;
  DateTime anchor = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<dynamic> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<dynamic> load() {
    if (scope == ReviewScope.year) {
      return context.appRead
          .get('/review/yearly', query: {'year': anchor.year.toString()});
    }
    return context.appRead
        .get('/review/monthly', query: {'month': monthString(anchor)});
  }

  void reload() => setState(() {
        future = load();
      });

  void changePeriod(int delta) {
    setState(() {
      anchor = scope == ReviewScope.year
          ? DateTime(anchor.year + delta, 1)
          : DateTime(anchor.year, anchor.month + delta);
      future = load();
    });
  }

  void changeScope(Set<ReviewScope> values) {
    if (values.isEmpty) return;
    setState(() {
      scope = values.first;
      anchor = DateTime(DateTime.now().year, DateTime.now().month);
      future = load();
    });
  }

  String get titleText => scope == ReviewScope.year
      ? '${anchor.year} 年饭桌回顾'
      : '${anchor.year} 年 ${anchor.month} 月饭桌回顾';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('饭桌回顾')),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: FutureBuilder<dynamic>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingList();
            }
            if (snapshot.hasError) {
              return ErrorState(
                  message: errorText(snapshot.error!), onRetry: reload);
            }
            final data = asMap(payload(snapshot.data));
            final summary = asMap(data['summary']);
            final topMeals = asList(data['topMeals']).map(asMap).toList();
            final photos = asList(data['photos']).map(asMap).toList();
            final bestMemory = asMap(data['bestMemory']);
            final nextSteps = reviewNextStepHints(data);
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  SoftCard(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF1E8), Color(0xFFFFD9C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const BrandMark(size: 58, compact: true),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleText,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: kCoffee,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    textOf(summary['sentence']).isEmpty
                                        ? '这一页会把你们的小家饭桌整理成一份温柔回顾。'
                                        : textOf(summary['sentence']),
                                    style: const TextStyle(
                                      color: kCocoa,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => changePeriod(-1),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Expanded(
                              child: Center(
                                child: SegmentedButton<ReviewScope>(
                                  segments: const [
                                    ButtonSegment(
                                      value: ReviewScope.month,
                                      label: Text('本月'),
                                      icon: Icon(Icons.calendar_view_month),
                                    ),
                                    ButtonSegment(
                                      value: ReviewScope.year,
                                      label: Text('今年'),
                                      icon: Icon(Icons.auto_graph),
                                    ),
                                  ],
                                  selected: {scope},
                                  onSelectionChanged: changeScope,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => changePeriod(1),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      DashboardTile(
                        icon: Icons.rate_review_outlined,
                        label: '饭后回忆',
                        value: countText(summary['memoryCount']),
                        color: const Color(0xFFFF8D7E),
                      ),
                      DashboardTile(
                        icon: Icons.restaurant_menu,
                        label: '安排餐次',
                        value: countText(summary['plannedMealCount']),
                        color: const Color(0xFFE09F67),
                      ),
                      DashboardTile(
                        icon: Icons.photo_library_outlined,
                        label: '饭桌照片',
                        value: countText(summary['photoCount']),
                        color: const Color(0xFF9E8B73),
                      ),
                      DashboardTile(
                        icon: Icons.favorite_outline,
                        label: '还想吃',
                        value: countText(summary['wishlistOpen']),
                        color: const Color(0xFF8AA36B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (nextSteps.isNotEmpty) ...[
                    ReviewNextStepsCard(hints: nextSteps),
                    const SizedBox(height: 14),
                  ],
                  ReviewTopMealsCard(meals: topMeals),
                  const SizedBox(height: 14),
                  ReviewChipsCard(
                    title: '饭桌关键词',
                    icon: Icons.local_offer_outlined,
                    groups: [
                      ReviewChipGroup(
                          label: '心情', items: asList(data['moodStats'])),
                      ReviewChipGroup(
                          label: '分类', items: asList(data['categoryStats'])),
                      ReviewChipGroup(
                          label: '均衡',
                          items: asList(data['healthTagStats']),
                          nameKey: 'tag'),
                    ],
                  ),
                  if (bestMemory.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ReviewBestMemoryCard(memory: bestMemory),
                  ],
                  const SizedBox(height: 14),
                  ReviewPhotoWall(photos: photos),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ReviewNextStepsCard extends StatelessWidget {
  const ReviewNextStepsCard({super.key, required this.hints});

  final List<String> hints;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF8EA), Color(0xFFFFE6D6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.flag_outlined,
            title: '下个饭桌小目标',
          ),
          const SizedBox(height: 10),
          ...hints.map(
            (hint) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: kCoral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint,
                      style: const TextStyle(
                        color: kCoffee,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => pushPage(context, const WeeklyPlanPage()),
                icon: const Icon(Icons.calendar_view_week_outlined),
                label: const Text('去排餐'),
              ),
              OutlinedButton.icon(
                onPressed: () => pushPage(context, const MemoryEditPage()),
                icon: const Icon(Icons.auto_stories_outlined),
                label: const Text('记一顿饭'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReviewTopMealsCard extends StatelessWidget {
  const ReviewTopMealsCard({super.key, required this.meals});

  final List<Map<String, dynamic>> meals;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: Icons.emoji_events_outlined, title: '常上桌的菜'),
          const SizedBox(height: 10),
          if (meals.isEmpty)
            const Text('还没有足够的菜品记录，安排几顿饭后这里会自动出现。')
          else
            ...meals.take(6).map((meal) {
              final image = imageUrl(meal['imageUrl']);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: RemoteImage(url: image),
                  ),
                ),
                title: Text(
                  textOf(meal['name']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '出现 ${countText(meal['count'])} 次 · 回忆 ${countText(meal['memoryCount'])} 次',
                ),
                trailing: textOf(meal['averageRating']) == '0'
                    ? null
                    : InfoChip('${textOf(meal['averageRating'])} 分'),
              );
            }),
        ],
      ),
    );
  }
}

class ReviewChipGroup {
  const ReviewChipGroup({
    required this.label,
    required this.items,
    this.nameKey = 'mood',
  });

  final String label;
  final List<dynamic> items;
  final String nameKey;
}

class ReviewChipsCard extends StatelessWidget {
  const ReviewChipsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.groups,
  });

  final String title;
  final IconData icon;
  final List<ReviewChipGroup> groups;

  @override
  Widget build(BuildContext context) {
    final visibleGroups = groups
        .map((group) => ReviewChipGroup(
            label: group.label,
            nameKey: group.nameKey,
            items: group.items.map(asMap).where((item) {
              final name = textOf(item[group.nameKey] ?? item['category']);
              return name.isNotEmpty;
            }).toList()))
        .where((group) => group.items.isNotEmpty)
        .toList();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(icon: icon, title: title),
          const SizedBox(height: 10),
          if (visibleGroups.isEmpty)
            const Text('还没有形成明显关键词，多记录几顿饭后会更有意思。')
          else
            ...visibleGroups.map((group) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.label,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: group.items.take(8).map((raw) {
                          final item = asMap(raw);
                          final name = textOf(item[group.nameKey] ??
                              item['category'] ??
                              item['tag']);
                          return InfoChip('$name ${countText(item['count'])}');
                        }).toList(),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class ReviewBestMemoryCard extends StatelessWidget {
  const ReviewBestMemoryCard({super.key, required this.memory});

  final Map<String, dynamic> memory;

  @override
  Widget build(BuildContext context) {
    final photos = asList(memory['photos']).map(imageUrl).toList();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: Icons.favorite_outline, title: '最值得记住的一顿'),
          const SizedBox(height: 10),
          Text(
            textOf(memory['title']).isEmpty
                ? '一顿值得记住的饭'
                : textOf(memory['title']),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '${textOf(memory['date'])} · ${mealTypeLabel(textOf(memory['mealType']))} · ${countText(memory['rating'])} 分',
            style: const TextStyle(color: kCocoa, fontWeight: FontWeight.w800),
          ),
          if (textOf(memory['note']).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(textOf(memory['note'])),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: RemoteImage(url: photos.first),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ReviewPhotoWall extends StatelessWidget {
  const ReviewPhotoWall({super.key, required this.photos});

  final List<Map<String, dynamic>> photos;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
              icon: Icons.photo_library_outlined, title: '饭桌照片墙'),
          const SizedBox(height: 10),
          if (photos.isEmpty)
            const Text('这个周期还没有照片，下一顿饭可以拍一张留给以后。')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length.clamp(0, 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: RemoteImage(
                      url: imageUrl(photo['photo'] ?? photo['url'])),
                );
              },
            ),
        ],
      ),
    );
  }
}

class AnniversaryPage extends StatefulWidget {
  const AnniversaryPage({super.key});

  @override
  State<AnniversaryPage> createState() => _AnniversaryPageState();
}

class _AnniversaryPageState extends State<AnniversaryPage> {
  late Future<List<dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<List<dynamic>> load() async {
    final list = await context.appRead.get('/anniversaries');
    return asList(payload(list is Map ? list['data'] ?? list : list));
  }

  void reload() => setState(() {
        future = load();
      });

  Future<List<Map<String, dynamic>>> loadTemplates() async {
    final response = await context.appRead.get('/anniversary-templates');
    return anniversaryTemplates(response);
  }

  Future<Map<String, dynamic>?> chooseTemplate(
    List<Map<String, dynamic>> templates,
  ) {
    if (templates.isEmpty) {
      return Future.value(<String, dynamic>{});
    }
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnniversaryTemplatePicker(templates: templates),
    );
  }

  Future<void> create() async {
    try {
      final template = await chooseTemplate(await loadTemplates());
      if (template == null) {
        return;
      }
      final date = await textDialog(
        context,
        title: '纪念日日期',
        hint: '例如：${dateString(DateTime.now())}',
        initial: dateString(DateTime.now()),
      );
      final dateText = date?.trim() ?? '';
      if (!isDateText(dateText)) {
        if (mounted) {
          showMessage(context, '请填写 YYYY-MM-DD 格式的日期');
        }
        return;
      }
      await context.appRead.post('/anniversaries', body: {
        'title': textOf(template['title']).isEmpty
            ? '周末小家宴'
            : textOf(template['title']),
        'date': dateText,
        'description': anniversaryTemplateDescription(template),
        'theme': textOf(template['theme']).isEmpty
            ? '温馨小家'
            : textOf(template['theme']),
        'meals': {'breakfast': [], 'lunch': [], 'dinner': []},
      });
      reload();
      if (mounted) {
        showMessage(context, '已创建纪念日菜单');
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('纪念日菜单')),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: FutureBuilder<List<dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingList();
            }
            if (snapshot.hasError) {
              return ErrorState(
                  message: errorText(snapshot.error!), onRetry: reload);
            }
            final items = anniversarySortedMenus(
              (snapshot.data ?? const []).map(asMap).toList(),
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(
                        icon: Icons.celebration_outlined,
                        title: '纪念日菜单模板',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '生日、恋爱纪念日、节日聚餐和周末小家宴都可以从模板开始，再慢慢补菜品和照片。',
                        style: TextStyle(
                          color: kCocoa,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: create,
                        icon: const Icon(Icons.celebration_outlined),
                        label: const Text('选择模板创建菜单'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const EmptyState(title: '还没有纪念日菜单')
                else
                  ...items.map((item) => AnniversaryMenuCard(
                        item: item,
                        onChanged: reload,
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> anniversaryTemplates(dynamic response) {
  final data = payload(response);
  final items = data is Map
      ? asList(
          data['templates'] ?? data['items'] ?? data['list'] ?? data['value'])
      : asList(data);
  return items.map(asMap).where((item) => item.isNotEmpty).toList();
}

List<String> anniversaryTemplateStructure(Map<String, dynamic> template) {
  return asList(template['structure'])
      .map(textOf)
      .where((item) => item.trim().isNotEmpty)
      .toList();
}

String anniversaryTemplateDescription(Map<String, dynamic> template) {
  final description = textOf(template['description']).trim();
  final structure = anniversaryTemplateStructure(template);
  if (structure.isEmpty) {
    return description;
  }
  final structureText = '建议结构：${structure.join('、')}';
  return description.isEmpty ? structureText : '$description\n$structureText';
}

bool isDateText(String value) =>
    RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim());

DateTime? anniversaryLocalDate(dynamic value) {
  final text = textOf(value).split('T').first.trim();
  if (!isDateText(text)) {
    return null;
  }
  final parts = text.split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.any((item) => item == null)) {
    return null;
  }
  try {
    return DateTime(parts[0]!, parts[1]!, parts[2]!);
  } catch (_) {
    return null;
  }
}

int? anniversaryDaysUntil(
  Map<String, dynamic> item, {
  DateTime? today,
}) {
  final date = anniversaryLocalDate(item['date']);
  if (date == null) {
    return null;
  }
  final now = today ?? DateTime.now();
  final localToday = DateTime(now.year, now.month, now.day);
  return date.difference(localToday).inDays;
}

String anniversaryCountdownLabel(
  Map<String, dynamic> item, {
  DateTime? today,
}) {
  final days = anniversaryDaysUntil(item, today: today);
  if (days == null) {
    return '日期待定';
  }
  if (days == 0) {
    return '今天就是纪念日';
  }
  if (days > 0) {
    return '还有 $days 天';
  }
  return '已过 ${days.abs()} 天';
}

List<Map<String, dynamic>> anniversarySortedMenus(
  List<Map<String, dynamic>> items, {
  DateTime? today,
}) {
  final sorted = [...items];
  int score(Map<String, dynamic> item) {
    final days = anniversaryDaysUntil(item, today: today);
    if (days == null) {
      return 1 << 30;
    }
    if (days >= 0) {
      return days;
    }
    return 100000 + days.abs();
  }

  sorted.sort((left, right) {
    final byDate = score(left).compareTo(score(right));
    if (byDate != 0) {
      return byDate;
    }
    return textOf(left['title']).compareTo(textOf(right['title']));
  });
  return sorted;
}

class AnniversaryTemplatePicker extends StatelessWidget {
  const AnniversaryTemplatePicker({super.key, required this.templates});

  final List<Map<String, dynamic>> templates;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SoftCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.celebration_outlined,
                title: '选择纪念日模板',
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final structure = anniversaryTemplateStructure(template);
                    return InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Navigator.pop(context, template),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kPaper,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: kLine),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: kPeach.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: kCoral,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        textOf(template['title']).isEmpty
                                            ? '温馨小家菜单'
                                            : textOf(template['title']),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      if (textOf(template['theme']).isNotEmpty)
                                        Text(
                                          textOf(template['theme']),
                                          style: const TextStyle(
                                            color: kCocoa,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (textOf(template['description']).isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(textOf(template['description'])),
                            ],
                            if (structure.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: structure
                                    .map((item) => InfoChip(
                                          item,
                                          icon: Icons.restaurant_menu,
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnniversaryMenuCard extends StatelessWidget {
  const AnniversaryMenuCard({
    super.key,
    required this.item,
    required this.onChanged,
  });

  final Map<String, dynamic> item;
  final VoidCallback onChanged;

  Future<void> addToShoppingList(BuildContext context) async {
    try {
      await addScheduleIngredientsToShoppingList(
        context,
        item,
        emptyMessage: '这个纪念日菜单还没有选择菜品，先编辑菜单再生成采购项。',
        noIngredientsMessage: '纪念日菜单里的菜还没有食材，先在菜谱里补充食材。',
        allExistingMessage: '纪念日菜单食材已经在本周购物清单里',
        addedMessageBuilder: (count) => '已加入纪念日菜单食材（$count 项）',
      );
    } catch (error) {
      if (context.mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> remove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除纪念日菜单'),
        content: Text('确认删除「${textOf(item['title'])}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await context.appRead.delete('/anniversaries/${idOf(item)}');
      onChanged();
      if (context.mounted) {
        showMessage(context, '已删除纪念日菜单');
      }
    } catch (error) {
      if (context.mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meals = anniversaryMenuMealNames(item);
    final countdown = anniversaryCountdownLabel(item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.celebration_outlined),
              ),
              title: Text(
                textOf(item['title']).isEmpty ? '纪念日菜单' : textOf(item['title']),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                textOf(item['date']).split('T').first,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip(countdown, icon: Icons.event_available_outlined),
                if (textOf(item['theme']).isNotEmpty)
                  InfoChip(textOf(item['theme']),
                      icon: Icons.local_florist_outlined),
              ],
            ),
            if (textOf(item['description']).isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(textOf(item['description'])),
            ],
            if (meals.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: meals
                    .take(6)
                    .map((item) => InfoChip(
                          item,
                          icon: Icons.restaurant_menu,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final changed = await pushPage(
                      context,
                      AnniversaryMenuEditPage(item: item),
                    );
                    if (changed == true) {
                      onChanged();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑菜单'),
                ),
                OutlinedButton.icon(
                  onPressed: () => addToShoppingList(context),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('加入购物清单'),
                ),
                OutlinedButton.icon(
                  onPressed: () => remove(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AnniversaryMenuEditPage extends StatefulWidget {
  const AnniversaryMenuEditPage({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  State<AnniversaryMenuEditPage> createState() =>
      _AnniversaryMenuEditPageState();
}

class _AnniversaryMenuEditPageState extends State<AnniversaryMenuEditPage> {
  late final TextEditingController titleController;
  late final TextEditingController dateController;
  late final TextEditingController themeController;
  late final TextEditingController descriptionController;
  late Future<dynamic> mealsFuture;
  late Map<String, Set<String>> selectedMeals;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: textOf(widget.item['title']));
    dateController = TextEditingController(
        text: textOf(widget.item['date']).split('T').first);
    themeController = TextEditingController(text: textOf(widget.item['theme']));
    descriptionController =
        TextEditingController(text: textOf(widget.item['description']));
    selectedMeals = anniversaryMenuMealIds(widget.item)
        .map((key, value) => MapEntry(key, value.toSet()));
    mealsFuture = context.appRead.get('/meals', query: {'limit': '200'});
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    themeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void toggleMeal(String type, String id) {
    setState(() {
      final bucket = selectedMeals.putIfAbsent(type, () => <String>{});
      bucket.contains(id) ? bucket.remove(id) : bucket.add(id);
    });
  }

  Future<void> save() async {
    final title = titleController.text.trim();
    final date = dateController.text.trim();
    if (title.isEmpty) {
      showMessage(context, '请填写菜单标题');
      return;
    }
    if (!isDateText(date)) {
      showMessage(context, '请填写 YYYY-MM-DD 格式的日期');
      return;
    }
    setState(() => saving = true);
    try {
      await context.appRead.put('/anniversaries/${idOf(widget.item)}', body: {
        'title': title,
        'date': date,
        'theme': themeController.text.trim(),
        'description': descriptionController.text.trim(),
        'meals': {
          for (final type in mealTypes)
            type: (selectedMeals[type] ?? <String>{}).toList(),
        },
        'existingPhotos': asList(widget.item['photos']),
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编辑纪念日菜单')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: saving ? null : save,
            icon: const Icon(Icons.save_outlined),
            label: Text(saving ? '保存中...' : '保存菜单'),
          ),
        ),
      ),
      body: AppBackdrop(
        alignment: Alignment.topCenter,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '标题'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateController,
                    decoration:
                        const InputDecoration(labelText: '日期 YYYY-MM-DD'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: themeController,
                    decoration: const InputDecoration(labelText: '主题'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: '备注和菜单结构'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<dynamic>(
              future: mealsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingList();
                }
                if (snapshot.hasError) {
                  return ErrorState(
                    message: errorText(snapshot.error!),
                    onRetry: () => setState(() {
                      mealsFuture = context.appRead
                          .get('/meals', query: {'limit': '200'});
                    }),
                  );
                }
                final meals = mealListFrom(snapshot.data)
                    .map(asMap)
                    .where((meal) => idOf(meal).isNotEmpty)
                    .toList();
                return SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        icon: Icons.restaurant_menu,
                        title: '选择菜单菜品',
                      ),
                      const SizedBox(height: 8),
                      ...mealTypes.map((type) => ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            initiallyExpanded: type == 'dinner',
                            title: Text(
                              '${mealTypeLabel(type)} ${(selectedMeals[type] ?? <String>{}).length} 道',
                            ),
                            children: meals.map((meal) {
                              final id = idOf(meal);
                              return CheckboxListTile(
                                value: (selectedMeals[type] ?? <String>{})
                                    .contains(id),
                                title: Text(textOf(meal['name'])),
                                subtitle: Text(textOf(meal['category'])),
                                onChanged: (_) => toggleMeal(type, id),
                              );
                            }).toList(),
                          )),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

const mealTypes = ['breakfast', 'lunch', 'dinner'];

List<String> anniversaryMenuMealNames(Map<String, dynamic> item) {
  final meals = asMap(item['meals']);
  final names = <String>[];
  for (final type in mealTypes) {
    names.addAll(mealNames(meals[type]));
  }
  return names.where((item) => item.trim().isNotEmpty).toSet().toList();
}

Map<String, List<String>> anniversaryMenuMealIds(Map<String, dynamic> item) {
  final meals = asMap(item['meals']);
  return {
    for (final type in mealTypes) type: mealIdsFromPlanValue(meals[type]),
  };
}

String householdInviteCode(Map<String, dynamic> household) {
  return friendlyText(household['inviteCode']).toUpperCase();
}

String normalizeInviteCode(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
}

List<Map<String, dynamic>> householdMembers(Map<String, dynamic> household) {
  return asList(household['members'])
      .map(asMap)
      .where((member) => member.isNotEmpty)
      .toList();
}

String householdMemberName(Map<String, dynamic> member) {
  final displayName = friendlyText(member['displayName']);
  if (displayName.isNotEmpty) {
    return displayName;
  }
  final username = friendlyText(member['username']);
  if (username.isNotEmpty) {
    return username;
  }
  final id = idOf(member);
  return id.isEmpty ? '小家成员' : id;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<dynamic> defaultStatusFuture;
  late Future<dynamic> issuesFuture;
  late Future<List<ApiEndpointStatus>> apiStatusFuture;

  @override
  void initState() {
    super.initState();
    defaultStatusFuture = context.appRead.get('/default-meals/status');
    issuesFuture =
        context.appRead.get('/meal-image-issues', query: {'status': 'open'});
    apiStatusFuture = context.appRead.checkApiEndpoints();
  }

  void reload() {
    setState(() {
      defaultStatusFuture = context.appRead.get('/default-meals/status');
      issuesFuture =
          context.appRead.get('/meal-image-issues', query: {'status': 'open'});
    });
  }

  void reloadApiStatus() {
    setState(() {
      apiStatusFuture = context.appRead.checkApiEndpoints();
    });
  }

  Future<void> copyInviteCode() async {
    final code = householdInviteCode(context.appRead.household ?? const {});
    if (code.isEmpty) {
      showMessage(context, '当前小家还没有邀请码');
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      showMessage(context, '已复制邀请码：$code');
    }
  }

  Future<void> refreshInviteCode() async {
    final confirmed = await confirmDialog(
      context,
      title: '刷新邀请码',
      message: '刷新后旧邀请码会失效，已经加入小家的成员不受影响。确认生成新的邀请码吗？',
      confirmText: '刷新',
    );
    if (!confirmed) {
      return;
    }
    try {
      await context.appRead.post('/household/invite/refresh');
      await context.appRead.refreshMe();
      final code = householdInviteCode(context.appRead.household ?? const {});
      if (mounted) {
        showMessage(context, code.isEmpty ? '已刷新邀请码' : '新邀请码：$code');
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> joinHousehold() async {
    final rawCode = await textDialog(
      context,
      title: '加入 TA 的小家',
      hint: '输入 TA 发给你的 6 位邀请码',
    );
    final code = normalizeInviteCode(rawCode ?? '');
    if (code.isEmpty) {
      return;
    }
    final confirmed = await confirmDialog(
      context,
      title: '确认加入小家',
      message: '加入后会切换到对方的小家，共享菜谱、日历、回忆和购物清单。确认继续吗？',
      confirmText: '加入',
    );
    if (!confirmed) {
      return;
    }
    try {
      await context.appRead.post('/household/join', body: {'inviteCode': code});
      await context.appRead.refreshMe();
      if (mounted) {
        showMessage(context, '已加入 ${context.appRead.householdName}');
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> updateHousehold() async {
    final name = await textDialog(context,
        title: '修改小家名称', initial: context.appRead.householdName);
    if (name == null || name.trim().isEmpty) {
      return;
    }
    try {
      await context.appRead.put('/household/me', body: {'name': name.trim()});
      await context.appRead.refreshMe();
      if (mounted) {
        showMessage(context, '已更新小家名称');
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> updateProfile() async {
    final name = await textDialog(context,
        title: '修改昵称', initial: context.appRead.displayName);
    if (name == null || name.trim().isEmpty) {
      return;
    }
    try {
      await context.appRead
          .put('/auth/profile', body: {'displayName': name.trim()});
      await context.appRead.refreshMe();
      if (mounted) {
        showMessage(context, '已更新昵称');
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> importDefaults() async {
    try {
      await context.appRead.post('/default-meals/import-missing');
      reload();
      if (mounted) {
        showMessage(context, '已导入缺失默认菜品');
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> restoreImages() async {
    try {
      await context.appRead.post('/default-meals/restore-images');
      reload();
      if (mounted) {
        showMessage(context, '已恢复默认菜品图片');
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final household = context.app.household ?? const {};
    final inviteCode = householdInviteCode(household);
    final members = householdMembers(household);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                  icon: Icons.home_outlined, title: context.app.householdName),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.app.themePalette.secondary
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: context.app.themePalette.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.key_outlined,
                        color: context.app.themePalette.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '小家邀请码',
                            style: TextStyle(
                              color: context.app.themePalette.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            inviteCode.isEmpty ? '暂无' : inviteCode,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FilledButton.icon(
                          onPressed: inviteCode.isEmpty ? null : copyInviteCode,
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('复制'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: refreshInviteCode,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('刷新'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (members.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  '小家成员',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final member in members)
                      HouseholdMemberChip(member: member),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: updateProfile,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('修改昵称'),
                  ),
                  OutlinedButton.icon(
                    onPressed: updateHousehold,
                    icon: const Icon(Icons.home_work_outlined),
                    label: const Text('修改小家'),
                  ),
                  OutlinedButton.icon(
                    onPressed: joinHousehold,
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text('加入小家'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.appRead.logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('退出登录'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<ApiEndpointStatus>>(
          future: apiStatusFuture,
          builder: (context, snapshot) {
            final statuses = snapshot.data ?? const <ApiEndpointStatus>[];
            final checking =
                snapshot.connectionState == ConnectionState.waiting;
            final allOk =
                statuses.isNotEmpty && statuses.every((item) => item.ok);
            return SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    icon: allOk
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_sync_outlined,
                    title: '服务器连接检测',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    checking
                        ? '正在检测主入口和备用入口...'
                        : allOk
                            ? '主入口和备用入口都可用，APP 会在网络异常时自动兜底。'
                            : '如果主入口不可用，APP 会优先尝试备用入口；失败信息如下。',
                    style: const TextStyle(
                      color: kCocoa,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (checking && statuses.isEmpty)
                    const LinearProgressIndicator(minHeight: 4)
                  else
                    ...statuses.map((status) => ApiEndpointStatusTile(
                          status: status,
                        )),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: checking ? null : reloadApiStatus,
                    icon: checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('重新检测'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                  icon: Icons.verified_user_outlined, title: '登录管理'),
              const SizedBox(height: 8),
              Text(
                context.app.isAuthed ? '已开启免登录，下次打开会直接进入小家。' : '当前未登录。',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text('上次登录：${dateTimeMinuteText(context.app.lastLoginAt)}'),
              Text('登录有效期：${dateTimeMinuteText(context.app.tokenExpiresAt)}'),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.appRead.logout(),
                icon: const Icon(Icons.logout),
                label: const Text('退出并重新登录'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: Icons.palette_outlined, title: '主题风格'),
              const SizedBox(height: 8),
              const Text(
                '选择更适合你们小家的饭桌氛围，颜色会同步到首页、导航、卡片和按钮。',
                style: TextStyle(color: kCocoa, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final palette in kThemePalettes)
                    ThemeChoiceCard(
                      palette: palette,
                      selected: context.app.themeKey == palette.key,
                      onTap: () => context.appRead.setThemeKey(palette.key),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: Icons.apps_outlined, title: '功能入口'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton(
                      onPressed: () =>
                          pushPage(context, const WeeklyPlanPage()),
                      child: const Text('本周计划')),
                  OutlinedButton(
                      onPressed: () =>
                          pushPage(context, const ShoppingListPage()),
                      child: const Text('购物清单')),
                  OutlinedButton(
                      onPressed: () => pushPage(context, const WishlistPage()),
                      child: const Text('想吃清单')),
                  OutlinedButton(
                      onPressed: () =>
                          pushPage(context, const PhotoAlbumPage()),
                      child: const Text('饭桌相册')),
                  OutlinedButton(
                      onPressed: () =>
                          pushPage(context, const TableReviewPage()),
                      child: const Text('饭桌回顾')),
                  OutlinedButton(
                      onPressed: () =>
                          pushPage(context, const AnniversaryPage()),
                      child: const Text('纪念日菜单')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<dynamic>(
          future: defaultStatusFuture,
          builder: (context, snapshot) {
            final data = snapshot.hasData
                ? asMap(payload(snapshot.data))
                : const <String, dynamic>{};
            return SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                      icon: Icons.restaurant_menu, title: '默认菜品管理'),
                  const SizedBox(height: 8),
                  Text(
                      '总数：${countText(data['total'] ?? data['defaultTotal'])}  已导入：${countText(data['imported'] ?? data['importedCount'])}  缺失：${countText(data['missing'] ?? data['missingCount'])}'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: importDefaults,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('导入缺失默认菜品'),
                      ),
                      OutlinedButton.icon(
                        onPressed: restoreImages,
                        icon: const Icon(Icons.image_search_outlined),
                        label: const Text('恢复默认图片'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<dynamic>(
          future: issuesFuture,
          builder: (context, snapshot) {
            final issues = snapshot.hasData
                ? imageIssues(snapshot.data)
                : const <Map<String, dynamic>>[];
            return SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                      icon: Icons.report_outlined,
                      title: '待修正图片 ${issues.length}'),
                  const SizedBox(height: 8),
                  if (issues.isEmpty)
                    const Text('当前没有待修正图片。')
                  else
                    ...issues.map(
                      (issue) => ImageIssueTile(
                        issue: issue,
                        onChanged: reload,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class HouseholdMemberChip extends StatelessWidget {
  const HouseholdMemberChip({super.key, required this.member});

  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final palette = context.app.themePalette;
    final name = householdMemberName(member);
    final username = friendlyText(member['username']);
    final initial = name.trim().isEmpty
        ? '家'
        : String.fromCharCode(name.trim().runes.first);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: palette.secondary.withValues(alpha: 0.38),
            child: Text(
              initial,
              style: TextStyle(
                color: palette.text,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              if (username.isNotEmpty && username != name)
                Text(
                  '@$username',
                  style: TextStyle(
                    color: palette.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ApiEndpointStatusTile extends StatelessWidget {
  const ApiEndpointStatusTile({super.key, required this.status});

  final ApiEndpointStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.app.themePalette;
    final color = status.ok ? palette.success : palette.accent;
    final statusText = status.ok ? '可用' : '不可用';
    final httpCode = status.statusCode == null ? '' : ' ${status.statusCode}';
    final elapsed = '${status.elapsed.inMilliseconds}ms';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              status.ok ? Icons.check_circle_outline : Icons.error_outline,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apiBaseLabel(status.apiBase),
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${status.healthUri}  $elapsed',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (status.message.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    status.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          InfoChip('$statusText$httpCode', icon: Icons.lan_outlined),
        ],
      ),
    );
  }
}

class ThemeChoiceCard extends StatelessWidget {
  const ThemeChoiceCard({
    super.key,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: 178,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? palette.secondary.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? palette.accent : palette.line,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    palette.label,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: selected ? 1 : 0.75,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? palette.accent : palette.muted,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ThemeTablePreview(palette: palette),
            const SizedBox(height: 8),
            Text(
              palette.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeTablePreview extends StatelessWidget {
  const _ThemeTablePreview({required this.palette});

  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradient,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child:
                    Icon(Icons.ramen_dining, color: palette.accent, size: 24),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _ThemeMiniPill(
              color: palette.secondary,
              textColor: palette.text,
              text: '晚餐',
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Row(
              children: [
                _ThemeSwatch(color: palette.background),
                _ThemeSwatch(color: palette.secondary),
                _ThemeSwatch(color: palette.primary),
                _ThemeSwatch(color: palette.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeMiniPill extends StatelessWidget {
  const _ThemeMiniPill({
    required this.color,
    required this.textColor,
    required this.text,
  });

  final Color color;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
    );
  }
}

List<Map<String, dynamic>> imageIssues(dynamic response) {
  final data = payload(response);
  final items = data is Map
      ? asList(data['issues'] ?? data['items'] ?? data['list'])
      : asList(data);
  return items.map(asMap).toList();
}

Map<String, dynamic> imageIssueMeal(Map<String, dynamic> issue) {
  final meal = asMap(issue['meal']);
  if (meal.isNotEmpty) {
    return meal;
  }
  return asMap(issue['mealId']);
}

String imageIssueMealId(Map<String, dynamic> issue) {
  final meal = imageIssueMeal(issue);
  final nestedId = idOf(meal);
  if (nestedId.isNotEmpty) {
    return nestedId;
  }
  return textOf(issue['mealId']);
}

String imageIssueMealName(Map<String, dynamic> issue) {
  final meal = imageIssueMeal(issue);
  final name = friendlyText(meal['name']);
  if (name.isNotEmpty) {
    return name;
  }
  final fallback = friendlyText(issue['mealName'] ?? issue['mealTitle']);
  if (fallback.isNotEmpty) {
    return fallback;
  }
  final mealId = imageIssueMealId(issue);
  return mealId.isEmpty ? '未知菜品' : mealId;
}

String imageIssueNote(Map<String, dynamic> issue) {
  final note = friendlyText(issue['note'] ?? issue['reason']);
  if (note.isNotEmpty) {
    return note;
  }
  final type = textOf(issue['issueType']);
  return imageIssueTypeLabel(type);
}

class ImageIssueTile extends StatelessWidget {
  const ImageIssueTile({
    super.key,
    required this.issue,
    required this.onChanged,
  });

  final Map<String, dynamic> issue;
  final VoidCallback onChanged;

  Future<void> markFixed(BuildContext context) async {
    final issueId = idOf(issue);
    if (issueId.isEmpty) {
      showMessage(context, '这个纠错记录缺少 ID');
      return;
    }
    try {
      await context.appRead
          .patch('/meal-image-issues/$issueId', body: {'status': 'fixed'});
      onChanged();
    } catch (error) {
      if (context.mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> openMealDetail(BuildContext context) async {
    final mealId = imageIssueMealId(issue);
    if (mealId.isEmpty) {
      showMessage(context, '这个纠错记录没有关联菜品');
      return;
    }
    await pushPage(context, MealDetailPage(mealId: mealId));
  }

  Future<void> editMealImage(BuildContext context) async {
    final mealId = imageIssueMealId(issue);
    if (mealId.isEmpty) {
      showMessage(context, '这个纠错记录没有关联菜品');
      return;
    }
    final changed = await pushPage(context, MealEditPage(mealId: mealId));
    if (changed == true && context.mounted) {
      await markFixed(context);
      if (context.mounted) {
        showMessage(context, '已更新菜品并标记图片纠错完成');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealName = imageIssueMealName(issue);
    final note = imageIssueNote(issue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.app.themePalette.surface.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.app.themePalette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mealName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              style: TextStyle(color: context.app.themePalette.muted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => openMealDetail(context),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('查看菜品'),
                ),
                FilledButton.icon(
                  onPressed: () => editMealImage(context),
                  icon: const Icon(Icons.image_search_outlined),
                  label: const Text('去换图'),
                ),
                TextButton.icon(
                  onPressed: () => markFixed(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('标记完成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final palette = context.app.themePalette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -54,
            child: _BackdropCircle(
              size: 190,
              color: palette.secondary.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            left: -48,
            bottom: 90,
            child: _BackdropCircle(
              size: 150,
              color: palette.primary.withValues(alpha: 0.13),
            ),
          ),
          Positioned(
            left: 22,
            top: 74,
            child: Icon(Icons.ramen_dining_outlined,
                size: 72, color: palette.primary.withValues(alpha: 0.07)),
          ),
          Positioned(
            right: 28,
            bottom: 36,
            child: Icon(Icons.favorite,
                size: 58, color: palette.accent.withValues(alpha: 0.06)),
          ),
          Align(alignment: alignment, child: child),
        ],
      ),
    );
  }
}

class _BackdropCircle extends StatelessWidget {
  const _BackdropCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64, this.compact = false});

  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.app.themePalette;
    final bowlSize = size * (compact ? 0.45 : 0.52);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE3D8), Color(0xFFFFF8EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.84)),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.22),
            blurRadius: compact ? 8 : 20,
            offset: Offset(0, compact ? 3 : 9),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.16,
            child: Icon(
              Icons.favorite,
              color: Colors.white.withValues(alpha: 0.88),
              size: size * 0.25,
            ),
          ),
          Positioned(
            left: size * 0.19,
            bottom: size * 0.22,
            child: Icon(Icons.rice_bowl_outlined,
                color: palette.primary, size: bowlSize),
          ),
          Positioned(
            right: size * 0.17,
            bottom: size * 0.20,
            child: Icon(Icons.soup_kitchen_outlined,
                color: palette.accent, size: bowlSize),
          ),
          Positioned(
            bottom: size * 0.12,
            child: Container(
              width: size * 0.62,
              height: compact ? 2 : 4,
              decoration: BoxDecoration(
                color: palette.success.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PartnerPresencePill extends StatelessWidget {
  const PartnerPresencePill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.app.themePalette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: palette.secondary.withValues(alpha: 0.42),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite, size: 15, color: palette.accent),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TapedLabel extends StatelessWidget {
  const TapedLabel({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.app.themePalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: palette.primary),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: palette.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class HoverLift extends StatefulWidget {
  const HoverLift({super.key, required this.child});

  final Widget child;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedScale(
        scale: hovering ? 1.018 : 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: hovering ? const Offset(0, -0.01) : Offset.zero,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final palette = context.app.themePalette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color:
            gradient == null ? palette.surface.withValues(alpha: 0.94) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.13),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.72),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.app.themePalette;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: palette.secondary.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
          ),
          child: Icon(icon, color: palette.primary, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900, color: palette.text),
          ),
        ),
      ],
    );
  }
}

class DetailSection extends StatelessWidget {
  const DetailSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(icon: icon, title: title),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.app.themePalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.secondary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: palette.primary),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: palette.muted,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
    );
  }
}

class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    this.placeholder,
  });

  final String url;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return ImagePlaceholder(placeholder: placeholder);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const ImagePlaceholder(message: '图片暂时加载失败'),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF4EC), Color(0xFFFFE2D5)],
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                value: loadingProgress.expectedTotalBytes == null
                    ? null
                    : loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, this.placeholder, this.message});

  final Widget? placeholder;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFEFE7), Color(0xFFFFD9CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            placeholder ??
                const Icon(Icons.ramen_dining_outlined,
                    size: 44, color: kCaramel),
            if (message != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kCocoa,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  const LoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SoftCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SoftCard(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: kCoral, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.action,
    this.onPressed,
  });

  final String title;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          const BrandMark(size: 62, compact: true),
          const SizedBox(height: 12),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          if (action != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onPressed, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = '确认',
  String cancelText = '取消',
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmText),
            ),
          ],
        ),
      ) ??
      false;
}

Future<String?> textDialog(
  BuildContext context, {
  required String title,
  String hint = '',
  String initial = '',
}) async {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确认')),
      ],
    ),
  );
}
