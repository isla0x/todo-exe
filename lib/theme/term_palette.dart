import 'package:flutter/widgets.dart';

/// 터미널 색 테마. `theme cmd|phosphor|amber` 로 바꾼다.
class TermPalette {
  const TermPalette({
    required this.id,
    required this.bg,
    required this.bar,
    required this.fg,
    required this.hi,
    required this.dim,
    required this.ok,
    required this.tag,
    required this.cmd,
    required this.warn,
    required this.line,
  });

  final String id;

  /// 배경
  final Color bg;

  /// 상단 바, 하단 입력 영역
  final Color bar;

  /// 기본 글자
  final Color fg;

  /// 강조 글자
  final Color hi;

  /// 보조 글자 (배경 대비 4.5:1 이상)
  final Color dim;

  /// 완료, 커서, 진행 막대
  final Color ok;

  /// #태그
  final Color tag;

  /// 명령어
  final Color cmd;

  /// 우선순위, 에러
  final Color warn;

  /// 구분선
  final Color line;

  static const cmdTheme = TermPalette(
    id: 'cmd',
    bg: Color(0xFF0C0C0C),
    bar: Color(0xFF1A1A1A),
    fg: Color(0xFFCCCCCC),
    hi: Color(0xFFF2F2F2),
    dim: Color(0xFF8A8A8A),
    ok: Color(0xFF16C60C),
    tag: Color(0xFFF9F1A5),
    cmd: Color(0xFF61D6D6),
    warn: Color(0xFFE74856),
    line: Color(0xFF2A2A2A),
  );

  static const phosphor = TermPalette(
    id: 'phosphor',
    bg: Color(0xFF050A06),
    bar: Color(0xFF0B170E),
    fg: Color(0xFF4AF626),
    hi: Color(0xFFB8FFA8),
    dim: Color(0xFF2E9A1A),
    ok: Color(0xFFB8FFA8),
    tag: Color(0xFFE8FF7A),
    cmd: Color(0xFF7CFFCB),
    warn: Color(0xFFFF6B5A),
    line: Color(0xFF16361D),
  );

  static const amber = TermPalette(
    id: 'amber',
    bg: Color(0xFF0F0A02),
    bar: Color(0xFF1C1305),
    fg: Color(0xFFFFB000),
    hi: Color(0xFFFFE3A3),
    dim: Color(0xFFB07A00),
    ok: Color(0xFFFFE3A3),
    tag: Color(0xFFFFD166),
    cmd: Color(0xFFFFCF70),
    warn: Color(0xFFFF6B3D),
    line: Color(0xFF3A2A0A),
  );

  static TermPalette of(String id) => switch (id) {
        'phosphor' => phosphor,
        'amber' => amber,
        _ => cmdTheme,
      };
}

const monoFamily = 'JetBrainsMono';
const monoFallback = ['NanumGothicCoding'];

/// 앱 전체에서 쓰는 고정폭 글꼴 스타일. 한글은 나눔고딕코딩으로 대체된다.
TextStyle termStyle(
  Color color, {
  double size = 14,
  FontWeight weight = FontWeight.w400,
  TextDecoration? decoration,
  double height = 1.5,
}) =>
    TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      decoration: decoration,
      decorationColor: color,
    );
