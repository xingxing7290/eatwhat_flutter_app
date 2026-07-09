import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:eatwhat_flutter_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('confirmDialog returns explicit user choice', (tester) async {
    BuildContext? probeContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) {
          probeContext = context;
          return const SizedBox();
        }),
      ),
    );

    final future = confirmDialog(
      probeContext!,
      title: '刷新邀请码',
      message: '旧邀请码会失效',
      confirmText: '刷新',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await future, isFalse);

    final confirmFuture = confirmDialog(
      probeContext!,
      title: '刷新邀请码',
      message: '旧邀请码会失效',
      confirmText: '刷新',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('刷新'));
    await tester.pumpAndSettle();
    expect(await confirmFuture, isTrue);
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

  test('theme palettes are rich, unique, and safely fallback', () {
    final keys = kThemePalettes.map((palette) => palette.key).toSet();

    expect(kThemePalettes.length, greaterThanOrEqualTo(8));
    expect(keys.length, kThemePalettes.length);
    expect(kThemePalettes.map((palette) => palette.label),
        containsAll(['晚餐烛光', '春日野餐', '烟火早市']));
    expect(paletteForKey('missing').key, kThemeCreamPeach);
  });

  test('android branding uses themed app name resource', () {
    final manifest =
        io.File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final strings = io.File('android/app/src/main/res/values/strings.xml')
        .readAsStringSync();

    expect(manifest, contains('android:label="@string/app_name"'));
    expect(strings, contains('<string name="app_name">小家饭桌</string>'));
  });

  test('household helpers extract invite code and member names', () {
    final household = {
      'inviteCode': '00b1ce',
      'members': [
        {'username': 'lsy', 'displayName': 'lsy'},
        {'username': 'zjx', 'displayName': '星星'},
      ],
    };

    expect(householdInviteCode(household), '00B1CE');
    expect(normalizeInviteCode(' 00 b1 ce '), '00B1CE');
    expect(householdMembers(household), hasLength(2));
    expect(householdMemberName(householdMembers(household).last), '星星');
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

  test('week helpers format ranges and relative labels', () {
    final sample = DateTime(2026, 7, 9);
    final currentWeek = mondayOf(DateTime.now());

    expect(dateString(mondayOf(sample)), '2026-07-06');
    expect(weekRangeLabel(sample), '2026-07-06 - 2026-07-12');
    expect(dateString(addWeeks(sample, 1)), '2026-07-13');
    expect(weekRelativeLabel(currentWeek), '本周');
    expect(weekRelativeLabel(addWeeks(currentWeek, -1)), '上周');
    expect(weekRelativeLabel(addWeeks(currentWeek, 1)), '下周');
  });

  test('month helpers format relative labels and roll over years', () {
    final sample = DateTime(2026, 12, 15);
    final currentMonth = monthOnly(DateTime.now());

    expect(monthString(sample), '2026-12');
    expect(monthTitleLabel(sample), '2026 年 12 月');
    expect(monthString(addMonths(sample, 1)), '2027-01');
    expect(monthRelativeLabel(currentMonth), '本月');
    expect(monthRelativeLabel(addMonths(currentMonth, -1)), '上月');
    expect(monthRelativeLabel(addMonths(currentMonth, 1)), '下月');
  });

  test('photoItems accepts plain urls and object photos', () {
    final photos = photoItems({
      'photos': [
        'http://113.44.50.108:3002/uploads/one.jpg',
        {'photo': '/api/uploads/two.jpg', 'title': '周末晚餐'}
      ]
    });

    expect(photos, hasLength(2));
    expect(photos.first['url'], 'http://113.44.50.108:3002/uploads/one.jpg');
    expect(photos.last['title'], '周末晚餐');
  });

  test('photoMealNames extracts populated meal names', () {
    final names = photoMealNames({
      'meals': [
        {
          'meal': {'name': '酸菜猪肉饺子'}
        }
      ],
      'meal': {'name': '番茄牛腩'}
    });

    expect(names, ['酸菜猪肉饺子', '番茄牛腩']);
  });

  test('anniversary helpers parse templates and build descriptions', () {
    final templates = anniversaryTemplates({
      'value': [
        {
          'title': '恋爱纪念日',
          'theme': '纪念日',
          'description': '选两道共同喜欢的菜。',
          'structure': ['共同喜欢', '甜品']
        }
      ]
    });

    expect(templates, hasLength(1));
    expect(anniversaryTemplateStructure(templates.first), ['共同喜欢', '甜品']);
    expect(
      anniversaryTemplateDescription(templates.first),
      '选两道共同喜欢的菜。\n建议结构：共同喜欢、甜品',
    );
    expect(isDateText('2026-07-09'), isTrue);
    expect(isDateText('2026/07/09'), isFalse);
  });

  test('anniversaryMenuMealNames reads populated menu meals', () {
    final names = anniversaryMenuMealNames({
      'meals': {
        'breakfast': [
          {
            'meal': {'name': '小米粥'}
          }
        ],
        'dinner': [
          {'name': '番茄牛腩'},
          {'name': '番茄牛腩'}
        ],
      }
    });

    expect(names, ['小米粥', '番茄牛腩']);
  });

  test('anniversaryMenuMealIds extracts selected meal ids by meal type', () {
    final ids = anniversaryMenuMealIds({
      'meals': {
        'breakfast': [
          {'_id': 'meal-a', 'name': '小米粥'}
        ],
        'lunch': ['meal-b'],
        'dinner': [
          {
            'meal': {'_id': 'meal-c', 'name': '番茄牛腩'}
          },
          {
            'meal': {'_id': 'meal-c'}
          },
        ],
      }
    });

    expect(ids['breakfast'], ['meal-a']);
    expect(ids['lunch'], ['meal-b']);
    expect(ids['dinner'], ['meal-c']);
  });

  test('wishlist meal helpers accept populated object and string id', () {
    expect(
      wishlistMealId({
        'title': '想吃番茄牛腩',
        'mealId': {'_id': 'meal-a', 'name': '番茄牛腩'}
      }),
      'meal-a',
    );
    expect(
      wishlistMealName({
        'title': '想吃番茄牛腩',
        'mealId': {'_id': 'meal-a', 'name': '番茄牛腩'}
      }),
      '番茄牛腩',
    );
    expect(wishlistMealId({'title': '手写愿望', 'mealId': 'meal-b'}), 'meal-b');
    expect(wishlistMealName({'title': '手写愿望', 'mealId': 'meal-b'}), '手写愿望');
  });

  test('wishlist status helpers provide readable state labels', () {
    expect(wishlistStatusLabel('open'), '\u60f3\u5403\u4e2d');
    expect(wishlistStatusLabel('planned'), '\u5df2\u5b89\u6392');
    expect(wishlistStatusLabel('done'), '\u5df2\u5b8c\u6210');
    expect(wishlistStatusLabel('all'), '\u5168\u90e8');
    expect(wishlistStatusLabel('unknown'), '\u60f3\u5403');
    expect(wishlistStatusBadgeLabel({'title': '\u624b\u5199\u613f\u671b'}),
        '\u60f3\u5403\u4e2d');
    expect(
        wishlistStatusBadgeLabel({'status': 'planned'}), '\u5df2\u5b89\u6392');
    expect(wishlistIsDone({'status': 'done'}), isTrue);
    expect(wishlistIsDone({'status': 'open'}), isFalse);
  });

  test('wishlist meal draft fields create a valid meal payload', () {
    final fields = wishlistMealDraftFields({
      'title': '\u5468\u672b\u725b\u8089\u9762',
      'note': '\u5c11\u8fa3\uff0c\u591a\u653e\u9999\u83dc',
      'category': '\u9762\u98df\u4e3b\u98df',
      'priority': 'high',
    });

    expect(fields['name'], '\u5468\u672b\u725b\u8089\u9762');
    expect(fields['description'], '\u5c11\u8fa3\uff0c\u591a\u653e\u9999\u83dc');
    expect(fields['category'], '\u9762\u98df\u4e3b\u98df');
    expect(fields['difficulty'], 'easy');
    expect(jsonDecode(fields['tags']!), contains('\u60f3\u5403\u6e05\u5355'));
    expect(jsonDecode(fields['tags']!), contains('\u4f18\u5148\u60f3\u5403'));
    expect(jsonDecode(fields['ingredients']!), isEmpty);
    expect(jsonDecode(fields['steps']!), isEmpty);
    expect(jsonDecode(fields['healthTags']!), contains('\u5feb\u624b'));
  });

  test('dashboard summary helpers extract partner wishes and photos', () {
    final data = {
      'partnerWishlist': [
        {
          '_id': 'wish-a',
          'title': '想吃酸菜鱼',
          'mealId': {'_id': 'meal-a', 'name': '酸菜鱼'}
        }
      ],
      'recentPhotos': [
        {
          'photo': 'http://113.44.50.108:3002/uploads/dinner.jpg',
          'title': '晚餐'
        },
        '',
      ],
    };

    final wishes = dashboardPartnerWishlist(data);
    final photos = dashboardRecentPhotos(data);

    expect(wishes, hasLength(1));
    expect(wishlistMealId(wishes.first), 'meal-a');
    expect(wishlistMealName(wishes.first), '酸菜鱼');
    expect(photos, hasLength(1));
    expect(photos.first['title'], '晚餐');
  });

  test('shoppingItemsFromIngredients normalizes and merges ingredients', () {
    final items = shoppingItemsFromIngredients([
      {'name': '鸡蛋', 'amount': '2个'},
      {'name': '鸡蛋', 'amount': '1个'},
      {'name': '面粉', 'quantity': '300', 'unit': '克'},
      '葱花 少许',
      {'name': ''},
    ]);

    expect(items, [
      {'name': '鸡蛋', 'amount': '2个、1个', 'category': 'meat_egg'},
      {'name': '面粉', 'amount': '300克', 'category': 'staple'},
      {'name': '葱花', 'amount': '少许', 'category': 'seasoning'},
    ]);
  });

  test('shoppingCategoryFor classifies common cooking ingredients', () {
    expect(shoppingCategoryFor('白菜'), 'vegetable');
    expect(shoppingCategoryFor('牛肉'), 'meat_egg');
    expect(shoppingCategoryFor('面条'), 'staple');
    expect(shoppingCategoryFor('生抽'), 'seasoning');
    expect(shoppingCategoryFor('椰奶'), 'other');
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
