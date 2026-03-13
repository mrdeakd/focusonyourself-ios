import SwiftUI

struct HomeScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: HomeViewModel

    private let dateFont = Font.custom("Inter", size: 13).weight(.regular)
    private let streakLabelFont = Font.custom("Inter", size: 13).weight(.semibold)
    private let iconSize: CGFloat = 14

    init(appState: AppState) {
        _viewModel = State(initialValue: HomeViewModel(appState: appState))
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
                    .font(.foyNavTitle)
                    .foregroundStyle(Color.foyForeground)
                Text(viewModel.formattedDate)
                    .font(dateFont)
                    .foregroundStyle(Color.foyForegroundSecondary)
            }
            Spacer()
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "flame.fill")
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(Color.foyOrange)
                Text("\(viewModel.streakCount) days")
                    .font(streakLabelFont)
                    .foregroundStyle(Color.foyOrange)
            }
            .padding(.vertical, Spacing.xxs)
            .padding(.horizontal, Spacing.sm)
            .background(Color.foyOrangeTint)
            .clipShape(Capsule())
        }
    }
}
