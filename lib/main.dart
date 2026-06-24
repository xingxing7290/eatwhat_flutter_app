// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPrimaryApiBase = 'http://113.44.50.108:8088/api';
const String kFallbackApiBase = 'http://113.44.50.108:3002/api';
const String kApiBase = kPrimaryApiBase;
const List<String> kReadApiBases = [kPrimaryApiBase, kFallbackApiBase];
const String kAssetBase = 'http://113.44.50.108:8088';
const Duration kRequestTimeout = Duration(seconds: 30);
const Duration kUploadTimeout = Duration(seconds: 90);
const double kUploadImageMaxSide = 1600;
const int kUploadImageQuality = 68;

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
const kImageExtensionPattern = r'\.(jpe?g|png|gif|webp)$';

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
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPeach,
      brightness: Brightness.light,
      primary: kCaramel,
      secondary: kPeach,
      tertiary: kSage,
      surface: kPaper,
      onSurface: kCoffee,
      error: kCoral,
    ),
    scaffoldBackgroundColor: kCream,
    fontFamilyFallback: const [
      'Microsoft YaHei',
      'PingFang SC',
      'Noto Sans CJK SC'
    ],
    visualDensity: VisualDensity.standard,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: kCoffee,
      displayColor: kCoffee,
      decorationColor: kCoffee,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCream,
      foregroundColor: kCoffee,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: kCoffee,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardTheme(
      color: kPaper,
      elevation: 0,
      shadowColor: kCaramel.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      labelStyle: const TextStyle(color: kCocoa, fontWeight: FontWeight.w700),
      hintStyle: const TextStyle(color: Color(0xFFBFA99C)),
      prefixIconColor: kCaramel,
      suffixIconColor: kCocoa,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: kLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: kLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: kCaramel, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kCoral,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 50),
        elevation: 0,
        shadowColor: kCoral.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kCoffee,
        backgroundColor: Colors.white.withValues(alpha: 0.62),
        side: const BorderSide(color: kLine),
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kCoral,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: kPeach.withValues(alpha: 0.34),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? kCoral : kCocoa,
        ),
      ),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: kCoffee,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? kPeach.withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.72),
        ),
        foregroundColor: WidgetStateProperty.all(kCoffee),
        side: WidgetStateProperty.all(const BorderSide(color: kLine)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? kCoral : kPaper,
      ),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: kLine, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: kCoral,
      inactiveTrackColor: kPeach.withValues(alpha: 0.25),
      thumbColor: kCaramel,
      overlayColor: kPeach.withValues(alpha: 0.18),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kCoral),
    dialogTheme: DialogTheme(
      backgroundColor: kPaper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      titleTextStyle: const TextStyle(
        color: kCoffee,
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
      backgroundColor: kCoffee,
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
  static const _savedUserKey = 'eatwhat.savedUsername';
  static const _savedPasswordKey = 'eatwhat.savedPassword';
  static const _rememberKey = 'eatwhat.rememberPassword';

  bool loading = true;
  String? token;
  Map<String, dynamic>? user;
  Map<String, dynamic>? household;

  bool get isAuthed => token != null && token!.isNotEmpty;
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
    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip',
      'X-Mobile-Client': 'eatwhat-flutter',
    };
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }
    if (auth && isAuthed) {
      headers['Authorization'] = 'Bearer $token';
    }

    final encoded = body == null ? null : jsonEncode(body);
    if (!['GET', 'POST', 'PUT', 'PATCH', 'DELETE'].contains(method)) {
      throw ApiException('Unsupported request method: $method');
    }
    final bases = method == 'GET' ? kReadApiBases : const [kApiBase];
    Object? lastError;
    for (var index = 0; index < bases.length; index += 1) {
      final uri = Uri.parse('${bases[index]}$path')
          .replace(queryParameters: cleanedQuery(query));
      try {
        final response = await rawHttpRequest(method, uri, headers, encoded);
        return decodeResponse(response);
      } on ApiException {
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
    late final http.StreamedResponse streamed;
    try {
      request.headers['Accept-Encoding'] = 'identity';
      streamed = await request.send().timeout(kUploadTimeout);
    } catch (error) {
      if (error is TimeoutException) {
        throw const ApiException('服务器响应超时，请检查网络或稍后重试');
      }
      throw ApiException('上传请求失败：$error');
    }
    final response = await http.Response.fromStream(streamed)
        .timeout(kUploadTimeout, onTimeout: () {
      throw const ApiException('服务器响应超时，请检查网络或稍后重试');
    });
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
  if (name.endsWith('.png')) return MediaType('image', 'png');
  if (name.endsWith('.gif')) return MediaType('image', 'gif');
  if (name.endsWith('.webp')) return MediaType('image', 'webp');
  return MediaType('image', 'jpeg');
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
        color: kCream,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kLine),
                boxShadow: [
                  BoxShadow(
                    color: kCaramel.withValues(alpha: 0.15),
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
    final today = DateTime.now();
    final results = await Future.wait<dynamic>([
      loadPart(
          () => context.appRead.get('/schedules/day/${dateString(today)}')),
      loadPart(() => context.appRead.get('/meals', query: {'limit': '1'})),
      loadPart(() => context.appRead.get('/default-meals/status')),
    ]);
    final meals = mealListFrom(results[1]);
    return <String, dynamic>{
      'todaySchedule': asMap(payload(results[0])),
      'mealCount': dashboardMealCount(results[1], meals),
      'wishlist': 0,
      'memories': 0,
      'defaultMeals': asMap(payload(results[2])),
      'imageIssues': {'open': 0},
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

  @override
  Widget build(BuildContext context) {
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
          if (!hasMeals) ...[
            const SizedBox(height: 6),
            const Text(
              '今天还没有安排，先给两个人定一餐喜欢的。',
              style: TextStyle(color: kCocoa, fontWeight: FontWeight.w700),
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

  Future<dynamic> loadMeals() {
    final query = searchController.text.trim();
    return context.appRead.get('/meals', query: {
      'limit': '1',
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
                      selected.clear();
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
        'limit': '1',
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
  final note = await textDialog(context, title: '图片不对', hint: '描述一下哪里不匹配');
  if (note == null) {
    return;
  }
  try {
    await context.appRead.post('/meal-image-issues', body: {
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
    future = context.appRead.get('/meals/${widget.mealId}');
  }

  void reload() => setState(() {
        future = context.appRead.get('/meals/${widget.mealId}');
      });

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
  final imagePicker = ImagePicker();
  final photos = <XFile>[];
  late Future<dynamic> mealsFuture;
  bool saving = false;
  bool pickingPhotos = false;

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController(text: dateString(DateTime.now()));
    titleController = TextEditingController(text: widget.initialTitle);
    selectedMealIds.addAll(widget.initialMealIds);
    mealsFuture = context.appRead.get('/meals', query: {'limit': '1'});
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

  void addPhotos(List<XFile> selected) {
    if (selected.isEmpty) {
      return;
    }
    setState(() => photos.addAll(selected));
    showMessage(context, '已添加 ${selected.length} 张照片');
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
        addPhotos(recovered);
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
        addPhotos(selected);
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
        addPhotos([selected]);
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

  Widget buildPhotoPickerSection(BuildContext context) {
    final title = photos.isEmpty ? '饭后照片' : '饭后照片 ${photos.length} 张';
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
                    const Text(
                      '支持图库多选，也可以现场拍照加入回忆',
                      style: TextStyle(color: kCocoa),
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
          if (photos.isEmpty)
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
              itemCount: photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(io.File(photo.path), fit: BoxFit.cover),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: () => removePhoto(index),
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
      await context.appRead.multipart(
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
                  PlanBlock(title: '新生成草稿', data: {
                    'days': draft!['preview'] ?? draft!['days'] ?? []
                  }),
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
  const PlanBlock({super.key, required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

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
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(textOf(day['date']),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    MealBadges(
                        title: '早', value: planMealValue(day, 'breakfast')),
                    MealBadges(title: '午', value: planMealValue(day, 'lunch')),
                    MealBadges(title: '晚', value: planMealValue(day, 'dinner')),
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

  Future<dynamic> load() => context.appRead
      .get('/shopping-list', query: {'weekStart': dateString(weekStart)});
  void reload() => setState(() {
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
    final text = await textDialog(context, title: '补充采购项', hint: '例如：鸡蛋 10个');
    if (text == null || text.trim().isEmpty) {
      return;
    }
    final parts = text.trim().split(RegExp(r'\s+'));
    try {
      await context.appRead.post('/shopping-list/items', body: {
        'weekStart': dateString(weekStart),
        'name': parts.first,
        'amount': parts.length > 1 ? parts.sublist(1).join(' ') : '',
        'category': 'other',
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
            final items = shoppingItems(snapshot.data);
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
                      await context.appRead
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
                    await context.appRead
                        .patch('/shopping-list/items/$id', body: {
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
      context.appRead.get('/wishlist', query: {'status': 'open'});
  void reload() => setState(() {
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
                    await context.appRead.post('/wishlist/$id/vote');
                    onChanged();
                  },
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  label: Text('投票 ${countText(item['votes'])}'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.appRead.patch('/wishlist/$id/status',
                        body: {'status': 'planned'});
                    onChanged();
                  },
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('标记已安排'),
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
            if (photos.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  EmptyState(title: '这个月还没有饭桌照片'),
                ],
              );
            }
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
                return HoverLift(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: GridTile(
                      footer: Container(
                        color: kCoffee.withValues(alpha: 0.62),
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          textOf(photo['title'] ?? photo['date']),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                      child: RemoteImage(
                          url: imageUrl(
                              photo['url'] ?? photo['photo'] ?? photo['src'])),
                    ),
                  ),
                );
              },
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

  Future<void> create() async {
    try {
      final templatesResponse =
          await context.appRead.get('/anniversary-templates');
      final templates = asList(payload(templatesResponse));
      final template =
          templates.isNotEmpty ? asMap(templates.first) : <String, dynamic>{};
      await context.appRead.multipart('POST', '/anniversaries', fields: {
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
    defaultStatusFuture = context.appRead.get('/default-meals/status');
    issuesFuture =
        context.appRead.get('/meal-image-issues', query: {'status': 'open'});
  }

  void reload() {
    setState(() {
      defaultStatusFuture = context.appRead.get('/default-meals/status');
      issuesFuture =
          context.appRead.get('/meal-image-issues', query: {'status': 'open'});
    });
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
                  const SizedBox(height: 80),
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
                              await context.appRead.patch(
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kCream, kOat, Color(0xFFFFF8F0)],
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
              color: kPeach.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            left: -48,
            bottom: 90,
            child: _BackdropCircle(
              size: 150,
              color: kCaramel.withValues(alpha: 0.13),
            ),
          ),
          Positioned(
            left: 22,
            top: 74,
            child: Icon(Icons.ramen_dining_outlined,
                size: 72, color: kCaramel.withValues(alpha: 0.07)),
          ),
          Positioned(
            right: 28,
            bottom: 36,
            child: Icon(Icons.favorite,
                size: 58, color: kCoral.withValues(alpha: 0.06)),
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
            color: kCaramel.withValues(alpha: 0.22),
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
            child:
                Icon(Icons.rice_bowl_outlined, color: kCaramel, size: bowlSize),
          ),
          Positioned(
            right: size * 0.17,
            bottom: size * 0.20,
            child: Icon(Icons.soup_kitchen_outlined,
                color: kCoral, size: bowlSize),
          ),
          Positioned(
            bottom: size * 0.12,
            child: Container(
              width: size * 0.62,
              height: compact ? 2 : 4,
              decoration: BoxDecoration(
                color: kSage.withValues(alpha: 0.34),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kLine),
        boxShadow: [
          BoxShadow(
            color: kCaramel.withValues(alpha: 0.08),
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
              color: kPeach.withValues(alpha: 0.42),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, size: 15, color: kCoral),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kCoffee,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: kCaramel),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: kCocoa,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? kPaper.withValues(alpha: 0.94) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: kCaramel.withValues(alpha: 0.13),
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
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: kPeach.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
          ),
          child: Icon(icon, color: kCaramel, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900, color: kCoffee),
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
        color: kPeach.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: kCaramel),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: const TextStyle(
                fontSize: 12,
                color: kCocoa,
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
