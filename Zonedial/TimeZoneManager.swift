import Foundation
import Combine

/// Central state for the app: persists the timezone list, runs a live clock,
/// and performs all timezone conversions exclusively through Foundation APIs.
final class TimeZoneManager: ObservableObject {

    // MARK: - Published state

    /// Fires every second so SwiftUI views redraw with the live time.
    @Published var currentDate = Date()

    /// Ordered list of saved TimeZone identifiers (e.g. "America/New_York").
    @Published var savedIdentifiers: [String] {
        didSet { save() }
    }

    /// Number of hours the user wants to shift the reference time by.
    @Published var hourOffset: Int = 0

    /// Number of minutes the user wants to shift the reference time by.
    @Published var minuteOffset: Int = 0

    /// When true, all displayed times are shifted by the combined offset.
    @Published var isHourOffsetMode: Bool = false

    /// Set of favorited timezone identifiers.
    @Published var favoriteIdentifiers: Set<String> {
        didSet { saveFavorites() }
    }

    /// When true, times are displayed in 24-hour format instead of 12-hour.
    @Published var use24HourTime: Bool {
        didSet { UserDefaults.standard.set(use24HourTime, forKey: "Zonedial.Use24HourTime") }
    }

    /// When true, seconds are shown in time displays.
    @Published var showSeconds: Bool {
        didSet { UserDefaults.standard.set(showSeconds, forKey: "Zonedial.ShowSeconds") }
    }

    // MARK: - Private

    private var timer: Timer?
    private let defaultsKey = "Zonedial.SavedTimeZoneIdentifiers"
    private let favoritesKey = "Zonedial.FavoriteTimeZoneIdentifiers"

    // MARK: - Init

    init() {
        self.savedIdentifiers = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        if let favs = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            self.favoriteIdentifiers = Set(favs)
        } else {
            self.favoriteIdentifiers = []
        }
        self.use24HourTime = UserDefaults.standard.bool(forKey: "Zonedial.Use24HourTime")
        self.showSeconds = UserDefaults.standard.bool(forKey: "Zonedial.ShowSeconds")
        startTimer()
    }

    // MARK: - Timer (fires at each whole second for accuracy)

    private func startTimer() {
        let now = Date()
        let nextSecond = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(nanosecond: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(1)

        let delay = nextSecond.timeIntervalSince(now)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.currentDate = Date()
            self?.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.currentDate = Date()
            }
            if let timer = self?.timer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }

    // MARK: - Derived date (respects hour/minute offset mode)

    /// The reference date used for all timezone conversions.
    var displayDate: Date {
        guard isHourOffsetMode else { return currentDate }
        var date = currentDate
        if hourOffset != 0 {
            date = Calendar.current.date(byAdding: .hour, value: hourOffset, to: date) ?? date
        }
        if minuteOffset != 0 {
            date = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: date) ?? date
        }
        return date
    }

    // MARK: - Persistence

    private func save() {
        UserDefaults.standard.set(savedIdentifiers, forKey: defaultsKey)
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIdentifiers), forKey: favoritesKey)
    }

    func toggleFavorite(identifier: String) {
        if favoriteIdentifiers.contains(identifier) {
            favoriteIdentifiers.remove(identifier)
        } else {
            favoriteIdentifiers.insert(identifier)
        }
    }

    func isFavorite(identifier: String) -> Bool {
        favoriteIdentifiers.contains(identifier)
    }

    // MARK: - List mutations

    func addTimeZone(identifier: String) {
        guard !savedIdentifiers.contains(identifier) else { return }
        savedIdentifiers.append(identifier)
    }

    func removeTimeZone(identifier: String) {
        savedIdentifiers.removeAll { $0 == identifier }
    }

    func moveTimeZone(from source: IndexSet, to destination: Int) {
        savedIdentifiers.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Formatting helpers (Foundation APIs only)

    /// Returns the time formatted in the given timezone.
    func formattedTime(for identifier: String) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if use24HourTime {
            formatter.dateFormat = showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            formatter.dateFormat = showSeconds ? "h:mm:ss a" : "h:mm a"
        }
        return formatter.string(from: displayDate)
    }

    var timeFormat: String {
        if use24HourTime {
            return showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            return showSeconds ? "h:mm:ss a" : "h:mm a"
        }
    }

    /// Returns "Tomorrow", "Yesterday", or nil if the day matches local.
    func dayOffsetLabel(for identifier: String) -> String? {
        guard let tz = TimeZone(identifier: identifier) else { return nil }

        var localCal = Calendar.current
        localCal.timeZone = TimeZone.current
        var targetCal = Calendar.current
        targetCal.timeZone = tz

        let localDay = localCal.component(.day, from: displayDate)
        let targetDay = targetCal.component(.day, from: displayDate)

        if targetDay > localDay { return "Tomorrow" }
        if targetDay < localDay { return "Yesterday" }
        return nil
    }

    /// Returns a display string like "GMT+9" or "GMT-5:30".
    func utcOffsetString(for identifier: String) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return "" }
        let offset = tz.secondsFromGMT(for: displayDate)
        let hours = offset / 3600
        let minutes = abs(offset % 3600) / 60
        if minutes == 0 {
            return String(format: "GMT%+d", hours)
        }
        return String(format: "GMT%+d:%02d", hours, minutes)
    }

    /// Returns the time difference between the target timezone and local, e.g. "+3:00" or "-1:30".
    func timeDifference(for identifier: String) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return "" }
        let targetOffset = tz.secondsFromGMT(for: displayDate)
        let localOffset = TimeZone.current.secondsFromGMT(for: displayDate)
        let diff = targetOffset - localOffset
        let hours = diff / 3600
        let minutes = abs(diff % 3600) / 60
        if minutes == 0 {
            return String(format: "%+d", hours)
        }
        return String(format: "%+d:%02d", hours, minutes)
    }

    /// Human-readable name from an identifier:
    /// "America/New_York" -> "America - New York"
    func displayName(for identifier: String) -> String {
        let comps = identifier.split(separator: "/")
        if comps.count >= 2 {
            return comps.dropFirst()
                .joined(separator: " - ")
                .replacingOccurrences(of: "_", with: " ")
        }
        return identifier.replacingOccurrences(of: "_", with: " ")
    }

    /// Just the city portion: "America/New_York" -> "New York"
    func cityName(for identifier: String) -> String {
        let comps = identifier.split(separator: "/")
        return (comps.last ?? Substring(identifier))
            .replacingOccurrences(of: "_", with: " ")
    }

    /// Just the region portion: "America/New_York" -> "America"
    func regionName(for identifier: String) -> String {
        let comps = identifier.split(separator: "/")
        guard comps.count >= 2 else { return "" }
        return comps[0].replacingOccurrences(of: "_", with: " ")
    }

    // MARK: - Search data source

    /// Maps common country/region names to their timezone identifiers.
    private static let countryTimeZones: [String: [String]] = [
        "india": ["Asia/Kolkata"],
        "japan": ["Asia/Tokyo"],
        "china": ["Asia/Shanghai", "Asia/Urumqi"],
        "brazil": ["America/Sao_Paulo", "America/Rio_Branco", "America/Manaus", "America/Fortaleza"],
        "russia": ["Europe/Moscow", "Asia/Yekaterinburg", "Asia/Novosibirsk", "Asia/Krasnoyarsk", "Asia/Irkutsk", "Asia/Vladivostok", "Asia/Kamchatka"],
        "mexico": ["America/Mexico_City", "America/Tijuana", "America/Cancun", "America/Monterrey"],
        "canada": ["America/Toronto", "America/Vancouver", "America/Edmonton", "America/Winnipeg", "America/Halifax", "America/St_Johns"],
        "uk": ["Europe/London"],
        "united kingdom": ["Europe/London"],
        "england": ["Europe/London"],
        "britain": ["Europe/London"],
        "germany": ["Europe/Berlin"],
        "france": ["Europe/Paris"],
        "italy": ["Europe/Rome"],
        "spain": ["Europe/Madrid"],
        "australia": ["Australia/Sydney", "Australia/Melbourne", "Australia/Brisbane", "Australia/Perth", "Australia/Adelaide"],
        "new zealand": ["Pacific/Auckland"],
        "south korea": ["Asia/Seoul"],
        "korea": ["Asia/Seoul"],
        "indonesia": ["Asia/Jakarta", "Asia/Makassar", "Asia/Jayapura"],
        "thailand": ["Asia/Bangkok"],
        "vietnam": ["Asia/Ho_Chi_Minh", "Asia/Saigon"],
        "philippines": ["Asia/Manila"],
        "singapore": ["Asia/Singapore"],
        "malaysia": ["Asia/Kuala_Lumpur"],
        "uae": ["Asia/Dubai"],
        "dubai": ["Asia/Dubai"],
        "united arab emirates": ["Asia/Dubai"],
        "egypt": ["Africa/Cairo"],
        "south africa": ["Africa/Johannesburg"],
        "nigeria": ["Africa/Lagos"],
        "kenya": ["Africa/Nairobi"],
        "argentina": ["America/Argentina/Buenos_Aires"],
        "chile": ["America/Santiago"],
        "colombia": ["America/Bogota"],
        "peru": ["America/Lima"],
        "turkey": ["Europe/Istanbul"],
        "saudi arabia": ["Asia/Riyadh"],
        "iran": ["Asia/Tehran"],
        "pakistan": ["Asia/Karachi"],
        "bangladesh": ["Asia/Dhaka"],
        "usa": ["America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles", "America/Anchorage", "Pacific/Honolulu"],
        "united states": ["America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles", "America/Anchorage", "Pacific/Honolulu"],
        "us": ["America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles", "America/Anchorage", "Pacific/Honolulu"]
    ]

    /// Maps common city names to their IANA timezone identifiers.
    private static let cityAliases: [String: String] = [
        "mumbai": "Asia/Kolkata",
        "bombay": "Asia/Kolkata",
        "delhi": "Asia/Kolkata",
        "new delhi": "Asia/Kolkata",
        "bangalore": "Asia/Kolkata",
        "bengaluru": "Asia/Kolkata",
        "chennai": "Asia/Kolkata",
        "madras": "Asia/Kolkata",
        "hyderabad": "Asia/Kolkata",
        "ahmedabad": "Asia/Kolkata",
        "pune": "Asia/Kolkata",
        "jaipur": "Asia/Kolkata",
        "lucknow": "Asia/Kolkata",
        "kolkata": "Asia/Kolkata",
        "calcutta": "Asia/Kolkata",
        "chandigarh": "Asia/Kolkata",
        "indore": "Asia/Kolkata",
        "kochi": "Asia/Kolkata",
        "cochin": "Asia/Kolkata",
        "goa": "Asia/Kolkata",
        "guwahati": "Asia/Kolkata",
        "patna": "Asia/Kolkata",
        "bhopal": "Asia/Kolkata",
        "nagpur": "Asia/Kolkata",
        "surat": "Asia/Kolkata",
        "kanpur": "Asia/Kolkata",
        "agra": "Asia/Kolkata",
        "varanasi": "Asia/Kolkata",
        "amritsar": "Asia/Kolkata",
        "darjeeling": "Asia/Kolkata",
        "shimla": "Asia/Kolkata",
        "udaipur": "Asia/Kolkata",
        "jodhpur": "Asia/Kolkata",
        "srinagar": "Asia/Kolkata",
        "tvm": "Asia/Kolkata",
        "trivandrum": "Asia/Kolkata",
        "thiruvananthapuram": "Asia/Kolkata",
        "bhubaneswar": "Asia/Kolkata",
        "gangtok": "Asia/Kolkata",
        "dehradun": "Asia/Kolkata",
        "raipur": "Asia/Kolkata",
        "ranchi": "Asia/Kolkata",
        "nainital": "Asia/Kolkata",
        "haridwar": "Asia/Kolkata",
        "rishikesh": "Asia/Kolkata",
        "pondicherry": "Asia/Kolkata",
        "puducherry": "Asia/Kolkata",
        "port blair": "Asia/Kolkata",
        "gurugram": "Asia/Kolkata",
        "gurgaon": "Asia/Kolkata",
        "noida": "Asia/Kolkata",
        "ghaziabad": "Asia/Kolkata",
        "faridabad": "Asia/Kolkata",
        "nashik": "Asia/Kolkata",
        "rajkot": "Asia/Kolkata",
        "vadodara": "Asia/Kolkata",
        "baroda": "Asia/Kolkata",
        "mysore": "Asia/Kolkata",
        "mysuru": "Asia/Kolkata",
        "mangalore": "Asia/Kolkata",
        "mangaluru": "Asia/Kolkata",
        "vijayawada": "Asia/Kolkata",
        "visakhapatnam": "Asia/Kolkata",
        "vizag": "Asia/Kolkata",
        "tirupati": "Asia/Kolkata",
        "coimbatore": "Asia/Kolkata",
        "madurai": "Asia/Kolkata",
        "salem": "Asia/Kolkata",
        "tiruchirappalli": "Asia/Kolkata",
        "trichy": "Asia/Kolkata",
        "allahabad": "Asia/Kolkata",
        "prayagraj": "Asia/Kolkata",
        "meerut": "Asia/Kolkata",
        "bareilly": "Asia/Kolkata",
        "jammu": "Asia/Kolkata",
        "dharamshala": "Asia/Kolkata",
        "manali": "Asia/Kolkata",
        "leh": "Asia/Kolkata",
        "kodaikanal": "Asia/Kolkata",
        "ooty": "Asia/Kolkata",
        "ootacamund": "Asia/Kolkata",
        "shillong": "Asia/Kolkata",
        "aizawl": "Asia/Kolkata",
        "imphal": "Asia/Kolkata",
        "kohima": "Asia/Kolkata",
        "itanagar": "Asia/Kolkata",
        "agartala": "Asia/Kolkata",
        "dibrugarh": "Asia/Kolkata",
        "siliguri": "Asia/Kolkata",
        "jamshedpur": "Asia/Kolkata",
        "dhanbad": "Asia/Kolkata",
        "bokaro": "Asia/Kolkata",
        "cuttack": "Asia/Kolkata",
        "rourkela": "Asia/Kolkata",
        "bilaspur": "Asia/Kolkata",
        "korba": "Asia/Kolkata",
        "ujjain": "Asia/Kolkata",
        "gwalior": "Asia/Kolkata",
        "jabalpur": "Asia/Kolkata",
        "aurangabad": "Asia/Kolkata",
        "solapur": "Asia/Kolkata",
        "kolhapur": "Asia/Kolkata",
        "amravati": "Asia/Kolkata",
        "nanded": "Asia/Kolkata",
        "akola": "Asia/Kolkata",
        "jalgaon": "Asia/Kolkata",
        "thane": "Asia/Kolkata",
        "navi mumbai": "Asia/Kolkata",
        "kalyan": "Asia/Kolkata",
        "vasai": "Asia/Kolkata",
        "virar": "Asia/Kolkata",
        "panvel": "Asia/Kolkata",
        "lonavala": "Asia/Kolkata",
        "mahabaleshwar": "Asia/Kolkata",
        "matheran": "Asia/Kolkata",
        "alibaug": "Asia/Kolkata",
        "daman": "Asia/Kolkata",
        "diu": "Asia/Kolkata",
        "silvassa": "Asia/Kolkata",
        "kavaratti": "Asia/Kolkata",
        "lakshadweep": "Asia/Kolkata",
        "andaman": "Asia/Kolkata",
        "nicobar": "Asia/Kolkata",
        "sikkim": "Asia/Kolkata",
        "meghalaya": "Asia/Kolkata",
        "arunachal": "Asia/Kolkata",
        "nagaland": "Asia/Kolkata",
        "manipur": "Asia/Kolkata",
        "mizoram": "Asia/Kolkata",
        "tripura": "Asia/Kolkata",
        "assam": "Asia/Kolkata",
        "west bengal": "Asia/Kolkata",
        "odisha": "Asia/Kolkata",
        "orissa": "Asia/Kolkata",
        "bihar": "Asia/Kolkata",
        "jharkhand": "Asia/Kolkata",
        "uttar pradesh": "Asia/Kolkata",
        "up": "Asia/Kolkata",
        "uttarakhand": "Asia/Kolkata",
        "himachal": "Asia/Kolkata",
        "himachal pradesh": "Asia/Kolkata",
        "punjab": "Asia/Kolkata",
        "haryana": "Asia/Kolkata",
        "rajasthan": "Asia/Kolkata",
        "gujarat": "Asia/Kolkata",
        "madhya pradesh": "Asia/Kolkata",
        "mp": "Asia/Kolkata",
        "chhattisgarh": "Asia/Kolkata",
        "maharashtra": "Asia/Kolkata",
        "andhra": "Asia/Kolkata",
        "andhra pradesh": "Asia/Kolkata",
        "telangana": "Asia/Kolkata",
        "karnataka": "Asia/Kolkata",
        "kerala": "Asia/Kolkata",
        "tamil nadu": "Asia/Kolkata",
        "tn": "Asia/Kolkata"
    ]

    /// Full sorted list of known identifiers with display names.
    var knownTimeZones: [(identifier: String, displayName: String)] {
        TimeZone.knownTimeZoneIdentifiers
            .map { ($0, displayName(for: $0)) }
            .sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
    }

    /// Filters the known timezones by city name, country, or abbreviation.
    func searchTimeZones(query: String) -> [(identifier: String, displayName: String)] {
        guard !query.isEmpty else { return knownTimeZones }
        let q = query.lowercased()

        let countryMatches: Set<String> = {
            var ids = Set<String>()
            for (country, identifiers) in Self.countryTimeZones {
                if country.contains(q) || q.contains(country) {
                    ids.formUnion(identifiers)
                }
            }
            return ids
        }()

        let cityMatches: Set<String> = {
            var ids = Set<String>()
            for (alias, identifier) in Self.cityAliases {
                if alias.contains(q) || q.contains(alias) {
                    ids.insert(identifier)
                }
            }
            return ids
        }()

        return knownTimeZones.filter { entry in
            if countryMatches.contains(entry.identifier) { return true }
            if cityMatches.contains(entry.identifier) { return true }
            let tz = TimeZone(identifier: entry.identifier)
            let abbrev = tz?.abbreviation(for: displayDate)?.lowercased() ?? ""
            return entry.displayName.lowercased().contains(q)
                || entry.identifier.lowercased().contains(q)
                || abbrev.contains(q)
        }
    }
}
