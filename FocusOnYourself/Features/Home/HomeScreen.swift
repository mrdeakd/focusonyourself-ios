import SwiftUI

struct HomeScreen: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                // Screen has no header: personalized greeting with streak badge
                HomeHeaderRow(
                    greeting: viewModel.greeting,
                    date: viewModel.formattedDate,
                    streakCount: viewModel.streakCount
                )

                if let error = viewModel.error {
                    InlineErrorView(error: error)
                }

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        AffirmationsCarouselView(
                            affirmations: viewModel.generatedQuotes,
                            isLoading: viewModel.isGeneratingAffirmation
                        )
                        .padding(.horizontal, -Spacing.screenHorizontal)
                        if viewModel.hasCheckedIn {
                            CheckedInCardView(
                                mood: viewModel.todaysMood,
                                streakCount: viewModel.streakCount,
                                viewModel: viewModel
                            )
                        } else {
                            MoodPickerView(
                                selectedMood: viewModel.selectedMood,
                                feelingsDescription: Bindable(viewModel).feelingsDescription,
                                onSelect: { viewModel.selectMood($0) },
                                onCheckIn: { viewModel.completeCheckIn() }
                            )
                        }

                        HomeArticlesSectionView(
                            articles: viewModel.articles,
                            onSelect: { viewModel.selectArticle($0) }
                        )
                    }
                    .padding(.bottom, Spacing.screenBottom)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .padding(.top, Spacing.md)
            .padding(.horizontal, Spacing.screenHorizontal)
        }
        .simultaneousGesture(TapGesture().onEnded {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        })
        .sheet(item: Bindable(viewModel).selectedArticle) { article in
            ArticleDetailView(article: article)
        }
        .sheet(isPresented: Bindable(viewModel).showingContextSheet) {
            DailyFactorsSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.loadArticles()
            await viewModel.generateAffirmationIfNeeded()
        }
    }
}
