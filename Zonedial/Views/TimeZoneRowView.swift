import SwiftUI

struct TimeZoneRowView: View {

    @EnvironmentObject var tz: TimeZoneManager
    let identifier: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary.opacity(0.3))

            Button {
                tz.toggleFavorite(identifier: identifier)
            } label: {
                Image(systemName: tz.isFavorite(identifier: identifier) ? "star.fill" : "star")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundColor(tz.isFavorite(identifier: identifier) ? .yellow : .secondary.opacity(0.4))

            VStack(alignment: .leading, spacing: 2) {
                Text(tz.cityName(for: identifier))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(tz.regionName(for: identifier))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("·")
                        .foregroundColor(.secondary.opacity(0.5))
                        .font(.system(size: 10))

                    Text(tz.utcOffsetString(for: identifier))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(tz.timeDifference(for: identifier))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.6))

            VStack(alignment: .trailing, spacing: 2) {
                Text(tz.formattedTime(for: identifier))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)

                if let badge = tz.dayOffsetLabel(for: identifier) {
                    Text(badge)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )
                }
            }

            Button {
                withAnimation { tz.removeTimeZone(identifier: identifier) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
