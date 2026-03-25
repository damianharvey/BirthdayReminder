import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var friendsManager:  FriendsManager
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var showingAddFriend   = false
    @State private var showingImport      = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                Group {
                    if friendsManager.friends.isEmpty {
                        emptyState
                    } else {
                        friendsList
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingImport = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .foregroundColor(AppTheme.accent)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFriend = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                FriendFormView(mode: .add)
            }
            .sheet(isPresented: $showingImport) {
                ContactImportView()
            }
        }
    }

    // MARK: - Sub-views

    private var friendsList: some View {
        List {
            ForEach(friendsManager.friendsSortedByLastName) { friend in
                NavigationLink { FriendDetailView(friend: friend) } label: {
                    FriendRow(friend: friend, showBirthday: friend.birthday != nil)
                }
                .listRowBackground(AppTheme.surface)
                .listRowSeparatorTint(AppTheme.divider)
            }
            .onDelete { offsets in
                friendsManager.delete(at: offsets, from: friendsManager.friendsSortedByLastName)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(AppTheme.secondary.opacity(0.4))

            Text("No friends yet")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(AppTheme.secondary)

            Text("Tap + to add a friend, or import from Contacts")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.secondary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let friend:      Friend
    let showBirthday: Bool

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(friend: friend, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.fullName)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.primary)

                if showBirthday, let str = friend.birthdayString {
                    HStack(spacing: 4) {
                        Text(str)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondary)

                        if let days = friend.daysUntilBirthday, days <= 30 {
                            Text("· \(days == 0 ? "Today!" : "\(days)d")")
                                .font(.system(size: 13))
                                .foregroundColor(days <= 7 ? AppTheme.accent : AppTheme.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 3)
    }
}
