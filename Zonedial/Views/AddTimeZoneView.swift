import SwiftUI

/// Searchable list of every known IANA timezone.  Tapping a row adds it
/// to the user's saved list and dismisses the view.
struct AddTimeZoneView: View {

    @EnvironmentObject var tz: TimeZoneManager
    @Binding var isPresented: Bool

    @State private var searchText = ""
    @State private var showFavorites = false
    @FocusState private var searchFocused: Bool

    private var results: [(identifier: String, displayName: String)] {
        let base = tz.searchTimeZones(query: searchText)
        if showFavorites {
            return base.filter { tz.isFavorite(identifier: $0.identifier) }
        }
        return base
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { isPresented = false } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Spacer()

                Text("Add Timezone")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Color.clear.frame(width: 40, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            HStack(spacing: 2) {
                Button {
                    showFavorites = false
                } label: {
                    Text("All")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(showFavorites ? .secondary : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(showFavorites ? Color.clear : Color.primary.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)

                Button {
                    showFavorites = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                        Text("Favorites")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(showFavorites ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(showFavorites ? Color.primary.opacity(0.12) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                TextField(showFavorites ? "Search favorites..." : "Search city or country...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($searchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.08))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

            if results.isEmpty {
                Spacer()
                Text(showFavorites ? "No favorites yet" : "No matches")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(results, id: \.identifier) { entry in
                        Button {
                            tz.addTimeZone(identifier: entry.identifier)
                            isPresented = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.displayName)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)

                                    HStack(spacing: 6) {
                                        Text(tz.utcOffsetString(for: entry.identifier))
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)

                                        Text("·")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary.opacity(0.4))

                                        Text(tz.formattedTime(for: entry.identifier))
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Button {
                                    tz.toggleFavorite(identifier: entry.identifier)
                                } label: {
                                    Image(systemName: tz.isFavorite(identifier: entry.identifier) ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundColor(tz.isFavorite(identifier: entry.identifier) ? .yellow : .secondary.opacity(0.3))
                                }
                                .buttonStyle(.plain)

                                if tz.savedIdentifiers.contains(entry.identifier) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(.bottom, 8)
        .onAppear {
            searchFocused = true
        }
    }
}
