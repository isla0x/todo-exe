# todo.exe

Windows cmd 느낌의 명령어 입력형 투두 앱 (Flutter).

```
█████  ███  ████   ███
  █   █   █ █   █ █   █
  █   █   █ █   █ █   █
  █   █   █ █   █ █   █
  █    ███  ████   ███
```

## 화면

| 부팅 | 메인 | help | stats |
|---|---|---|---|
| 부팅 로그, 진행 막대 | 할 일 목록 + `C:\todo>` 입력창 | 명령어 설명 | 7일 막대, 태그별, 4주 잔디 |

## 명령어

| 명령어 | 설명 | 예시 |
|---|---|---|
| `add <할 일> [#태그] [!]` | 추가. 명령어 없이 입력해도 추가됨 | `add 보고서 초안 #work !!` |
| `done <번호>` / `undo <번호>` | 완료 / 완료 취소 (줄을 탭해도 됨) | `done 3` |
| `edit <번호> <내용>` | 수정 | `edit 2 운동 1시간 #health` |
| `rm <번호>` | 삭제 | `rm 4` |
| `ls [--todo \| --done \| #태그]` | 필터 | `ls #work` |
| `clear` | 완료 항목 정리 (통계 기록은 유지) | |
| `cls` | 화면 로그 지우기 | |
| `stats` | 통계 화면 | |
| `theme [cmd \| phosphor \| amber]` | 색 테마 | `theme amber` |
| `crt [on \| off]` | 주사선 효과 | |

`!` 개수가 우선순위(1~3), `#태그`는 첫 번째 것만 인식해요. 하드웨어 키보드가 있으면 ↑ ↓ 로 이전 명령어를 불러올 수 있어요.

## 폰에 설치해 보기 (Flutter 설치 없이)

1. GitHub 저장소의 **Actions** 탭 → 가장 최근 `build` 실행 클릭
2. 아래 **Artifacts** 의 `todo-exe-apk` 다운로드 → 압축 풀기 → `app-release.apk`
3. 안드로이드 폰으로 옮겨서 설치 ("출처를 알 수 없는 앱" 허용 필요)

## 로컬에서 실행

[Flutter 설치](https://docs.flutter.dev/get-started/install) 후:

```bash
# 처음 한 번: android/ ios/ 폴더 생성 + 앱 이름 설정
bash tool/setup_platforms.sh
# Windows PowerShell 이라면:
#   flutter create --org com.isla0x --project-name todo_exe --platforms android,ios .

flutter pub get
flutter run          # 연결된 폰/에뮬레이터에서 실행
flutter test         # 테스트
```

생성된 `android/`, `ios/` 폴더는 커밋해 두면 앱 아이콘·이름을 바꿀 때 편해요.

## 구조

```
lib/
  main.dart                 앱 시작, 테마, CRT 효과
  models/task.dart          할 일, 완료 기록
  logic/commands.dart       명령어 해석·실행 (순수 Dart, 테스트 대상)
  logic/stats.dart          연속 달성일, 7일/태그/4주 집계
  state/todo_store.dart     상태 + 기기 저장 (shared_preferences)
  theme/term_palette.dart   cmd / phosphor / amber 색
  widgets/term_widgets.dart 제목줄, 버튼, 아이콘
  screens/                  boot, home, help, stats
test/                       명령어·통계·화면 테스트
```

## 폰트

- [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) — SIL OFL 1.1
- [Nanum Gothic Coding](https://github.com/google/fonts/tree/main/ofl/nanumgothiccoding) — SIL OFL 1.1

라이선스 전문은 `assets/fonts/OFL-*.txt`.
