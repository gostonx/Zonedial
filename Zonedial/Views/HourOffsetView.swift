import SwiftUI

struct HourOffsetView: View {

    @EnvironmentObject var tz: TimeZoneManager
    @State private var text: String = ""
    @State private var selectedMinute: Int = 0

    private let minuteOptions: [(value: Int, label: String)] = [
        (0, "0m"),
        (15, "15m"),
        (30, "30m"),
        (45, "45m")
    ]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("Offset:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Button {
                    tz.hourOffset -= 1
                    text = String(tz.hourOffset)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 20, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.08))
                )
                .foregroundColor(.secondary)

                TextField("0", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .frame(width: 36)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.primary.opacity(0.08))
                    )
                    .onChange(of: text) { _, newValue in
                        let cleaned = cleanInput(newValue)
                        if cleaned != newValue {
                            text = cleaned
                            return
                        }
                        if let parsed = Int(newValue) {
                            tz.hourOffset = parsed
                        } else if newValue.isEmpty || newValue == "-" {
                            tz.hourOffset = 0
                        }
                    }
                    .onAppear {
                        text = String(tz.hourOffset)
                    }

                Button {
                    tz.hourOffset += 1
                    text = String(tz.hourOffset)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 20, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.08))
                )
                .foregroundColor(.secondary)

                Text("hr")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    tz.hourOffset = 0
                    tz.minuteOffset = 0
                    tz.isHourOffsetMode = false
                    text = "0"
                    selectedMinute = 0
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Reset offset")
            }

            HStack(spacing: 4) {
                Text("Minutes:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.leading, 0)

                ForEach(minuteOptions, id: \.value) { option in
                    Button {
                        selectedMinute = option.value
                        tz.minuteOffset = option.value
                    } label: {
                        Text(option.label)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(selectedMinute == option.value ? .white : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedMinute == option.value
                                        ? Color.accentColor
                                        : Color.primary.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .onAppear {
                selectedMinute = tz.minuteOffset
            }
        }
    }

    private func cleanInput(_ input: String) -> String {
        var result = ""
        var hasMinus = false
        for ch in input {
            if ch == "-" && !hasMinus && result.isEmpty {
                result.append(ch)
                hasMinus = true
            } else if ch.isNumber {
                result.append(ch)
            }
        }
        if result == "-0" || result.isEmpty {
            return "0"
        }
        return result
    }
}
