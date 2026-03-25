import SwiftUI

@main
struct BirthdayBellApp: App {
    @StateObject private var friendsManager  = FriendsManager()
    @StateObject private var settingsManager = SettingsManager()

    @State private var pendingImportResult: ImportResult?
    @State private var showingOpenURLError  = false
    @State private var openURLError:        ImportError?

    init() {
        NotificationManager.requestPermission()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(friendsManager)
                .environmentObject(settingsManager)
                .onAppear {
                    NotificationManager.scheduleAll(
                        friends:     friendsManager.friends,
                        defaultDays: settingsManager.defaultReminderDays
                    )
                }
                .onOpenURL { url in
                    handleOpenURL(url)
                }
                .sheet(item: $pendingImportResult) { result in
                    BirthdayImportView(result: result)
                        .environmentObject(friendsManager)
                        .environmentObject(settingsManager)
                }
                .alert("Import Failed", isPresented: $showingOpenURLError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(openURLError?.errorDescription ?? "Unknown error.")
                }
        }
    }

    // MARK: - File open handler (AirDrop, Files app, Mail)

    private func handleOpenURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }
        do {
            pendingImportResult = try friendsManager.importMerge(from: data)
        } catch let error as ImportError {
            openURLError = error
            showingOpenURLError = true
        } catch {
            openURLError = .invalidFormat
            showingOpenURLError = true
        }
    }

    private func configureAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .light),
            .foregroundColor: UIColor(AppTheme.primary)
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.primary)
        ]
    }
}
