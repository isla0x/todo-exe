import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pro/pro_controller.dart';
import 'screens/boot_screen.dart';
import 'state/todo_store.dart';
import 'theme/term_palette.dart';
import 'widget_sync.dart';
import 'widgets/term_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final pro = ProController();
  await pro.init();
  final store = TodoStore(pro: pro);
  await store.load();
  store.systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

  // 위젯은 할 일이나 PRO 상태가 바뀔 때마다 새로 그린다. (store 는 pro 변화도 알려준다)
  await WidgetSync.init();
  void pushWidget() => WidgetSync.push(store.data, store.now(), pro: store.isPro);
  pushWidget();
  store.addListener(pushWidget);

  runApp(TodoExeApp(store: store));
}

class TodoExeApp extends StatefulWidget {
  const TodoExeApp({super.key, required this.store});

  final TodoStore store;

  @override
  State<TodoExeApp> createState() => _TodoExeAppState();
}

class _TodoExeAppState extends State<TodoExeApp> with WidgetsBindingObserver {
  TodoStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store.systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 폰에서 다크/라이트를 바꾸면 바로 따라간다.
  @override
  void didChangePlatformBrightness() {
    store.systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = store.palette;
        return MaterialApp(
          title: 'todo.exe',
          debugShowCheckedModeBanner: false,
          theme: _theme(p),
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: (p.isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light).copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: p.bar,
              systemNavigationBarIconBrightness: p.isLight ? Brightness.dark : Brightness.light,
            ),
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (store.crtOn)
                  const Positioned.fill(
                    child: IgnorePointer(child: CustomPaint(painter: ScanlinePainter())),
                  ),
              ],
            ),
          ),
          home: BootScreen(store: store),
        );
      },
    );
  }

  ThemeData _theme(TermPalette p) => ThemeData(
        useMaterial3: true,
        brightness: p.isLight ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: p.bg,
        fontFamily: monoFamily,
        fontFamilyFallback: monoFallback,
        colorScheme: p.isLight
            ? ColorScheme.light(surface: p.bg, primary: p.ok, secondary: p.cmd, error: p.warn)
            : ColorScheme.dark(surface: p.bg, primary: p.ok, secondary: p.cmd, error: p.warn),
        splashFactory: NoSplash.splashFactory,
        highlightColor: p.fg.withAlpha(30),
        hoverColor: p.fg.withAlpha(16),
        focusColor: p.cmd.withAlpha(48),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: p.ok,
          selectionColor: p.cmd.withAlpha(90),
          selectionHandleColor: p.ok,
        ),
      );
}
