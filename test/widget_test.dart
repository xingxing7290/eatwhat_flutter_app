import 'package:eatwhat_flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
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
