import Foundation
import Contacts

enum ContactsManager {

    static func requestAccess(completion: @escaping (Bool) -> Void) {
        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func fetchContacts(completion: @escaping ([Friend]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [
                CNContactGivenNameKey       as CNKeyDescriptor,
                CNContactFamilyNameKey      as CNKeyDescriptor,
                CNContactBirthdayKey        as CNKeyDescriptor,
                CNContactPhoneNumbersKey    as CNKeyDescriptor,
                CNContactEmailAddressesKey  as CNKeyDescriptor,
                CNContactIdentifierKey      as CNKeyDescriptor
            ]

            var friends: [Friend] = []
            let request = CNContactFetchRequest(keysToFetch: keys)

            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    let birthday: Date? = contact.birthday.flatMap {
                        Calendar.current.date(from: $0)
                    }

                    let phones = contact.phoneNumbers.map { p in
                        PhoneNumber(
                            label: CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: p.label ?? ""),
                            number: p.value.stringValue
                        )
                    }

                    let emails = contact.emailAddresses.map { e in
                        EmailAddress(
                            label: CNLabeledValue<NSString>.localizedString(forLabel: e.label ?? ""),
                            email: e.value as String
                        )
                    }

                    friends.append(Friend(
                        firstName:         contact.givenName,
                        lastName:          contact.familyName,
                        birthday:          birthday,
                        phoneNumbers:      phones,
                        emailAddresses:    emails,
                        contactIdentifier: contact.identifier
                    ))
                }
            } catch {
                print("Contacts fetch error: \(error)")
            }

            DispatchQueue.main.async { completion(friends) }
        }
    }
}
