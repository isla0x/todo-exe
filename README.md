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

## PRO (한 번 결제)

| 무료 | PRO |
|---|---|
| 할 일 전체 기능, stats, cmd 테마 | phosphor · amber 테마, CRT 효과, 홈 화면 · 잠금화면 위젯 |

- 상품 ID: `todo_exe_pro` (비소모성 / Non-Consumable)
- 명령어: `upgrade`(구매 화면), `restore`(구매 복원). 제목줄 `PRO` 링크로도 열 수 있어요.
- PRO 가 아니면 위젯은 `Access is denied.` 잠금 화면을 보여줘요.
- 디버그 빌드에서만 `pro --dev` 로 결제 없이 PRO 를 켜고 끌 수 있어요 (출시 빌드에서는 동작 안 함).

### 스토어에 상품 등록
- **App Store Connect** → 앱 → 수익화 → 앱 내 구입 → `+` → **비소모성**, 제품 ID `todo_exe_pro`, 가격, 한국어 표시 이름/설명, 심사용 스크린샷(PRO 화면)
- 첫 인앱 구입은 **앱 버전과 함께 심사 제출**해야 해요.
- 테스트: TestFlight 또는 Xcode 의 StoreKit Configuration 파일 (Sandbox 계정으로 실제 결제 없이 테스트)

## iOS 위젯 (홈 화면 · 잠금화면)

| 위치 | 크기 | 내용 |
|---|---|---|
| 홈 화면 | 작게 / 중간 / 크게 | `C:\todo> ls --todo` + 남은 할 일(우선순위 순) + 진행 막대, 연속 달성일 |
| 잠금화면 | 직사각형 | `C:\todo> 3/7` + 할 일 2개 |
| 잠금화면 | 원형 | 남은 개수 + 진행 링 |
| 잠금화면 | 시계 위 한 줄 | `>_ 남은 할 일 4 · 연속 12일` |

앱에서 할 일이 바뀌면 위젯도 바로 바뀌어요. 색은 `theme` 설정을 따라가요(잠금화면은 iOS가 단색으로 그려요).

### 처음 한 번 설정 (Xcode, iOS 17 이상)

1. `open ios/Runner.xcworkspace`
2. **File → New → Target… → Widget Extension**
   - Product Name: `TodoWidget`
   - Include Live Activity / Control / Configuration App Intent: **모두 체크 해제**
   - Finish → "Activate scheme?" 은 **Cancel** (Runner 로 계속 실행)
3. 왼쪽에서 **TodoWidget** 타깃 → General → **Minimum Deployments 를 17.0** 으로
4. **Runner** 타깃 → Signing & Capabilities → **+ Capability → App Groups** → `+` → `group.com.isla0x.todoexe`
5. **TodoWidget** 타깃도 4번과 똑같이 (같은 그룹 체크). Team 도 Runner 와 같게.
6. 터미널에서 `bash tool/install_ios_widget.sh` (위젯 코드 덮어쓰기)
7. Runner 선택 후 ▶︎ 실행 → 홈 화면 길게 누르기 → `+` → **todo.exe** 추가
   잠금화면은 잠금화면 길게 누르기 → 사용자화 → 잠금 화면 → 위젯 추가

설정한 `ios/` 폴더는 커밋해 두세요: `git add ios && git commit -m "iOS 위젯 타깃" && git push`

**막힐 때**
- `Cycle inside Runner` 빌드 오류: Runner 타깃 → Build Phases 에서 **Embed Foundation Extensions** 를 **Run Script / Thin Binary 위로** 끌어올리기
- 위젯에 "할 일이 없어요"만 나옴: 두 타깃의 App Group 이름이 정확히 같은지 확인하고 앱을 한 번 열기
- 무료 Apple ID 에서 App Groups 추가가 안 되면 알려주세요

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
  widget_sync.dart          iOS 위젯으로 데이터 전달
ios_widget/                 iOS 위젯 SwiftUI 코드 (tool/install_ios_widget.sh 로 복사)
test/                       명령어·통계·화면·위젯 데이터 테스트
```

## 폰트

- [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) — SIL OFL 1.1
- [Nanum Gothic Coding](https://github.com/google/fonts/tree/main/ofl/nanumgothiccoding) — SIL OFL 1.1

라이선스 전문은 `assets/fonts/OFL-*.txt`.
