import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:eatwhat_flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login shell when no saved token exists', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const EatwhatRoot());
    await tester.pumpAndSettle();

    expect(find.text('安排吃啥'), findsWidgets);
    expect(find.text('登录'), findsOneWidget);
    expect(find.text('申请账号 / 加入小家'), findsOneWidget);
  });

  testWidgets('appRead can be used during initState without subscribing',
      (tester) async {
    final appState = AppState();
    addTearDown(appState.dispose);

    await tester.pumpWidget(AppScope(
      appState: appState,
      child: const _InitReadProbe(),
    ));

    expect(find.text('not authed'), findsOneWidget);
  });

  test('init keeps valid cached session when profile refresh is offline',
      () async {
    final token = fakeJwt(DateTime.now().add(const Duration(hours: 2)));
    SharedPreferences.setMockInitialValues({
      'eatwhat.accessToken': token,
      'eatwhat.cachedUser': jsonEncode({
        'id': 'u1',
        'displayName': 'Codex Test',
      }),
      'eatwhat.cachedHousehold': jsonEncode({'name': 'QA Home'}),
    });

    final appState = _FakeAppState((method, uri, headers, body) {
      throw const io.SocketException('offline');
    });
    addTearDown(appState.dispose);

    await appState.init();

    expect(appState.loading, isFalse);
    expect(appState.isAuthed, isTrue);
    expect(appState.displayName, 'Codex Test');
    expect(appState.householdName, 'QA Home');
  });

  test('init clears expired saved token and asks user to log in again',
      () async {
    SharedPreferences.setMockInitialValues({
      'eatwhat.accessToken':
          fakeJwt(DateTime.now().subtract(const Duration(minutes: 2))),
      'eatwhat.cachedUser': jsonEncode({'id': 'u1'}),
      'eatwhat.cachedHousehold': jsonEncode({'name': 'QA Home'}),
    });

    final appState = AppState();
    addTearDown(appState.dispose);
    await appState.init();
    final prefs = await SharedPreferences.getInstance();

    expect(appState.isAuthed, isFalse);
    expect(appState.sessionNotice, contains('登录已过期'));
    expect(prefs.getString('eatwhat.accessToken'), isNull);
  });

  test('401 from authenticated request clears local session', () async {
    final token = fakeJwt(DateTime.now().add(const Duration(hours: 2)));
    SharedPreferences.setMockInitialValues({'eatwhat.accessToken': token});

    final appState = _FakeAppState((method, uri, headers, body) async {
      return http.Response.bytes(
        utf8.encode(jsonEncode({'error': 'token expired'})),
        401,
      );
    })
      ..token = token
      ..user = {'id': 'u1'};
    addTearDown(appState.dispose);

    await expectLater(appState.get('/protected'), throwsA(isA<ApiException>()));
    final prefs = await SharedPreferences.getInstance();

    expect(appState.isAuthed, isFalse);
    expect(appState.sessionNotice, contains('登录已过期'));
    expect(prefs.getString('eatwhat.accessToken'), isNull);
  });

  test('saveLogin always keeps username and only stores remembered password',
      () async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    addTearDown(appState.dispose);

    await appState.saveLogin('alice', 'secret', false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('eatwhat.savedUsername'), 'alice');
    expect(prefs.getString('eatwhat.savedPassword'), isNull);

    await appState.saveLogin('alice', 'secret', true);
    expect(prefs.getString('eatwhat.savedUsername'), 'alice');
    expect(prefs.getString('eatwhat.savedPassword'), 'secret');
  });

  test('theme selection is saved and restored on next launch', () async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    addTearDown(appState.dispose);

    await appState.setThemeKey('japanese_wood');
    expect(appState.themePalette.label, '日式原木');

    final restored = AppState();
    addTearDown(restored.dispose);
    await restored.init();
    expect(restored.themeKey, 'japanese_wood');
    expect(restored.themePalette.label, '日式原木');
  });

  test('mealIdsFromPlanValue extracts ids from schedule meal structures', () {
    final ids = mealIdsFromPlanValue([
      {
        'meal': {'_id': 'meal-a', 'name': '番茄牛腩'}
      },
      {
        'meal': {'id': 'meal-b', 'name': '酸菜饺子'}
      },
      {'mealId': 'meal-c'},
      'meal-d',
      {
        'meal': {'_id': 'meal-a'}
      },
    ]);

    expect(ids, ['meal-a', 'meal-b', 'meal-c', 'meal-d']);
  });

  test('food focus renderer highlights center subject', () {
    final source = img.Image(width: 48, height: 48);
    for (var y = 0; y < source.height; y += 1) {
      for (var x = 0; x < source.width; x += 1) {
        source.setPixelRgb(x, y, 70, 150, 110);
      }
    }
    for (var y = 14; y < 36; y += 1) {
      for (var x = 12; x < 38; x += 1) {
        source.setPixelRgb(x, y, 220, 90, 65);
      }
    }

    final outputBytes =
        renderFoodFocusBytes(Uint8List.fromList(img.encodeJpg(source)));
    final output = img.decodeImage(Uint8List.fromList(outputBytes));

    expect(outputBytes.length, greaterThan(100));
    expect(output, isNotNull);
    expect(output!.getPixel(24, 25).r, greaterThan(output.getPixel(2, 2).r));
  });
}

String fakeJwt(DateTime expiresAt) {
  String encodePart(Map<String, dynamic> data) {
    return base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  }

  return [
    encodePart({'alg': 'none', 'typ': 'JWT'}),
    encodePart({'exp': expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000}),
    'signature',
  ].join('.');
}

class _FakeAppState extends AppState {
  _FakeAppState(this.handler);

  final Future<http.Response> Function(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) handler;

  @override
  Future<http.Response> rawHttpRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    return handler(method, uri, headers, body);
  }
}

class _InitReadProbe extends StatefulWidget {
  const _InitReadProbe();

  @override
  State<_InitReadProbe> createState() => _InitReadProbeState();
}

class _InitReadProbeState extends State<_InitReadProbe> {
  late final bool isAuthed;

  @override
  void initState() {
    super.initState();
    isAuthed = context.appRead.isAuthed;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      isAuthed ? 'authed' : 'not authed',
      textDirection: TextDirection.ltr,
    );
  }
}
