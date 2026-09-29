import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_exe/pro/pro_controller.dart';
import 'package:todo_exe/state/todo_store.dart';
import 'package:todo_exe/theme/term_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mode auto 는 폰 설정을, light/dark 는 고정값을 따른다 (cmd)', () async {
    SharedPreferences.setMockInitialValues({});
    final store = TodoStore();
    await store.load();

    store.systemBrightness = Brightness.light;
    expect(store.palette, same(TermPalette.cmdLight));
    store.systemBrightness = Brightness.dark;
    expect(store.palette, same(TermPalette.cmdTheme));

    store.run('mode light');
    expect(store.palette.isLight, isTrue);
    store.run('mode dark');
    store.systemBrightness = Brightness.light;
    expect(store.palette.isLight, isFalse);
  });

  test('phosphor · amber 는 밝은 모드에서도 어둡다', () async {
    SharedPreferences.setMockInitialValues({});
    final pro = ProController();
    final store = TodoStore(pro: pro);
    await store.load();
    store.run('pro --dev');
    store.run('mode light');
    store.run('theme amber');
    expect(store.palette, same(TermPalette.amber));
    expect(store.palette.isLight, isFalse);
  });
}
