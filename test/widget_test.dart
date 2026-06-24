import 'dart:typed_data';

import 'package:eatwhat_flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
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
