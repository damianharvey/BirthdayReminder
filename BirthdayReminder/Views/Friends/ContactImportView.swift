import SwiftUI

struct ContactImportView: View {
    @EnvironmentObject var friendsManager: FriendsManager
    @Environment(\.dismiss) private var dismiss

    @State private var contacts:           [Friend]   = []
    @State private var selected:           Set<UUID>  = []
    @State private var isLoading                      = true
    @State private var permissionDenied               = false
    @State private var searchText                     = ""

    private var filtered: [Friend] {
        searchText.isEmpty
            ? contacts
            : contacts.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(AppTheme.accent)
                } else if permissionDenied {
                    permissionDeniedView
                } else if contacts.isEmpty {
                    allImportedView
                } else {
                    contactsList
                }
            }
            .navigationTitle("Import Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import (\(selected.count))") { importSelected() }
                        .foregroundColor(AppTheme.accent)
                        .fontWeight(.medium)
                        .disabled(selected.isEmpty)
                }
            }
            .onAppear(perform: loadContacts)
        }
    }

    // MARK: - Sub-views

    private var contactsList: some View {
        List {
            ForEach(filtered) { contact in
                Button {
                    if selected.contains(contact.id) {
                        selected.remove(contact.id)
                    } else {
                        selected.insert(contact.id)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selected.contains(contact.id)
                              ? "checkmark.circle.fill"
                              : "circle")
                            .foregroundColor(selected.contains(contact.id)
                                             ? AppTheme.accent
                                             : AppTheme.divider)
                            .font(.system(size: 22))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(contact.fullName.isEmpty ? "(No Name)" : contact.fullName)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.primary)

                            if let str = contact.birthdayString {
                                Text(str)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.secondary)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(AppTheme.surface)
                .listRowSeparatorTint(AppTheme.divider)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search contacts")
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(AppTheme.secondary.opacity(0.4))

            Text("Contacts Access Denied")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(AppTheme.primary)

            Text("Enable access in Settings to import contacts.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundColor(AppTheme.accent)
            .padding(.top, 8)
        }
    }

    private var allImportedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(AppTheme.accent.opacity(0.6))

            Text("All contacts imported")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(AppTheme.secondary)
        }
    }

    // MARK: - Logic

    private func loadContacts() {
        ContactsManager.requestAccess { granted in
            guard granted else {
                permissionDenied = true
                isLoading        = false
                return
            }

            ContactsManager.fetchContacts { friends in
                let existingIds = Set(friendsManager.friends.compactMap { $0.contactIdentifier })
                contacts = friends
                    .filter { friend in
                        guard let cid = friend.contactIdentifier else { return true }
                        return !existingIds.contains(cid)
                    }
                    .filter { !$0.fullName.trimmingCharacters(in: .whitespaces).isEmpty }
                    .sorted { $0.lastName.localizedCompare($1.lastName) == .orderedAscending }
                isLoading = false
            }
        }
    }

    private func importSelected() {
        contacts
            .filter { selected.contains($0.id) }
            .forEach { friendsManager.add($0) }
        dismiss()
    }
}
