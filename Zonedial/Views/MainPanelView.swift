import SwiftUI
import ServiceManagement

struct MainPanelView: View {

    @EnvironmentObject var tz: TimeZoneManager
    @State private var showingAddSheet = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Group {
            if showingAddSheet {
                AddTimeZoneView(isPresented: $showingAddSheet)
                    .environmentObject(tz)
                    .frame(minHeight: 360)
            } else {
                mainContent
            }
        }
        .frame(width: 360)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        )
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            formatToggles
            localTimeHeader
            timezoneSection
            if !tz.savedIdentifiers.isEmpty {
                HStack {
                    Text("\(tz.savedIdentifiers.count) \(tz.savedIdentifiers.count == 1 ? "city" : "cities")")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 2)
            }
            bottomToolbar
        }
        .padding(.vertical, 12)
    }

    // MARK: - Format Toggles

    private var formatToggles: some View {
        HStack {
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .help("Quit")

            Spacer().frame(width: 8)

            HStack(spacing: 2) {
                Button { tz.use24HourTime = false } label: {
                    Text("12H")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(tz.use24HourTime ? .secondary : .primary)
                        .frame(width: 26)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(tz.use24HourTime ? Color.clear : Color.primary.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)

                Button { tz.use24HourTime = true } label: {
                    Text("24H")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(tz.use24HourTime ? .primary : .secondary)
                        .frame(width: 26)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(tz.use24HourTime ? Color.primary.opacity(0.15) : Color.clear)
                        )
                }
                .buttonStyle(.plain)

                Button { tz.showSeconds.toggle() } label: {
                    Text("SEC")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundColor(tz.showSeconds ? .primary : .secondary)
                        .frame(width: 26)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(tz.showSeconds ? Color.primary.opacity(0.15) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                if launchAtLogin {
                    try? SMAppService.mainApp.unregister()
                } else {
                    try? SMAppService.mainApp.register()
                }
                launchAtLogin.toggle()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: launchAtLogin ? "checkmark.square.fill" : "square")
                        .font(.system(size: 9))
                    Text("Launch at Login")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Local Time Header

    private var localTimeHeader: some View {
        VStack(spacing: 4) {
            Text(localTimeString)
                .font(.system(size: 38, weight: .thin, design: .default))
                .foregroundColor(timeHeaderColor)

            Text(localDateString)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            if tz.isHourOffsetMode {
                let desc = offsetDescription
                if !desc.isEmpty {
                    Text("(\(desc))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(timeHeaderColor)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    private var offsetDescription: String {
        let hours = abs(tz.hourOffset)
        let minutes = abs(tz.minuteOffset)
        let totalMinutes = tz.hourOffset * 60 + tz.minuteOffset
        guard totalMinutes != 0 else { return "" }

        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) hour\(hours > 1 ? "s" : "")") }
        if minutes > 0 { parts.append("\(minutes) minute\(minutes > 1 ? "s" : "")") }
        let joined = parts.joined(separator: " ")
        let action = totalMinutes > 0 ? "added" : "subtracted"
        return "\(joined) \(action)"
    }

    private var timeHeaderColor: Color {
        guard tz.isHourOffsetMode else { return .primary }
        let totalMinutes = tz.hourOffset * 60 + tz.minuteOffset
        if totalMinutes >= 60 { return .green }
        if totalMinutes > 0 { return .orange }
        if totalMinutes < 0 { return .red }
        return .primary
    }

    private var localTimeString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = tz.timeFormat
        return f.string(from: tz.displayDate)
    }

    private var localDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: tz.displayDate)
    }

    // MARK: - Timezone List

    private var timezoneSection: some View {
        VStack(spacing: 0) {
            if tz.savedIdentifiers.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(sortedIdentifiers, id: \.self) { id in
                        TimeZoneRowView(identifier: id)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                    }
                    .onMove(perform: tz.moveTimeZone)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 60, maxHeight: 280)
            }
        }
    }

    private var sortedIdentifiers: [String] {
        tz.savedIdentifiers.sorted { a, b in
            let aFav = tz.isFavorite(identifier: a)
            let bFav = tz.isFavorite(identifier: b)
            if aFav != bFav { return aFav }
            return false
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text("No timezones added")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Text("Use + to add your first city")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.vertical, 36)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            HStack {
                Button { showingAddSheet = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13))
                        Text("Add Timezone")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        tz.isHourOffsetMode.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tz.isHourOffsetMode
                            ? "clock.badge.checkmark.fill"
                            : "clock.arrow.circlepath")
                            .font(.system(size: 13))
                        Text("Add/Subtract Time")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(tz.isHourOffsetMode ? .accentColor : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            if tz.isHourOffsetMode {
                HourOffsetView()
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
            }
        }
    }
}
