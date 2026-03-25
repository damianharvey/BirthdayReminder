import SwiftUI
import UniformTypeIdentifiers

// MARK: - Sheet routing

private enum ActiveSheet: Identifiable {
    case shareExport(URL)
    case importReview(ImportResult)

    var id: String {
        switch self {
        case .shareExport:  return "export"
        case .importReview: return "import"
        }
    }
}

// MARK: - Main view

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var friendsManager:  FriendsManager

    @State private var showingRescheduleConfirm = false
    @State private var activeSheet:       ActiveSheet?
    @State private var showingFileImporter = false
    @State private var showingImportError  = false
    @State private var importError:        ImportError?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                List {
                    // Notifications
                    Section {
                        HStack {
                            Label("Default reminder", systemImage: "bell")
                                .foregroundColor(AppTheme.primary)
                            Spacer()
                            Stepper(
                                "\(settingsManager.defaultReminderDays) day\(settingsManager.defaultReminderDays == 1 ? "" : "s")",
                                value: $settingsManager.defaultReminderDays,
                                in: 1...365
                            )
                            .fixedSize()
                            .foregroundColor(AppTheme.secondary)
                        }
                    } header: {
                        SectionHeader(title: "Notifications")
                    } footer: {
                        Text("How many days before a birthday to receive a reminder. Friends with a custom reminder override this setting.")
                            .foregroundColor(AppTheme.secondary)
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)

                    // Home screen
                    Section {
                        HStack {
                            Label("Show upcoming", systemImage: "calendar")
                                .foregroundColor(AppTheme.primary)
                            Spacer()
                            Stepper(
                                "\(settingsManager.upcomingDaysToShow) days",
                                value: $settingsManager.upcomingDaysToShow,
                                in: 7...180,
                                step: 7
                            )
                            .fixedSize()
                            .foregroundColor(AppTheme.secondary)
                        }
                    } header: {
                        SectionHeader(title: "Home Screen")
                    } footer: {
                        Text("How far ahead to display upcoming birthdays on the home screen.")
                            .foregroundColor(AppTheme.secondary)
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)

                    // Actions
                    Section {
                        Button {
                            showingRescheduleConfirm = true
                        } label: {
                            Label("Reschedule all reminders", systemImage: "arrow.clockwise")
                                .foregroundColor(AppTheme.accent)
                        }

                        Button {
                            exportList()
                        } label: {
                            Label("Share birthday list", systemImage: "square.and.arrow.up")
                                .foregroundColor(AppTheme.accent)
                        }

                        Button {
                            showingFileImporter = true
                        } label: {
                            Label("Import birthday list", systemImage: "square.and.arrow.down")
                                .foregroundColor(AppTheme.accent)
                        }
                    } header: {
                        SectionHeader(title: "Actions")
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)

                    // Stats
                    Section {
                        statRow("Total friends",    "\(friendsManager.friends.count)")
                        statRow("With birthday",    "\(friendsManager.friendsWithBirthday.count)")
                        statRow("Without birthday", "\(friendsManager.friendsWithoutBirthday.count)")
                    } header: {
                        SectionHeader(title: "Statistics")
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reschedule Reminders?", isPresented: $showingRescheduleConfirm) {
                Button("Reschedule") {
                    NotificationManager.scheduleAll(
                        friends:     friendsManager.friends,
                        defaultDays: settingsManager.defaultReminderDays
                    )
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All existing birthday reminders will be cancelled and rescheduled using the current default.")
            }
            .alert("Import Failed", isPresented: $showingImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importError?.errorDescription ?? "Unknown error.")
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [UTType("com.birthdayreminder.birthdaybell") ?? .data]
            ) { result in
                handleFileImport(result)
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .shareExport(let url):
                    ActivityView(items: [url])
                        .onDisappear {
                            try? FileManager.default.removeItem(at: url)
                        }
                case .importReview(let importResult):
                    BirthdayImportView(result: importResult)
                        .environmentObject(friendsManager)
                        .environmentObject(settingsManager)
                }
            }
        }
    }

    // MARK: - Export

    private func exportList() {
        guard let data = friendsManager.exportData() else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "BirthdayBell-\(formatter.string(from: Date())).birthdaybell"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        guard (try? data.write(to: url)) != nil else { return }
        activeSheet = .shareExport(url)
    }

    // MARK: - Import

    private func handleFileImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }
        do {
            let importResult = try friendsManager.importMerge(from: data)
            activeSheet = .importReview(importResult)
        } catch let error as ImportError {
            importError = error
            showingImportError = true
        } catch {
            importError = .invalidFormat
            showingImportError = true
        }
    }

    // MARK: - Helpers

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(AppTheme.primary)
            Spacer()
            Text(value)
                .foregroundColor(AppTheme.secondary)
        }
    }
}

// MARK: - UIActivityViewController wrapper

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
