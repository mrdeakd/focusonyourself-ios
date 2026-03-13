import SwiftUI

struct SettingsScreen: View {
    @Environment(AppState.self) private var appState

    @State private var draftName: String = ""
    @State private var draftCategories: Set<AffirmationCategory> = []
    @State private var draftNotifications: Bool = true
    @State private var draftAppleIntelligence: Bool = false

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed header
                HStack {
                    Text("Settings")
                        .font(.inter(18, weight: .medium))
                        .foregroundStyle(Color.foyForeground)
                    Spacer()
                    Button("Save") {
                        save()
                    }
                    .font(.inter(15, weight: .medium))
                    .foregroundStyle(Color.foyNavy)
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        nameSection
                        categoriesSection
                        notificationsSection
                        appleIntelligenceSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear { loadDrafts() }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("YOUR NAME")
            TextField("Your name", text: $draftName)
                .font(.inter(15))
                .foregroundStyle(Color.foyForeground)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color.foyCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.foyBorder, lineWidth: 1)
                )
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("AFFIRMATION CATEGORIES")
            VStack(spacing: 0) {
                ForEach(Array(AffirmationCategory.allCases.enumerated()), id: \.element.id) { index, category in
                    VStack(spacing: 0) {
                        if index > 0 {
                            Divider()
                                .background(Color.foyBorder)
                        }
                        HStack {
                            Text(category.displayName)
                                .font(.inter(15))
                                .foregroundStyle(Color.foyForeground)
                            Spacer()
                            let isSelected = draftCategories.contains(category)
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(isSelected ? Color.foyNavy : Color.foyButtonDisabled)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if draftCategories.contains(category) {
                                draftCategories.remove(category)
                            } else {
                                draftCategories.insert(category)
                            }
                        }
                    }
                }
            }
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("NOTIFICATIONS")
            HStack {
                Text("Daily 9am Reminder")
                    .font(.inter(15))
                    .foregroundStyle(Color.foyForeground)
                Spacer()
                FOYToggle(isOn: $draftNotifications)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var appleIntelligenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("APPLE INTELLIGENCE")
            VStack(spacing: 0) {
                HStack {
                    Text("Apple Intelligence")
                        .font(.inter(15))
                        .foregroundStyle(Color.foyForeground)
                    Spacer()
                    FOYToggle(isOn: $draftAppleIntelligence)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()
                    .background(Color.foyBorder)
                    .padding(.horizontal, 16)

                Text("After check-in, generate a personalized affirmation using on-device AI. Requires iPhone 15 Pro or newer.")
                    .font(.inter(12))
                    .foregroundStyle(Color.foyPlaceholder)
                    .lineSpacing(6)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.inter(11, weight: .medium))
            .foregroundStyle(Color.foyPlaceholder)
            .kerning(0.8)
    }

    private func loadDrafts() {
        draftName = appState.profile.name
        draftCategories = Set(appState.profile.selectedCategories)
        draftNotifications = appState.profile.notificationsEnabled
        draftAppleIntelligence = appState.profile.appleIntelligenceEnabled
    }

    private func save() {
        var updated = appState.profile
        updated.name = draftName
        updated.selectedCategories = AffirmationCategory.allCases.filter { draftCategories.contains($0) }
        updated.notificationsEnabled = draftNotifications
        updated.appleIntelligenceEnabled = draftAppleIntelligence
        appState.updateProfile(updated)
    }
}
