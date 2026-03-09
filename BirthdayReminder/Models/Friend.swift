import Foundation

struct PhoneNumber: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var label: String
    var number: String
}

struct EmailAddress: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var label: String
    var email: String
}

struct Friend: Identifiable, Codable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var birthday: Date?
    var phoneNumbers: [PhoneNumber]
    var emailAddresses: [EmailAddress]
    /// Custom reminder days for this friend. Empty = use the global default.
    var reminderDays: [Int]
    var contactIdentifier: String?

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var initials: String {
        let f = firstName.prefix(1)
        let l = lastName.prefix(1)
        return "\(f)\(l)".uppercased()
    }

    var daysUntilBirthday: Int? {
        guard let birthday = birthday else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var components = calendar.dateComponents([.month, .day], from: birthday)
        let currentYear = calendar.component(.year, from: today)
        components.year = currentYear

        guard var next = calendar.date(from: components) else { return nil }
        if next < today {
            components.year = currentYear + 1
            guard let nextYear = calendar.date(from: components) else { return nil }
            next = nextYear
        }
        return calendar.dateComponents([.day], from: today, to: next).day
    }

    var turningAge: Int? {
        guard let birthday = birthday else { return nil }
        let years = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
        return years + 1
    }

    var birthdayString: String? {
        guard let birthday = birthday else { return nil }
        let f = DateFormatter()
        f.dateFormat = "MMMM d"
        return f.string(from: birthday)
    }

    var primaryPhone: PhoneNumber? { phoneNumbers.first }
    var primaryEmail: EmailAddress? { emailAddresses.first }

    // MARK: - Codable (handles migration from old Int? format)

    enum CodingKeys: String, CodingKey {
        case id, firstName, lastName, birthday, phoneNumbers,
             emailAddresses, reminderDays, contactIdentifier
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self,        forKey: .id)
        firstName      = try c.decode(String.self,      forKey: .firstName)
        lastName       = try c.decode(String.self,      forKey: .lastName)
        birthday       = try c.decodeIfPresent(Date.self,   forKey: .birthday)
        phoneNumbers   = try c.decode([PhoneNumber].self,   forKey: .phoneNumbers)
        emailAddresses = try c.decode([EmailAddress].self,  forKey: .emailAddresses)
        contactIdentifier = try c.decodeIfPresent(String.self, forKey: .contactIdentifier)

        // Migrate: old format was Int?, new format is [Int]
        if let arr = try? c.decodeIfPresent([Int].self, forKey: .reminderDays) {
            reminderDays = arr ?? []
        } else if let single = try? c.decodeIfPresent(Int.self, forKey: .reminderDays) {
            reminderDays = [single]
        } else {
            reminderDays = []
        }
    }

    init(id: UUID = UUID(),
         firstName: String,
         lastName: String,
         birthday: Date? = nil,
         phoneNumbers: [PhoneNumber] = [],
         emailAddresses: [EmailAddress] = [],
         reminderDays: [Int] = [],
         contactIdentifier: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.birthday = birthday
        self.phoneNumbers = phoneNumbers
        self.emailAddresses = emailAddresses
        self.reminderDays = reminderDays
        self.contactIdentifier = contactIdentifier
    }

    var avatarColor: AvatarColor {
        let index = abs(fullName.hashValue) % AvatarColor.allCases.count
        return AvatarColor.allCases[index]
    }
}

enum AvatarColor: String, CaseIterable {
    case sage    = "6B8F71"
    case slate   = "7B9EA8"
    case sand    = "9B8E7B"
    case mauve   = "8B7B9B"
    case rose    = "9B7B7B"
    case steel   = "7B8B9B"
}
