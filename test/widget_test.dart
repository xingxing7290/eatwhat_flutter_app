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

  testWidgets('appRead can be used during initState without subscribing', (
    tester,
  ) async {
    final appState = AppState();
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      AppScope(appState: appState, child: const _InitReadProbe()),
    );

    expect(find.text('not authed'), findsOneWidget);
  });

  testWidgets('confirmDialog returns explicit user choice', (tester) async {
    BuildContext? probeContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            probeContext = context;
            return const SizedBox();
          },
        ),
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

  test(
    'init keeps valid cached session when profile refresh is offline',
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
    },
  );

  test(
    'init clears expired saved token and asks user to log in again',
    () async {
      SharedPreferences.setMockInitialValues({
        'eatwhat.accessToken': fakeJwt(
          DateTime.now().subtract(const Duration(minutes: 2)),
        ),
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
    },
  );

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

  test(
    'write requests fall back to secondary API base on network failure',
    () async {
      final requestedUris = <String>[];
      final appState = _FakeAppState((method, uri, headers, body) async {
        requestedUris.add(uri.toString());
        if (uri.toString().startsWith(kPrimaryApiBase)) {
          throw const io.SocketException('primary port is offline');
        }
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'ok': true,
              'method': method,
              'body': jsonDecode(body ?? '{}'),
            }),
          ),
          200,
        );
      });
      addTearDown(appState.dispose);

      final response = asMap(
        await appState.post(
          '/auth/login',
          body: {'username': 'lsy', 'password': 'secret'},
          auth: false,
        ),
      );

      expect(response['ok'], isTrue);
      expect(response['method'], 'POST');
      expect(asMap(response['body'])['username'], 'lsy');
      expect(requestedUris, hasLength(2));
      expect(requestedUris.first, startsWith(kPrimaryApiBase));
      expect(requestedUris.last, startsWith(kFallbackApiBase));
    },
  );

  test('api health helpers build readable diagnostics', () {
    expect(
      healthUriForApiBase(kPrimaryApiBase).toString(),
      'http://113.44.50.108:8088/health',
    );
    expect(apiBaseLabel(kPrimaryApiBase), '113.44.50.108:8088');
    expect(apiBaseLabel('http://example.com/nested/api'), 'example.com/nested');
  });

  test('api endpoint checker reports both healthy and failed ports', () async {
    final requestedUris = <String>[];
    final appState = _FakeAppState((method, uri, headers, body) async {
      requestedUris.add(uri.toString());
      if (uri.toString() == healthUriForApiBase(kPrimaryApiBase).toString()) {
        return http.Response.bytes(utf8.encode('healthy\n'), 200);
      }
      throw const io.SocketException('fallback port offline');
    });
    addTearDown(appState.dispose);

    final statuses = await appState.checkApiEndpoints();

    expect(statuses, hasLength(2));
    expect(statuses.first.apiBase, kPrimaryApiBase);
    expect(statuses.first.ok, isTrue);
    expect(statuses.first.statusCode, 200);
    expect(statuses.first.message, 'healthy');
    expect(statuses.last.apiBase, kFallbackApiBase);
    expect(statuses.last.ok, isFalse);
    expect(statuses.last.message, contains('fallback port offline'));
    expect(requestedUris, [
      healthUriForApiBase(kPrimaryApiBase).toString(),
      healthUriForApiBase(kFallbackApiBase).toString(),
    ]);
  });

  test(
    'saveLogin always keeps username and only stores remembered password',
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
    },
  );

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
    expect(
      kThemePalettes.map((palette) => palette.label),
      containsAll(['晚餐烛光', '春日野餐', '烟火早市']),
    );
    expect(paletteForKey('missing').key, kThemeCreamPeach);
  });

  test('android branding uses themed app name resource', () {
    final manifest = io.File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final strings = io.File(
      'android/app/src/main/res/values/strings.xml',
    ).readAsStringSync();

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
        'meal': {'_id': 'meal-a', 'name': '番茄牛腩'},
      },
      {
        'meal': {'id': 'meal-b', 'name': '酸菜饺子'},
      },
      {'mealId': 'meal-c'},
      'meal-d',
      {
        'meal': {'_id': 'meal-a'},
      },
    ]);

    expect(ids, ['meal-a', 'meal-b', 'meal-c', 'meal-d']);
  });

  test('scheduleMealIdsFor restores selected ids for each meal type', () {
    final schedule = {
      'meals': {
        'breakfast': [
          {
            'meal': {'_id': 'meal-a', 'name': '小米粥'},
          },
        ],
        'lunch': [
          {'mealId': 'meal-b'},
        ],
        'dinner': ['meal-c'],
      },
    };

    expect(scheduleMealIdsFor(schedule, 'breakfast'), ['meal-a']);
    expect(scheduleMealIdsFor(schedule, 'lunch'), ['meal-b']);
    expect(scheduleMealIdsFor(schedule, 'dinner'), ['meal-c']);
    expect(scheduleMealIdsFor(schedule, 'snack'), isEmpty);
    expect(scheduleMealIds(schedule), ['meal-a', 'meal-b', 'meal-c']);
    expect(scheduleMealObjects(schedule).map((meal) => meal['_id']).toList(), [
      'meal-a',
      'meal-b',
      'meal-c',
    ]);
    expect(scheduleMealTypesWithMeals(schedule), [
      'breakfast',
      'lunch',
      'dinner',
    ]);
    expect(normalizedMealType('snack'), 'dinner');
    expect(scheduleMemoryTitle('lunch'), '午餐饭后回忆');
  });

  test('scheduleBalanceHints combines backend hints and health tags', () {
    final schedule = {
      'balanceHints': ['今天记得多喝水'],
      'meals': {
        'breakfast': [
          {
            'meal': {
              '_id': 'meal-a',
              'name': '油条',
              'healthTags': ['重口', '下饭'],
              'category': '面食主食',
            },
          },
        ],
        'lunch': [
          {
            'meal': {
              '_id': 'meal-b',
              'name': '炸酱面',
              'tags': ['重口'],
              'category': '面食主食',
            },
          },
        ],
      },
    };

    final hints = scheduleBalanceHints(schedule);

    expect(hints, contains('今天记得多喝水'));
    expect(hints, contains('今天蔬菜偏少，补一份青菜更舒服'));
    expect(hints, contains('重口菜偏多，搭配清淡汤水'));
    expect(hints, contains('蛋白质偏少，可以加蛋或豆制品'));
  });

  test('schedule month summary counts arranged days and nudges next steps', () {
    final summary = scheduleMonthSummary(
      {
        '2026-07-01': {
          'meals': {
            'breakfast': [
              {'name': '小米粥'},
            ],
            'lunch': [],
            'dinner': [
              {
                'meal': {'_id': 'meal-a', 'name': '番茄牛腩'},
              },
            ],
          },
        },
        '2026-07-02': {
          'lunch': [
            {'mealId': 'meal-b', 'name': '牛肉面'},
          ],
        },
      },
      year: 2026,
      month: 7,
    );

    expect(summary.totalDays, 31);
    expect(summary.arrangedDays, 2);
    expect(summary.emptyDays, 29);
    expect(summary.mealSlotCount, 3);
    expect(summary.mealCount, 3);
    expect(summary.progress, closeTo(2 / 31, 0.001));
    expect(scheduleMonthSummaryText(summary), '7 月已安排 2 天、3 餐，共 3 道菜。');
    expect(scheduleMonthEmptyDaysLabel(summary, limit: 3), '待安排：3、4、5 日等');
    expect(scheduleMonthNudge(summary), '已安排的日子里餐次还偏少，可以把早餐或午餐也补上。');
  });

  test('schedule month summary handles empty and nearly full months', () {
    final empty = scheduleMonthSummary(const {}, year: 2026, month: 2);

    expect(empty.totalDays, 28);
    expect(empty.arrangedDays, 0);
    expect(empty.progress, 0);
    expect(scheduleMonthSummaryText(empty), '2 月还没有饭桌安排，可以先从本周菜单生成一份草稿。');
    expect(scheduleMonthNudge(empty), '先安排今晚，再慢慢补齐两个人的一周三餐。');

    final almostFullSchedules = {
      for (var day = 1; day <= 28; day += 1)
        if (day != 27 && day != 28)
          dateString(DateTime(2026, 2, day)): {
            'dinner': [
              {'name': '家常晚餐'},
            ],
          },
    };
    final almostFull = scheduleMonthSummary(
      almostFullSchedules,
      year: 2026,
      month: 2,
    );

    expect(almostFull.arrangedDays, 26);
    expect(scheduleMonthEmptyDaysLabel(almostFull), '待安排：27、28 日');
    expect(scheduleMonthNudge(almostFull), '这个月饭桌节奏很完整，记得吃完补回忆和照片。');
  });

  test('meal favorite helpers build safe lightweight update fields', () {
    final meal = {'_id': 'meal-a', 'name': '番茄牛腩', 'favorite': true};
    final stringFavorite = {
      '_id': 'meal-b',
      'name': '酸菜饺子',
      'favorite': 'true',
    };

    expect(mealIsFavorite(meal), isTrue);
    expect(mealIsFavorite(stringFavorite), isTrue);
    expect(mealIsFavorite({'favorite': false}), isFalse);
    expect(mealFavoriteUpdateFields(meal, favorite: false), {
      'name': '番茄牛腩',
      'favorite': 'false',
    });
  });

  test('meal rating helpers clamp and build safe update fields', () {
    final meal = {'_id': 'meal-a', 'name': '番茄牛腩', 'rating': 4.5};

    expect(mealRatingValue('4.5'), 4.5);
    expect(mealRatingValue('-1'), 0);
    expect(mealRatingValue('9'), 5);
    expect(mealRatingValue('', fallback: 3.5), 3.5);
    expect(mealRatingUpdateFields(meal, rating: 4.25), {
      'name': '番茄牛腩',
      'rating': '4.3',
    });
  });

  test('meal completeness helpers find missing recipe details', () {
    final complete = mealCompleteness({
      'image': '/uploads/beef.jpg',
      'description': '牛肉软烂，番茄汤汁浓。',
      'ingredients': [
        {'name': '牛肉', 'amount': '500g'},
      ],
      'steps': [
        {'description': '牛肉焯水后和番茄一起炖煮'},
      ],
      'tips': '最后加盐，汤味更清亮。',
    });
    final incomplete = mealCompleteness({
      'photos': [
        {'url': '/uploads/noodle.jpg'},
      ],
      'ingredients': ['面条 1把'],
      'steps': [],
    });

    expect(complete.completed, 5);
    expect(complete.value, 1);
    expect(mealCompletenessLabel(complete), '资料完整');
    expect(mealCompletenessHint(complete), contains('照片、食材、做法和小技巧'));
    expect(incomplete.completed, 2);
    expect(incomplete.missing, ['简介', '做法步骤', '小技巧']);
    expect(mealCompletenessLabel(incomplete), '资料 2/5');
    expect(mealCompletenessHint(incomplete), contains('简介、做法步骤、小技巧'));
    expect(
      mealHasNonEmptyList([
        {'name': '', 'amount': ''},
      ]),
      isFalse,
    );
  });

  test('meal completeness sorting puts incomplete recipes first', () {
    final meals = [
      {
        'name': '完整菜',
        'image': '/uploads/full.jpg',
        'description': '有简介',
        'ingredients': ['鸡蛋 2个'],
        'steps': ['炒熟'],
        'tips': '小火',
      },
      {
        'name': '缺做法',
        'image': '/uploads/missing-step.jpg',
        'description': '有简介',
        'ingredients': ['面条 1把'],
        'steps': [],
        'tips': '',
      },
      {'name': '空菜', 'ingredients': []},
    ];

    final sorted = sortMealsByCompleteness(meals).map(asMap).toList();

    expect(sorted.map((meal) => meal['name']), ['空菜', '缺做法', '完整菜']);
  });

  test('meal edit helpers build drafts templates and save warning', () {
    expect(ingredientDraftsFromText('鸡蛋 2个\n葱花 少许'), [
      {'name': '鸡蛋', 'amount': '2个'},
      {'name': '葱花', 'amount': '少许'},
    ]);
    expect(stepDraftsFromText('洗菜\n炒熟'), [
      {'description': '洗菜'},
      {'description': '炒熟'},
    ]);
    expect(mealIngredientTemplate('面食主食'), contains('主食 1份'));
    expect(mealStepTemplate('汤羹'), contains('转小火'));

    final draftCompleteness = mealCompleteness(
      mealEditDraftForCompleteness(
        image: '',
        description: '快手早餐',
        ingredientsText: '鸡蛋 2个',
        stepsText: '',
        tips: '',
      ),
    );

    expect(draftCompleteness.missing, ['成品照片', '做法步骤', '小技巧']);
    expect(
      mealSaveCompletenessConfirmMessage(draftCompleteness),
      contains('仍然保存这道菜吗'),
    );
  });

  test('meal delete confirm message names the target safely', () {
    expect(mealDeleteConfirmMessage({'name': '番茄牛腩'}), contains('「番茄牛腩」'));
    expect(mealDeleteConfirmMessage({}), contains('这道菜'));
  });

  test('weekly draft helpers remove meal from ids and preview', () {
    final draft = {
      'days': [
        {
          'date': '2026-07-06',
          'meals': {
            'breakfast': ['meal-a', 'meal-b'],
            'lunch': ['meal-c'],
            'dinner': [],
          },
        },
      ],
      'preview': [
        {
          'date': '2026-07-06',
          'meals': {
            'breakfast': [
              {'_id': 'meal-a', 'name': '番茄牛腩'},
              {'_id': 'meal-b', 'name': '鸡蛋灌饼'},
            ],
            'lunch': [
              {'_id': 'meal-c', 'name': '大盘鸡'},
            ],
            'dinner': [],
          },
        },
      ],
    };

    final initialEntries = planMealEntries(
      asMap(asList(draft['preview']).first)['meals']['breakfast'],
    );
    expect(initialEntries.first['id'], 'meal-a');
    expect(initialEntries.first['name'], '番茄牛腩');

    final updated = removeMealFromWeeklyDraft(
      draft,
      date: '2026-07-06',
      type: 'breakfast',
      mealId: 'meal-a',
    );
    final updatedDays = asList(updated['days']).map(asMap).toList();
    final updatedPreview = asList(updated['preview']).map(asMap).toList();

    expect(
      mealIdsFromPlanValue(asMap(updatedDays.first['meals'])['breakfast']),
      ['meal-b'],
    );
    expect(
      planMealEntries(
        asMap(updatedPreview.first['meals'])['breakfast'],
      ).map((item) => item['id']),
      ['meal-b'],
    );
  });

  test(
    'weekly draft helpers add meal to ids and preview without duplicates',
    () {
      final draft = {
        'days': [
          {
            'date': '2026-07-06',
            'meals': {'breakfast': [], 'lunch': [], 'dinner': []},
          },
        ],
        'preview': [
          {
            'date': '2026-07-06',
            'meals': {'breakfast': [], 'lunch': [], 'dinner': []},
          },
        ],
      };
      final meal = {'_id': 'meal-x', 'name': '牛肉面'};

      final updated = addMealToWeeklyDraft(
        draft,
        date: '2026-07-06',
        type: 'dinner',
        meal: meal,
      );
      final duplicated = addMealToWeeklyDraft(
        updated,
        date: '2026-07-06',
        type: 'dinner',
        meal: meal,
      );
      final updatedDays = asList(duplicated['days']).map(asMap).toList();
      final updatedPreview = asList(duplicated['preview']).map(asMap).toList();

      expect(
        mealIdsFromPlanValue(asMap(updatedDays.first['meals'])['dinner']),
        ['meal-x'],
      );
      final previewEntry = planMealEntries(
        asMap(updatedPreview.first['meals'])['dinner'],
      ).first;
      expect(previewEntry['id'], 'meal-x');
      expect(previewEntry['name'], '牛肉面');
    },
  );

  test('planHints reads and deduplicates balance hints', () {
    expect(
      planHints({
        'hints': ['今天蔬菜偏少', '包含快手菜', '今天蔬菜偏少', ''],
      }),
      ['今天蔬菜偏少', '包含快手菜'],
    );
    expect(
      planHints({
        'balanceHints': ['今天口味偏重'],
      }),
      ['今天口味偏重'],
    );
    expect(planHints({'hints': []}), isEmpty);
  });

  test('weekly draft apply summary counts days slots and meals', () {
    final summary = weeklyDraftApplySummary({
      'days': [
        {
          'date': '2026-07-06',
          'meals': {
            'breakfast': ['meal-a'],
            'lunch': [
              {'_id': 'meal-b', 'name': '牛肉面'},
              {
                'meal': {'_id': 'meal-c', 'name': '拌黄瓜'},
              },
            ],
            'dinner': [],
          },
        },
        {
          'date': '2026-07-07',
          'meals': {
            'breakfast': [],
            'lunch': [],
            'dinner': [
              {'name': '手写菜名'},
            ],
          },
        },
        {
          'date': '2026-07-08',
          'meals': {'breakfast': [], 'lunch': [], 'dinner': []},
        },
      ],
    });

    expect(summary.dayCount, 2);
    expect(summary.mealSlotCount, 3);
    expect(summary.mealCount, 4);
    expect(weeklyDraftApplySummaryText(summary), '草稿包含 2 天、3 餐、4 道菜');
    expect(weeklyDraftApplyConfirmMessage(summary), contains('确认写入日历吗'));
    expect(
      weeklyDraftApplySummaryText(
        weeklyDraftApplySummary({
          'preview': [
            {
              'date': '2026-07-09',
              'meals': {'breakfast': [], 'lunch': [], 'dinner': []},
            },
          ],
        }),
      ),
      '草稿里还没有安排菜品',
    );
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

  test('reviewNextStepHints suggests useful follow-up actions', () {
    expect(
      reviewNextStepHints({
        'summary': {
          'plannedMealCount': 0,
          'memoryCount': 0,
          'photoCount': 0,
          'wishlistOpen': 2,
        },
      }),
      ['先安排一顿这个周期最想吃的饭', '吃完后补一条饭后回忆，留下今天的味道', '下次开饭前拍一张饭桌照片'],
    );
    expect(
      reviewNextStepHints({
        'summary': {
          'plannedMealCount': 4,
          'memoryCount': 2,
          'photoCount': 1,
          'wishlistOpen': 1,
        },
        'topMeals': [],
      }),
      ['把 1 个想吃愿望安排进最近的晚餐', '多安排几顿后会形成常上桌菜榜'],
    );
    expect(
      reviewNextStepHints({
        'summary': {
          'plannedMealCount': 4,
          'memoryCount': 2,
          'photoCount': 1,
          'wishlistOpen': 0,
        },
        'topMeals': [
          {'name': '番茄牛腩'},
        ],
      }),
      ['给最喜欢的一道菜补充做法、照片或小技巧'],
    );
  });

  test('review top meal helpers read identity and image fields', () {
    expect(reviewTopMealId({'_id': 'meal-a', 'name': '番茄牛腩'}), 'meal-a');
    expect(reviewTopMealId({'mealId': 'meal-b', 'name': '牛肉面'}), 'meal-b');
    expect(
      reviewTopMealImage({'coverImage': '/uploads/cover.jpg'}),
      '$kAssetBase/uploads/cover.jpg',
    );
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
        {'photo': '/api/uploads/two.jpg', 'title': '周末晚餐'},
      ],
    });

    expect(photos, hasLength(2));
    expect(photos.first['url'], 'http://113.44.50.108:3002/uploads/one.jpg');
    expect(photos.last['title'], '周末晚餐');
  });

  test('mealRelatedMemoryItems reads wrapped memories and limits preview', () {
    final memories = mealRelatedMemoryItems({
      'memories': [
        {'_id': 'memory-a', 'title': 'first'},
        {},
        {'_id': 'memory-b', 'title': 'second'},
        {'_id': 'memory-c', 'title': 'third'},
        {'_id': 'memory-d', 'title': 'fourth'},
      ],
    });

    expect(memories.map((item) => item['_id']), [
      'memory-a',
      'memory-b',
      'memory-c',
    ]);
    expect(
      mealRelatedMemoryItems({
        'memories': [
          {'_id': 'memory-a'},
          {'_id': 'memory-b'},
        ],
      }, limit: 0)
          .map((item) => item['_id']),
      ['memory-a', 'memory-b'],
    );
  });

  test('memory helpers keep selected meal ids and existing photo urls', () {
    final memory = {
      'mealIds': [
        {'_id': 'meal-a', 'name': 'first'},
        'meal-b',
        {'id': 'meal-c'},
        {'_id': 'meal-a'},
      ],
      'photos': ['/api/uploads/one.jpg', 'http://cdn.example.com/two.jpg', ''],
    };

    expect(memoryMealIds(memory), ['meal-a', 'meal-b', 'meal-c']);
    expect(memoryExistingPhotoRefs(memory), [
      '/api/uploads/one.jpg',
      'http://cdn.example.com/two.jpg',
    ]);
    expect(memoryPhotoUrls(memory), [
      '$kAssetBase/api/uploads/one.jpg',
      'http://cdn.example.com/two.jpg',
    ]);
  });

  test('photoMealNames extracts populated meal names', () {
    final names = photoMealNames({
      'meals': [
        {
          'meal': {'name': '酸菜猪肉饺子'},
        },
      ],
      'meal': {'name': '番茄牛腩'},
    });

    expect(names, ['酸菜猪肉饺子', '番茄牛腩']);
  });

  test('album photo helpers keep memory identity and fallback payload', () {
    final photo = {
      'memoryId': 'memory-a',
      'date': '2026-07-09T12:00:00.000Z',
      'mealType': 'dinner',
      'title': '周四晚餐',
      'mood': '开心',
      'note': '牛肉很软',
      'rating': 5,
      'photo': '/api/uploads/dinner.jpg',
      'meals': [
        {'_id': 'meal-a', 'name': '番茄牛腩'},
      ],
    };
    final nested = {
      'memory': {'_id': 'memory-b'},
      'url': '/api/uploads/second.jpg',
    };
    final fallback = albumPhotoMemoryFallback(photo);

    expect(albumPhotoMemoryId(photo), 'memory-a');
    expect(albumPhotoMemoryId(nested), 'memory-b');
    expect(albumPhotoDate(photo), '2026-07-09');
    expect(fallback['_id'], 'memory-a');
    expect(fallback['photos'], ['/api/uploads/dinner.jpg']);
    expect(memoryMealIds(fallback), ['meal-a']);
  });

  test('anniversary helpers parse templates and build descriptions', () {
    final templates = anniversaryTemplates({
      'value': [
        {
          'title': '恋爱纪念日',
          'theme': '纪念日',
          'description': '选两道共同喜欢的菜。',
          'structure': ['共同喜欢', '甜品'],
        },
      ],
    });

    expect(templates, hasLength(1));
    expect(anniversaryTemplateStructure(templates.first), ['共同喜欢', '甜品']);
    expect(
      anniversaryTemplateDescription(templates.first),
      '选两道共同喜欢的菜。\n建议结构：共同喜欢、甜品',
    );
    expect(isDateText('2026-07-09'), isTrue);
    expect(isDateText('2026/07/09'), isFalse);
    expect(
      anniversaryLocalDate('2026-07-09T12:00:00.000Z'),
      DateTime(2026, 7, 9),
    );
    expect(
      anniversaryCountdownLabel({
        'date': '2026-07-10',
      }, today: DateTime(2026, 7, 10, 18)),
      '\u4eca\u5929\u5c31\u662f\u7eaa\u5ff5\u65e5',
    );
    expect(
      anniversaryCountdownLabel({
        'date': '2026-07-13',
      }, today: DateTime(2026, 7, 10)),
      '\u8fd8\u6709 3 \u5929',
    );
    expect(
      anniversaryCountdownLabel({
        'date': '2026-07-08',
      }, today: DateTime(2026, 7, 10)),
      '\u5df2\u8fc7 2 \u5929',
    );
    expect(anniversaryCountdownLabel({'date': ''}), '\u65e5\u671f\u5f85\u5b9a');
  });

  test('anniversary menus sort by upcoming date first', () {
    final sorted = anniversarySortedMenus([
      {'title': 'past', 'date': '2026-07-01'},
      {'title': 'unknown', 'date': ''},
      {'title': 'future', 'date': '2026-07-13'},
      {'title': 'today', 'date': '2026-07-10'},
    ], today: DateTime(2026, 7, 10));

    expect(sorted.map((item) => item['title']), [
      'today',
      'future',
      'past',
      'unknown',
    ]);
  });

  test('anniversaryMenuMealNames reads populated menu meals', () {
    final names = anniversaryMenuMealNames({
      'meals': {
        'breakfast': [
          {
            'meal': {'name': '小米粥'},
          },
        ],
        'dinner': [
          {'name': '番茄牛腩'},
          {'name': '番茄牛腩'},
        ],
      },
    });

    expect(names, ['小米粥', '番茄牛腩']);
  });

  test('anniversaryMenuMealIds extracts selected meal ids by meal type', () {
    final menu = {
      'meals': {
        'breakfast': [
          {'_id': 'meal-a', 'name': '小米粥'},
        ],
        'lunch': ['meal-b'],
        'dinner': [
          {
            'meal': {'_id': 'meal-c', 'name': '番茄牛腩'},
          },
          {
            'meal': {'_id': 'meal-c'},
          },
        ],
      },
    };
    final ids = anniversaryMenuMealIds(menu);

    expect(ids['breakfast'], ['meal-a']);
    expect(ids['lunch'], ['meal-b']);
    expect(ids['dinner'], ['meal-c']);
    expect(scheduleMealIds(menu), ['meal-a', 'meal-b', 'meal-c']);
    expect(scheduleMealObjects(menu).map((meal) => meal['_id']).toList(), [
      'meal-a',
      'meal-b',
      'meal-c',
    ]);
  });

  test('wishlist meal helpers accept populated object and string id', () {
    expect(
      wishlistMealId({
        'title': '想吃番茄牛腩',
        'mealId': {'_id': 'meal-a', 'name': '番茄牛腩'},
      }),
      'meal-a',
    );
    expect(
      wishlistMealName({
        'title': '想吃番茄牛腩',
        'mealId': {'_id': 'meal-a', 'name': '番茄牛腩'},
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
    expect(
      wishlistStatusBadgeLabel({'title': '\u624b\u5199\u613f\u671b'}),
      '\u60f3\u5403\u4e2d',
    );
    expect(
      wishlistStatusBadgeLabel({'status': 'planned'}),
      '\u5df2\u5b89\u6392',
    );
    expect(wishlistIsDone({'status': 'done'}), isTrue);
    expect(wishlistIsDone({'status': 'open'}), isFalse);
    expect(wishlistPriorityLabel('high'), '\u4f18\u5148\u60f3\u5403');
    expect(wishlistPriorityLabel('low'), '\u968f\u7f18\u60f3\u5403');
    expect(wishlistPriorityLabel('normal'), '\u666e\u901a\u60f3\u5403');
    expect(wishlistPriorityLabel('unknown'), '\u666e\u901a\u60f3\u5403');
    expect(
      wishlistSignalLabels({
        'createdByPartner': true,
        'votedByPartner': true,
        'votedByMe': true,
      }),
      ['TA \u521b\u5efa', 'TA \u4e5f\u6295\u4e86', '\u6211\u5df2\u6295'],
    );
    expect(wishlistSignalLabels({'partnerSignal': true}), ['TA \u60f3\u5403']);
    expect(
      wishlistDashboardNote({'priority': 'high'}),
      '\u4f18\u5148\u60f3\u5403',
    );
    expect(
      wishlistDashboardNote({'note': '\u60f3\u52a0\u4e00\u70b9\u9999\u83dc'}),
      '\u60f3\u52a0\u4e00\u70b9\u9999\u83dc',
    );
    expect(
      wishlistDashboardActionLabel({'title': '\u624b\u5199\u613f\u671b'}),
      '\u5efa\u8c31\u5e76\u5b89\u6392',
    );
    expect(
      wishlistDashboardActionLabel({
        'mealId': {'_id': 'meal-a', 'name': '\u9178\u83dc\u9c7c'},
      }),
      '\u4eca\u665a\u5403',
    );
  });

  test('wishlist sorting summarizes the best dinner candidate', () {
    final sorted = sortWishlistItems([
      {'title': '已安排牛肉面', 'status': 'planned', 'priority': 'high'},
      {'title': '完成的饺子', 'status': 'done', 'priority': 'high'},
      {
        'title': '普通炒菜',
        'status': 'open',
        'priority': 'normal',
        'votes': 10,
        'createdAt': '2026-07-11T08:00:00.000Z',
      },
      {
        'title': 'TA 的酸菜鱼',
        'status': 'open',
        'priority': 'high',
        'partnerSignal': true,
        'votes': 3,
        'createdAt': '2026-07-10T08:00:00.000Z',
      },
      {
        'title': '我想吃饺子',
        'status': 'open',
        'priority': 'high',
        'votes': 8,
        'createdAt': '2026-07-12T08:00:00.000Z',
      },
    ]);

    expect(sorted.map((item) => item['title']), [
      'TA 的酸菜鱼',
      '我想吃饺子',
      '普通炒菜',
      '已安排牛肉面',
      '完成的饺子',
    ]);
    expect(wishlistFilteredItems(sorted, 'open'), hasLength(3));
    expect(wishlistStatusCounts(sorted), {'open': 3, 'planned': 1, 'done': 1});
    expect(wishlistTopCandidate(sorted)?['title'], 'TA 的酸菜鱼');
    expect(wishlistSummaryText(sorted), 'TA 想吃：TA 的酸菜鱼，已有 3 票，可以一键安排到今晚。');
    expect(wishlistSummaryText(const []), '当前没有待安排的想吃愿望，记录一个小馋念后就能排进今天晚餐。');
  });

  test('wishlist draft fields normalize add wish form data', () {
    expect(wishlistDraftFields(title: '   '), isNull);

    final draft = wishlistDraftFields(
      title: '  周末牛肉面  ',
      note: '  少辣，多放香菜  ',
      category: '   ',
      priority: 'unknown',
    );

    expect(draft, {
      'title': '周末牛肉面',
      'note': '少辣，多放香菜',
      'category': '小家想吃',
      'priority': 'normal',
    });
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
          'mealId': {'_id': 'meal-a', 'name': '酸菜鱼'},
        },
      ],
      'recentPhotos': [
        {
          'photo': 'http://113.44.50.108:3002/uploads/dinner.jpg',
          'title': '晚餐',
        },
        '',
      ],
      'anniversaries': [
        {'title': '已经过了', 'date': '2026-07-01'},
        {'title': '恋爱纪念日', 'date': '2026-07-13'},
        {'title': '今天菜单', 'date': '2026-07-10'},
      ],
    };

    final wishes = dashboardPartnerWishlist(data);
    final photos = dashboardRecentPhotos(data);
    final anniversaries = dashboardAnniversaryMenus(
      data,
      today: DateTime(2026, 7, 10),
    );

    expect(wishes, hasLength(1));
    expect(wishlistMealId(wishes.first), 'meal-a');
    expect(wishlistMealName(wishes.first), '酸菜鱼');
    expect(photos, hasLength(1));
    expect(photos.first['title'], '晚餐');
    expect(anniversaries.map((item) => item['title']), [
      '今天菜单',
      '恋爱纪念日',
      '已经过了',
    ]);
  });

  test('dashboard shopping helpers summarize current week groceries', () {
    final items = dashboardShoppingItems({
      'shoppingList': {
        'items': [
          {'name': '鸡蛋', 'amount': '10个', 'checked': true},
          {'name': '番茄', 'amount': '3个', 'checked': false},
        ],
      },
    });

    expect(items, hasLength(2));
    expect(shoppingDashboardRatioText(items), '1/2');
    expect(shoppingDashboardRatioText(const []), '待生成');
    expect(shoppingItemPreviewText(items.last), '番茄 3个');
  });

  test(
    'dashboard maintenance helpers count default meals and image issues',
    () {
      final data = {
        'defaultMeals': {'total': 200, 'imported': 180, 'missing': 20},
        'imageIssues': {
          'items': [
            {'_id': 'issue-a'},
            {'_id': 'issue-b'},
          ],
        },
      };

      final status = dashboardDefaultMealStatus(data);

      expect(defaultMealTotalCount(status), 200);
      expect(defaultMealImportedCount(status), 180);
      expect(defaultMealMissingCount(status), 20);
      expect(dashboardImageIssueOpenCount(data), 2);
      expect(dashboardNeedsMaintenance(data), isTrue);
      expect(
        dashboardNeedsMaintenance({
          'defaultMeals': {'missing': 0},
        }),
        isFalse,
      );
    },
  );

  test('image issue helpers extract meal identity and note', () {
    final populated = {
      '_id': 'issue-a',
      'meal': {'_id': 'meal-a', 'name': '番茄牛腩'},
      'note': '图片像甜品',
    };
    expect(imageIssueMealId(populated), 'meal-a');
    expect(imageIssueMealName(populated), '番茄牛腩');
    expect(imageIssueNote(populated), '图片像甜品');

    final fallback = {'mealId': 'meal-b', 'issueType': 'mismatch'};
    expect(imageIssueMealId(fallback), 'meal-b');
    expect(imageIssueMealName(fallback), 'meal-b');
    expect(imageIssueNote(fallback), '菜名不匹配');
    expect(imageIssueTypeLabel('non_food'), '不是菜品照片');
    expect(
      imageIssueDraftNote(issueType: 'low_quality', note: '画面太暗'),
      '图片模糊或太暗：画面太暗',
    );
    expect(imageIssueDraftNote(issueType: 'missing'), '没有展示成品');
  });

  test('image issue summaries group type counts and priority hints', () {
    final issues = [
      {'issueType': 'low_quality'},
      {'issueType': 'non_food'},
      {'type': 'non_food'},
      {'category': 'duplicate'},
      {'note': '没有类型时默认按不匹配处理'},
    ];

    final counts = imageIssueTypeCounts(issues);

    expect(imageIssueType(issues.last), 'mismatch');
    expect(counts.map((entry) => '${entry.key}:${entry.value}'), [
      'mismatch:1',
      'non_food:2',
      'low_quality:1',
      'duplicate:1',
    ]);
    expect(imageIssueFixPriorityText(issues), '优先替换不是菜品照片的项目，避免默认菜库出现明显错图。');
    expect(
      imageIssueFixPriorityText([
        {'issueType': 'mismatch'},
      ]),
      '优先处理菜名不匹配的图片，保证排餐时一眼能认出菜。',
    );
    expect(
      imageIssueFixPriorityText([
        {'issueType': 'low_quality'},
      ]),
      '按数量最多的问题类型优先处理：图片模糊或太暗。',
    );
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

  test('shopping item draft normalizes manual entry fields', () {
    expect(normalizedShoppingCategory('vegetable'), 'vegetable');
    expect(normalizedShoppingCategory('unknown'), 'other');

    final draft = shoppingItemDraftFromText('鸡蛋 10个', category: 'meat_egg');
    expect(draft, isNotNull);
    expect(draft!['name'], '鸡蛋');
    expect(draft['amount'], '10个');
    expect(draft['category'], 'meat_egg');

    expect(shoppingItemDraftFromText('   '), isNull);
  });

  test('shopping progress helpers track purchased and remaining items', () {
    final items = [
      {'name': '\u9e21\u86cb', 'checked': true},
      {'name': '\u897f\u7ea2\u67ff', 'purchased': true},
      {'name': '\u9762\u6761', 'checked': false},
    ];

    expect(shoppingItemChecked(items.first), isTrue);
    expect(shoppingItemChecked(items.last), isFalse);
    expect(shoppingPurchasedCount(items), 2);
    expect(shoppingRemainingItems(items).map((item) => item['name']), [
      '\u9762\u6761',
    ]);
    expect(shoppingProgressValue(items), closeTo(2 / 3, 0.001));
    expect(
      shoppingProgressText(items),
      '\u5df2\u8d2d 2 / \u5171 3\uff0c\u5269\u4f59 1 \u9879',
    );
    expect(
      shoppingProgressText(const []),
      '\u8fd8\u6ca1\u6709\u91c7\u8d2d\u9879',
    );
  });

  test('shopping remaining category summary groups unchecked items', () {
    final items = [
      {'name': '白菜', 'category': 'vegetable', 'checked': false},
      {'name': '鸡蛋', 'category': 'meat_egg', 'checked': true},
      {'name': '牛肉', 'category': 'meat_egg', 'checked': false},
      {'name': '面条', 'category': 'staple', 'checked': false},
      {'name': '生抽', 'category': 'seasoning', 'purchased': false},
      {'name': '保鲜袋', 'category': 'other', 'checked': false},
      {'name': '香菜', 'category': 'vegetable', 'checked': false},
    ];

    final counts = shoppingRemainingCategoryCounts(items);

    expect(counts.map((entry) => '${entry.key}:${entry.value}'), [
      'vegetable:2',
      'meat_egg:1',
      'staple:1',
      'seasoning:1',
      'other:1',
    ]);
    expect(
      shoppingRemainingCategorySummary(items),
      '蔬菜 2 · 肉蛋 1 · 主食 1 · 调料 1 · 其他 1',
    );
    expect(
      shoppingRemainingCategorySummary([
        {'name': '鸡蛋', 'category': 'meat_egg', 'checked': true},
      ]),
      '本周采购项都已勾选完成',
    );
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

    final outputBytes = renderFoodFocusBytes(
      Uint8List.fromList(img.encodeJpg(source)),
    );
    final output = img.decodeImage(Uint8List.fromList(outputBytes));

    expect(outputBytes.length, greaterThan(100));
    expect(output, isNotNull);
    expect(output!.getPixel(24, 25).r, greaterThan(output.getPixel(2, 2).r));
  });

  test('memory photo upload hints explain format and state', () {
    expect(readableFileSize(900), '900 B');
    expect(readableFileSize(1536), '1.5 KB');
    expect(readableFileSize(kUploadImageMaxBytes), '2.0 MB');
    expect(
      memoryPhotoPickerHint(existingCount: 0, newCount: 0),
      contains('自动压缩为 JPG'),
    );
    expect(
      memoryPhotoPickerHint(existingCount: 2, newCount: 0),
      contains('已有 2 张线上照片'),
    );
    expect(
      memoryPhotoPickerHint(existingCount: 1, newCount: 3),
      contains('新增 3 张已压缩为 JPG'),
    );
  });

  test('upload jpeg encoder keeps memory photos under size limit', () {
    final source = img.Image(width: 1600, height: 1200);
    for (var y = 0; y < source.height; y += 1) {
      for (var x = 0; x < source.width; x += 1) {
        source.setPixelRgb(
          x,
          y,
          (x * 19 + y * 7) % 256,
          (x * 5 + y * 23) % 256,
          (x * 11 + y * 13) % 256,
        );
      }
    }

    final outputBytes = encodeJpgWithinUploadLimit(source);
    final output = img.decodeImage(Uint8List.fromList(outputBytes));

    expect(outputBytes.length, lessThanOrEqualTo(kUploadImageMaxBytes));
    expect(output, isNotNull);
    expect(output!.width, lessThanOrEqualTo(kFoodFocusMaxSide));
    expect(output.height, lessThanOrEqualTo(kFoodFocusMaxSide));
  });

  test('guest order session helpers normalize lists and statuses', () {
    final sessions = guestOrderSessions({
      'sessions': [
        {'_id': 'session-a', 'title': '周末家宴', 'status': 'open'},
        {'id': 'session-b', 'title': '生日晚餐', 'status': 'locked'},
        {'title': '缺少 ID'},
      ],
    });

    expect(sessions.length, 2);
    expect(idOf(sessions.first), 'session-a');
    expect(guestOrderStatusLabel('open'), '开放点菜');
    expect(guestOrderStatusLabel('locked'), '已锁单');
    expect(guestOrderStatusLabel('expired'), '已过期');
  });

  test('guest order summary supports nested and flattened payloads', () {
    final nested = guestOrderSummary({
      'summary': {'guestCount': 3, 'dishCount': 5, 'totalQuantity': 8},
    });
    final flat = guestOrderSummary({
      'guestCount': 2,
      'dishCount': 4,
      'totalQuantity': 6,
    });

    expect(guestOrderNumber(nested['guestCount']), 3);
    expect(guestOrderNumber(nested['totalQuantity']), 8);
    expect(guestOrderNumber(flat['dishCount']), 4);
    expect(guestOrderNumber('6'), 6);
  });

  testWidgets('guest order sessions page renders restaurant-style summary', (
    tester,
  ) async {
    final appState = _FakeAppState((method, uri, headers, body) async {
      expect(method, 'GET');
      expect(uri.path, endsWith('/guest-orders'));
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'sessions': [
              {
                'id': 'session-a',
                'title': '周六朋友家宴',
                'status': 'open',
                'guestCount': 3,
                'totalQuantity': 8,
                'expiresAt': '2026-07-24T12:00:00.000Z',
              },
            ],
          }),
        ),
        200,
      );
    })
      ..token = fakeJwt(DateTime.now().add(const Duration(hours: 2)))
      ..user = {'id': 'host-a'}
      ..household = {'id': 'home-a', 'name': '测试小家'};
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      AppScope(
        appState: appState,
        child: const MaterialApp(home: GuestOrderSessionsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('宴请点菜'), findsOneWidget);
    expect(find.text('周六朋友家宴'), findsOneWidget);
    expect(find.text('3 位客人'), findsOneWidget);
    expect(find.text('8 份菜'), findsOneWidget);
    expect(find.text('开放点菜'), findsOneWidget);
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
