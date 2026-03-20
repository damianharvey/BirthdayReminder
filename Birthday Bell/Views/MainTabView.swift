import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var friendsManager:  FriendsManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedTab = 0

    var upcomingCount: Int {
        friendsManager.upcomingBirthdays(within: settingsManager.upcomingDaysToShow).count
    }

    // Tab bar height + safe area bottom inset
    private let tabBarHeight: CGFloat = 64

    var body: some View {
        ZStack(alignment: .bottom) {
            // All three views stay in memory so navigation state is preserved.
            // Invisible tabs have hit-testing disabled so they don't intercept touches.
            ZStack {
                HomeView()
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 0)

                FriendsView()
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 1)

                SettingsView()
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 2)
            }
            // Push content above the tab bar
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: tabBarHeight)
            }

            CustomTabBar(selectedTab: $selectedTab, badge: upcomingCount)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Custom tab bar

private struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let badge: Int

    private let items: [(icon: String, label: String)] = [
        ("house",     "Home"),
        ("person.2",  "Friends"),
        ("gearshape", "Settings"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: "B8CDB9").opacity(0.6))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    TabBarButton(
                        icon:       items[i].icon,
                        isSelected: selectedTab == i,
                        badge:      i == 0 ? badge : 0
                    ) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedTab = i
                        }
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(
            Color(hex: "DCE9DD")
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Individual button

private struct TabBarButton: View {
    let icon:       String
    let isSelected: Bool
    let badge:      Int
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .regular : .light))
                        .foregroundStyle(
                            isSelected ? Color(hex: "4E7355") : Color(hex: "8FA690")
                        )
                        .frame(width: 28, height: 28)
                        .scaleEffect(isSelected ? 1.0 : 0.92)
                        .animation(.easeInOut(duration: 0.18), value: isSelected)

                    if badge > 0 {
                        Text(badge > 9 ? "9+" : "\(badge)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color(hex: "C0473A").opacity(0.9))
                            .clipShape(Capsule())
                            .offset(x: 8, y: -4)
                    }
                }

                Capsule()
                    .fill(isSelected ? Color(hex: "6B8F71") : Color.clear)
                    .frame(width: 24, height: 3)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
