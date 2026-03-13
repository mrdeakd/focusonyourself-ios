import SwiftUI

struct HomeScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: HomeViewModel

    init(appState: AppState) {
        _viewModel = State(initialValue: HomeViewModel(profile: appState.profile))
    }

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerRow
                    AffirmationCardView(
                        quote: viewModel.todayAffirmation.quote,
                        category: viewModel.todayAffirmation.category
                    )
                    MoodPickerView(
                        selectedMood: viewModel.selectedMood,
                        onSelect: { viewModel.selectMood($0) },
                        onCheckIn: { viewModel.completeCheckIn() }
                    )
                }
                .padding(.top, Spacing.md)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.screenBottom)
            }
        }
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(viewModel.greeting)
                    .font(.inter(18, weight: .medium))
                    .foregroundStyle(Color.foyForeground)
                Text(viewModel.formattedDate)
                    .font(.inter(13))
                    .foregroundStyle(Color.foyForegroundSecondary)
            }
            Spacer()
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "flame.fill")
                    .resizable()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(Color.foyOrange)
                Text("\(viewModel.streakCount) days")
                    .font(.inter(13, weight: .semibold))
                    .foregroundStyle(Color.foyOrange)
            }
            .padding(.vertical, Spacing.xxs)
            .padding(.horizontal, Spacing.sm)
            .background(Color.foyOrangeTint)
            .clipShape(Capsule())
        }
    }
}
