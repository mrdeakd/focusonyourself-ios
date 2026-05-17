import SwiftUI

struct MeditateScreen: View {
    @State private var viewModel = MeditateViewModel()

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeaderView(title: "Meditate")

                CategoryFilterChipsView(viewModel: viewModel)
                    .padding(.bottom, Spacing.sm)

                if let error = viewModel.error {
                    InlineErrorView(error: error)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.sm)
                }

                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        if viewModel.isLoading {
                            ForEach(0..<8, id: \.self) { _ in
                                SessionCardView(session: .placeholder, isPro: false)
                                    .redacted(reason: .placeholder)
                                    .shimmer()
                            }
                        } else {
                            ForEach(viewModel.sessions) { session in
                                Button {
                                    viewModel.handleSessionTap(session)
                                } label: {
                                    SessionCardView(session: session, isPro: viewModel.isPro)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.screenBottom)
                }
                .scrollIndicators(.hidden)
            }
        }
        .fullScreenCover(item: Bindable(viewModel).selectedSession) { session in
            MeditationPlayerView(session: session)
        }
        .sheet(isPresented: Bindable(viewModel).showingPaywall) {
            PaywallScreen()
        }
        .task {
            await viewModel.loadSessions()
        }
        .onChange(of: viewModel.selectedCategory) {
            Task { await viewModel.loadSessions() }
        }
    }
}
