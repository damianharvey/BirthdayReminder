import Foundation

class FriendsManager: ObservableObject {
    @Published var friends: [Friend] = []

    private let storageKey = "friends_data"

    init() { load() }

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
