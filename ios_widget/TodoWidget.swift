// todo.exe 홈 화면 · 잠금화면 위젯
//
// 앱(Flutter)이 App Group 저장소에 "snapshot" 키로 JSON 을 넣으면 이 위젯이 읽어서 그린다.
// JSON 모양은 lib/widget_sync.dart 의 widgetSnapshot() 과 같다.
//
// 지원 크기
//   홈 화면   : 작게 / 중간 / 크게
//   잠금 화면 : 직사각형 / 원형 / 시계 위 한 줄

import SwiftUI
import WidgetKit

private let appGroupId = "group.com.isla0x.todoexe"
private let snapshotKey = "snapshot"

// MARK: - 데이터

struct TodoItem: Decodable, Hashable {
    /// "#01"
    let n: String
    /// 내용
    let t: String
    /// 우선순위 0~3
    let p: Int
    /// 태그 (# 없이)
    let g: String
}

struct TodoSnapshot: Decodable {
    /// PRO 결제 여부. 예전 버전 데이터에는 없을 수 있다.
    let pro: Bool?
    let theme: String
    let done: Int
    let total: Int
    let streak: Int
    let todo: [TodoItem]

    var left: Int { max(0, total - done) }
    var isPro: Bool { pro ?? false }

    static let empty = TodoSnapshot(pro: false, theme: "cmd", done: 0, total: 0, streak: 0, todo: [])

    static let sample = TodoSnapshot(
        pro: true, theme: "cmd", done: 3, total: 7, streak: 12,
        todo: [
            TodoItem(n: "#01", t: "주간 보고서 초안 작성", p: 2, g: "work"),
            TodoItem(n: "#03", t: "앱 온보딩 와이어프레임", p: 1, g: "side"),
            TodoItem(n: "#05", t: "책 20페이지 읽기", p: 0, g: "life"),
            TodoItem(n: "#07", t: "운동 30분", p: 0, g: "health"),
        ]
    )

    static func load() -> TodoSnapshot {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let raw = defaults.string(forKey: snapshotKey),
            let data = raw.data(using: .utf8),
            let snap = try? JSONDecoder().decode(TodoSnapshot.self, from: data)
        else { return .empty }
        return snap
    }
}

// MARK: - 색 (앱의 theme 명령어와 같은 팔레트)

struct TermColors {
    let bg, bar, fg, hi, dim, ok, tag, cmd, warn, line: Color

    static func of(_ id: String) -> TermColors {
        switch id {
        case "phosphor":
            return TermColors(bg: Color(hex: 0x050A06), bar: Color(hex: 0x0B170E), fg: Color(hex: 0x4AF626),
                              hi: Color(hex: 0xB8FFA8), dim: Color(hex: 0x2E9A1A), ok: Color(hex: 0xB8FFA8),
                              tag: Color(hex: 0xE8FF7A), cmd: Color(hex: 0x7CFFCB), warn: Color(hex: 0xFF6B5A),
                              line: Color(hex: 0x16361D))
        case "amber":
            return TermColors(bg: Color(hex: 0x0F0A02), bar: Color(hex: 0x1C1305), fg: Color(hex: 0xFFB000),
                              hi: Color(hex: 0xFFE3A3), dim: Color(hex: 0xB07A00), ok: Color(hex: 0xFFE3A3),
                              tag: Color(hex: 0xFFD166), cmd: Color(hex: 0xFFCF70), warn: Color(hex: 0xFF6B3D),
                              line: Color(hex: 0x3A2A0A))
        default:
            return TermColors(bg: Color(hex: 0x0C0C0C), bar: Color(hex: 0x1A1A1A), fg: Color(hex: 0xCCCCCC),
                              hi: Color(hex: 0xF2F2F2), dim: Color(hex: 0x8A8A8A), ok: Color(hex: 0x16C60C),
                              tag: Color(hex: 0xF9F1A5), cmd: Color(hex: 0x61D6D6), warn: Color(hex: 0xE74856),
                              line: Color(hex: 0x2A2A2A))
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - 도우미

private func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
    .system(size: size, weight: weight, design: .monospaced)
}

/// [████░░░░░░]
private func textBar(done: Int, total: Int, width: Int) -> String {
    let cells = total == 0 ? 0 : min(width, max(0, Int((Double(done) * Double(width) / Double(total)).rounded())))
    return "[" + String(repeating: "█", count: cells) + String(repeating: "░", count: width - cells) + "]"
}

/// 09.29 화
private func shortDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateFormat = "MM.dd E"
    return f.string(from: date)
}

// MARK: - 타임라인

struct TodoEntry: TimelineEntry {
    let date: Date
    let snap: TodoSnapshot
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: .now, snap: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        let snap = TodoSnapshot.load()
        // 위젯 고르는 화면에서는 어떤 모습인지 보이도록 예시를 보여준다.
        completion(TodoEntry(date: .now, snap: context.isPreview ? .sample : snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        let now = Date()
        let entry = TodoEntry(date: now, snap: TodoSnapshot.load())
        // 날짜 표시가 바뀌도록 자정에 한 번 더 그린다. 할 일이 바뀌면 앱이 바로 새로 그리게 한다.
        let midnight = Calendar.current.nextDate(
            after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

// MARK: - 홈 화면 위젯

struct HomeWidgetView: View {
    let entry: TodoEntry
    let family: WidgetFamily

    private var c: TermColors { .of(entry.snap.theme) }
    private var small: Bool { family == .systemSmall }
    private var maxRows: Int { family == .systemLarge ? 9 : 3 }

    var body: some View {
        let s = entry.snap
        let rows = Array(s.todo.prefix(maxRows))

        VStack(alignment: .leading, spacing: 0) {
            // 창 제목줄
            HStack(spacing: 6) {
                Text(">_").font(mono(11, .bold)).foregroundColor(c.hi)
                Text("todo.exe").font(mono(11)).foregroundColor(c.hi)
                Spacer(minLength: 4)
                Text(shortDate(entry.date)).font(mono(10)).foregroundColor(c.dim).lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: 26)
            .background(c.bar)

            VStack(alignment: .leading, spacing: small ? 3 : 4) {
                (Text("C:\\todo> ").foregroundColor(c.dim) + Text("ls --todo").foregroundColor(c.cmd))
                    .font(mono(small ? 10 : 11))
                    .lineLimit(1)

                if rows.isEmpty {
                    Text(s.total == 0 ? "할 일이 없어요." : "✓ 모두 완료!")
                        .font(mono(12)).foregroundColor(s.total == 0 ? c.dim : c.ok)
                    if s.total == 0 {
                        (Text("add").foregroundColor(c.cmd) + Text(" 로 추가해 보세요").foregroundColor(c.dim))
                            .font(mono(11))
                    }
                } else {
                    ForEach(rows, id: \.self) { item in
                        TaskLine(item: item, c: c, compact: small)
                    }
                    if s.left > rows.count {
                        Text("... +\(s.left - rows.count)").font(mono(11)).foregroundColor(c.dim)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Text(textBar(done: s.done, total: s.total, width: small ? 6 : 10))
                        .foregroundColor(c.ok)
                    Text("\(s.done)/\(s.total)").foregroundColor(c.hi)
                    Spacer(minLength: 0)
                    if !small {
                        Text("연속 \(s.streak)일").foregroundColor(c.dim)
                    }
                    Text("_").foregroundColor(c.ok)
                }
                .font(mono(small ? 10 : 11))
                .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
    }
}

struct TaskLine: View {
    let item: TodoItem
    let c: TermColors
    let compact: Bool

    var body: some View {
        HStack(spacing: 5) {
            Text("[ ]").foregroundColor(c.fg)
            if !compact {
                Text(item.n).foregroundColor(c.dim)
            }
            Text(item.t).foregroundColor(c.hi).lineLimit(1)
            Spacer(minLength: 0)
            if item.p > 0 {
                Text(String(repeating: "!", count: item.p)).fontWeight(.bold).foregroundColor(c.warn)
            }
            if !compact && !item.g.isEmpty {
                Text("#" + item.g).foregroundColor(c.tag).lineLimit(1)
            }
        }
        .font(mono(compact ? 11 : 12))
    }
}

// MARK: - 잠금화면 위젯

/// 직사각형: 3줄 터미널
struct LockRectView: View {
    let snap: TodoSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("C:\\todo> \(snap.done)/\(snap.total)")
                .font(mono(13, .bold))
                .widgetAccentable()
            if snap.todo.isEmpty {
                Text(snap.total == 0 ? "> 할 일 없음" : "> 모두 완료 ✓").font(mono(12))
            } else {
                ForEach(Array(snap.todo.prefix(2)), id: \.self) { item in
                    Text("> " + item.t + (item.p > 0 ? " " + String(repeating: "!", count: item.p) : ""))
                        .font(mono(12))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 원형: 남은 개수 + 진행 링
struct LockCircleView: View {
    let snap: TodoSnapshot

    var body: some View {
        Gauge(value: Double(snap.done), in: 0...Double(max(snap.total, 1))) {
            Text(">_").font(mono(10))
        } currentValueLabel: {
            Text("\(snap.left)").font(mono(18, .bold))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
    }
}

/// 시계 위 한 줄
struct LockInlineView: View {
    let snap: TodoSnapshot

    var body: some View {
        Text(">_ 남은 할 일 \(snap.left) · 연속 \(snap.streak)일")
    }
}

// MARK: - PRO 가 아닐 때

/// 홈 화면: cmd 권한 오류처럼 보이는 잠금 화면
struct LockedHomeView: View {
    let date: Date
    let family: WidgetFamily
    private let c = TermColors.of("cmd")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(">_").font(mono(11, .bold)).foregroundColor(c.hi)
                Text("todo.exe").font(mono(11)).foregroundColor(c.hi)
                Spacer(minLength: 4)
                Text(shortDate(date)).font(mono(10)).foregroundColor(c.dim).lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: 26)
            .background(c.bar)

            VStack(alignment: .leading, spacing: 4) {
                (Text("C:\\todo> ").foregroundColor(c.dim) + Text("widget").foregroundColor(c.cmd))
                    .font(mono(11))
                Text("Access is denied.").font(mono(12, .bold)).foregroundColor(c.warn)
                Text("위젯은 PRO 기능이에요.").font(mono(11)).foregroundColor(c.fg)
                Spacer(minLength: 0)
                (Text("앱에서 ").foregroundColor(c.dim) + Text("upgrade").foregroundColor(c.cmd) + Text(" 입력_").foregroundColor(c.dim))
                    .font(mono(11))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
    }
}

struct LockedAccessoryView: View {
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text(">_").font(mono(11, .bold))
                    Text("PRO").font(mono(12, .bold))
                }
            }
            .widgetAccentable()
        case .accessoryInline:
            Text(">_ todo.exe · PRO 필요")
        default:
            VStack(alignment: .leading, spacing: 1) {
                Text("C:\\todo> widget").font(mono(12, .bold)).widgetAccentable()
                Text("Access is denied.").font(mono(12))
                Text("앱에서 upgrade").font(mono(12))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 위젯 정의

struct TodoWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodoEntry

    var body: some View {
        if entry.snap.isPro {
            unlocked
        } else {
            locked
        }
    }

    @ViewBuilder
    private var locked: some View {
        switch family {
        case .accessoryRectangular, .accessoryCircular, .accessoryInline:
            LockedAccessoryView(family: family).containerBackground(for: .widget) { Color.clear }
        default:
            LockedHomeView(date: entry.date, family: family)
                .containerBackground(for: .widget) { TermColors.of("cmd").bg }
        }
    }

    @ViewBuilder
    private var unlocked: some View {
        switch family {
        case .accessoryRectangular:
            LockRectView(snap: entry.snap).containerBackground(for: .widget) { Color.clear }
        case .accessoryCircular:
            LockCircleView(snap: entry.snap).containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            LockInlineView(snap: entry.snap).containerBackground(for: .widget) { Color.clear }
        default:
            HomeWidgetView(entry: entry, family: family)
                .containerBackground(for: .widget) { TermColors.of(entry.snap.theme).bg }
        }
    }
}

struct TodoWidget: Widget {
    /// Flutter 쪽 WidgetSync.iOSWidgetKind 와 같아야 한다.
    let kind = "TodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoWidgetView(entry: entry)
        }
        .configurationDisplayName("todo.exe")
        .description("남은 할 일과 진행률을 cmd 스타일로 보여줘요.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryRectangular, .accessoryCircular, .accessoryInline,
        ])
        .contentMarginsDisabled()
    }
}

// MARK: - Xcode 미리보기

#Preview("작게", as: .systemSmall) {
    TodoWidget()
} timeline: {
    TodoEntry(date: .now, snap: .sample)
}

#Preview("중간", as: .systemMedium) {
    TodoWidget()
} timeline: {
    TodoEntry(date: .now, snap: .sample)
}

#Preview("잠금 직사각형", as: .accessoryRectangular) {
    TodoWidget()
} timeline: {
    TodoEntry(date: .now, snap: .sample)
}

#Preview("잠금 원형", as: .accessoryCircular) {
    TodoWidget()
} timeline: {
    TodoEntry(date: .now, snap: .sample)
}

#Preview("PRO 아님", as: .systemSmall) {
    TodoWidget()
} timeline: {
    TodoEntry(date: .now, snap: .empty)
}
