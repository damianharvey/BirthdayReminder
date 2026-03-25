import SwiftUI

struct BirthdayImportView: View {
    @EnvironmentObject var friendsManager:  FriendsManager
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss

    let result: ImportResult

    @State private var strategy: ImportStrategy = .mergeNew
    @State private var showingReplaceConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                List {
                    Section {
                        summaryRow
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)

                    Section {
                        Picker("Strategy", selection: $strategy) {
                            Text("Add New").tag(ImportStrategy.mergeNew)
                            Text("Add & Update").tag(ImportStrategy.mergeAndReplace)
                            Text("Replace All").tag(ImportStrategy.replaceAll)
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(AppTheme.background)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } footer: {
                        strategyFooter
                    }

                    if !result.newFriends.isEmpty {
                        Section {
                            ForEach(result.newFriends) { friend in
                                newFriendRow(friend)
                            }
                        } header: {
                            SectionHeader(title: "New (\(result.newFriends.count))")
                        }
                        .listRowBackground(AppTheme.surface)
                        .listRowSeparatorTint(AppTheme.divider)
                    }

                    if !result.conflictFriends.isEmpty {
                        Section {
                            if strategy == .replaceAll {
                                Label(
                                    "Your \(result.totalExisting) existing friends will be deleted",
                                    systemImage: "exclamationmark.triangle"
                                )
                                .font(.system(size: 13))
                                .foregroundColor(.orange)
                                .listRowBackground(Color.orange.opacity(0.08))
                            }
                            ForEach(result.conflictFriends) { friend in
                                conflictFriendRow(friend)
                            }
                        } header: {
                            SectionHeader(title: "Already in Your List (\(result.conflictFriends.count))")
                        }
                        .listRowBackground(AppTheme.surface)
                        .listRowSeparatorTint(AppTheme.divider)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Import Birthdays")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") { handleImport() }
                        .foregroundColor(AppTheme.accent)
                        .fontWeight(.medium)
                }
            }
            .confirmationDialog(
                "Replace all \(result.totalExisting) friends?",
                isPresented: $showingReplaceConfirm,
                titleVisibility: .visible
            ) {
                Button("Replace", role: .destructive) { performImport() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All existing friends will be deleted and replaced with the imported list. This cannot be undone.")
            }
        }
    }

    // MARK: - Sub-views

    private var summaryRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(result.incoming.count) friend\(result.incoming.count == 1 ? "" : "s") in file")
                .font(.system(size: 15))
                .foregroundColor(AppTheme.primary)
            HStack(spacing: 16) {
                Label("\(result.newFriends.count) new", systemImage: "person.badge.plus")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.accent)
                Label("\(result.conflictFriends.count) already in list", systemImage: "person.2")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var strategyFooter: some View {
        switch strategy {
        case .mergeNew:
            Text("Only friends not already in your list will be added.")
                .foregroundColor(AppTheme.secondary)
        case .mergeAndReplace:
            Text("New friends will be added. Friends already in your list will be updated with the imported data.")
                .foregroundColor(AppTheme.secondary)
        case .replaceAll:
            Text("All existing friends will be deleted and replaced with the imported list.")
                .foregroundColor(.orange)
        }
    }

    @ViewBuilder
    private var conflictBadge: some View {
        switch strategy {
        case .mergeNew:
            Text("kept")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppTheme.divider.opacity(0.6))
                .clipShape(Capsule())
        case .mergeAndReplace:
            Text("updated")
                .font(.system(size: 11))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
        case .replaceAll:
            Text("deleted")
                .font(.system(size: 11))
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private func newFriendRow(_ friend: Friend) -> some View {
        HStack(spacing: 12) {
            AvatarView(friend: friend, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.fullName.isEmpty ? "(No Name)" : friend.fullName)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.primary)
                if let str = friend.birthdayString {
                    Text(str)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.secondary)
                }
            }
        }
    }

    private func conflictFriendRow(_ friend: Friend) -> some View {
        HStack(spacing: 12) {
            AvatarView(friend: friend, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.fullName.isEmpty ? "(No Name)" : friend.fullName)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.primary)
                if let str = friend.birthdayString {
                    Text(str)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.secondary)
                }
            }
            Spacer()
            conflictBadge
        }
    }

    // MARK: - Logic

    private func handleImport() {
        if strategy == .replaceAll && result.totalExisting > 0 {
            showingReplaceConfirm = true
        } else {
            performImport()
        }
    }

    private func performImport() {
        friendsManager.applyImport(result, strategy: strategy)
        NotificationManager.scheduleAll(
            friends:     friendsManager.friends,
            defaultDays: settingsManager.defaultReminderDays
        )
        dismiss()
    }
}
