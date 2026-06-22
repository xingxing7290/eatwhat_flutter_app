// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads

import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kApiBase = 'http://113.44.50.108:3002/api';
const String kAssetBase = 'http://113.44.50.108:3002';

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
      theme: cozyTheme(),
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

ThemeData cozyTheme() {
  const background = Color(0xFFFDFBF7);
  const surface = Color(0xFFFFFBF6);
  const peach = Color(0xFFFFB4A2);
  const caramel = Color(0xFFE09F67);
  const coffee = Color(0xFF4A3E3D);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: peach,
      brightness: Brightness.light,
      primary: caramel,
      secondary: peach,
      surface: surface,
      onSurface: coffee,
    ),
    scaffoldBackgroundColor: background,
    fontFamilyFallback: const [
      'Microsoft YaHei',
      'PingFang SC',
      'Noto Sans CJK SC'
    ],
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: coffee,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: coffee,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardTheme(
      color: surface,
      elevation: 1,
      shadowColor: caramel.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF2D8C8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF2D8C8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: caramel, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: caramel,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: coffee,
        side: const BorderSide(color: Color(0xFFEED2BF)),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      indicatorColor: peach.withValues(alpha: 0.28),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
}

extension AppContext on BuildContext {
  AppState get app => AppScope.of(this);
}

class AppState extends ChangeNotifier {
  static const _tokenKey = 'eatwhat.accessToken';
  static const _savedUserKey = 'eatwhat.savedUsername';
  static const _savedPasswordKey = 'eatwhat.savedPassword';
  static const _rememberKey = 'eatwhat.rememberPassword';

  final http.Client _client = http.Client();

  bool loading = true;
  String? token;
  Map<String, dynamic>? user;
  Map<String, dynamic>? household;

  bool get isAuthed => token != null && token!.isNotEmpty;
  String get displayName => textOf(user?['displayName']).isNotEmpty
      ? textOf(user?['displayName'])
      : textOf(user?['username']);
  String get householdName => textOf(household?['name']).isNotEmpty
      ? textOf(household?['name'])
      : '我的小家';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    if (isAuthed) {
      try {
        await refreshMe();
      } catch (_) {
        token = null;
        await prefs.remove(_tokenKey);
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
    if (remember) {
      await prefs.setString(_savedUserKey, username);
      await prefs.setString(_savedPasswordKey, password);
    } else {
      await prefs.remove(_savedUserKey);
      await prefs.remove(_savedPasswordKey);
    }
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token!);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token!);
    notifyListeners();
  }

  Future<void> refreshMe() async {
    final response = await get('/auth/me');
    final data = asMap(payload(response));
    user = asMap(data['user'] ?? data);
    household = asMap(data['household']);
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    user = null;
    household = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
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
    final uri = Uri.parse('$kApiBase$path')
        .replace(queryParameters: cleanedQuery(query));
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }
    if (auth && isAuthed) {
      headers['Authorization'] = 'Bearer $token';
    }

    late final http.Response response;
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(uri, headers: headers, body: encoded);
        break;
      case 'PUT':
        response = await _client.put(uri, headers: headers, body: encoded);
        break;
      case 'PATCH':
        response = await _client.patch(uri, headers: headers, body: encoded);
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
        break;
      default:
        throw ApiException('不支持的请求方法: $method');
    }
    return decodeResponse(response);
  }

  Future<dynamic> multipart(
    String method,
    String path, {
    Map<String, String>? fields,
    Map<String, XFile>? files,
    Map<String, List<XFile>>? multiFiles,
  }) async {
    final request = http.MultipartRequest(method, Uri.parse('$kApiBase$path'));
    request.headers['Accept'] = 'application/json';
    if (isAuthed) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(fields ?? {});
    for (final entry in (files ?? {}).entries) {
      request.files.add(http.MultipartFile.fromBytes(
        entry.key,
        await entry.value.readAsBytes(),
        filename: entry.value.name,
      ));
    }
    for (final entry in (multiFiles ?? {}).entries) {
      for (final file in entry.value) {
        request.files.add(http.MultipartFile.fromBytes(
          entry.key,
          await file.readAsBytes(),
          filename: file.name,
        ));
      }
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return decodeResponse(response);
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
          message.isEmpty ? '服务器请求失败 ${response.statusCode}' : message);
    }
    return body;
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
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
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
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

DateTime mondayOf(DateTime value) {
  return DateTime(value.year, value.month, value.day)
      .subtract(Duration(days: value.weekday - 1));
}

String errorText(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  return error.toString().replaceFirst('Exception: ', '');
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 54, color: Color(0xFFE09F67)),
            SizedBox(height: 16),
            Text('正在准备小家的饭桌...'),
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
      final saved = await context.app.savedLogin();
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
      await context.app
          .login(usernameController.text.trim(), passwordController.text);
      await context.app.saveLogin(
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SoftCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.favorite,
                        color: Color(0xFFFF8D7E), size: 54),
                    const SizedBox(height: 14),
                    Text(
                      '安排吃啥',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF4A3E3D),
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '情侣夫妻的小家饭桌记录',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
      await context.app.register(
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '没有邀请码会创建新的小家；填写 TA 的邀请码会加入同一个小家。',
                  style: TextStyle(fontWeight: FontWeight.w700),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                context.app.householdName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: pages[index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
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
    );
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

  Future<dynamic> load() => context.app.get('/dashboard/summary');

  void reload() => setState(() => future = load());

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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SoftCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF5EE), Color(0xFFFFE1D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.app.displayName}，今天也好好吃饭',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text('TA 想吃、周计划、饭后回忆都会汇总在这里。'),
                    const SizedBox(height: 16),
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
                    value: countText(data['today']),
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
                    value: countText(data['wishlist'] ?? data['wishCount']),
                    color: const Color(0xFFFF8D7E),
                  ),
                  DashboardTile(
                    icon: Icons.photo_library_outlined,
                    label: '最近回忆',
                    value: countText(data['memories'] ?? data['memoryCount']),
                    color: const Color(0xFF9E8B73),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.16),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(height: 14),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
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

  Future<dynamic> load() => context.app.get('/schedules', query: {
        'year': month.year.toString(),
        'month': month.month.toString(),
      });

  void reload() => setState(() => future = load());

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
        return RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.all(16),
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
                  mainAxisExtent: 190,
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
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: today ? const Color(0xFFFFF0EA) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: today ? const Color(0xFFFF8D7E) : const Color(0xFFF1DCCF),
              width: today ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE09F67).withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                if (today)
                  const Icon(Icons.favorite,
                      color: Color(0xFFFF8D7E), size: 18),
              ],
            ),
            const SizedBox(height: 10),
            MealBadges(title: '早', value: schedule['breakfast']),
            MealBadges(title: '午', value: schedule['lunch']),
            MealBadges(title: '晚', value: schedule['dinner']),
            const Spacer(),
            const Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.edit_calendar_outlined,
                  size: 18, color: Color(0xFFE09F67)),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFFFFE1D8),
            child: Text(title,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              names.isEmpty ? '还没安排' : names.take(2).join('、'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: names.isEmpty ? Colors.grey : const Color(0xFF4A3E3D),
                fontWeight: names.isEmpty ? FontWeight.w500 : FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
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
      result.add(textOf(map['name'] ?? map['title']));
    }
  }
  return result.where((item) => item.isNotEmpty).toList();
}

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
  late Future<dynamic> mealsFuture;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    mealsFuture = context.app.get('/meals', query: {'limit': '200'});
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await context.app
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
            final meals = snapshot.hasData
                ? mealListFrom(snapshot.data)
                : const <dynamic>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
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
                    selected.clear();
                  }),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        final meal = asMap(meals[index]);
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

  Future<dynamic> load() => context.app.get('/meals', query: {
        'search': searchController.text,
        'limit': '200',
      });

  void reload() => setState(() => future = load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: searchController,
              onSubmitted: (_) => reload(),
              decoration: InputDecoration(
                hintText: '搜索菜名、食材、做法...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: reload,
                ),
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
                      mainAxisExtent: 360,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await pushPage(context, const MealEditPage());
          if (changed == true) {
            reload();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('新增菜谱'),
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
        final changed = await pushPage(context, MealDetailPage(mealId: id));
        if (changed == true) {
          onChanged();
        }
      },
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: RemoteImage(url: image),
              ),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip: '图片不对',
                        icon: const Icon(Icons.report_gmailerrorred_outlined),
                        onPressed: () => reportImageIssue(context, id),
                      ),
                      IconButton(
                        tooltip: '编辑',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final changed =
                              await pushPage(context, MealEditPage(mealId: id));
                          if (changed == true) {
                            onChanged();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    textOf(meal['description']).isEmpty
                        ? '还没有写简介。'
                        : textOf(meal['description']),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      InfoChip(
                          '${textOf(meal['cookTime']).isEmpty ? '30' : textOf(meal['cookTime'])} 分钟'),
                      InfoChip(textOf(meal['difficulty']).isEmpty
                          ? '家常'
                          : textOf(meal['difficulty'])),
                      InfoChip(
                          '${textOf(meal['rating']).isEmpty ? '0' : textOf(meal['rating'])} 分'),
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
    );
  }
}

Future<void> reportImageIssue(BuildContext context, String mealId) async {
  final note = await textDialog(context, title: '图片不对', hint: '描述一下哪里不匹配');
  if (note == null) {
    return;
  }
  try {
    await context.app.post('/meal-image-issues', body: {
      'mealId': mealId,
      'issueType': 'mismatch',
      'note': note,
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

class MealDetailPage extends StatefulWidget {
  const MealDetailPage({super.key, required this.mealId});

  final String mealId;

  @override
  State<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends State<MealDetailPage> {
  late Future<dynamic> future;

  @override
  void initState() {
    super.initState();
    future = context.app.get('/meals/${widget.mealId}');
  }

  void reload() =>
      setState(() => future = context.app.get('/meals/${widget.mealId}'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('菜谱详情')),
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
          final meal = asMap(payload(snapshot.data));
          final image =
              imageUrl(meal['image'] ?? meal['coverImage'] ?? meal['imageUrl']);
          final photos = asList(meal['photos'])
              .map(imageUrl)
              .where((item) => item.isNotEmpty)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: AspectRatio(
                    aspectRatio: 16 / 10, child: RemoteImage(url: image)),
              ),
              const SizedBox(height: 16),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      textOf(meal['name']),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
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
                        InfoChip(textOf(meal['difficulty']).isEmpty
                            ? '家常'
                            : textOf(meal['difficulty'])),
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
                          onPressed: () async {
                            final changed = await pushPage(
                              context,
                              MemoryEditPage(
                                initialMealIds: [widget.mealId],
                                initialTitle: '做了 ${textOf(meal['name'])}',
                              ),
                            );
                            if (changed == true && mounted) {
                              showMessage(context, '已记录这顿饭');
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('做过一次'),
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
            ],
          );
        },
      ),
    );
  }
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
          asMap(payload(await context.app.get('/meals/${widget.mealId}')));
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
    final selected =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 86);
    if (selected != null) {
      setState(() => image = selected);
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
      await context.app.multipart(
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
      body: initialLoading
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
                          decoration: const InputDecoration(labelText: '小技巧')),
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
                        onChanged: (value) => setState(() => favorite = value),
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
      context.app.get('/memories', query: {'month': monthString(month)});
  void reload() => setState(() => future = load());

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
              padding: const EdgeInsets.all(16),
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
                      .map((item) => MemoryCard(memory: asMap(item)))
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

class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.memory});

  final Map<String, dynamic> memory;

  @override
  Widget build(BuildContext context) {
    final photos = asList(memory['photos'])
        .map(imageUrl)
        .where((item) => item.isNotEmpty)
        .toList();
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
            if (textOf(memory['note']).isNotEmpty) Text(textOf(memory['note'])),
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

class MemoryEditPage extends StatefulWidget {
  const MemoryEditPage({
    super.key,
    this.initialMealIds = const [],
    this.initialTitle = '',
  });

  final List<String> initialMealIds;
  final String initialTitle;

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
  final photos = <XFile>[];
  late Future<dynamic> mealsFuture;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController(text: dateString(DateTime.now()));
    titleController = TextEditingController(text: widget.initialTitle);
    selectedMealIds.addAll(widget.initialMealIds);
    mealsFuture = context.app.get('/meals', query: {'limit': '200'});
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

  Future<void> pickPhotos() async {
    final picker = ImagePicker();
    final selected = await picker.pickMultiImage(imageQuality: 86);
    if (selected.isNotEmpty) {
      setState(() => photos.addAll(selected));
    }
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await context.app.multipart(
        'POST',
        '/memories',
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
          'participants': jsonEncode([context.app.displayName]),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                OutlinedButton.icon(
                  onPressed: pickPhotos,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(photos.isEmpty
                      ? '选择照片（支持 PNG/JPG）'
                      : '已选择 ${photos.length} 张'),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(saving ? '保存中...' : '保存回忆'),
                ),
              ],
            ),
          ),
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

  Future<dynamic> load() => context.app
      .get('/weekly-plans', query: {'weekStart': dateString(weekStart)});
  void reload() => setState(() => future = load());

  Future<void> generate() async {
    setState(() => busy = true);
    try {
      final response = await context.app.post('/weekly-plans/generate',
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
      await context.app.post('/weekly-plans/apply', body: {
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
          final data = asMap(payload(snapshot.data));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${dateString(weekStart)} 这一周',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
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
                PlanBlock(title: '新生成草稿', data: draft!),
              ],
            ],
          );
        },
      ),
    );
  }
}

class PlanBlock extends StatelessWidget {
  const PlanBlock({super.key, required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final days = asList(data['days'] ?? data['plan'] ?? data['items']);
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(textOf(day['date']),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    MealBadges(title: '早', value: day['breakfast']),
                    MealBadges(title: '午', value: day['lunch']),
                    MealBadges(title: '晚', value: day['dinner']),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  DateTime weekStart = mondayOf(DateTime.now());
  late Future<dynamic> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<dynamic> load() => context.app
      .get('/shopping-list', query: {'weekStart': dateString(weekStart)});
  void reload() => setState(() => future = load());

  Future<void> generate() async {
    try {
      await context.app.post('/shopping-list/generate',
          body: {'weekStart': dateString(weekStart)});
      reload();
    } catch (error) {
      if (mounted) {
        showMessage(context, errorText(error));
      }
    }
  }

  Future<void> addItem() async {
    final text = await textDialog(context, title: '补充采购项', hint: '例如：鸡蛋 10个');
    if (text == null || text.trim().isEmpty) {
      return;
    }
    final parts = text.trim().split(RegExp(r'\s+'));
    try {
      await context.app.post('/shopping-list/items', body: {
        'weekStart': dateString(weekStart),
        'name': parts.first,
        'amount': parts.length > 1 ? parts.sublist(1).join(' ') : '',
        'category': '其他',
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
      await context.app.delete('/shopping-list/purchased',
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
          final items = shoppingItems(snapshot.data);
          final grouped = <String, List<Map<String, dynamic>>>{};
          for (final item in items) {
            grouped
                .putIfAbsent(
                    textOf(item['category']).isEmpty
                        ? '其他'
                        : textOf(item['category']),
                    () => [])
                .add(item);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SoftCard(
                child: Wrap(
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
                      onPressed: clearPurchased,
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('清空已购'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const EmptyState(title: '暂无采购项')
              else
                ...grouped.entries.map((entry) => ShoppingGroup(
                    title: entry.key, items: entry.value, onChanged: reload)),
            ],
          );
        },
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

class ShoppingGroup extends StatelessWidget {
  const ShoppingGroup({
    super.key,
    required this.title,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final List<Map<String, dynamic>> items;
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
              return CheckboxListTile(
                value: checked,
                title: Text(textOf(item['name'])),
                subtitle: Text(textOf(item['amount'])),
                secondary: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    try {
                      await context.app
                          .delete('/shopping-list/items/$id', query: {
                        'weekStart': dateString(mondayOf(DateTime.now())),
                      });
                      onChanged();
                    } catch (error) {
                      if (context.mounted) {
                        showMessage(context, errorText(error));
                      }
                    }
                  },
                ),
                onChanged: (value) async {
                  try {
                    await context.app.patch('/shopping-list/items/$id', body: {
                      'weekStart': dateString(mondayOf(DateTime.now())),
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

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<dynamic> load() =>
      context.app.get('/wishlist', query: {'status': 'open'});
  void reload() => setState(() => future = load());

  Future<void> addWish() async {
    final title = await textDialog(context, title: '想吃什么', hint: '比如：周末想吃番茄牛腩');
    if (title == null || title.trim().isEmpty) {
      return;
    }
    try {
      await context.app.post('/wishlist', body: {
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
          final items = wishlistItems(snapshot.data);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SoftCard(
                child: FilledButton.icon(
                  onPressed: addWish,
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('添加想吃'),
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const EmptyState(title: '暂时没有想吃项')
              else
                ...items
                    .map((item) => WishlistCard(item: item, onChanged: reload)),
            ],
          );
        },
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

class WishlistCard extends StatelessWidget {
  const WishlistCard({super.key, required this.item, required this.onChanged});

  final Map<String, dynamic> item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final id = idOf(item);
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
            if (textOf(item['note']).isNotEmpty) Text(textOf(item['note'])),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.app.post('/wishlist/$id/vote');
                    onChanged();
                  },
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  label: Text('投票 ${countText(item['votes'])}'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.app.patch('/wishlist/$id/status',
                        body: {'status': 'planned'});
                    onChanged();
                  },
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('标记已安排'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.app.delete('/wishlist/$id');
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
      context.app.get('/photo-album', query: {'month': monthString(month)});
  void reload() => setState(() => future = load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('饭桌相册')),
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
          final photos = photoItems(snapshot.data);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: GridTile(
                  footer: Container(
                    color: Colors.black.withValues(alpha: 0.42),
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      textOf(photo['title'] ?? photo['date']),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  child: RemoteImage(
                      url: imageUrl(
                          photo['url'] ?? photo['photo'] ?? photo['src'])),
                ),
              );
            },
          );
        },
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
    final list = await context.app.get('/anniversaries');
    return asList(payload(list is Map ? list['data'] ?? list : list));
  }

  void reload() => setState(() => future = load());

  Future<void> create() async {
    try {
      final templatesResponse = await context.app.get('/anniversary-templates');
      final templates = asList(payload(templatesResponse));
      final template =
          templates.isNotEmpty ? asMap(templates.first) : <String, dynamic>{};
      await context.app.multipart('POST', '/anniversaries', fields: {
        'title': textOf(template['title']).isEmpty
            ? '周末小家宴'
            : textOf(template['title']),
        'date': dateString(DateTime.now()),
        'description': textOf(template['description']),
        'theme': textOf(template['theme']).isEmpty
            ? '温馨小家'
            : textOf(template['theme']),
        'meals': jsonEncode({'breakfast': [], 'lunch': [], 'dinner': []}),
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
      appBar: AppBar(title: const Text('纪念日菜单')),
      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingList();
          }
          if (snapshot.hasError) {
            return ErrorState(
                message: errorText(snapshot.error!), onRetry: reload);
          }
          final items = (snapshot.data ?? const []).map(asMap).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SoftCard(
                child: FilledButton.icon(
                  onPressed: create,
                  icon: const Icon(Icons.celebration_outlined),
                  label: const Text('用模板创建纪念日菜单'),
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const EmptyState(title: '还没有纪念日菜单')
              else
                ...items.map((item) => SoftCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                            child: Icon(Icons.celebration_outlined)),
                        title: Text(textOf(item['title'])),
                        subtitle: Text(
                            '${textOf(item['date']).split('T').first} · ${textOf(item['theme'])}'),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<dynamic> defaultStatusFuture;
  late Future<dynamic> issuesFuture;

  @override
  void initState() {
    super.initState();
    defaultStatusFuture = context.app.get('/default-meals/status');
    issuesFuture =
        context.app.get('/meal-image-issues', query: {'status': 'open'});
  }

  void reload() {
    setState(() {
      defaultStatusFuture = context.app.get('/default-meals/status');
      issuesFuture =
          context.app.get('/meal-image-issues', query: {'status': 'open'});
    });
  }

  Future<void> updateHousehold() async {
    final name = await textDialog(context,
        title: '修改小家名称', initial: context.app.householdName);
    if (name == null || name.trim().isEmpty) {
      return;
    }
    try {
      await context.app.put('/household/me', body: {'name': name.trim()});
      await context.app.refreshMe();
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
        title: '修改昵称', initial: context.app.displayName);
    if (name == null || name.trim().isEmpty) {
      return;
    }
    try {
      await context.app
          .put('/auth/profile', body: {'displayName': name.trim()});
      await context.app.refreshMe();
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
      await context.app.post('/default-meals/import-missing');
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
      await context.app.post('/default-meals/restore-images');
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                  icon: Icons.home_outlined, title: context.app.householdName),
              const SizedBox(height: 8),
              Text(
                  '邀请码：${textOf(household['inviteCode']).isEmpty ? '暂无' : textOf(household['inviteCode'])}'),
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
                    onPressed: () => context.app.logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('退出登录'),
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
                  const SizedBox(height: 12),
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
                    ...issues.map((issue) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(textOf(asMap(issue['meal'])['name'] ??
                              issue['mealName'] ??
                              issue['mealId'])),
                          subtitle: Text(textOf(issue['note'])),
                          trailing: TextButton(
                            onPressed: () async {
                              await context.app.patch(
                                  '/meal-image-issues/${idOf(issue)}',
                                  body: {'status': 'fixed'});
                              reload();
                            },
                            child: const Text('标记完成'),
                          ),
                        )),
                ],
              ),
            );
          },
        ),
      ],
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? Colors.white : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0D8C9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE09F67).withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
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
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE09F67)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF2D8C8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: const Color(0xFFE09F67)),
            const SizedBox(width: 4),
          ],
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
      return Container(
        color: const Color(0xFFFFE1D8),
        child: Center(
          child: placeholder ??
              const Icon(Icons.restaurant, size: 42, color: Color(0xFFE09F67)),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFFFE1D8),
        child: const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 42, color: Color(0xFFE09F67))),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: const Color(0xFFFFF0EA),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
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
              const Icon(Icons.error_outline,
                  color: Color(0xFFFF8D7E), size: 48),
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
          const Icon(Icons.local_dining_outlined,
              size: 48, color: Color(0xFFE09F67)),
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
