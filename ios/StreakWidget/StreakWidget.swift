// BudgetBuddy streak widget (WidgetKit, iOS 17+).
//
// Data comes from Flutter via the `home_widget` package, written to the shared
// App Group UserDefaults by lib/features/home/services/widget_sync_service.dart.
// All values are Strings; keys are documented in that Dart file.

import SwiftUI
import WidgetKit

private let appGroupId = "group.com.hamrobudget"

// MARK: - Model

enum PiggyMood { case happy, worried, sad }

struct StreakEntry: TimelineEntry {
  let date: Date
  let streak: Int
  let todaySpent: String
  let budgetLeft: String?   // nil = no budget set (or new month, not synced yet)
  let budgetPct: Double     // spent / limit, can exceed 1
  let hide: Bool
  let mood: PiggyMood
  let title: String
  let message: String

  static let placeholder = StreakEntry(
    date: .now, streak: 7, todaySpent: "Rs 450", budgetLeft: "Rs 1,550",
    budgetPct: 0.6, hide: false, mood: .happy,
    title: "Nice work!", message: "You're on track today")
}

enum StreakData {
  private static let dayFmt: DateFormatter = {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f
  }()

  static func entry(at date: Date) -> StreakEntry {
    let d = UserDefaults(suiteName: appGroupId)
    func s(_ k: String) -> String { d?.string(forKey: k) ?? "" }

    let cal = Calendar.current
    let today = dayFmt.string(from: date)
    let yesterday = dayFmt.string(from: cal.date(byAdding: .day, value: -1, to: date) ?? date)
    let monthKey = String(today.prefix(7))

    let rawStreak = Int(s("bb_streak")) ?? 0
    let lastActive = s("bb_last_active")
    let streakAlive = lastActive == today || lastActive == yesterday
    let streak = streakAlive ? rawStreak : 0
    let streakBroken = !streakAlive && rawStreak > 0

    let loggedToday = s("bb_last_log") == today
    let todaySpent = s("bb_today_date") == today ? s("bb_today_spent") : s("bb_zero")

    let sameMonth = s("bb_month_key") == monthKey
    let hasBudget = s("bb_has_budget") == "1" && sameMonth
    let pct = hasBudget ? (Double(s("bb_budget_pct")) ?? 0) : 0
    let left: String? = hasBudget ? s("bb_budget_left") : nil

    let hour = cal.component(.hour, from: date)
    let (mood, title, message): (PiggyMood, String, String) = {
      if hasBudget && pct > 1 {
        return (.sad, "Over budget", "Let's slow down spending 💸")
      }
      if streakBroken {
        return (.sad, "Streak lost", "Open the app to start a new one")
      }
      if !loggedToday {
        if hour >= 20 {
          return streak > 0
            ? (.worried, "\(streak)-day streak!", "Log today's spending before midnight")
            : (.worried, "Quick check-in?", "Log today's spending")
        }
        if hour >= 12 {
          return (.worried, "Haven't logged today 👀", "It only takes a few seconds")
        }
        return (.happy, "Good morning!", "Ready to track today?")
      }
      if hasBudget && pct >= 0.85 {
        return (.worried, "Budget almost gone", "Spend carefully this month")
      }
      return (.happy, "Nice work!", "You're on track today")
    }()

    return StreakEntry(
      date: date, streak: streak,
      todaySpent: todaySpent.isEmpty ? "—" : todaySpent,
      budgetLeft: left, budgetPct: pct, hide: s("bb_hide") == "1",
      mood: mood, title: title, message: message)
  }
}

// MARK: - Timeline

struct StreakProvider: TimelineProvider {
  func placeholder(in context: Context) -> StreakEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
    completion(context.isPreview ? .placeholder : StreakData.entry(at: .now))
  }

  /// One entry now + one at each moment the message can change
  /// (noon, 8 pm, midnight) over the next day. The app also reloads the
  /// timeline whenever data changes.
  func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
    let now = Date()
    let cal = Calendar.current
    var dates: [Date] = [now]
    let start = cal.startOfDay(for: now)
    for dayOffset in 0...1 {
      for hour in [0, 12, 20] {
        if let day = cal.date(byAdding: .day, value: dayOffset, to: start),
          let t = cal.date(byAdding: .hour, value: hour, to: day),
          t > now
        {
          dates.append(t.addingTimeInterval(5))
        }
      }
    }
    let entries = dates.map { StreakData.entry(at: $0) }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

// MARK: - Colors

extension Color {
  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255)
  }
  static let bbDeep = Color(hex: 0x0E4A30)
  static let bbMid = Color(hex: 0x17694A)
  static let piggyBody = Color(hex: 0xC8EFD9)
  static let piggySnout = Color(hex: 0x9BDDB8)
}

extension PiggyMood {
  var gradient: LinearGradient {
    let colors: [Color]
    switch self {
    case .happy: colors = [.bbDeep, .bbMid]
    case .worried: colors = [Color(hex: 0xB45309), Color(hex: 0xF59E0B)]
    case .sad: colors = [Color(hex: 0x9F1239), Color(hex: 0xF43F5E)]
    }
    return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
  }
}

// MARK: - Piggy (drawn in a 100×100 space, same geometry as the Android vectors)

private struct P: Shape {
  let draw: (inout Path) -> Void
  func path(in r: CGRect) -> Path {
    var p = Path()
    draw(&p)
    return p.applying(
      CGAffineTransform(scaleX: r.width / 100, y: r.height / 100)
        .translatedBy(x: r.minX * 100 / max(r.width, 1), y: r.minY * 100 / max(r.height, 1)))
  }
}

private func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> P {
  P { $0.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)) }
}

struct PiggyView: View {
  let mood: PiggyMood

  var body: some View {
    let ink = Color.bbDeep
    let line = StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)

    GeometryReader { geo in
      let k = geo.size.width / 100  // stroke scale
      let stroke = StrokeStyle(lineWidth: line.lineWidth * k, lineCap: .round, lineJoin: .round)
      let thin = StrokeStyle(lineWidth: 2.5 * k, lineCap: .round, lineJoin: .round)

      ZStack {
        // Ears
        P { $0.move(to: .init(x: 18, y: 32)); $0.addLine(to: .init(x: 27, y: 8)); $0.addLine(to: .init(x: 44, y: 24)); $0.closeSubpath() }
          .fill(Color.piggyBody)
        P { $0.move(to: .init(x: 18, y: 32)); $0.addLine(to: .init(x: 27, y: 8)); $0.addLine(to: .init(x: 44, y: 24)); $0.closeSubpath() }
          .stroke(ink, style: thin)
        P { $0.move(to: .init(x: 82, y: 32)); $0.addLine(to: .init(x: 73, y: 8)); $0.addLine(to: .init(x: 56, y: 24)); $0.closeSubpath() }
          .fill(Color.piggyBody)
        P { $0.move(to: .init(x: 82, y: 32)); $0.addLine(to: .init(x: 73, y: 8)); $0.addLine(to: .init(x: 56, y: 24)); $0.closeSubpath() }
          .stroke(ink, style: thin)

        // Head
        ellipse(50, 56, 36, 36).fill(Color.piggyBody)
        ellipse(50, 56, 36, 36).stroke(ink, style: thin)

        // Cheeks
        if mood == .happy {
          ellipse(26, 62, 6, 5).fill(Color(hex: 0xF9A8D4).opacity(0.8))
          ellipse(74, 62, 6, 5).fill(Color(hex: 0xF9A8D4).opacity(0.8))
        }

        // Eyes
        switch mood {
        case .happy:
          P { $0.move(to: .init(x: 30, y: 47)); $0.addQuadCurve(to: .init(x: 42, y: 47), control: .init(x: 36, y: 38)) }
            .stroke(ink, style: stroke)
          P { $0.move(to: .init(x: 58, y: 47)); $0.addQuadCurve(to: .init(x: 70, y: 47), control: .init(x: 64, y: 38)) }
            .stroke(ink, style: stroke)
        case .worried, .sad:
          ellipse(36, 46, 4, 4.5).fill(ink)
          ellipse(64, 46, 4, 4.5).fill(ink)
          // Brows, raised in the middle
          P { $0.move(to: .init(x: 29, y: 38)); $0.addLine(to: .init(x: 41, y: 34)) }.stroke(ink, style: thin)
          P { $0.move(to: .init(x: 71, y: 38)); $0.addLine(to: .init(x: 59, y: 34)) }.stroke(ink, style: thin)
        }

        // Snout
        ellipse(50, 65, 15, 11).fill(Color.piggySnout)
        ellipse(50, 65, 15, 11).stroke(ink, style: thin)
        ellipse(44.5, 65, 2.5, 4).fill(ink)
        ellipse(55.5, 65, 2.5, 4).fill(ink)

        // Mouth
        switch mood {
        case .happy:
          P { $0.move(to: .init(x: 42, y: 81)); $0.addQuadCurve(to: .init(x: 58, y: 81), control: .init(x: 50, y: 89)) }
            .stroke(ink, style: stroke)
        case .worried:
          P {
            $0.move(to: .init(x: 41, y: 83))
            $0.addQuadCurve(to: .init(x: 50, y: 83), control: .init(x: 45.5, y: 79))
            $0.addQuadCurve(to: .init(x: 59, y: 83), control: .init(x: 54.5, y: 87))
          }.stroke(ink, style: stroke)
        case .sad:
          P { $0.move(to: .init(x: 42, y: 86)); $0.addQuadCurve(to: .init(x: 58, y: 86), control: .init(x: 50, y: 78)) }
            .stroke(ink, style: stroke)
        }

        // Extras
        switch mood {
        case .happy:  // a coin
          ellipse(88, 16, 8, 8).fill(Color(hex: 0xFCD34D))
          ellipse(88, 16, 8, 8).stroke(Color(hex: 0xB45309), style: StrokeStyle(lineWidth: 1.5 * k))
          ellipse(88, 16, 3.5, 3.5).stroke(Color(hex: 0xB45309), style: StrokeStyle(lineWidth: 1.2 * k))
        case .worried:  // sweat drop
          P {
            $0.move(to: .init(x: 86, y: 28))
            $0.addQuadCurve(to: .init(x: 86, y: 42), control: .init(x: 93, y: 38))
            $0.addQuadCurve(to: .init(x: 86, y: 28), control: .init(x: 79, y: 38))
          }.fill(Color(hex: 0x7DD3FC))
        case .sad:  // tear
          P {
            $0.move(to: .init(x: 34, y: 52))
            $0.addQuadCurve(to: .init(x: 34, y: 64), control: .init(x: 40, y: 61))
            $0.addQuadCurve(to: .init(x: 34, y: 52), control: .init(x: 28, y: 61))
          }.fill(Color(hex: 0x7DD3FC))
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .aspectRatio(1, contentMode: .fit)
  }
}

// MARK: - Views

private let addURL = URL(string: "budgetbuddy://add-expense?homeWidget")!
private let homeURL = URL(string: "budgetbuddy://dashboard?homeWidget")!

struct StreakBadge: View {
  let streak: Int
  var body: some View {
    HStack(spacing: 3) {
      Text("🔥").font(.system(size: 13))
      Text("\(streak)").font(.system(size: 15, weight: .heavy, design: .rounded))
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(.white.opacity(0.18), in: Capsule())
  }
}

struct SmallStreakView: View {
  let entry: StreakEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        PiggyView(mood: entry.mood).frame(width: 58, height: 58)
        Spacer(minLength: 0)
        StreakBadge(streak: entry.streak)
      }
      Spacer(minLength: 4)
      Text(entry.title)
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      Text(entry.message)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.white.opacity(0.85))
        .lineLimit(2)
    }
    .widgetURL(addURL)
  }
}

struct MediumStreakView: View {
  let entry: StreakEntry
  private func amount(_ s: String) -> String { entry.hide ? "••••" : s }

  var body: some View {
    HStack(spacing: 14) {
      // Left: piggy + streak + message
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top) {
          PiggyView(mood: entry.mood).frame(width: 62, height: 62)
          Spacer(minLength: 0)
          StreakBadge(streak: entry.streak)
        }
        Spacer(minLength: 4)
        Text(entry.title)
          .font(.system(size: 15, weight: .bold, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
        Text(entry.message)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.white.opacity(0.85))
          .lineLimit(2)
      }

      // Right: numbers + add button
      VStack(alignment: .leading, spacing: 6) {
        VStack(alignment: .leading, spacing: 1) {
          Text("Spent today").font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.75))
          Text(amount(entry.todaySpent))
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
        }
        if let left = entry.budgetLeft {
          VStack(alignment: .leading, spacing: 3) {
            Text("Budget left").font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.75))
            Text(amount(left))
              .font(.system(size: 13, weight: .semibold, design: .rounded))
              .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
            GeometryReader { g in
              ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.2))
                Capsule().fill(.white).frame(width: g.size.width * min(max(entry.budgetPct, 0), 1))
              }
            }
            .frame(height: 5)
          }
        } else {
          Text("No monthly budget set")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
        }
        Spacer(minLength: 0)
        Link(destination: addURL) {
          HStack(spacing: 4) {
            Image(systemName: "plus").font(.system(size: 12, weight: .bold))
            Text("Add").font(.system(size: 13, weight: .bold, design: .rounded))
          }
          .foregroundStyle(Color.bbDeep)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 7)
          .background(.white, in: Capsule())
        }
      }
      .frame(maxWidth: 130)
    }
    .widgetURL(homeURL)
  }
}

struct StreakWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: StreakEntry

  var body: some View {
    Group {
      switch family {
      case .systemMedium: MediumStreakView(entry: entry)
      default: SmallStreakView(entry: entry)
      }
    }
    .containerBackground(for: .widget) { entry.mood.gradient }
  }
}

// MARK: - Widget

@main
struct StreakWidget: Widget {
  // Must match WidgetSyncService.iOSKind in Dart.
  let kind = "StreakWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
      StreakWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Daily Streak")
    .description("Keep your tracking streak alive and see today's spending.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview(as: .systemSmall) {
  StreakWidget()
} timeline: {
  StreakEntry.placeholder
}
