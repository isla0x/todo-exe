import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/boot_screen.dart';
import 'state/todo_store.dart';
import 'theme/term_palette.dart';
import 'widget_sync.dart';
import 'widgets/term_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = TodoStore();
  await store.load();

  // 위젯은 할 일이 바뀔 때마다 새로 그린다.
  await WidgetSync.init();
  WidgetSync.push(store.data, store.now());
  store.addListener(() => WidgetSync.push(store.data, store.now()));

  runApp(TodoExeApp(store: store));
}

class TodoExeApp extends StatelessWidget {
  const TodoExeApp({super.key, required this.store});

  final TodoStore store;

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
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: p.bar,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (store.data.crt)
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: p.bg,
        fontFamily: monoFamily,
        fontFamilyFallback: monoFallback,
        colorScheme: ColorScheme.dark(surface: p.bg, primary: p.ok, secondary: p.cmd, error: p.warn),
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
