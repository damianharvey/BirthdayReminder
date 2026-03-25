import Foundation

class FriendsManager: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var messagedTodayIDs: Set<UUID> = []

    private let storageKey       = "friends_data"
    private let messagedIDsKey   = "messaged_today_ids"
    private let messagedDateKey  = "messaged_today_date"

    init() { load(); loadMessagedToday() }

    // MARK: - CRUD

    func add(_ friend: Friend) {
        friends.append(friend)
        save()
    }

    func update(_ friend: Friend) {
        guard let i = friends.firstIndex(where: { $0.id == friend.id }) else { return }
        friends[i] = friend
        save()
    }

    func delete(_ friend: Friend) {
        friends.removeAll { $0.id == friend.id }
        save()
    }

    func delete(at offsets: IndexSet, from list: [Friend]) {
        let ids = offsets.map { list[$0].id }
        friends.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: - Message Today

    func markMessaged(_ friend: Friend) {
        messagedTodayIDs.insert(friend.id)
        saveMessagedToday()
    }

    func hasBeenMessaged(_ friend: Friend) -> Bool {
        messagedTodayIDs.contains(friend.id)
    }

    private func saveMessagedToday() {
        let ids = messagedTodayIDs.map { $0.uuidString }
        UserDefaults.standard.set(ids, forKey: messagedIDsKey)
        UserDefaults.standard.set(Calendar.current.startOfDay(for: Date()), forKey: messagedDateKey)
    }

    private func loadMessagedToday() {
        guard
            let storedDate = UserDefaults.standard.object(forKey: messagedDateKey) as? Date,
            Calendar.current.isDateInToday(storedDate),
            let ids = UserDefaults.standard.stringArray(forKey: messagedIDsKey)
        else {
            messagedTodayIDs = []
            return
        }
        messagedTodayIDs = Set(ids.compactMap { UUID(uuidString: $0) })
    }

    // MARK: - Derived lists

    var friendsWithBirthday: [Friend] {
        friends
            .filter { $0.birthday != nil }
            .sorted { $0.lastName.localizedCompare($1.lastName) == .orderedAscending }
    }

    var friendsWithoutBirthday: [Friend] {
        friends
            .filter { $0.birthday == nil }
            .sorted { $0.lastName.localizedCompare($1.lastName) == .orderedAscending }
    }

    func upcomingBirthdays(within days: Int) -> [Friend] {
        friendsWithBirthday
            .filter { ($0.daysUntilBirthday ?? 999) <= days }
            .sorted { ($0.daysUntilBirthday ?? 999) < ($1.daysUntilBirthday ?? 999) }
    }

    // MARK: - Import / Export

    func exportData() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let stripped = friends.map { friend -> Friend in
            var copy = friend
            copy.contactIdentifier = nil
            return copy
        }
        let envelope = BirthdayBellExport(
            version: 1,
            exportedAt: Date(),
            appBundleID: Bundle.main.bundleIdentifier ?? "",
            friends: stripped
        )
        return try? encoder.encode(envelope)
    }

    func importMerge(from data: Data) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope: BirthdayBellExport
        do {
            envelope = try decoder.decode(BirthdayBellExport.self, from: data)
        } catch {
            throw ImportError.invalidFormat
        }
        guard envelope.appBundleID == Bundle.main.bundleIdentifier else {
            throw ImportError.wrongApp
        }
        guard envelope.version <= 1 else {
            throw ImportError.unsupportedVersion
        }
        let existingIDs = Set(friends.map { $0.id })
        let newFriends = envelope.friends.filter { !existingIDs.contains($0.id) }
        let conflictFriends = envelope.friends.filter { existingIDs.contains($0.id) }
        return ImportResult(
            incoming: envelope.friends,
            newFriends: newFriends,
            conflictFriends: conflictFriends,
            totalExisting: friends.count
        )
    }

    func applyImport(_ result: ImportResult, strategy: ImportStrategy) {
        switch strategy {
        case .mergeNew:
            let existingIDs = Set(friends.map { $0.id })
            friends.append(contentsOf: result.incoming.filter { !existingIDs.contains($0.id) })
        case .mergeAndReplace:
            for incoming in result.incoming {
                if let i = friends.firstIndex(where: { $0.id == incoming.id }) {
                    friends[i] = incoming
                } else {
                    friends.append(incoming)
                }
            }
        case .replaceAll:
            friends = result.incoming
        }
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(friends) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([Friend].self, from: data)
        else { return }
        friends = decoded
    }
}
