import SwiftUI

struct HomeScreen: View {
    @State private var viewModel = HomeViewModel()

    private let iconSize: CGFloat = 14

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                headerRow

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        AffirmationsCarouselView(
                            affirmations: viewModel.todayAffirmations,
                            isLoading: viewModel.isGeneratingAffirmation
                        )
                        .padding(.horizontal, -Spacing.xl)
                        if viewModel.hasCheckedIn {
                            CheckedInCardView(
                                mood: viewModel.todaysMood,
                                streakCount: viewModel.streakCount
                            )
                        } else {
                            MoodPickerView(
                                selectedMood: viewModel.selectedMood,
                                feelingsDescription: Bindable(viewModel).feelingsDescription,
                                onSelect: { viewModel.selectMood($0) },
                                onCheckIn: { viewModel.completeCheckIn() }
                            )
                        }
                    }
                }
            }
            .padding(.top, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxxs)
        }
        .simultaneousGesture(TapGesture().onEnded {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        })
        .task {
            await viewModel.generateAffirmationIfNeeded()
        }
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(viewModel.greeting)
                    .font(.foyNavTitle)
                    .foregroundStyle(Color.foyForeground)
                Text(viewModel.formattedDate)
                    .font(.foyCaption)
                    .foregroundStyle(Color.foyForegroundSecondary)
            }
            Spacer()
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "flame.fill")
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(Color.foyOrange)
                Text("\(viewModel.streakCount) days")
                    .font(.foyCaptionSemibold)
                    .foregroundStyle(Color.foyOrange)
            }
            .padding(.vertical, Spacing.xxs)
            .padding(.horizontal, Spacing.sm)
            .background(Color.foyOrangeTint)
            .clipShape(Capsule())
        }
    }
}
